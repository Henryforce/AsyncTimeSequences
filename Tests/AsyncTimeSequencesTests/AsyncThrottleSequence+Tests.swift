//
//  AsyncThrottleSequence+Tests.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 14/12/21.
//

import XCTest
@testable import AsyncTimeSequences
import AsyncTimeSequencesSupport

final class AsyncThrottleSequenceTests: XCTestCase {
    
    func testAsyncThrottleSequenceWithLatest() async {
        // Given
        let scheduler = TestAsyncScheduler()
        let items = [1,5,10,15,20]
        let expectedItems = [20]
        let baseDelay = 5.0
        var receivedItems = [Int]()
        let sequence = ControlledDataSequence(
            items: items
        )
        var iterator = sequence
            .throttle(
                for: baseDelay,
                scheduler: scheduler,
                latest: true
            ).makeAsyncIterator()

        // When
        await sequence.iterator.waitForItemsToBeSent(5) // Wait for all items to be dispatched
        await scheduler.advance(by: baseDelay) // Wait for all scheduled to be executed

        while receivedItems.count < expectedItems.count, let value = await iterator.next() {
            receivedItems.append(value)
        }

        // Then
        XCTAssertEqual(receivedItems, expectedItems)
    }
    
    func testAsyncThrottleSequenceWithLatestWithTwoTimeAdvances() async {
        // Given
        let scheduler = TestAsyncScheduler()
        let items = [1,5,10,15,20]
        let expectedItems = [10, 20]
        let baseDelay = 5.0
        var receivedItems = [Int]()
        let sequence = ControlledDataSequence(
            items: items
        )
        var iterator = sequence
            .throttle(
                for: baseDelay,
                scheduler: scheduler,
                latest: true
            ).makeAsyncIterator()

        // When
        await sequence.iterator.waitForItemsToBeSent(3) // Wait for 3 items to be dispatched
        await scheduler.advance(by: baseDelay) // Wait for all scheduled to be executed

        await sequence.iterator.waitForItemsToBeSent(2)
        await scheduler.advance(by: baseDelay) // Wait for all scheduled to be executed

        while receivedItems.count < expectedItems.count, let value = await iterator.next() {
            receivedItems.append(value)
        }

        // Then
        XCTAssertEqual(receivedItems, expectedItems)
    }

    func testAsyncThrottleSequenceWithoutLatestWithTwoTimeAdvances() async {
        // Given
        let scheduler = TestAsyncScheduler()
        let items = [1,5,10,15,20]
        let expectedItems = [1, 15]
        let baseDelay = 5.0
        var receivedItems = [Int]()
        let sequence = ControlledDataSequence(
            items: items
        )
        var iterator = sequence
            .throttle(
                for: baseDelay,
                scheduler: scheduler,
                latest: false
            ).makeAsyncIterator()

        // When
        await sequence.iterator.waitForItemsToBeSent(3)
        await scheduler.advance(by: baseDelay) // Wait for all scheduled to be executed

        await sequence.iterator.waitForItemsToBeSent(2)
        await scheduler.advance(by: baseDelay) // Wait for all scheduled to be executed

        while receivedItems.count < expectedItems.count, let value = await iterator.next() {
            receivedItems.append(value)
        }

        // Then
        XCTAssertEqual(receivedItems, expectedItems)
    }
    
}
