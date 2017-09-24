//
//  RxNavigationControllerDelegateProxy.swift
//  RxCocoa
//
//  Created by Diogo on 13/04/17.
//  Copyright © 2017 Krunoslav Zaher. All rights reserved.
//

#if os(iOS) || os(tvOS)

    import UIKit
    #if !RX_NO_MODULE
        import RxSwift
    #endif

    extension UINavigationController: HasDelegate {
        public typealias Delegate = UINavigationControllerDelegate
    }

    /// For more information take a look at `DelegateProxyType`.
    open class RxNavigationControllerDelegateProxy
        : DelegateProxy<UINavigationController, UINavigationControllerDelegate>
        , DelegateProxyType 
        , UINavigationControllerDelegate {

        /// Typed parent object.
        public weak private(set) var navigationController: UINavigationController?

        /// - parameter parentObject: Parent object for delegate proxy.
        public init(parentObject: ParentObject) {
            self.navigationController = parentObject
            super.init(parentObject: parentObject, delegateProxy: RxNavigationControllerDelegateProxy.self)
        }

        // Register known implementations
        public static func registerKnownImplementations() {
            self.register { RxNavigationControllerDelegateProxy(parentObject: $0) }
        }
    }
#endif
