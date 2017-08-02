//
//  DelegateProxyTest+Cocoa.swift
//  Tests
//
//  Created by Krunoslav Zaher on 12/5/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Cocoa
@testable import RxCocoa
@testable import RxSwift
import XCTest

// MARK: Tests

extension DelegateProxyTest {
    func test_NSTextFieldDelegateExtension() {
        performDelegateTest(NSTextFieldSubclass(frame: CGRect.zero), proxyType: ExtendNSTextFieldDelegateProxy.self)
    }
}

// MARK: Mocks

class ExtendNSTextFieldDelegateProxy
    : RxTextFieldDelegateProxy<NSTextFieldSubclass>
    , TestDelegateProtocol {
    required init(parentObject: ParentObject) {
        super.init(parentObject: parentObject)
    }
}

final class NSTextFieldSubclass
    : NSTextField
    , TestDelegateControl {
    func doThatTest(_ value: Int) {
        (delegate as! TestDelegateProtocol).testEventHappened?(value)
    }

    var delegateProxy: DelegateProxy<NSTextFieldSubclass, NSTextFieldDelegate> {
        return self.rx.delegate
    }

    func setMineForwardDelegate(_ testDelegate: NSTextFieldDelegate) -> Disposable {
        return RxTextFieldDelegateProxy.installForwardDelegate(testDelegate, retainDelegate: false, onProxyForObject: self)
    }
}
