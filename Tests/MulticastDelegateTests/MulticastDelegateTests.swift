//
//  MulticastDelegateTests.swift
//  MulticastDelegateTests
//
//  Created by kemchenj on 2021/10/17.
//

import XCTest
import MulticastDelegate

class MulticastDelegateTests: XCTestCase {

    func testMain() {
        let mainDelegate = MockDelegate()
        let secondaryDelegate = MockDelegate()

        let multicastDelegate: MockProtocol = {
            let delegate = MulticastMockDelegate()
            delegate.mainDelegate = mainDelegate
            delegate.addDelegate(secondaryDelegate, shouldRetain: false)
            return delegate
        }()

        for i in 0..<10 {
            XCTAssertEqual(i, mainDelegate.methodInvokedCount(#selector(MockProtocol.testNonOptionalFunc)))
            XCTAssertEqual(i, secondaryDelegate.methodInvokedCount(#selector(MockProtocol.testNonOptionalFunc)))
            multicastDelegate.testNonOptionalFunc()

            XCTAssertEqual(i, mainDelegate.methodInvokedCount(#selector(MockProtocol.testNonOptionalFuncWithReturnValue)))
            XCTAssertEqual(0, secondaryDelegate.methodInvokedCount(#selector(MockProtocol.testNonOptionalFuncWithReturnValue)))
            XCTAssertEqual(true, multicastDelegate.testNonOptionalFuncWithReturnValue())

            XCTAssertEqual(i, mainDelegate.methodInvokedCount(#selector(MockProtocol.testOptionalFunc)))
            XCTAssertEqual(i, secondaryDelegate.methodInvokedCount(#selector(MockProtocol.testOptionalFunc)))
            multicastDelegate.testOptionalFunc?()

            let integer = i
            let rect = CGRect(x: i, y: i, width: i, height: i)
            let nsArray = NSArray()
            var cgPoint = rect.origin
            let nilObject: NSObject? = nil
            XCTAssertEqual(i, mainDelegate.methodInvokedCount(#selector(MockProtocol.testOptionalFuncWithArguments)))
            XCTAssertEqual(i, secondaryDelegate.methodInvokedCount(#selector(MockProtocol.testOptionalFuncWithArguments)))
            multicastDelegate.testOptionalFuncWithArguments?(integer: integer, cgRect: rect, nsArray: nsArray, unsafePointer: &cgPoint, nilObject: nilObject)

            XCTAssertEqual(mainDelegate.integer, integer)
            XCTAssertEqual(mainDelegate.cgRect, rect)
            XCTAssertEqual(mainDelegate.nsArray, nsArray)
            XCTAssertEqual(mainDelegate.unsafePointer?.pointee, cgPoint)
            XCTAssertEqual(mainDelegate.nilObject, nilObject)

            XCTAssertEqual(secondaryDelegate.integer, integer)
            XCTAssertEqual(secondaryDelegate.cgRect, rect)
            XCTAssertEqual(secondaryDelegate.nsArray, nsArray)
            XCTAssertEqual(secondaryDelegate.unsafePointer?.pointee, cgPoint)
            XCTAssertEqual(secondaryDelegate.nilObject, nilObject)
        }
    }

    func testShouldRetain() {
        let multicastDelegate = MulticastMockDelegate()

        multicastDelegate.addDelegate(MockDelegate(), shouldRetain: false)
        XCTAssertTrue(multicastDelegate.delegates.allObjects.isEmpty)

        multicastDelegate.addDelegate(MockDelegate(), shouldRetain: true)
        XCTAssertFalse(multicastDelegate.delegates.allObjects.isEmpty)
    }
}

class MulticastMockDelegate: MulticastDelegate<MockProtocol>, MockProtocol {
    func testNonOptionalFunc() {
        mainDelegate?.testNonOptionalFunc()
        delegates.allObjects.forEach { $0.testNonOptionalFunc() }
    }

    func testNonOptionalFuncWithReturnValue() -> Bool {
        mainDelegate?.testNonOptionalFuncWithReturnValue() ?? false
    }
}

class MockDelegate: NSObject, MockProtocol {
    var methodsInvokedCounter = [Selector: Int]()

    var integer: Int?
    var cgRect: CGRect?
    var nsArray: NSArray?
    var unsafePointer: UnsafeMutablePointer<CGPoint>?
    var nilObject: NSObject?

    func methodInvokedCount(_ selector: Selector) -> Int {
        methodsInvokedCounter[selector, default: 0]
    }

    func testNonOptionalFunc() {
        methodsInvokedCounter[#selector(testNonOptionalFunc), default: 0] += 1
    }

    func testNonOptionalFuncWithReturnValue() -> Bool {
        methodsInvokedCounter[#selector(testNonOptionalFuncWithReturnValue), default: 0] += 1
        return true
    }

    func testOptionalFunc() {
        methodsInvokedCounter[#selector(testOptionalFunc), default: 0] += 1
    }

    func testOptionalFuncWithArguments(integer: Int, cgRect: CGRect, nsArray: NSArray, unsafePointer: UnsafeMutablePointer<CGPoint>, nilObject: NSObject?) {
        methodsInvokedCounter[#selector(testOptionalFuncWithArguments(integer:cgRect:nsArray:unsafePointer:nilObject:)), default: 0] += 1
        self.integer = integer
        self.cgRect = cgRect
        self.nsArray = nsArray
        self.unsafePointer = unsafePointer
        self.nilObject = nilObject
    }
}

@objc protocol MockProtocol: NSObjectProtocol {
    @objc func testNonOptionalFunc()
    @objc func testNonOptionalFuncWithReturnValue() -> Bool
    @objc optional func testOptionalFunc()
    @objc optional func testOptionalFuncWithArguments(integer: Int, cgRect: CGRect, nsArray: NSArray, unsafePointer: UnsafeMutablePointer<CGPoint>, nilObject: NSObject?)
}

