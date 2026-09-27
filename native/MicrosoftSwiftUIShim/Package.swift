// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MicrosoftSwiftUIShim",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "MicrosoftSwiftUIShim", type: .dynamic, targets: ["MicrosoftSwiftUIShim"])
    ],
    targets: [
        .target(name: "MicrosoftSwiftUIShim"),
        .testTarget(name: "MicrosoftSwiftUIShimTests", dependencies: ["MicrosoftSwiftUIShim"])
    ]
)
