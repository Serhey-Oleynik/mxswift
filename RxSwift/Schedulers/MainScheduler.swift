//
//  MainScheduler.swift
//  RxSwift
//
//  Created by Krunoslav Zaher on 2/8/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Dispatch

/**
Abstracts work that needs to be performed on `DispatchQueue.main`. In case `schedule` methods are called from `DispatchQueue.main`, it will perform action immediately without scheduling.

This scheduler is usually used to perform UI work.

Main scheduler is a specialization of `SerialDispatchQueueScheduler`.

This scheduler is optimized for `observeOn` operator. To ensure observable sequence is subscribed on main thread using `subscribeOn`
operator please use `ConcurrentMainScheduler` because it is more optimized for that purpose.
*/
public final class MainScheduler : SerialDispatchQueueScheduler {

    private let _mainQueue: DispatchQueue

    var numberEnqueued = AtomicInt(0)

    /// Initializes new instance of `MainScheduler`.
    public init() {
        self._mainQueue = DispatchQueue.main
        super.init(serialQueue: self._mainQueue)
    }

    /// Singleton instance of `MainScheduler`
    public static let instance = MainScheduler()

    /// Singleton instance of `MainScheduler` that always schedules work asynchronously
    /// and doesn't perform optimizations for calls scheduled from main queue.
    public static let asyncInstance = SerialDispatchQueueScheduler(serialQueue: DispatchQueue.main)

    /// In case this method is called on a background thread it will throw an exception.
    public class func ensureExecutingOnScheduler(errorMessage: String? = nil) {
        if !DispatchQueue.isMain {
            rxFatalError(errorMessage ?? "Executing on background thread. Please use `MainScheduler.instance.schedule` to schedule work on main thread.")
        }
    }

    override func scheduleInternal<StateType>(_ state: StateType, action: @escaping (StateType) -> Disposable) -> Disposable {
        let previousNumberEnqueued = self.numberEnqueued.increment()

        if DispatchQueue.isMain && previousNumberEnqueued == 0 {
            let disposable = action(state)
            self.numberEnqueued.decrement()
            return disposable
        }

        let cancel = SingleAssignmentDisposable()

        self._mainQueue.async {
            if !cancel.isDisposed {
                _ = action(state)
            }

            self.numberEnqueued.decrement()
        }

        return cancel
    }
}
