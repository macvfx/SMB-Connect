import AppKit
import Foundation

public enum SMBConnectMountClientError: Error, Equatable, LocalizedError {
    case invalidVolumeName
    case requiredDirectoryMustBeOnAVolume

    public var errorDescription: String? {
        switch self {
        case .invalidVolumeName:
            return "The SMB Connect Mount Name is invalid."
        case .requiredDirectoryMustBeOnAVolume:
            return "The required directory must be below /Volumes/<Mount Name>."
        }
    }
}

/// The storage identity CopyTrust owns: a stable mounted-volume name and a
/// folder on that volume. It contains no SMB endpoint or credential data.
public struct SMBConnectMountRequirement: Equatable, Sendable {
    public let volumeName: String
    public let relativeFolder: String

    public init(volumeName: String, relativeFolder: String = "") throws {
        let volumeName = volumeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !volumeName.isEmpty,
              volumeName != ".",
              volumeName != "..",
              volumeName.count <= 255,
              !volumeName.contains("/")
        else {
            throw SMBConnectMountClientError.invalidVolumeName
        }

        guard !relativeFolder.hasPrefix("/") else {
            throw SMBConnectMountClientError.requiredDirectoryMustBeOnAVolume
        }
        let folder = relativeFolder.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if !folder.isEmpty {
            let components = folder.split(separator: "/", omittingEmptySubsequences: false)
            guard !components.contains(where: { $0.isEmpty || $0 == "." || $0 == ".." }) else {
                throw SMBConnectMountClientError.requiredDirectoryMustBeOnAVolume
            }
        }

        self.volumeName = volumeName
        self.relativeFolder = folder
    }

    public init(requiredDirectory: URL) throws {
        guard requiredDirectory.isFileURL else {
            throw SMBConnectMountClientError.requiredDirectoryMustBeOnAVolume
        }

        let components = requiredDirectory.standardizedFileURL.pathComponents
        guard components.count >= 3, components[0] == "/", components[1] == "Volumes" else {
            throw SMBConnectMountClientError.requiredDirectoryMustBeOnAVolume
        }

        try self.init(
            volumeName: components[2],
            relativeFolder: components.dropFirst(3).joined(separator: "/")
        )
    }

    public var volumeURL: URL {
        URL(fileURLWithPath: "/Volumes", isDirectory: true)
            .appendingPathComponent(volumeName, isDirectory: true)
    }

    public var requiredDirectoryURL: URL {
        guard !relativeFolder.isEmpty else { return volumeURL }
        return volumeURL.appendingPathComponent(relativeFolder, isDirectory: true)
    }
}

public enum SMBConnectMountContract {
    public static let minimumSMBConnectVersion = "0.7.4"
    public static let scheme = "smbconnect"

    public static func requestURL(
        volumeName: String,
        requestID: UUID = UUID()
    ) throws -> URL {
        let requirement = try SMBConnectMountRequirement(volumeName: volumeName)
        var components = URLComponents()
        components.scheme = scheme
        components.host = "v1"
        components.path = "/mount"
        components.queryItems = [
            URLQueryItem(name: "volume", value: requirement.volumeName),
            URLQueryItem(name: "request", value: requestID.uuidString.lowercased())
        ]
        guard let url = components.url else {
            throw SMBConnectMountClientError.invalidVolumeName
        }
        return url
    }
}

public enum SMBConnectMountOutcome: Equatable, Sendable {
    case alreadyAvailable
    case mounted(requestID: UUID)
    case volumeAvailableButFolderMissing(requestID: UUID?)
    case smbConnectUnavailable
    case requestCouldNotBeOpened(requestID: UUID)
    case timedOut(requestID: UUID)
    case cancelled(requestID: UUID)
}

/// A small caller-side client suitable for CopyTrust.
///
/// SMB Connect's v1 URL is intentionally fire-and-forget. This client sends at
/// most one request and then watches the filesystem for the required volume and
/// folder. It never receives or stores SMB connection details or credentials.
@MainActor
public struct SMBConnectMountClient {
    public struct Environment {
        public var directoryExists: (URL) -> Bool
        public var applicationURL: (URL) -> URL?
        public var openURL: (URL) -> Bool
        public var now: () -> Date
        public var sleep: (TimeInterval) async throws -> Void

        public init(
            directoryExists: @escaping (URL) -> Bool,
            applicationURL: @escaping (URL) -> URL?,
            openURL: @escaping (URL) -> Bool,
            now: @escaping () -> Date,
            sleep: @escaping (TimeInterval) async throws -> Void
        ) {
            self.directoryExists = directoryExists
            self.applicationURL = applicationURL
            self.openURL = openURL
            self.now = now
            self.sleep = sleep
        }

        @MainActor public static let live = Environment(
            directoryExists: { url in
                var isDirectory: ObjCBool = false
                return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
                    && isDirectory.boolValue
            },
            applicationURL: { NSWorkspace.shared.urlForApplication(toOpen: $0) },
            openURL: { NSWorkspace.shared.open($0) },
            now: Date.init,
            sleep: { seconds in
                try await Task<Never, Never>.sleep(
                    nanoseconds: UInt64(max(0, seconds) * 1_000_000_000)
                )
            }
        )
    }

    private let environment: Environment

    public init(environment: Environment = .live) {
        self.environment = environment
    }

    /// Requests one missing volume and waits for CopyTrust's complete required
    /// directory. A timeout is deliberately not described as a refusal because
    /// v1 has no reply channel; SMB Connect may be offline, awaiting setup, or
    /// showing the reason in its own diagnostics.
    public func ensureAvailable(
        _ requirement: SMBConnectMountRequirement,
        timeout: TimeInterval = 15,
        pollInterval: TimeInterval = 0.25
    ) async -> SMBConnectMountOutcome {
        if environment.directoryExists(requirement.requiredDirectoryURL) {
            return .alreadyAvailable
        }
        if environment.directoryExists(requirement.volumeURL) {
            return .volumeAvailableButFolderMissing(requestID: nil)
        }

        let requestID = UUID()
        let requestURL: URL
        do {
            requestURL = try SMBConnectMountContract.requestURL(
                volumeName: requirement.volumeName,
                requestID: requestID
            )
        } catch {
            return .requestCouldNotBeOpened(requestID: requestID)
        }

        guard environment.applicationURL(requestURL) != nil else {
            return .smbConnectUnavailable
        }
        guard environment.openURL(requestURL) else {
            return .requestCouldNotBeOpened(requestID: requestID)
        }

        let deadline = environment.now().addingTimeInterval(max(0, timeout))
        repeat {
            if environment.directoryExists(requirement.requiredDirectoryURL) {
                return .mounted(requestID: requestID)
            }
            if environment.directoryExists(requirement.volumeURL) {
                return .volumeAvailableButFolderMissing(requestID: requestID)
            }
            if environment.now() >= deadline {
                return .timedOut(requestID: requestID)
            }

            do {
                try await environment.sleep(max(0.05, pollInterval))
            } catch {
                return .cancelled(requestID: requestID)
            }
        } while true
    }
}
