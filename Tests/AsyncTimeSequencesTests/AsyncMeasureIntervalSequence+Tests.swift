//
//  AsyncMeasureIntervalSequence+Tests.swift
//  AsyncTimeSequencesTests
//
//  Created by Henry Javier Serrano Echeverria on 27/12/21.
//

import Foundation

import XCTest
import CombineSchedulers
@testable import AsyncTimeSequences

final class AsyncMeasureIntervalSequence_Tests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testAsyncMeasureIntervalSequence() async {
        // Given
        let scheduler = DispatchQueue.asyncTest
        let items = [1,5,10,15,20]
        let expectedItems: [DispatchQueue.SchedulerTimeType.Stride] = [
            .seconds(3),
            .seconds(8),
            .seconds(12),
            .seconds(1000)
        ]
        var receivedItems = [DispatchQueue.SchedulerTimeType.Stride]()
        
        // When
        let sequence = ControlledDataSequence(
            items: items
        )
        var iterator = sequence
            .measureInterval(using: scheduler)
            .makeAsyncIterator()
        
        await sequence.iterator.waitForItemsToBeSent(1)
        await scheduler.waitForScheduledJobs(count: 1)
        
        for item in expectedItems {
            scheduler.advance(by: item)
            await sequence.iterator.waitForItemsToBeSent(1)
            await scheduler.waitForScheduledJobs(count: 1)
        }
        
        while receivedItems.count < expectedItems.count, let value = await iterator.next() {
            receivedItems.append(value)
        }

        // Then
        XCTAssertEqual(receivedItems, expectedItems)
    }

}
