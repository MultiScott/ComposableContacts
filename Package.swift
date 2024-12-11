// swift-tools-version: 6.0
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
        .package(url: "https://github.com/pointfreeco/swift-sharing", from: "1.0.3"),
        .package(url: "https://github.com/pointfreeco/swift-perception", from: "1.4.1")
    ],
    targets: [
        .target(
            name: "ComposableContacts",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "DependenciesMacros", package: "swift-dependencies"),
                .product(name: "CNContactStoreWrapper", package: "CNContactStoreWrapper"),
                .product(name: "Sharing", package: "swift-sharing"),
                .product(name: "Perception", package: "swift-perception"),
            ]
        ),
        .testTarget(
            name: "ComposableContactsTests",
            dependencies: ["ComposableContacts"]
        ),
    ]
)


