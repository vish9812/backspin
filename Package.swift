// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "backspin",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "backspin", targets: ["backspin"]),
    ],
    targets: [
        .target(name: "ScrollCore"),
        .executableTarget(name: "backspin", dependencies: ["ScrollCore"]),
        .testTarget(name: "ScrollCoreTests", dependencies: ["ScrollCore"]),
    ]
)
