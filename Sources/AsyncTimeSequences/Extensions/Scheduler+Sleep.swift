//
//  Scheduler+Sleep.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 14/11/21.
//

import Foundation
import Combine

extension Scheduler {
    typealias AsyncSchedulerJobClosure = () async -> Void
    
    public func sleep(_ interval: Self.SchedulerTimeType.Stride) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.schedule(after: self.now.advanced(by: interval)) {
                continuation.resume()
            }
        }
    }
    
    func schedule(interval: Self.SchedulerTimeType.Stride, closure: @escaping AsyncSchedulerJobClosure) {
        self.schedule(after: self.now.advanced(by: interval)) {
            Task {
                await closure()
            }
        }
    }
}
