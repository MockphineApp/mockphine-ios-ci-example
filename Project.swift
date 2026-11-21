import ProjectDescription

let project = Project(
  name: "ShopSample",
  settings: .settings(base: ["SWIFT_VERSION": "6.0"]),
  targets: [
    .target(
      name: "ShopSample",
      destinations: .iOS,
      product: .app,
      bundleId: "com.mockphine.example.shop",
      deploymentTargets: .iOS("18.0"),
      infoPlist: .extendingDefault(with: [
        "UILaunchScreen": [:],
        "NSAppTransportSecurity": ["NSAllowsLocalNetworking": true],
      ]),
      sources: ["App/**/*.swift"]
    ),
    .target(
      name: "ShopSampleUITests",
      destinations: .iOS,
      product: .uiTests,
      bundleId: "com.mockphine.example.shop.uitests",
      deploymentTargets: .iOS("18.0"),
      sources: ["UITests/**/*.swift"],
      dependencies: [.target(name: "ShopSample")]
    ),
  ],
  schemes: [
    .scheme(
      name: "ShopSample",
      buildAction: .buildAction(targets: ["ShopSample"]),
      testAction: .targets(["ShopSampleUITests"]),
      runAction: .runAction(executable: "ShopSample")
    )
  ]
)
