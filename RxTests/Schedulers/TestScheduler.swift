//
//  TestScheduler.swift
//  Rx
//
//  Created by Krunoslav Zaher on 2/8/15.
//  Copyright (c) 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation
import RxSwift

public class TestScheduler : VirtualTimeSchedulerBase {

    public struct Defaults {
        public static let created = 100
        public static let subscribed = 200
        public static let disposed = 1000
    }

    public override init(initialClock: Time) {
        super.init(initialClock: initialClock)
    }
    
    public func createHotObservable<Element>(events: [Recorded<Event<Element>>]) -> HotObservable<Element> {
        return HotObservable(testScheduler: self as AnyObject as! TestScheduler, recordedEvents: events)
    }
    
    public func createColdObservable<Element>(events: [Recorded<Event<Element>>]) -> ColdObservable<Element> {
        return ColdObservable(testScheduler: self as AnyObject as! TestScheduler, recordedEvents: events)
    }

    public func createObserver<E>(type: E.Type) -> MockObserver<E> {
        return MockObserver(scheduler: self as AnyObject as! TestScheduler)
    }
    
    public func scheduleAt(time: Time, action: () -> Void) {
        self.schedule((), time: time) { _ in
            action()
            return NopDisposable.instance
        }
    }
    
    public func start<Element>(created: Time, subscribed: Time, disposed: Time, create: () -> Observable<Element>) -> MockObserver<Element> {
        var source : Observable<Element>? = nil
        var subscription : Disposable? = nil
        let observer: MockObserver<Element> = createObserver(Element)
        
        let state : Void = ()
        
        self.schedule(state, time: created) { (state) in
            source = create()
            return NopDisposable.instance
        }
        
        self.schedule(state, time: subscribed) { (state) in
            subscription = source!.subscribe(observer)
            return NopDisposable.instance
        }
        
        self.schedule(state, time: disposed) { (state) in
            subscription!.dispose()
            return NopDisposable.instance
        }

        start()
        
        return observer
    }
    
    public func start<Element>(disposed: Time, create: () -> Observable<Element>) -> MockObserver<Element> {
        return start(Defaults.created, subscribed: Defaults.subscribed, disposed: disposed, create: create)
    }

    public func start<Element>(create: () -> Observable<Element>) -> MockObserver<Element> {
        return start(Defaults.created, subscribed: Defaults.subscribed, disposed: Defaults.disposed, create: create)
    }
}