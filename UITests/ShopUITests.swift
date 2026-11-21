import XCTest

final class ShopUITests: XCTestCase {
  @MainActor
  private func launch(mockState: String? = nil) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchEnvironment["API_BASE_URL"] =
      ProcessInfo.processInfo.environment["MOCK_BASE_URL"] ?? "http://127.0.0.1:47851"
    if let mockState {
      app.launchEnvironment["MOCK_STATE"] = mockState
    }
    app.launch()
    return app
  }

  @MainActor
  private func waitForStatus(_ text: String, in app: XCUIApplication) {
    let status = app.staticTexts["status"]
    XCTAssertTrue(status.waitForExistence(timeout: 120))
    let shown = NSPredicate(format: "label == %@", text)
    wait(for: [expectation(for: shown, evaluatedWith: status)], timeout: 120)
  }

  @MainActor
  func testProductsComeFromTheMock() {
    let app = launch()
    XCTAssertTrue(app.staticTexts["Espresso cup"].waitForExistence(timeout: 120))
  }

  @MainActor
  func testCheckoutSucceeds() {
    let app = launch()
    waitForStatus("Ready", in: app)
    app.buttons["buy"].tap()
    waitForStatus("Order placed", in: app)
  }

  @MainActor
  func testCheckoutShowsADeclinedCard() {
    let app = launch(mockState: "declined")
    waitForStatus("Ready", in: app)
    app.buttons["buy"].tap()
    waitForStatus("Payment declined", in: app)
  }
}
