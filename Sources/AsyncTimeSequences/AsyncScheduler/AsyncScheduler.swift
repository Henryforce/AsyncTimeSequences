//
//  AsyncScheduler.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 5/1/22.
//

import Foundation

public typealias AsyncSchedulerHandler = () async -> Void

public protocol AsyncScheduler: Actor {
    var now: TimeInterval { get }
    
    @discardableResult
    func schedule(after: TimeInterval, handler: @escaping AsyncSchedulerHandler) -> Task<Void, Never>
}

public actor MainAsyncScheduler: AsyncScheduler {
    public static let `default` = MainAsyncScheduler()
    
    lazy var queue = MinimumPriorityQueue()
    lazy var idCounter: UInt = 0
    lazy var completedElementIds = Set<UInt>()
    lazy var cancelledElementIds = Set<UInt>()
    
    public var now: TimeInterval {
        Date().timeIntervalSince1970
    }
    
    /// Schedule async-closures to be executed in order based on the timeinterval provided.
    ///
    /// - parameter after: TimeInterval to wait until execution
    /// - parameter handler: async closure to be executed when 'after' time elapses
    ///
    /// - Returns: reference to a Task which supports cancellation
    ///
    /// - Complexity: O(log n) where n is the number of elements currently scheduled
    @discardableResult
    public func schedule(
        after: TimeInterval,
        handler: @escaping AsyncSchedulerHandler
    ) -> Task<Void, Never> {
        let currentId = idCounter
        let element = AsyncSchedulerHandlerElement(
            handler: handler,
            id: currentId,
            time: now + after
        )
        
        queue.enqueue(element)
        
        increaseCounterId()
        
        return Task {
            try? await Task.sleep(nanoseconds: UInt64(after * 1000000000))
            await complete(currentId: currentId, cancelled: Task.isCancelled)
        }
    }
    
    /// Based on the timeIntervalSince1970 from Date, the smallest intervals will need
    /// to complete before other elements' handlers can be executed. Due to the nature
    /// of Tasks, there could be some situations where some tasks scheduled to finish
    /// before others finish first. This could potentially have unwanted behaviors on
    /// objects scheduling events. To address this matter, a minimum priority queue
    /// is critical to always keep the first element that should be completed in the
    /// top of the queue. Once its task completes, a Set will keep track of all
    /// completed ID tasks that are yet to be executed. If the current top element of
    /// the queue has already completed, its closure will execute. This will repeat
    /// until all completed top elements of the queue are executed.
    /// The obvious drawback of this handling, is that a small delay could be
    /// introduced to some scheduled async-closures. Ideally, this would be in the
    /// order of micro/nanoseconds depending of the system load.
    ///
    /// - parameter currentId: integer variable denoting handler/task id
    /// - parameter cancelled: boolean flag required to determine whether or not to execute the handler
    ///
    /// - Complexity: O(log n) where n is the number of elements currently scheduled
    private func complete(currentId: UInt, cancelled: Bool) async {
        completedElementIds.insert(currentId)
        if cancelled {
            cancelledElementIds.insert(currentId)
        }
        
        while let minElement = queue.peek, completedElementIds.contains(minElement.id) {
            queue.removeFirst()
            completedElementIds.remove(minElement.id)
            // If the current minimum element id is not cancelled, proceed to
            // complete its handler. Otherwise, skip and remove it from the set
            guard !cancelledElementIds.contains(minElement.id) else {
                cancelledElementIds.remove(minElement.id)
                continue
            }
            await minElement.handler()
        }
    }
    
    private func increaseCounterId() {
        if idCounter == UInt.max {
            idCounter = .zero
        } else {
            idCounter += 1
        }
    }
}
