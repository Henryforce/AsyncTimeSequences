//
//  Scheduler+Sleep.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 14/11/21.
//

import Foundation
import Combine

extension Scheduler {
    public func sleep(_ interval: Self.SchedulerTimeType.Stride) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.schedule(after: self.now.advanced(by: interval)) {
                continuation.resume()
            }
        }
    }
}
