//
//  DispatchQueueConfiguration.swift
//  Rx
//
//  Created by Krunoslav Zaher on 7/23/16.
//  Copyright © 2016 Krunoslav Zaher. All rights reserved.
//

import Foundation

struct DispatchQueueConfiguration {
    let queue: DispatchQueue
    let leeway: DispatchTimeInterval
}

private func dispatchInterval(_ interval: Foundation.TimeInterval) -> DispatchTimeInterval {
    precondition(interval >= 0.0)
    // TODO: Replace 1000 with something that actually works 
    // NSEC_PER_MSEC returns 1000000
    return DispatchTimeInterval.milliseconds(Int(interval * 1000.0))
}

extension DispatchQueueConfiguration {
    func schedule<StateType>(_ state: StateType, action: (StateType) -> Disposable) -> Disposable {
        let cancel = SingleAssignmentDisposable()

        queue.async {
            if cancel.disposed {
                return
            }


            cancel.disposable = action(state)
        }

        return cancel
    }

    func scheduleRelative<StateType>(_ state: StateType, dueTime: Foundation.TimeInterval, action: (StateType) -> Disposable) -> Disposable {
        let deadline = DispatchTime.now() + dispatchInterval(dueTime)

        let compositeDisposable = CompositeDisposable()

        let timer = DispatchSource.timer(queue: queue)
        timer.scheduleOneshot(deadline: deadline)

        // TODO:
        // This looks horrible, and yes, it is.
        // It looks like Apple has made a conceputal change here, and I'm unsure why.
        // Need more info on this.
        // It looks like just setting timer to fire and not holding a reference to it
        // until deadline causes timer cancellation.
        var timerReference: DispatchSourceTimer? = timer
        let cancelTimer = AnonymousDisposable {
            timerReference?.cancel()
            timerReference = nil
        }

        timer.setEventHandler(handler: {
            if compositeDisposable.disposed {
                return
            }
            _ = compositeDisposable.insert(action(state))
            cancelTimer.dispose()
        })
        timer.resume()

        _ = compositeDisposable.insert(cancelTimer)

        return compositeDisposable
    }

    func schedulePeriodic<StateType>(_ state: StateType, startAfter: TimeInterval, period: TimeInterval, action: (StateType) -> StateType) -> Disposable {
        let initial = DispatchTime.now() + dispatchInterval(startAfter)

        var timerState = state

        let timer = DispatchSource.timer(queue: queue)
        timer.scheduleRepeating(deadline: initial, interval: dispatchInterval(period), leeway: leeway)

        // TODO:
        // This looks horrible, and yes, it is.
        // It looks like Apple has made a conceputal change here, and I'm unsure why.
        // Need more info on this.
        // It looks like just setting timer to fire and not holding a reference to it
        // until deadline causes timer cancellation.
        var timerReference: DispatchSourceTimer? = timer
        let cancelTimer = AnonymousDisposable {
            timerReference?.cancel()
            timerReference = nil
        }

        timer.setEventHandler(handler: {
            if cancelTimer.disposed {
                return
            }
            timerState = action(timerState)
        })
        timer.resume()
        
        return cancelTimer
    }
}
