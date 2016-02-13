//
//  NSControl+Rx.swift
//  RxCocoa
//
//  Created by Krunoslav Zaher on 5/31/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation
import Cocoa
#if !RX_NO_MODULE
import RxSwift
#endif

var rx_value_key: UInt8 = 0
var rx_control_events_key: UInt8 = 0

extension NSControl {

    /**
    Reactive wrapper for control event.
    */
    public var rx_controlEvent: ControlEvent<Void> {
        MainScheduler.ensureExecutingOnScheduler()

        let source = rx_lazyInstanceObservable(&rx_control_events_key) { () -> Observable<Void> in
            Observable.create { [weak self] observer in
                MainScheduler.ensureExecutingOnScheduler()

                guard let control = self else {
                    observer.on(.Completed)
                    return NopDisposable.instance
                }

                let observer = ControlTarget(control: control) { control in
                    observer.on(.Next())
                }
                
                return observer
            }.takeUntil(self.rx_deallocated)
        }
        
        return ControlEvent(events: source)
    }

    static func rx_value<C: NSControl, T: Equatable>(control: C, getter: (C) -> T, setter: (C, T) -> Void) -> ControlProperty<T> {
        MainScheduler.ensureExecutingOnScheduler()

        let source = control.rx_lazyInstanceObservable(&rx_value_key) { () -> Observable<T> in
            return Observable.create { [weak weakControl = control] (observer: AnyObserver<T>) in
                guard let control = weakControl else {
                    observer.on(.Completed)
                    return NopDisposable.instance
                }

                observer.on(.Next(getter(control)))

                let observer = ControlTarget(control: control) { _ in
                    if let control = weakControl {
                        observer.on(.Next(getter(control)))
                    }
                }
                
                return observer
            }
            .distinctUntilChanged()
            .takeUntil(control.rx_deallocated)
        }

        let bindingObserver = UIBindingObserver(UIElement: control, binding: setter)

        return ControlProperty(values: source, valueSink: bindingObserver)
    }

    /**
     Bindable sink for `enabled` property.
    */
    public var rx_enabled: AnyObserver<Bool> {
        return UIBindingObserver(UIElement: self) { (owner, value) in
            owner.enabled = value
        }.asObserver()
    }
}