# AsyncTimeSequences

![badge-platforms][] [![badge-spm][]][spm]

(Work in Progress)

This is a convenient package to add missing time async sequences such as debounce, delay, timeout...

These sequences are recommended to be used with AsyncStreams, but as they conform to AsyncSequence the possibilities are endless.

## How to use

For all examples, please first consider this sample sequence (remember that you can use any Async Sequence):

```swift
let asyncSequence = AsyncStream { (continuation:AsyncStream<Int>.Continuation) in
    Task {
        let items = [1,2,3,4,5,6]
        for item in items {
            continuation.yield(item)
            try? await Task.sleep(nanoseconds: 1000000)
        }
        continuation.finish()
    }
}
```

All the async sequences will need an async scheduler. For convenience, there is one already bundled with this package. You should be good with the main one provided. But you are free to add your custom one if required.

### Timeout

```swift
asyncSequence.timeout(for: 2, scheduler: MainAsyncScheduler.default)
```

### Delay

```swift
asyncSequence.delay(for: 3, scheduler: MainAsyncScheduler.default)
```

### Debounce

```swift
asyncSequence.debounce(for: 3, scheduler: MainAsyncScheduler.default)
```

### Throttle

```swift
asyncSequence.throttle(for: 3, scheduler: MainAsyncScheduler.default, latest: true)
```

### MeasureInterval

```swift
asyncSequence.measureInterval(using: MainAsyncScheduler.default)
```

## How to test

(Coming soon)

## Installation

### Swift Package Manager

In Xcode, select File --> Swift Packages --> Add Package Dependency and then add the following url:

```swift
https://github.com/Henryforce/AsyncTimeSequences
```

[badge-platforms]: https://img.shields.io/badge/platforms-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS-lightgrey.svg

[badge-spm]: https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg

[spm]: https://github.com/apple/swift-package-manager
