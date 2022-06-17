// swift-tools-version:5.6

import PackageDescription

let package = Package(
  name: "swift-data-store",
  defaultLocalization: "en",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15)
  ],
  products: [
    .library(name: "SwiftDataStore", targets: ["SwiftDataStore"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "SwiftDataStore",
      dependencies: []
    ),
    .testTarget(
      name: "SwiftDataStoreTests",
      dependencies: ["SwiftDataStore"]
    )
  ]
)
