//
//  RxTest.swift
//  RxTests
//
//  Created by Krunoslav Zaher on 2/8/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import XCTest
import RxSwift
import RxTests
import Foundation

#if TRACE_RESOURCES
#elseif RELEASE
#elseif os(Linux)
#else
let failure = unhandled_case()
#endif

// because otherwise OSX unit tests won't run
#if os(iOS)
    import UIKit
#elseif os(OSX)
    import AppKit
#endif



#if os(Linux)
// TODO: Implement PerformanceTests.swift for Linux
func getMemoryInfo() -> (bytes: Int64, allocations: Int64) {
    return (0, 0)
}
#endif


class RxTest
    : XCTestCase {

    #if os(Linux)
        var allTests : [(String, () throws -> Void)] = []
    #endif

    fileprivate var startResourceCount: AtomicInt = 0

    var accumulateStatistics: Bool {
        return true
    }

    #if TRACE_RESOURCES
        static var totalNumberOfAllocations: Int64 = 0
        static var totalNumberOfAllocatedBytes: Int64 = 0

        var startNumberOfAllocations: Int64 = 0
        var startNumberOfAllocatedBytes: Int64 = 0
    #endif

    override func setUp() {
        super.setUp()
        setUpActions()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        tearDownActions()
    }
}

extension RxTest {
    struct Defaults {
        static let created = 100
        static let subscribed = 200
        static let disposed = 1000
    }

    func sleep(_ time: TimeInterval) {
        let _ = RunLoop.current.run(mode: RunLoopMode.defaultRunLoopMode, before: Date(timeIntervalSinceNow: time))
    }

    func setUpActions(){
        #if TRACE_RESOURCES
            self.startResourceCount = resourceCount
            //registerMallocHooks()
            (startNumberOfAllocatedBytes, startNumberOfAllocations) = getMemoryInfo()
        #endif
    }

    func tearDownActions() {
        #if TRACE_RESOURCES
            // give 5 sec to clean up resources
            for _ in 0..<30 {
                if self.startResourceCount < resourceCount {
                    // main schedulers need to finish work
                    print("Waiting for resource cleanup ...")
                    RunLoop.current.run(mode: RunLoopMode.defaultRunLoopMode, before: Date(timeIntervalSinceNow: 0.05)  )
                }
                else {
                    break
                }
            }

            XCTAssertEqual(self.startResourceCount, resourceCount)
            let (endNumberOfAllocatedBytes, endNumberOfAllocations) = getMemoryInfo()

            let (newBytes, newAllocations) = (endNumberOfAllocatedBytes - startNumberOfAllocatedBytes, endNumberOfAllocations - startNumberOfAllocations)

            if accumulateStatistics {
                RxTest.totalNumberOfAllocations += newAllocations
                RxTest.totalNumberOfAllocatedBytes += newBytes
            }
            print("allocatedBytes = \(newBytes), allocations = \(newAllocations) (totalBytes = \(RxTest.totalNumberOfAllocatedBytes), totalAllocations = \(RxTest.totalNumberOfAllocations))")
        #endif
    }

}
