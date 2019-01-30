//
//  ObserverBase.swift
//  RxSwift
//
//  Created by Krunoslav Zaher on 2/15/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

class ObserverBase<ElementType> : Disposable, ObserverType {
    typealias E = ElementType

    private var _isStopped = AtomicInt(0)

    func on(_ event: Event<E>) {
        switch event {
        case .next:
            if self._isStopped.load() == 0 {
                self.onCore(event)
            }
        case .error, .completed:
            if self._isStopped.fetchOr(1) == 0 {
                self.onCore(event)
            }
        }
    }

    func onCore(_ event: Event<E>) {
        rxAbstractMethod()
    }

    func dispose() {
        self._isStopped.fetchOr(1)
    }
}
