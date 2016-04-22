//
//  Just.swift
//  Rx
//
//  Created by Krunoslav Zaher on 8/30/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation

class JustScheduledSink<O: ObserverType> : Sink<O> {
    typealias Parent = JustScheduled<O.E>

    private let _parent: Parent

    init(parent: Parent, observer: O) {
        _parent = parent
        super.init(observer: observer)
    }

    func run() -> Disposable {
        let scheduler = _parent._scheduler
        return scheduler.schedule(state: _parent._element) { element in
            self.forwardOn(event: .Next(element))
            return scheduler.schedule(state: ()) { _ in
                self.forwardOn(event: .Completed)
                return NopDisposable.instance
            }
        }
    }
}

class JustScheduled<Element> : Producer<Element> {
    private let _scheduler: ImmediateSchedulerType
    private let _element: Element

    init(element: Element, scheduler: ImmediateSchedulerType) {
        _scheduler = scheduler
        _element = element
    }

    override func subscribe<O : ObserverType where O.E == E>(observer: O) -> Disposable {
        let sink = JustScheduledSink(parent: self, observer: observer)
        sink.disposable = sink.run()
        return sink
    }
}

class Just<Element> : Producer<Element> {
    private let _element: Element
    
    init(element: Element) {
        _element = element
    }
    
    override func subscribe<O : ObserverType where O.E == Element>(observer: O) -> Disposable {
        observer.on(event: .Next(_element))
        observer.on(event: .Completed)
        return NopDisposable.instance
    }
}