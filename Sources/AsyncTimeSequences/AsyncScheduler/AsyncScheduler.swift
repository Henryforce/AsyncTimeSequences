//
//  AsyncScheduler.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 5/1/22.
//

import Foundation

public typealias AsyncScheduleHandler = () async -> Void

public protocol AsyncScheduler: Actor {
    var now: TimeInterval { get }
    func schedule(after: TimeInterval, handler: @escaping AsyncScheduleHandler)
}

public actor MainAsyncScheduler: AsyncScheduler {
    public static let base = MainAsyncScheduler()
    
    public var now: TimeInterval {
        Date().timeIntervalSince1970
    }
    
    public func schedule(after: TimeInterval, handler: @escaping AsyncScheduleHandler) {
        Task {
            try? await Task.sleep(milliseconds: UInt64(after * 1000))
            await handler()
        }
    }
    
}

// TODO: Decide if it is important to include these extension functions later...
//extension TimeInterval {
//    static func seconds(_ value: UInt) -> TimeInterval {
//        return TimeInterval(value)
//    }
//
//    static func milliseconds(_ value: UInt) -> TimeInterval {
//        return TimeInterval(value) * 0.001
//    }
//}
