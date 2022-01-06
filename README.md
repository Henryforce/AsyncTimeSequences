# AsyncTimeSequences

(Work in Progress)

This is a convenient package to add missing time async sequences such as debounce, delay, timeout...

These sequences are recommended to be used with AsyncStreams, but as they conform to AsyncSequence the possibilities are endless.

## How to use

For all examples, please first consider this sample sequence (remember that you can use any Async Sequence):

```
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

```
asyncSequence.timeout(for: 2, scheduler: .main)
```

### Delay

```
asyncSequence.delay(for: 3, scheduler: .main)
```

### Debounce

```
asyncSequence.debounce(for: 3, scheduler: .main)
```

### Throttle

```
asyncSequence.throttle(for: 3, scheduler: .main, latest: true)
```

### MeasureInterval

```
asyncSequence.measureInterval(using: .main)
```

## How to test

(Coming soon)

## Installation

### Swift Package Manager
