// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SwiftFileStore",
  platforms: [.iOS(.v14), .macOS(.v12)],
  products: [
    .library(
      name: "SwiftFileStore",
      targets: ["SwiftFileStore"]
    ),
  ],
  dependencies: [],
  targets: [
    .target(
      name: "SwiftFileStore",
      dependencies: []
    ),
    .testTarget(
      name: "SwiftFileStoreTests",
      dependencies: ["SwiftFileStore"]
    ),
  ]
)
