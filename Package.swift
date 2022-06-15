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
    .library(name: "DataStore", targets: ["DataStore"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "DataStore",
      dependencies: []
    ),
    .testTarget(
      name: "DataStoreTests",
      dependencies: ["DataStore"]
    )
  ]
)
