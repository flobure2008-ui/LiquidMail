// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LiquidMail",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "LiquidMail",
            targets: ["LiquidMail"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "LiquidMail",
            dependencies: [],
            path: "."
        )
    ]
)
