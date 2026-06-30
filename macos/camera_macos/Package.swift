// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "camera_macos",
  platforms: [
    .macOS(.v10_11)
  ],
  products: [
    .library(name: "camera-macos", targets: ["camera_macos"])
  ],
  dependencies: [
    .package(name: "FlutterFramework", path: "../FlutterFramework")
  ],
  targets: [
    .target(
      name: "camera_macos",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework")
      ]
    )
  ]
)