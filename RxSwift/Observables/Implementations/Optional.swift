//
//  Optional.swift
//  RxSwift
//
//  Created by tarunon on 2016/12/13.
//  Copyright © 2016 Krunoslav Zaher. All rights reserved.
//

import Foundation

class ObservableOptionalSink<E, O: ObserverType> : Sink<O> where E == O.E {
    typealias Parent = ObservableOptional<E>

    private let _parent: Parent

    init(parent: Parent, observer: O, cancel: Cancelable) {
        _parent = parent
        super.init(observer: observer, cancel: cancel)
    }

    func run() -> Disposable {
        return _parent._scheduler.schedule(_parent._optional) { (optional) -> Disposable in
            if let next = optional {
                self.forwardOn(.next(next))
                return self._parent._scheduler.schedule(()) { _ in
                    self.forwardOn(.completed)
                    return Disposables.create()
                }
            } else {
                self.forwardOn(.completed)
                return Disposables.create()
            }
        }
    }
}

class ObservableOptional<E> : Producer<E> {
    fileprivate let _optional: E?
    fileprivate let _scheduler: ImmediateSchedulerType

    init(optional: E?, scheduler: ImmediateSchedulerType) {
        _optional = optional
        _scheduler = scheduler
    }

    override func run<O : ObserverType>(_ observer: O, cancel: Cancelable) -> (sink: Disposable, subscription: Disposable) where O.E == E {
        let sink = ObservableOptionalSink(parent: self, observer: observer, cancel: cancel)
        let subscription = sink.run()
        return (sink: sink, subscription: subscription)
    }
}
