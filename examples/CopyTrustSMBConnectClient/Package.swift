// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CopyTrustSMBConnectClient",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "SMBConnectMountClient",
            targets: ["SMBConnectMountClient"]
        )
    ],
    targets: [
        .target(name: "SMBConnectMountClient"),
        .testTarget(
            name: "SMBConnectMountClientTests",
            dependencies: ["SMBConnectMountClient"]
        )
    ]
)
