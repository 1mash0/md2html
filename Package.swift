// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "md2html",
    platforms: [.macOS(.v13)],
    products: [
            .executable(
                name: "md2h",
                targets: [
                    "md2html"
                ]
            )
        ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.6.1"),
        .package(url: "https://github.com/JohnSundell/Ink.git", from: "0.6.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "md2html",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Ink", package: "Ink")
            ]
        ),
    ]
)
