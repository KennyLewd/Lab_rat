// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LabRat",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "LabRat", targets: ["LabRat"])],
    targets: [
        .executableTarget(name: "LabRat"),
        .testTarget(name: "LabRatTests", dependencies: ["LabRat"])
    ]
)
