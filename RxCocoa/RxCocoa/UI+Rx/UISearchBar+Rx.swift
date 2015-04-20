//
//  UISearchBar+Rx.swift
//  RxCocoa
//
//  Created by Krunoslav Zaher on 3/28/15.
//  Copyright (c) 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation
import RxSwift

class SearchBarDelegate: NSObject, UISearchBarDelegate {
    typealias Observer = ObserverOf<String>
    typealias DisposeKey = Bag<ObserverOf<String>>.KeyType
    
    var observers: Bag<Observer> = Bag()
    
    func addObserver(observer: Observer) -> DisposeKey {
        MainScheduler.ensureExecutingOnScheduler()
        
        return observers.put(observer)
    }
    
    func removeObserver(key: DisposeKey) {
        MainScheduler.ensureExecutingOnScheduler()
        
        let observer = observers.removeKey(key)
        
        if observer == nil {
            removingObserverFailed()
        }
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        let event = Event.Next(Box(searchText))
        
        handleObserverResult(dispatch(event, self.observers.all))
    }
}

extension UISearchBar {
    
    public func rx_searchText() -> Observable<String> {
        
        rx_checkSearchBarDelegate()
        
        return AnonymousObservable { observer in
            var maybeDelegate = self.rx_checkSearchBarDelegate()
            
            if maybeDelegate == nil {
                maybeDelegate = SearchBarDelegate()
                self.delegate = maybeDelegate
            }
            
            let delegate = maybeDelegate!
            
            let key = delegate.addObserver(observer)
            
            return success(AnonymousDisposable {
                delegate.removeObserver(key)
            })
        }
    }
    
    // private 
    
    private func rx_checkSearchBarDelegate() -> SearchBarDelegate? {
        MainScheduler.ensureExecutingOnScheduler()
        
        if self.delegate == nil {
            return nil
        }
        
        let maybeDelegate = self.delegate as? SearchBarDelegate
        
        if maybeDelegate == nil {
            rxFatalError("Search bar already has incompatible delegate set. To use rx observable (for now) please remove earlier delegate registration.")
        }
        
        return maybeDelegate!
    }
}