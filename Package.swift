// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SynchronousLock",
    products: [
        .library(
            name: "SynchronousLock",
            targets: ["SynchronousLock"]),
    ],
    targets: [
        .target(
            name: "SynchronousLock",
			swiftSettings: [
				.swiftLanguageMode(.v6)
			],
		),
        .testTarget(
            name: "SynchronousLockTests",
            dependencies: ["SynchronousLock"],
			swiftSettings: [
				.swiftLanguageMode(.v6)
			],
        ),
    ]
)
