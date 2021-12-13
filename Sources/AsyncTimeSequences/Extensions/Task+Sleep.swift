//
//  Task+Sleep.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 13/11/21.
//

import Foundation

extension Task where Success == Never, Failure == Never {
    static public func sleep(seconds: UInt64) async {
        await sleep(seconds * 1000000000)
    }
    
    static public func sleep(milliseconds: UInt64) async {
        await sleep(milliseconds * 1000000)
    }
}
