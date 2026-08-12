import Foundation
import Testing
@testable import SMBConnectMountClient

@MainActor
struct SMBConnectMountClientTests {
    @Test
    func buildsTheReleasedV1URLWithoutConnectionDetails() throws {
        let requestID = UUID(uuidString: "5F9A2751-35E4-46D9-9D51-2211E6EFA214")!
        let url = try SMBConnectMountContract.requestURL(
            volumeName: "Example Archive ü",
            requestID: requestID
        )
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        #expect(url.scheme == "smbconnect")
        #expect(url.host == "v1")
        #expect(url.path == "/mount")
        #expect(components?.queryItems?.map(\.name) == ["volume", "request"])
        #expect(components?.queryItems?.first?.value == "Example Archive ü")
    }

    @Test
    func derivesVolumeAndFolderFromARequiredDirectory() throws {
        let requirement = try SMBConnectMountRequirement(
            requiredDirectory: URL(fileURLWithPath: "/Volumes/Example_Archive/Projects/Example_Project")
        )

        #expect(requirement.volumeName == "Example_Archive")
        #expect(requirement.relativeFolder == "Projects/Example_Project")
        #expect(requirement.requiredDirectoryURL.path == "/Volumes/Example_Archive/Projects/Example_Project")
    }

    @Test
    func rejectsDirectoriesOutsideVolumes() {
        #expect(throws: SMBConnectMountClientError.requiredDirectoryMustBeOnAVolume) {
            try SMBConnectMountRequirement(
                requiredDirectory: URL(fileURLWithPath: "/Users/example/Example_Project")
            )
        }
    }

    @Test
    func rejectsUnsafeVolumeAndRelativeFolderValues() {
        #expect(throws: SMBConnectMountClientError.invalidVolumeName) {
            try SMBConnectMountRequirement(volumeName: "..")
        }
        #expect(throws: SMBConnectMountClientError.requiredDirectoryMustBeOnAVolume) {
            try SMBConnectMountRequirement(
                volumeName: "Example_Archive",
                relativeFolder: "/Archives"
            )
        }
        #expect(throws: SMBConnectMountClientError.requiredDirectoryMustBeOnAVolume) {
            try SMBConnectMountRequirement(
                volumeName: "Example_Archive",
                relativeFolder: "Archives/../Projects"
            )
        }
    }

    @Test
    func doesNothingWhenTheCompleteDirectoryAlreadyExists() async throws {
        let requirement = try SMBConnectMountRequirement(
            volumeName: "Example_Archive",
            relativeFolder: "Archives"
        )
        var opened = false
        let client = SMBConnectMountClient(environment: environment(
            directoryExists: { $0 == requirement.requiredDirectoryURL },
            applicationURL: { _ in URL(fileURLWithPath: "/Applications/SMB Connect.app") },
            openURL: { _ in opened = true; return true }
        ))

        #expect(await client.ensureAvailable(requirement) == .alreadyAvailable)
        #expect(!opened)
    }

    @Test
    func reportsMissingFolderWithoutRequestingAnAlreadyMountedVolume() async throws {
        let requirement = try SMBConnectMountRequirement(
            volumeName: "Example_Archive",
            relativeFolder: "Archives"
        )
        var opened = false
        let client = SMBConnectMountClient(environment: environment(
            directoryExists: { $0 == requirement.volumeURL },
            applicationURL: { _ in URL(fileURLWithPath: "/Applications/SMB Connect.app") },
            openURL: { _ in opened = true; return true }
        ))

        #expect(await client.ensureAvailable(requirement) == .volumeAvailableButFolderMissing(requestID: nil))
        #expect(!opened)
    }

    @Test
    func sendsOneRequestAndWaitsForTheCompleteDirectory() async throws {
        let requirement = try SMBConnectMountRequirement(
            volumeName: "Example_Archive",
            relativeFolder: "Archives"
        )
        var openedURLs: [URL] = []
        var directoryIsAvailable = false
        var clock = Date(timeIntervalSince1970: 0)
        let client = SMBConnectMountClient(environment: environment(
            directoryExists: { url in
                directoryIsAvailable && url == requirement.requiredDirectoryURL
            },
            applicationURL: { _ in URL(fileURLWithPath: "/Applications/SMB Connect.app") },
            openURL: { url in openedURLs.append(url); return true },
            now: { clock },
            sleep: { seconds in
                clock.addTimeInterval(seconds)
                directoryIsAvailable = true
            }
        ))

        let outcome = await client.ensureAvailable(requirement, timeout: 2, pollInterval: 0.1)
        guard case .mounted = outcome else {
            Issue.record("Expected mounted, got \(outcome)")
            return
        }
        #expect(openedURLs.count == 1)
    }

    @Test
    func doesNotSendARequestWhenNoHandlerIsInstalled() async throws {
        let requirement = try SMBConnectMountRequirement(volumeName: "Example_Archive")
        var opened = false
        let client = SMBConnectMountClient(environment: environment(
            directoryExists: { _ in false },
            applicationURL: { _ in nil },
            openURL: { _ in opened = true; return true }
        ))

        #expect(await client.ensureAvailable(requirement) == .smbConnectUnavailable)
        #expect(!opened)
    }

    @Test
    func timesOutWithoutRetryingTheRequest() async throws {
        let requirement = try SMBConnectMountRequirement(volumeName: "Example_Archive")
        var openedURLs: [URL] = []
        var clock = Date(timeIntervalSince1970: 0)
        let client = SMBConnectMountClient(environment: environment(
            directoryExists: { _ in false },
            applicationURL: { _ in URL(fileURLWithPath: "/Applications/SMB Connect.app") },
            openURL: { url in openedURLs.append(url); return true },
            now: { clock },
            sleep: { seconds in clock.addTimeInterval(seconds) }
        ))

        let outcome = await client.ensureAvailable(requirement, timeout: 0.1, pollInterval: 0.1)
        guard case .timedOut = outcome else {
            Issue.record("Expected timedOut, got \(outcome)")
            return
        }
        #expect(openedURLs.count == 1)
    }

    @Test
    func cancellationStopsPolling() async throws {
        struct ExpectedCancellation: Error { }

        let requirement = try SMBConnectMountRequirement(volumeName: "Example_Archive")
        let client = SMBConnectMountClient(environment: environment(
            directoryExists: { _ in false },
            applicationURL: { _ in URL(fileURLWithPath: "/Applications/SMB Connect.app") },
            openURL: { _ in true },
            sleep: { _ in throw ExpectedCancellation() }
        ))

        let outcome = await client.ensureAvailable(requirement)
        guard case .cancelled = outcome else {
            Issue.record("Expected cancelled, got \(outcome)")
            return
        }
    }

    private func environment(
        directoryExists: @escaping (URL) -> Bool,
        applicationURL: @escaping (URL) -> URL?,
        openURL: @escaping (URL) -> Bool,
        now: @escaping () -> Date = Date.init,
        sleep: @escaping (TimeInterval) async throws -> Void = { _ in }
    ) -> SMBConnectMountClient.Environment {
        SMBConnectMountClient.Environment(
            directoryExists: directoryExists,
            applicationURL: applicationURL,
            openURL: openURL,
            now: now,
            sleep: sleep
        )
    }
}
