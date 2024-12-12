// swift-tools-version: 5.10.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ComposableContacts",
    platforms: [
        .iOS(.v13),
        .macOS(.v13),
        .watchOS(.v10),
    ],
    products: [
        .library(
            name: "ComposableContacts",
            targets: ["ComposableContacts"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.6.2"),
        .package(url: "https://github.com/MultiScott/CNContactStoreWrapper", from: "0.2.2"),
    ],
    targets: [
        .target(
            name: "ComposableContacts",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
                .product(name: "CNContactStoreWrapper", package: "CNContactStoreWrapper"),
            ]
        ),
        .testTarget(
            name: "ComposableContactsTests",
            dependencies: ["ComposableContacts"]
        ),
    ]
)
