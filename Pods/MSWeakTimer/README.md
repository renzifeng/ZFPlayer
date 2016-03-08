MSWeakTimer
===========

## Description

Thread-safe `NSTimer` drop-in alternative that doesn't retain the target and supports being used with `GCD` queues.

## Motivation
The first motivation for this class was to have a type of timer that objects could *own* and retain, without this creating a retain cycle ( *like `NSTimer` causes, since it retains its target* ). This way you can just release the timer in the `-dealloc` method of the object class that owns the timer.

The other problem when using `NSTimer` is this note on the documentation:

>**Special Considerations**

>You must send this message from the thread on which the timer was installed. If you send this message from another thread, the input source associated with the timer may not be removed from its run loop, which could prevent the thread from exiting properly.

More often than not, an object needs to create a timer and invalidate it when a certain event occurs. However, doing this when that object works with a private `GCD` queue gets tricky. This timer object is thread safe and doesn't have the notion of run loop, so it can be used with `GCD` queues and installed / invalidated from any thread or queue.

[Related Stackoverflow question](http://stackoverflow.com/questions/14653951/is-it-safe-to-schedule-and-invalidate-nstimers-on-a-gcd-serial-queue/14657684#14657684).

## Implementation
The implementation of `MSWeakTimer` was reviewed and validated by a `libdispatch` (`GCD`) engineer at the WWDC 2013 Core OS Lab.

## How to Use

Create an `MSWeakTimer` object with this class method:

```objc
+ (MSWeakTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)timeInterval
                                         target:(id)target
                                       selector:(SEL)selector
                                       userInfo:(id)userInfo
                                        repeats:(BOOL)repeats
                                  dispatchQueue:(dispatch_queue_t)dispatchQueue;
```

Check out the code in the [sample app](https://github.com/mindsnacks/MSWeakTimer/blob/master/MSWeakTimer-SampleProject/MSWeakTimer-SampleProject/Classes/MSSampleViewController.m).

## Installation

- Using [Cocoapods](http://cocoapods.org/):

Just add this line to your `Podfile`:

```
pod 'MSWeakTimer', '~> 1.1.0'
```

- Manually:

Simply add the files `MSWeakTimer.h` and `MSWeakTimer.m` to your project.

## Compatibility

- Requires ARC. If you want to use it in a project without ARC, mark ```MSWeakTimer.m``` with the linker flag ```-fobjc-arc```.
- Supports iOS iOS5+ and Mac OSX 10.7+.

## License
`MSWeakTimer` is available under the MIT license. See the LICENSE file for more info.
