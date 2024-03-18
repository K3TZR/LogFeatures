// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "LoggingFeatures",
  platforms: [.macOS(.v14),],
  
  products: [
    .library(name: "XCGWrapper", targets: ["XCGWrapper"]),
  ],

  dependencies: [
    // ----- K3TZR -----
    // ----- OTHER -----
    .package(url: "https://github.com/DaveWoodCom/XCGLogger.git", from: "7.0.1"),
  ],
  
  // --------------- Modules ---------------
  targets: [
    // XCGWrapper
    .target( name: "XCGWrapper", dependencies: [
      .product(name: "XCGLogger", package: "XCGLogger"),
      .product(name: "ObjcExceptionBridging", package: "XCGLogger"),
    ]),
  ]
  
  // --------------- Tests ---------------
)
