//
//  NSButton+RxTests.swift
//  Tests
//
//  Created by Krunoslav Zaher on 11/26/16.
//  Copyright © 2016 Krunoslav Zaher. All rights reserved.
//

import RxSwift
import RxCocoa
import AppKit
import XCTest

final class NSButtonTests: RxTest {

}

extension NSButtonTests {
    func testButton_DelegateEventCompletesOnDealloc() {
        let createView: () -> NSButton = { NSButton(frame: CGRect(x: 0, y: 0, width: 1, height: 1)) }
        ensureEventDeallocated(createView) { (view: NSButton) in view.rx.tap }
    }

    func testButton_StateCompletesOnDealloc() {
        let createView: () -> NSButton = { NSButton(frame: CGRect(x: 0, y: 0, width: 1, height: 1)) }
        ensurePropertyDeallocated(createView, 0) { (view: NSButton) in view.rx.state }
    }

    func testButton_state_observer_on() {
        let button = NSButton(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        _ = Observable.just(NSOnState).bind(to: button.rx.state)

        XCTAssertEqual(button.state, NSOnState)
    }

    func testButton_state_observer_off() {
        let button = NSButton(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        _ = Observable.just(NSOffState).bind(to: button.rx.state)

        XCTAssertEqual(button.state, NSOffState)
    }
	
	func testButton_multipleObservers() {
		let button = NSButton(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
		var value1: NSControl.StateValue? = nil
		var value2: NSControl.StateValue? = nil

		_ = Observable.just(NSControl.StateValue.off).bind(to: button.rx.state)
		_ = button.rx.state.subscribe(onNext: { value1 = $0 })
		_ = button.rx.state.subscribe(onNext: { value2 = $0 })
		_ = Observable.just(NSControl.StateValue.on).bind(to: button.rx.state)

		if let target = button.target, let action = button.action {
			_ = target.perform(action, with: button)
		}

		XCTAssertEqual(button.state, NSControl.StateValue.on)
		XCTAssertEqual(value1, NSControl.StateValue.on)
		XCTAssertEqual(value2, NSControl.StateValue.on)
	}
}
