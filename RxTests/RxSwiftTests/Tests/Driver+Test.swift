//
//  Driver+Test.swift
//  RxTests
//
//  Created by Krunoslav Zaher on 10/14/15.
//
//

import Foundation
import RxSwift
import RxCocoa
import XCTest

class DriverTest : RxTest {
    var backgroundScheduler = SerialDispatchQueueScheduler(globalConcurrentQueuePriority: .Default)

    override func tearDown() {
        super.tearDown()
    }
}

// test helpers that make sure that resulting driver operator honors definition
// * only one subscription is made and shared - shareReplay(1)
// * subscription is made on main thread - subscribeOn(MainScheduler.sharedInstance)
// * events are observed on main thread - observeOn(MainScheduler.sharedInstance)
// * it can't error out - it needs to have catch somewhere
extension DriverTest {

    func subscribeTwiceOnBackgroundSchedulerAndExpectResultsOnMainScheduler<R: Equatable>(driver: Driver<R>, subscribedOnBackground: () -> ()) -> [R] {
        var firstElements = [R]()
        var secondElements = [R]()

        let subscribeFinished = self.expectationWithDescription("subscribeFinished")

        var expectation1: XCTestExpectation!
        var expectation2: XCTestExpectation!

        backgroundScheduler.schedule(()) { _ in
            _ = driver.asObservable().subscribe { e in
                XCTAssertTrue(NSThread.isMainThread())
                switch e {
                case .Next(let element):
                    firstElements.append(element)
                case .Error(let error):
                    XCTFail("Error passed \(error)")
                case .Completed:
                    expectation1.fulfill()
                }
            }
            _ = driver.asDriver().asObservable().subscribe { e in
                XCTAssertTrue(NSThread.isMainThread())
                switch e {
                case .Next(let element):
                    secondElements.append(element)
                case .Error(let error):
                    XCTFail("Error passed \(error)")
                case .Completed:
                    expectation2.fulfill()
                }
            }

            // Subscription should be made on main scheduler
            // so this will make sure execution is continued after 
            // subscription because of serial nature of main scheduler.
            MainScheduler.sharedInstance.schedule(()) { _ in
                subscribeFinished.fulfill()
                return NopDisposable.instance

            }

            return NopDisposable.instance
        }

        waitForExpectationsWithTimeout(1.0) { error in
            XCTAssertTrue(error == nil)
        }

        expectation1 = self.expectationWithDescription("finished1")
        expectation2 = self.expectationWithDescription("finished2")

        subscribedOnBackground()

        waitForExpectationsWithTimeout(1.0) { error in
            XCTAssertTrue(error == nil)
        }

        XCTAssertTrue(firstElements == secondElements)

        return firstElements
    }
}

// conversions
extension DriverTest {
    func testAsDriver_onErrorJustReturn() {
        let hotObservable = MainThreadPrimitiveHotObservable<Int>()
        let driver = hotObservable.asDriver(onErrorJustReturn: -1)

        let results = subscribeTwiceOnBackgroundSchedulerAndExpectResultsOnMainScheduler(driver) {
            XCTAssertTrue(hotObservable.subscriptions == [SubscribedToHotObservable])

            hotObservable.on(.Next(1))
            hotObservable.on(.Next(2))
            hotObservable.on(.Error(testError))

            XCTAssertTrue(hotObservable.subscriptions == [UnsunscribedFromHotObservable])
        }

        XCTAssertEqual(results, [1, 2, -1])
    }

    func testAsDriver_onErrorDriveWith() {
        let hotObservable = MainThreadPrimitiveHotObservable<Int>()
        let driver = hotObservable.asDriver(onErrorDriveWith: Drive.just(-1))

        let results = subscribeTwiceOnBackgroundSchedulerAndExpectResultsOnMainScheduler(driver) {
            XCTAssertTrue(hotObservable.subscriptions == [SubscribedToHotObservable])

            hotObservable.on(.Next(1))
            hotObservable.on(.Next(2))
            hotObservable.on(.Error(testError))

            XCTAssertTrue(hotObservable.subscriptions == [UnsunscribedFromHotObservable])
        }

        XCTAssertEqual(results, [1, 2, -1])
    }

    func testAsDriver_onErrorRecover() {
        let hotObservable = MainThreadPrimitiveHotObservable<Int>()
        let driver = hotObservable.asDriver { e in
            return Drive.empty()
        }

        let results = subscribeTwiceOnBackgroundSchedulerAndExpectResultsOnMainScheduler(driver) {
            XCTAssertTrue(hotObservable.subscriptions == [SubscribedToHotObservable])

            hotObservable.on(.Next(1))
            hotObservable.on(.Next(2))
            hotObservable.on(.Error(testError))

            XCTAssertTrue(hotObservable.subscriptions == [UnsunscribedFromHotObservable])
        }

        XCTAssertEqual(results, [1, 2])
    }
}

// map
extension DriverTest {
    func testAsDriver_map() {
        let hotObservable = MainThreadPrimitiveHotObservable<Int>()
        let driver = hotObservable.asDriver(onErrorJustReturn: -1).map { (n: Int) -> Int in
            XCTAssertTrue(NSThread.isMainThread())
            return n + 1
        }

        let results = subscribeTwiceOnBackgroundSchedulerAndExpectResultsOnMainScheduler(driver) {
            XCTAssertTrue(hotObservable.subscriptions == [SubscribedToHotObservable])

            hotObservable.on(.Next(1))
            hotObservable.on(.Next(2))
            hotObservable.on(.Error(testError))

            XCTAssertTrue(hotObservable.subscriptions == [UnsunscribedFromHotObservable])
        }

        XCTAssertEqual(results, [2, 3, 0])
    }

}

// filter
extension DriverTest {
    func testAsDriver_filter() {
        let hotObservable = MainThreadPrimitiveHotObservable<Int>()
        let driver = hotObservable.asDriver(onErrorJustReturn: -1).filter { n in
            XCTAssertTrue(NSThread.isMainThread())
            return n % 2 == 0
        }

        let results = subscribeTwiceOnBackgroundSchedulerAndExpectResultsOnMainScheduler(driver) {
            XCTAssertTrue(hotObservable.subscriptions == [SubscribedToHotObservable])

            hotObservable.on(.Next(1))
            hotObservable.on(.Next(2))
            hotObservable.on(.Error(testError))

            XCTAssertTrue(hotObservable.subscriptions == [UnsunscribedFromHotObservable])
        }

        XCTAssertEqual(results, [2])
    }
}


// switch latest
extension DriverTest {
    func testAsDriver_switchLatest() {
        let hotObservable = MainThreadPrimitiveHotObservable<Driver<Int>>()
        let hotObservable1 = MainThreadPrimitiveHotObservable<Int>()
        let hotObservable2 = MainThreadPrimitiveHotObservable<Int>()

        let driver = hotObservable.asDriver(onErrorJustReturn: hotObservable1.asDriver(onErrorJustReturn: -1)).switchLatest()

        let results = subscribeTwiceOnBackgroundSchedulerAndExpectResultsOnMainScheduler(driver) {
            XCTAssertTrue(hotObservable.subscriptions == [SubscribedToHotObservable])

            hotObservable.on(.Next(hotObservable1.asDriver(onErrorJustReturn: -2)))

            hotObservable1.on(.Next(1))
            hotObservable1.on(.Next(2))
            hotObservable1.on(.Error(testError))

            hotObservable.on(.Next(hotObservable2.asDriver(onErrorJustReturn: -3)))

            hotObservable2.on(.Next(10))
            hotObservable2.on(.Next(11))
            hotObservable2.on(.Error(testError))

            hotObservable.on(.Error(testError))

            hotObservable1.on(.Completed)
            hotObservable.on(.Completed)

            XCTAssertTrue(hotObservable.subscriptions == [UnsunscribedFromHotObservable])
        }

        XCTAssertEqual(results, [
            1, 2, -2,
            10, 11, -3
            ])
    }
}

// doOn
extension DriverTest {
    func testAsDriver_doOn() {
        let hotObservable = MainThreadPrimitiveHotObservable<Int>()

        var events = [Event<Int>]()

        let driver = hotObservable.asDriver(onErrorJustReturn: -1).doOn { e in
            XCTAssertTrue(NSThread.isMainThread())

            events.append(e)
        }

        let results = subscribeTwiceOnBackgroundSchedulerAndExpectResultsOnMainScheduler(driver) {
            XCTAssertTrue(hotObservable.subscriptions == [SubscribedToHotObservable])

            hotObservable.on(.Next(1))
            hotObservable.on(.Next(2))
            hotObservable.on(.Error(testError))

            XCTAssertTrue(hotObservable.subscriptions == [UnsunscribedFromHotObservable])
        }

        XCTAssertEqual(results, [1, 2, -1])
        let expectedEvents = [Event.Next(1), Event.Next(2), Event.Next(-1), Event.Completed] as [Event<Int>]
        XCTAssertEqual(events, expectedEvents, ==)
    }
}

// distinct until change
extension DriverTest {
    func testAsDriver_distinctUntilChanged1() {
        let hotObservable = MainThreadPrimitiveHotObservable<Int>()

        let driver = hotObservable.asDriver(onErrorJustReturn: -1).distinctUntilChanged()

        let results = subscribeTwiceOnBackgroundSchedulerAndExpectResultsOnMainScheduler(driver) {
            XCTAssertTrue(hotObservable.subscriptions == [SubscribedToHotObservable])

            hotObservable.on(.Next(1))
            hotObservable.on(.Next(2))
            hotObservable.on(.Next(2))
            hotObservable.on(.Error(testError))

            XCTAssertTrue(hotObservable.subscriptions == [UnsunscribedFromHotObservable])
        }

        XCTAssertEqual(results, [1, 2, -1])
    }

    func testAsDriver_distinctUntilChanged2() {
        let hotObservable = MainThreadPrimitiveHotObservable<Int>()

        let driver = hotObservable.asDriver(onErrorJustReturn: -1).distinctUntilChanged({ $0 })

        let results = subscribeTwiceOnBackgroundSchedulerAndExpectResultsOnMainScheduler(driver) {
            XCTAssertTrue(hotObservable.subscriptions == [SubscribedToHotObservable])

            hotObservable.on(.Next(1))
            hotObservable.on(.Next(2))
            hotObservable.on(.Next(2))
            hotObservable.on(.Error(testError))

            XCTAssertTrue(hotObservable.subscriptions == [UnsunscribedFromHotObservable])
        }

        XCTAssertEqual(results, [1, 2, -1])
    }

    func testAsDriver_distinctUntilChanged3() {
        let hotObservable = MainThreadPrimitiveHotObservable<Int>()

        let driver = hotObservable.asDriver(onErrorJustReturn: -1).distinctUntilChanged({ $0 == $1 })

        let results = subscribeTwiceOnBackgroundSchedulerAndExpectResultsOnMainScheduler(driver) {
            XCTAssertTrue(hotObservable.subscriptions == [SubscribedToHotObservable])

            hotObservable.on(.Next(1))
            hotObservable.on(.Next(2))
            hotObservable.on(.Next(2))
            hotObservable.on(.Error(testError))

            XCTAssertTrue(hotObservable.subscriptions == [UnsunscribedFromHotObservable])
        }

        XCTAssertEqual(results, [1, 2, -1])
    }


    func testAsDriver_distinctUntilChanged4() {
        let hotObservable = MainThreadPrimitiveHotObservable<Int>()

        let driver = hotObservable.asDriver(onErrorJustReturn: -1).distinctUntilChanged({ $0 }) { $0 == $1 }

        let results = subscribeTwiceOnBackgroundSchedulerAndExpectResultsOnMainScheduler(driver) {
            XCTAssertTrue(hotObservable.subscriptions == [SubscribedToHotObservable])

            hotObservable.on(.Next(1))
            hotObservable.on(.Next(2))
            hotObservable.on(.Next(2))
            hotObservable.on(.Error(testError))

            XCTAssertTrue(hotObservable.subscriptions == [UnsunscribedFromHotObservable])
        }

        XCTAssertEqual(results, [1, 2, -1])
    }

}

// flat map
extension DriverTest {
    func testAsDriver_flatMap() {
        let hotObservable = MainThreadPrimitiveHotObservable<Int>()
        let driver = hotObservable.asDriver(onErrorJustReturn: -1).flatMap { (n: Int) -> Driver<Int> in
            XCTAssertTrue(NSThread.isMainThread())
            return Drive.just(n + 1)
        }

        let results = subscribeTwiceOnBackgroundSchedulerAndExpectResultsOnMainScheduler(driver) {
            XCTAssertTrue(hotObservable.subscriptions == [SubscribedToHotObservable])

            hotObservable.on(.Next(1))
            hotObservable.on(.Next(2))
            hotObservable.on(.Error(testError))

            XCTAssertTrue(hotObservable.subscriptions == [UnsunscribedFromHotObservable])
        }

        XCTAssertEqual(results, [2, 3, 0])
    }
    
}

// merge
extension DriverTest {
    func testAsDriver_merge() {
        let hotObservable = MainThreadPrimitiveHotObservable<Int>()
        let driver = hotObservable.asDriver(onErrorJustReturn: -1).map { (n: Int) -> Driver<Int> in
            XCTAssertTrue(NSThread.isMainThread())
            return Drive.just(n + 1)
        }.merge()

        let results = subscribeTwiceOnBackgroundSchedulerAndExpectResultsOnMainScheduler(driver) {
            XCTAssertTrue(hotObservable.subscriptions == [SubscribedToHotObservable])

            hotObservable.on(.Next(1))
            hotObservable.on(.Next(2))
            hotObservable.on(.Error(testError))

            XCTAssertTrue(hotObservable.subscriptions == [UnsunscribedFromHotObservable])
        }

        XCTAssertEqual(results, [2, 3, 0])
    }

    func testAsDriver_merge2() {
        let hotObservable = MainThreadPrimitiveHotObservable<Int>()
        let driver = hotObservable.asDriver(onErrorJustReturn: -1).map { (n: Int) -> Driver<Int> in
            XCTAssertTrue(NSThread.isMainThread())
            return Drive.just(n + 1)
        }.merge(maxConcurrent: 1)

        let results = subscribeTwiceOnBackgroundSchedulerAndExpectResultsOnMainScheduler(driver) {
            XCTAssertTrue(hotObservable.subscriptions == [SubscribedToHotObservable])

            hotObservable.on(.Next(1))
            hotObservable.on(.Next(2))
            hotObservable.on(.Error(testError))

            XCTAssertTrue(hotObservable.subscriptions == [UnsunscribedFromHotObservable])
        }

        XCTAssertEqual(results, [2, 3, 0])
    }
}

// debounce
extension DriverTest {
    func testAsDriver_debounce() {
        let hotObservable = MainThreadPrimitiveHotObservable<Int>()
        let driver = hotObservable.asDriver(onErrorJustReturn: -1).debounce(0.0, MainScheduler.sharedInstance)

        let results = subscribeTwiceOnBackgroundSchedulerAndExpectResultsOnMainScheduler(driver) {
            XCTAssertTrue(hotObservable.subscriptions == [SubscribedToHotObservable])

            hotObservable.on(.Error(testError))

            XCTAssertTrue(hotObservable.subscriptions == [UnsunscribedFromHotObservable])
        }

        XCTAssertEqual(results, [-1])
    }

    func testAsDriver_throttle() {
        let hotObservable = MainThreadPrimitiveHotObservable<Int>()
        let driver = hotObservable.asDriver(onErrorJustReturn: -1).throttle(0.0, MainScheduler.sharedInstance)

        let results = subscribeTwiceOnBackgroundSchedulerAndExpectResultsOnMainScheduler(driver) {
            XCTAssertTrue(hotObservable.subscriptions == [SubscribedToHotObservable])

            hotObservable.on(.Next(1))
            hotObservable.on(.Next(2))
            hotObservable.on(.Error(testError))

            XCTAssertTrue(hotObservable.subscriptions == [UnsunscribedFromHotObservable])
        }

        XCTAssertEqual(results, [-1])
    }

}

// scan
extension DriverTest {
    func testAsDriver_scan() {
        let hotObservable = MainThreadPrimitiveHotObservable<Int>()
        let driver = hotObservable.asDriver(onErrorJustReturn: -1).scan(0) { (a: Int, n: Int) -> Int in
            XCTAssertTrue(NSThread.isMainThread())
            return a + n
        }

        let results = subscribeTwiceOnBackgroundSchedulerAndExpectResultsOnMainScheduler(driver) {
            XCTAssertTrue(hotObservable.subscriptions == [SubscribedToHotObservable])

            hotObservable.on(.Next(1))
            hotObservable.on(.Next(2))
            hotObservable.on(.Error(testError))

            XCTAssertTrue(hotObservable.subscriptions == [UnsunscribedFromHotObservable])
        }

        XCTAssertEqual(results, [1, 3, 2])
    }
    
}

// concat
extension DriverTest {
    func testAsDriver_concat() {
        let hotObservable1 = MainThreadPrimitiveHotObservable<Int>()
        let hotObservable2 = MainThreadPrimitiveHotObservable<Int>()

        let driver = [hotObservable1.asDriver(onErrorJustReturn: -1), hotObservable2.asDriver(onErrorJustReturn: -2)].concat()

        let results = subscribeTwiceOnBackgroundSchedulerAndExpectResultsOnMainScheduler(driver) {
            XCTAssertTrue(hotObservable1.subscriptions == [SubscribedToHotObservable])

            hotObservable1.on(.Next(1))
            hotObservable1.on(.Next(2))
            hotObservable1.on(.Error(testError))

            XCTAssertTrue(hotObservable1.subscriptions == [UnsunscribedFromHotObservable])
            XCTAssertTrue(hotObservable2.subscriptions == [SubscribedToHotObservable])

            hotObservable2.on(.Next(4))
            hotObservable2.on(.Next(5))
            hotObservable2.on(.Error(testError))

            XCTAssertTrue(hotObservable2.subscriptions == [UnsunscribedFromHotObservable])
        }

        XCTAssertEqual(results, [1, 2, -1, 4, 5, -2])
    }
}

// combine latest
extension DriverTest {
    func testAsDriver_combineLatest_array() {
        let hotObservable1 = MainThreadPrimitiveHotObservable<Int>()
        let hotObservable2 = MainThreadPrimitiveHotObservable<Int>()

        let driver = [hotObservable1.asDriver(onErrorJustReturn: -1), hotObservable2.asDriver(onErrorJustReturn: -2)].combineLatest { a in a.reduce(0, combine: +) }

        let results = subscribeTwiceOnBackgroundSchedulerAndExpectResultsOnMainScheduler(driver) {
            XCTAssertTrue(hotObservable1.subscriptions == [SubscribedToHotObservable])
            XCTAssertTrue(hotObservable2.subscriptions == [SubscribedToHotObservable])

            hotObservable1.on(.Next(1))
            hotObservable2.on(.Next(4))

            hotObservable1.on(.Next(2))
            hotObservable2.on(.Next(5))

            hotObservable1.on(.Error(testError))
            hotObservable2.on(.Error(testError))

            XCTAssertTrue(hotObservable1.subscriptions == [UnsunscribedFromHotObservable])
            XCTAssertTrue(hotObservable2.subscriptions == [UnsunscribedFromHotObservable])
        }
        
        XCTAssertEqual(results, [5, 6, 7, 4, -3])
    }

    func testAsDriver_combineLatest() {
        let hotObservable1 = MainThreadPrimitiveHotObservable<Int>()
        let hotObservable2 = MainThreadPrimitiveHotObservable<Int>()

        let driver = combineLatest(hotObservable1.asDriver(onErrorJustReturn: -1), hotObservable2.asDriver(onErrorJustReturn: -2), resultSelector: +)

        let results = subscribeTwiceOnBackgroundSchedulerAndExpectResultsOnMainScheduler(driver) {
            XCTAssertTrue(hotObservable1.subscriptions == [SubscribedToHotObservable])
            XCTAssertTrue(hotObservable2.subscriptions == [SubscribedToHotObservable])

            hotObservable1.on(.Next(1))
            hotObservable2.on(.Next(4))

            hotObservable1.on(.Next(2))
            hotObservable2.on(.Next(5))

            hotObservable1.on(.Error(testError))
            hotObservable2.on(.Error(testError))

            XCTAssertTrue(hotObservable1.subscriptions == [UnsunscribedFromHotObservable])
            XCTAssertTrue(hotObservable2.subscriptions == [UnsunscribedFromHotObservable])
        }
        
        XCTAssertEqual(results, [5, 6, 7, 4, -3])
    }
}

// zip
extension DriverTest {
    func testAsDriver_zip_array() {
        let hotObservable1 = MainThreadPrimitiveHotObservable<Int>()
        let hotObservable2 = MainThreadPrimitiveHotObservable<Int>()

        let driver = [hotObservable1.asDriver(onErrorJustReturn: -1), hotObservable2.asDriver(onErrorJustReturn: -2)].zip { a in a.reduce(0, combine: +) }

        let results = subscribeTwiceOnBackgroundSchedulerAndExpectResultsOnMainScheduler(driver) {
            XCTAssertTrue(hotObservable1.subscriptions == [SubscribedToHotObservable])
            XCTAssertTrue(hotObservable2.subscriptions == [SubscribedToHotObservable])

            hotObservable1.on(.Next(1))
            hotObservable2.on(.Next(4))

            hotObservable1.on(.Next(2))
            hotObservable2.on(.Next(5))

            hotObservable1.on(.Error(testError))
            hotObservable2.on(.Error(testError))

            XCTAssertTrue(hotObservable1.subscriptions == [UnsunscribedFromHotObservable])
            XCTAssertTrue(hotObservable2.subscriptions == [UnsunscribedFromHotObservable])
        }

        XCTAssertEqual(results, [5, 7, -3])
    }

    func testAsDriver_zip() {
        let hotObservable1 = MainThreadPrimitiveHotObservable<Int>()
        let hotObservable2 = MainThreadPrimitiveHotObservable<Int>()

        let driver = zip(hotObservable1.asDriver(onErrorJustReturn: -1), hotObservable2.asDriver(onErrorJustReturn: -2), resultSelector: +)

        let results = subscribeTwiceOnBackgroundSchedulerAndExpectResultsOnMainScheduler(driver) {
            XCTAssertTrue(hotObservable1.subscriptions == [SubscribedToHotObservable])
            XCTAssertTrue(hotObservable2.subscriptions == [SubscribedToHotObservable])

            hotObservable1.on(.Next(1))
            hotObservable2.on(.Next(4))

            hotObservable1.on(.Next(2))
            hotObservable2.on(.Next(5))

            hotObservable1.on(.Error(testError))
            hotObservable2.on(.Error(testError))

            XCTAssertTrue(hotObservable1.subscriptions == [UnsunscribedFromHotObservable])
            XCTAssertTrue(hotObservable2.subscriptions == [UnsunscribedFromHotObservable])
        }
        
        XCTAssertEqual(results, [5, 7, -3])
    }
}