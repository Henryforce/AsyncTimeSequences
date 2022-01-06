//
//  TestAsyncScheduler.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 5/1/22.
//

import Foundation

// TODO: Move to test sub-package
public actor TestAsyncScheduler: AsyncScheduler {
    
    struct QueueItem {
        let interval: TimeInterval
        let handler: AsyncScheduleHandler
    }
    
    private let queue = Dequeue<QueueItem>()
    private var savedContinuation: CheckedContinuation<Void, Never>?
    private var savedContinuationCount: Int = .zero
    
    public var now: TimeInterval = Date().timeIntervalSince1970
    
    public func schedule(after interval: TimeInterval, handler: @escaping AsyncScheduleHandler) {
        let item = QueueItem(interval: interval + now, handler: handler)
        queue.enqueue(item)
        
        checkForSavedContinuation()
    }
    
    public func advance(by interval: TimeInterval) async {
        let threshold = now + interval
        now = threshold
        
        while let peekedItem = queue.peek(), peekedItem.interval <= now,
              let item = queue.dequeue() {
            await item.handler()
        }
        
    }
    
    public func waitForScheduledJobs(count: Int) async {
        await withCheckedContinuation({ (continuation: CheckedContinuation<Void, Never>) in
            if (queue.count >= count) {
                continuation.resume()
                return
            }
            savedContinuation = continuation
        })
    }
    
    private func checkForSavedContinuation() {
        guard let savedContinuation = savedContinuation,
            queue.count >= savedContinuationCount else { return }
        savedContinuationCount = .zero
        savedContinuation.resume()
        self.savedContinuation = nil
    }
}
