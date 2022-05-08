//
//  AsyncMeasureIntervalSequence+Tests.swift
//  AsyncTimeSequencesTests
//
//  Created by Henry Javier Serrano Echeverria on 27/12/21.
//

import AsyncTimeSequencesSupport
import Foundation
import XCTest

@testable import AsyncTimeSequences

final class AsyncMeasureIntervalSequence_Tests: XCTestCase {

  func testAsyncMeasureIntervalSequence() async {
    // Given
    let scheduler = TestAsyncScheduler()
    let items = [1, 5, 10, 15, 20]
    let expectedItems: [TimeInterval] = [
      3,
      8,
      12,
      1000,
    ]
    var receivedItems = [TimeInterval]()

    // When
    let sequence = ControlledDataSequence(
      items: items
    )
    var iterator =
      sequence
      .measureInterval(using: scheduler)
      .makeAsyncIterator()

    await sequence.iterator.waitForItemsToBeSent(1)

    for item in expectedItems {
      await scheduler.advance(by: item)
      await sequence.iterator.waitForItemsToBeSent(1)
    }

    while receivedItems.count < expectedItems.count, let value = await iterator.next() {
      receivedItems.append(value)
    }

    // Then
    XCTAssertEqual(receivedItems, expectedItems)
  }

}
