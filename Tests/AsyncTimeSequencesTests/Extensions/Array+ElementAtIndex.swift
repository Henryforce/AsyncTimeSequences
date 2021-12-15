//
//  Array+ElementAtIndex.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 14/12/21.
//

import Foundation

extension Array {
    func element(at index: Int) -> Element? {
        guard !isEmpty, index >= 0, index < count else { return nil }
        return self[index]
    }
}
