//
//  NSView+Rx.swift
//  Rx
//
//  Created by Krunoslav Zaher on 12/6/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

#if os(OSX)

    import Foundation
    import Cocoa
    #if !RX_NO_MODULE
    import RxSwift
    #endif

    extension Reactive where Base: NSView {
        /**
         Bindable sink for `hidden` property.
         */
        public var hidden:  UIBindingObserver<Base, Bool> {
            return UIBindingObserver(UIElement: self.base) { view, value in
                view.isHidden = value
            }
        }

        /**
         Bindable sink for `alphaValue` property.
         */
        public var alpha: UIBindingObserver<Base, CGFloat> {
            return UIBindingObserver(UIElement: self.base) { view, value in
                view.alphaValue = value
            }
        }
    }

#endif
