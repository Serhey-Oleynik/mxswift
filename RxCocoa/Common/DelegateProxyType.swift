//
//  DelegateProxyType.swift
//  RxCocoa
//
//  Created by Krunoslav Zaher on 6/15/15.
//  Copyright (c) 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation
#if !RX_NO_MODULE
import RxSwift
#endif

/**
`DelegateProxyType` protocol enables using both normal delegates and Rx observable sequences with
views that can have only one delegate/datasource registered.

`Proxies` store information about observers, subscriptions and delegates
for specific views.

Type implementing `DelegateProxyType` should never be initialized directly.

To fetch initialized instance of type implementing `DelegateProxyType`, `proxyForObject` method
should be used.

This is more or less how it works.



      +-------------------------------------------+
      |                                           |                           
      | UIView subclass (UIScrollView)            |                           
      |                                           |
      +-----------+-------------------------------+                           
                  |                                                           
                  | Delegate                                                  
                  |                                                           
                  |                                                           
      +-----------v-------------------------------+                           
      |                                           |                           
      | Delegate proxy : DelegateProxyType        +-----+---->  Observable<T1>
      |                , UIScrollViewDelegate     |     |
      +-----------+-------------------------------+     +---->  Observable<T2>
                  |                                     |                     
                  |                                     +---->  Observable<T3>
                  |                                     |                     
                  | forwards events                     |
                  | to custom delegate                  |
                  |                                     v                     
      +-----------v-------------------------------+                           
      |                                           |                           
      | Custom delegate (UIScrollViewDelegate)    |                           
      |                                           |
      +-------------------------------------------+                           


Since RxCocoa needs to automagically create those Proxys
..and because views that have delegates can be hierarchical

UITableView : UIScrollView : UIView

.. and corresponding delegates are also hierarchical

UITableViewDelegate : UIScrollViewDelegate : NSObject

.. and sometimes there can be only one proxy/delegate registered,
every view has a corresponding delegate virtual factory method.

In case of UITableView / UIScrollView, there is

    extensions UIScrollView {
        public func rx_createDelegateProxy() -> RxScrollViewDelegateProxy {
            return RxScrollViewDelegateProxy(view: self)
        }
    ....


and override in UITableView

    extension UITableView {
        public override func rx_createDelegateProxy() -> RxScrollViewDelegateProxy {
        ....


*/
public protocol DelegateProxyType : AnyObject {
    /**
    Creates new proxy for target object.
    */
    static func createProxyForObject(object: AnyObject) -> AnyObject
   
    /**
    Returns assigned proxy for object.
    
    - parameter object: Object that can have assigned delegate proxy.
    - returns: Assigned delegate proxy or `nil` if no delegate proxy is assigned.
    */
    static func assignedProxyFor(object: AnyObject) -> AnyObject?
    
    /**
    Assigns proxy to object.
    
    - parameter object: Object that can have assigned delegate proxy.
    - parameter proxy: Delegate proxy object to assign to `object`.
    */
    static func assignProxy(proxy: AnyObject, toObject object: AnyObject)
    
    /**
    Returns designated delegate property for object.
    
    Objects can have multiple delegate properties.
    
    Each delegate property needs to have it's own type implementing `DelegateProxyType`.
    
    - parameter object: Object that has delegate property.
    - returns: Value of delegate property.
    */
    static func currentDelegateFor(object: AnyObject) -> AnyObject?

    /**
    Sets designated delegate property for object.
    
    Objects can have multiple delegate properties.
    
    Each delegate property needs to have it's own type implementing `DelegateProxyType`.
    
    - parameter toObject: Object that has delegate property.
    - parameter delegate: Delegate value.
    */
    static func setCurrentDelegate(delegate: AnyObject?, toObject object: AnyObject)
    
    /**
    Returns reference of normal delegate that receives all forwarded messages
    through `self`.
    
    - returns: Value of reference if set or nil.
    */
    func forwardToDelegate() -> AnyObject?

    /**
    Sets reference of normal delegate that receives all forwarded messages
    through `self`.
    
    - parameter forwardToDelegate: Reference of delegate that receives all messages through `self`.
    - parameter retainDelegate: Should `self` retain `forwardToDelegate`.
    */
    func setForwardToDelegate(forwardToDelegate: AnyObject?, retainDelegate: Bool)
}

/**
Returns existing proxy for object or installs new instance of delegate proxy.

- parameter object: Target object on which to install delegate proxy.
- returns: Installed instance of delegate proxy.


    extension UISearchBar {

        public var rx_delegate: DelegateProxy {
            return proxyForObject(RxSearchBarDelegateProxy.self, self)
        }
        
        public var rx_text: ControlProperty<String> {
            let source: Observable<String> = self.rx_delegate.observe("searchBar:textDidChange:")
            ...
        }
    }
*/
public func proxyForObject<P: DelegateProxyType>(type: P.Type, _ object: AnyObject) -> P {
    MainScheduler.ensureExecutingOnScheduler()
    
    let maybeProxy = P.assignedProxyFor(object) as? P
    
    let proxy: P
    if maybeProxy == nil {
        proxy = P.createProxyForObject(object) as! P
        P.assignProxy(proxy, toObject: object)
        assert(P.assignedProxyFor(object) === proxy)
    }
    else {
        proxy = maybeProxy!
    }
    
    let currentDelegate: AnyObject? = P.currentDelegateFor(object)
    
    if currentDelegate !== proxy {
        proxy.setForwardToDelegate(currentDelegate, retainDelegate: false)
        P.setCurrentDelegate(proxy, toObject: object)
        assert(P.currentDelegateFor(object) === proxy)
        assert(proxy.forwardToDelegate() === currentDelegate)
    }
        
    return proxy
}

@available(*, deprecated=2.0.0, message="Please use version that takes type as first argument.")
public func proxyForObject<P: DelegateProxyType>(object: AnyObject) -> P {
    return proxyForObject(P.self, object)
}

func installDelegate<P: DelegateProxyType>(proxy: P, delegate: AnyObject, retainDelegate: Bool, onProxyForObject object: AnyObject) -> Disposable {
    weak var weakDelegate: AnyObject? = delegate
    
    assert(proxy.forwardToDelegate() === nil, "There is already a set delegate \(proxy.forwardToDelegate())")
    
    proxy.setForwardToDelegate(delegate, retainDelegate: retainDelegate)
    
    // refresh properties after delegate is set
    // some views like UITableView cache `respondsToSelector`
    P.setCurrentDelegate(nil, toObject: object)
    P.setCurrentDelegate(proxy, toObject: object)
    
    assert(proxy.forwardToDelegate() === delegate, "Setting of delegate failed")
    
    return AnonymousDisposable {
        MainScheduler.ensureExecutingOnScheduler()
        
        let delegate: AnyObject? = weakDelegate
        
        assert(delegate == nil || proxy.forwardToDelegate() === delegate, "Delegate was changed from time it was first set. Current \(proxy.forwardToDelegate()), and it should have been \(proxy)")
        
        proxy.setForwardToDelegate(nil, retainDelegate: retainDelegate)
    }
}

extension ObservableType {
    func subscribeProxyDataSourceForObject<P: DelegateProxyType>(object: AnyObject, dataSource: AnyObject, retainDataSource: Bool, binding: (P, Event<E>) -> Void)
        -> Disposable {
        let proxy = proxyForObject(P.self, object)
        let disposable = installDelegate(proxy, delegate: dataSource, retainDelegate: retainDataSource, onProxyForObject: object)
        
        let subscription = self.asObservable()
            // source can't ever end, otherwise it will release the subscriber
            .concat(never())
            .subscribe { [weak object] (event: Event<E>) in
                MainScheduler.ensureExecutingOnScheduler()

                if let object = object {
                    assert(proxy === P.currentDelegateFor(object), "Proxy changed from the time it was first set.\nOriginal: \(proxy)\nExisting: \(P.currentDelegateFor(object))")
                }
                
                binding(proxy, event)
                
                switch event {
                case .Error(let error):
                    bindingErrorToInterface(error)
                    disposable.dispose()
                case .Completed:
                    disposable.dispose()
                default:
                    break
                }
            }
            
        return StableCompositeDisposable.create(subscription, disposable)
    }
}
