//  Copyright © 2026 Checkout.com. All rights reserved.

import XCTest
@testable import SampleApplication

@MainActor
final class StoredCardConfigurationTests: XCTestCase {

  // MARK: - MainViewModel.storedCardConfiguration

  func test_noneSource_omitsStoredCard() {
    let viewModel = MainViewModel()
    viewModel.storedCardSource = .none

    XCTAssertNil(viewModel.storedCardConfiguration)
  }

  func test_instrumentIdsSource_splitsAndTrimsTheList() {
    let viewModel = MainViewModel()
    viewModel.storedCardSource = .instrumentIds
    viewModel.instrumentIds = " src_one , src_two ,, "

    let configuration = viewModel.storedCardConfiguration

    XCTAssertEqual(configuration?.instrumentIds, ["src_one", "src_two"])
    XCTAssertNil(configuration?.customerId)
    XCTAssertNil(configuration?.defaultInstrumentId)
  }

  func test_instrumentIdsSource_keepsDefaultInstrumentId() {
    let viewModel = MainViewModel()
    viewModel.storedCardSource = .instrumentIds
    viewModel.instrumentIds = "src_one,src_two"
    viewModel.defaultInstrumentId = " src_two "

    XCTAssertEqual(viewModel.storedCardConfiguration?.defaultInstrumentId, "src_two")
  }

  func test_instrumentIdsSource_withoutAnyId_omitsStoredCard() {
    let viewModel = MainViewModel()
    viewModel.storedCardSource = .instrumentIds
    viewModel.instrumentIds = " , "

    XCTAssertNil(viewModel.storedCardConfiguration)
  }

  func test_customerIdSource_ignoresTheInstrumentFields() {
    let viewModel = MainViewModel()
    viewModel.storedCardSource = .customerId
    viewModel.customerId = "cus_one"
    viewModel.instrumentIds = "src_one"
    viewModel.defaultInstrumentId = "src_one"

    let configuration = viewModel.storedCardConfiguration

    XCTAssertEqual(configuration?.customerId, "cus_one")
    XCTAssertNil(configuration?.instrumentIds)
    XCTAssertNil(configuration?.defaultInstrumentId)
  }

  func test_customerIdSource_withoutId_omitsStoredCard() {
    let viewModel = MainViewModel()
    viewModel.storedCardSource = .customerId
    viewModel.customerId = "  "

    XCTAssertNil(viewModel.storedCardConfiguration)
  }

  // MARK: - Encoding

  func test_encoding_usesSnakeCaseKeysAndSkipsUnsetFields() throws {
    let configuration = StoredCardConfiguration(instrumentIds: ["src_one", "src_two"],
                                                defaultInstrumentId: "src_two")

    let data = try JSONEncoder().encode(configuration)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

    XCTAssertEqual(json["instrument_ids"] as? [String], ["src_one", "src_two"])
    XCTAssertEqual(json["default_instrument_id"] as? String, "src_two")
    XCTAssertNil(json["customer_id"])
  }
}
