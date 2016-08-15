//
//  NSObject+RxTests.swift
//  RxTests
//
//  Created by Krunoslav Zaher on 7/11/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import XCTest

class NSObjectTests: RxTest {
    
}

// deallocated
extension NSObjectTests {
    func testDeallocated_ObservableFires() {
        var a = NSObject()
        
        var fired = false
        
        _ = a
            .deallocated
            .map { _ in
                return 1
            }
            .subscribe(onNext: { _ in
                fired = true
            })
        
        XCTAssertFalse(fired)
        
        a = NSObject()
        
        XCTAssertTrue(fired)
    }
    
    func testDeallocated_ObservableCompletes() {
        var a = NSObject()
        
        var fired = false
        
        _ = a
            .deallocated
            .map { _ in
                return 1
            }
            .subscribe(onCompleted: {
                fired = true
            })
        
        XCTAssertFalse(fired)
        
        a = NSObject()
        
        XCTAssertTrue(fired)
    }

    func testDeallocated_ObservableDispose() {
        var a = NSObject()
        
        var fired = false

        _ = a
            .deallocated
            .map { _ in
                return 1
            }
            .subscribe(onNext: { _ in
                fired = true
            })
            .dispose()

        XCTAssertFalse(fired)
        
        a = NSObject()
        
        XCTAssertFalse(fired)
    }
}

#if !DISABLE_SWIZZLING
// rx_deallocating
extension NSObjectTests {
    func testDeallocating_ObservableFires() {
        var a = NSObject()
        
        var fired = false
        
        _ = a
            .rx_deallocating
            .map { _ in
                return 1
            }
            .subscribe(onNext: { _ in
                fired = true
            })
        
        XCTAssertFalse(fired)
        
        a = NSObject()
        
        XCTAssertTrue(fired)
    }
    
    func testDeallocating_ObservableCompletes() {
        var a = NSObject()
        
        var fired = false
        
        _ = a
            .rx_deallocating
            .map { _ in
                return 1
            }
            .subscribe(onCompleted: {
                fired = true
            })
        
        XCTAssertFalse(fired)
        
        a = NSObject()
        
        XCTAssertTrue(fired)
    }
    
    func testDeallocating_ObservableDispose() {
        var a = NSObject()
        
        var fired = false

        _ = a
            .rx_deallocating
            .map { _ in
                return 1
            }
            .subscribe(onNext: { _ in
                fired = true
            })
            .dispose()
        
        XCTAssertFalse(fired)
        
        a = NSObject()
        
        XCTAssertFalse(fired)
    }
}
#endif
