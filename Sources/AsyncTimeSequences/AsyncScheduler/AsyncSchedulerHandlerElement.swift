//
//  AsyncSchedulerHandlerElement.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 17/4/22.
//

import Foundation

struct AsyncSchedulerHandlerElement {
    let handler: AsyncSchedulerHandler
    let id: UInt
    let time: TimeInterval
}

extension AsyncSchedulerHandlerElement: Comparable {
    static func < (lhs: AsyncSchedulerHandlerElement, rhs: AsyncSchedulerHandlerElement) -> Bool {
        if lhs.time == rhs.time {
            return lhs.id <= rhs.id
        }
        return lhs.time < rhs.time
    }
    
    static func == (lhs: AsyncSchedulerHandlerElement, rhs: AsyncSchedulerHandlerElement) -> Bool {
        return lhs.time == rhs.time && lhs.id == rhs.id
    }
}

extension AsyncSchedulerHandlerElement {
    var unsafeMutablePointer: UnsafeMutablePointer<AsyncSchedulerHandlerElement> {
        let pointer = UnsafeMutablePointer<AsyncSchedulerHandlerElement>.allocate(capacity: 1)
        pointer.initialize(to: self)
        return pointer
    }
}
