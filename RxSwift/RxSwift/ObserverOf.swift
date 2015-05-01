//
//  ObserverOf.swift
//  Rx
//
//  Created by Krunoslav Zaher on 2/28/15.
//  Copyright (c) 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation

public struct ObserverOf<ElementType> {
    typealias Element = ElementType
    
    private typealias ObserverSinkType = (Event<Element>) -> Void

    private let observer: ObserverSinkType
    private let instance: AnyObject?

    /// Construct an instance whose `on(event)` calls `observer.on(event)`
    public init<O : ObserverType where O.Element == Element>(_ observer: O) {
        var observerReference = observer // this is because swift compiler crashing
        self.instance = observerReference
        self.observer = { e in
            return observerReference.on(e)
        }
    }
    
    /// Send `event` to this observer.
    public func on(event: Event<Element>) {
        return observer(event)
    }
}

public func dispatch<Element>(event: Event<Element>, observers: [ObserverOf<Element>]?) {
    if let observers = observers {
        observers.map { $0.on(event) }
    }
}
