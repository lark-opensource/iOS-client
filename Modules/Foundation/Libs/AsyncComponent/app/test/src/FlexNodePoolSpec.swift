//
//  FlexNodePoolSpec.swift
//  AsyncComponentDevEEUnitTest
//
//  Created by qihongye on 2020/5/5.
//

import UIKit
import Foundation
import XCTest

@testable import AsyncComponent
import EEFlexiable

var itemCount: Int32 = 0
class Item: Equatable {
    let id: Int32
    var isUpdate = false

    init() {
        id = OSAtomicIncrement32(&itemCount)
    }

    func update() {
        isUpdate = !isUpdate
    }

    static func ==(_ lhs: Item, _ rhs: Item) -> Bool {
        return lhs.id == rhs.id
    }
}

enum ASComponentStyleValue {
    case position(CSSPosition)
    case display(CSSDisplay)
    case flexDirection(CSSFlexDirection)
    case flexBasis(CSSValue)
    case flexWrap(CSSWrap)
    case flexGrow(CGFloat)
    case flexShrink(CGFloat)
    case justifyContent(CSSJustify)
    case alignContent(CSSAlign)
    case alignItems(CSSAlign)
    case alignSelf(CSSAlign)
    case maxWidth(CSSValue)
    case minWidth(CSSValue)
    case width(CSSValue)
    case height(CSSValue)
    case maxHeight(CSSValue)
    case minHeight(CSSValue)
    case margin(CSSValue)
    case marginLeft(CSSValue)
    case marginTop(CSSValue)
    case marginRight(CSSValue)
    case marginBottom(CSSValue)
    case padding(CSSValue)
    case paddingLeft(CSSValue)
    case paddingTop(CSSValue)
    case paddingRight(CSSValue)
    case paddingBottom(CSSValue)
    case left(CSSValue)
    case top(CSSValue)
    case right(CSSValue)
    case bottom(CSSValue)
    case borderWidth(CGFloat)
    case borderStartWidth(CGFloat)
    case borderEndWidth(CGFloat)
    case borderTopWidth(CGFloat)
    case borderRightWidth(CGFloat)
    case borderBottomWidth(CGFloat)
    case borderLeftWidth(CGFloat)
    case border(Border?)
    case direction(CSSDirection)
    case overflow(CSSOverflow)
    case aspectRatio(CGFloat)
}

class FlexNodePoolSpec: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testObjectPool() {
        var set = Set<Int32>()
        let pool = ObjectPool<Item>(factory: { Item() }) { _ in }
        for _ in 0..<7 {
            set.insert(pool.borrowOne(expansion: true).id)
        }
        XCTAssertEqual(pool.idleElements.count, 0)
        XCTAssertEqual(set.count, 7)

        // 释放所有
        pool.returnAll()
        XCTAssertEqual(pool.idleElements.count, 7)

        for _ in 0..<4 {
            set.insert(pool.borrowOne(expansion: true).id)
        }
        XCTAssertEqual(pool.idleElements.count, 3)
        XCTAssertEqual(set.count, 7)
        XCTAssertEqual(pool.elementActiveStates, [false, false, false, true, true, true, true])

        // 释放所有
        pool.returnAll()
        XCTAssertEqual(pool.idleElements.count, 7)

        for _ in 0..<10 {
            set.insert(pool.borrowOne(expansion: true).id)
        }
        XCTAssertEqual(pool.idleElements.count, 0)
        XCTAssertEqual(set.count, 10)
        XCTAssertEqual(pool.elementActiveStates, [true, true, true, true, true, true, true, true, true, true])

        // 释放所有
        pool.returnAll()
        XCTAssertEqual(pool.idleElements.count, 10)

        for _ in 0..<9 {
            set.insert(pool.borrowOne(expansion: true).id)
        }
        XCTAssertEqual(pool.idleElements.count, 1)
        XCTAssertEqual(set.count, 10)
        XCTAssertEqual(pool.elementActiveStates, [false, true, true, true, true, true, true, true, true, true])

        // 释放所有
        pool.returnAll()
        XCTAssertEqual(pool.idleElements.count, 10)

        for _ in 0..<10 {
            set.insert(pool.borrowOne(expansion: true).id)
        }
        XCTAssertEqual(pool.idleElements.count, 0)
        XCTAssertEqual(set.count, 10)
        XCTAssertEqual(pool.elementActiveStates, [true, true, true, true, true, true, true, true, true, true])

        XCTAssertEqual(itemCount, 10)
    }

    func testObjectPoolManager() {
        let manager = ObjectPoolManager<Item>(factory: { Item() }, prepareForReuse: {_ in })
        var poolSet = Set<Int8>()
        var objectSet = Set<Int32>()
        let lock = NSLock()
        let objectLock = NSLock()
        let exp1 = XCTestExpectation(description: "1")
        let exp2 = XCTestExpectation(description: "2")
        let exp3 = XCTestExpectation(description: "3")
        let count = 100
        let loopCount = 100
        DispatchQueue.global().async {
            for _ in 0..<loopCount {
                let pool = manager.borrowPool()
                lock.lock()
                poolSet.insert(pool.id)
                lock.unlock()
                for _ in 0..<count {
                    let object = pool.borrowOne(expansion: true)
                    object.update()
                    objectLock.lock()
                    objectSet.insert(object.id)
                    objectLock.unlock()
                }
                manager.returnPool(pool)
            }
            exp1.fulfill()
        }
        DispatchQueue.global().async {
            for _ in 0..<loopCount {
                let pool = manager.borrowPool()
                lock.lock()
                poolSet.insert(pool.id)
                lock.unlock()
                for _ in 0..<count {
                    let object = pool.borrowOne(expansion: true)
                    object.update()
                    objectLock.lock()
                    objectSet.insert(object.id)
                    objectLock.unlock()
                }
                manager.returnPool(pool)
            }
            exp2.fulfill()
        }
        DispatchQueue.global().async {
            for _ in 0..<loopCount {
                let pool = manager.borrowPool()
                lock.lock()
                poolSet.insert(pool.id)
                lock.unlock()
                for _ in 0..<count {
                    let object = pool.borrowOne(expansion: true)
                    object.update()
                    objectLock.lock()
                    objectSet.insert(object.id)
                    objectLock.unlock()
                }
                manager.returnPool(pool)
            }
            exp3.fulfill()
        }
        wait(for: [exp1, exp2, exp3], timeout: 5)
        XCTAssertEqual(poolSet.count, 3)
        XCTAssertEqual(objectSet.count, 3 * count)
    }

    func testMemorySize() {
        // 
        let style = ASComponentStyle()
        print(MallocSize(ref: style))
        var map: [UInt8: ASComponentStyleValue] = [:]
        let value1 = ASComponentStyleValue.alignContent(.auto)
        let value2 = ASComponentStyleValue.aspectRatio(0)
        let value3 = ASComponentStyleValue.border(nil)
        let value4 = ASComponentStyleValue.border(Border(BorderEdge(width: 0, color: .black, style: .solid)))
        map[0] = value1
        map[1] = value2
        map[2] = value3
        map[3] = value4
        print(MemoryLayout<ASComponentStyleValue>.size, MemoryLayout<ASComponentStyleValue>.alignment, MemoryLayout<ASComponentStyleValue>.stride)
        print(MemoryLayout.size(ofValue: map), MemoryLayout.stride(ofValue: map))
        print(MallocSize(ref: map))
        print(MemoryLayout.size(ofValue: value1), MemoryLayout.stride(ofValue: value1))
        print(MemoryLayout.size(ofValue: value2), MemoryLayout.stride(ofValue: value2))
        print(MemoryLayout.size(ofValue: value3), MemoryLayout.stride(ofValue: value3))
        print(MemoryLayout.size(ofValue: value4), MemoryLayout.stride(ofValue: value4))

        /**
         before:
            MallocSize(ref: ASComponentStyle()): 496
            BoxSizing stride: 1 1
            ASComponentUIStyle stride:  184 177
            CSSPosition stride 4 4
            CSSDisplay stride 4 4
            CSSFlexDirection stride 4 4
            CSSValue stride 8 8
            CSSWrap stride 4 4
            CGFloat stride 8 8
            CSSJustify stride 4 4
            CSSAlign stride 4 4
            Border? stride 96 89
            Border stride 96 89
            CSSDirection stride 4 4
            CSSOverflow stride 4 4
            BorderEdge stride 24 17
         */
        if true {
            print("ASComponentUIStyle stride: ", MemoryLayout<ASComponentUIStyle>.stride, MemoryLayout<ASComponentUIStyle>.size)
            print("BoxSizing stride", MemoryLayout<BoxSizing>.stride, MemoryLayout<BoxSizing>.size)
            print("CSSPosition stride", MemoryLayout<CSSPosition>.stride, MemoryLayout<CSSPosition>.size)
            print("CSSDisplay stride", MemoryLayout<CSSDisplay>.stride, MemoryLayout<CSSDisplay>.size)
            print("CSSFlexDirection stride", MemoryLayout<CSSFlexDirection>.stride, MemoryLayout<CSSFlexDirection>.size)
            print("CSSValue stride", MemoryLayout<CSSValue>.stride, MemoryLayout<CSSValue>.size)
            print("CSSWrap stride", MemoryLayout<CSSWrap>.stride, MemoryLayout<CSSWrap>.size)
            print("CGFloat stride", MemoryLayout<CGFloat>.stride, MemoryLayout<CGFloat>.size)
            print("CSSJustify stride", MemoryLayout<CSSJustify>.stride, MemoryLayout<CSSJustify>.size)
            print("CSSAlign stride", MemoryLayout<CSSAlign>.stride, MemoryLayout<CSSAlign>.size)
            print("Border? stride", MemoryLayout<Border?>.stride, MemoryLayout<Border?>.size)
            print("Border stride", MemoryLayout<Border>.stride, MemoryLayout<Border>.size)
            print("CSSDirection stride", MemoryLayout<CSSDirection>.stride, MemoryLayout<CSSDirection>.size)
            print("CSSOverflow stride", MemoryLayout<CSSOverflow>.stride, MemoryLayout<CSSOverflow>.size)
            print("BorderEdge stride", MemoryLayout<BorderEdge>.stride, MemoryLayout<BorderEdge>.size)
        }
    }

    /// These two tests below show me: Reuse object is better than renew object either memory or cpu-time.
    func testPerformanceFlexNodeInit() {
        // This is an example of a performance test case.
        var arr = buildFlexNodes()
        if #available(iOS 13.0, *) {
            self.measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
                for i in 0..<arr.count {
                    arr[i] = FlexNode()
                }
            }
        } else {
            self.measure {
                for i in 0..<arr.count {
                    arr[i] = FlexNode()
                }
            }
        }
    }

    @available(iOS 13.0, *)
    func testPerformanceFlexNodeReset() {
        // This is an example of a performance test case.
        let arr = buildFlexNodes()
        if #available(iOS 13.0, *) {
            self.measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
                for i in 0..<arr.count {
                    arr[i].reset()
                }
            }
        } else {
            self.measure {
                for i in 0..<arr.count {
                    arr[i].reset()
                }
            }
        }
    }
}

func buildFlexNodes() -> [FlexNode] {
    var arr: [FlexNode] = []
    for _ in 0..<1000 {
        let node = FlexNode()
        let node1 = FlexNode()
        let node2 = FlexNode()
        let node3 = FlexNode()
        let node4 = FlexNode()
        let node5 = FlexNode()
        let node6 = FlexNode()
        let node7 = FlexNode()
        let node8 = FlexNode()
        let node9 = FlexNode()
        let node10 = FlexNode()
        let node11 = FlexNode()
        let node12 = FlexNode()
        let node13 = FlexNode()
        let node14 = FlexNode()
        let node15 = FlexNode()
        let node16 = FlexNode()
        let node17 = FlexNode()
        let node18 = FlexNode()
        let node19 = FlexNode()
        node1.setSubFlexNodes([node4, node5, node6])
        node2.setSubFlexNodes([node7, node8, node9])
        node3.setSubFlexNodes([node10, node11, node12])
        node4.setSubFlexNodes([node13, node14, node15])
        node5.setSubFlexNodes([node16, node17, node18, node19])
        node.setSubFlexNodes([node1, node2, node3])
        arr.append(contentsOf: [node, node1, node2, node3, node4, node5, node6, node7, node8, node9,
                                node10, node11, node12, node13, node14, node15, node16, node17, node18, node19])
    }
    return arr
}

func MallocSize<T>(ref: T) -> Int {
    return malloc_size(UnsafeRawPointer(bitPattern: unsafeBitCast(ref, to: UInt.self))!)
}
