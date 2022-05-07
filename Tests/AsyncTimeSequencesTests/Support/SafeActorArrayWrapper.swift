//
//  SafeActorArrayWrapper.swift
//  AsyncTimeSequences
//
//  Created by Henry Javier Serrano Echeverria on 12/2/22.
//

import Foundation

actor SafeActorArrayWrapper<T> {
  private var _elements = [T]()
  private var savedCount = 0
  private var savedContinuation: CheckedContinuation<Void, Never>?

  var elements: [T] { _elements }

  init() {}

  func append(_ element: T) {
    _elements.append(element)
    guard _elements.count >= savedCount, let continuation = savedContinuation else { return }
    continuation.resume()
    savedContinuation = nil
  }

  /// This function will wait for `count` elements to be appended to the inner array until
  /// it returns. An internal continuation helps it resume when this condition is fulfilled
  func waitForElements(_ count: Int) async {
    guard _elements.count < count else { return }
    savedCount = count
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      savedContinuation = continuation
    }
  }
}
