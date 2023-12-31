//
//  CopyStringSpec.swift
//  LKRichViewDevEEUnitTest
//
//  Created by qihongye on 2023/9/10.
//

import XCTest

@testable import LKRichView

// swiftlint:disable force_cast
final class CopyStringSpec: XCTestCase {
    var core: LKRichViewCore!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        core = LKRichViewCore()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCopyStyle() throws {
        if true {
            var style = LKRenderRichStyle()
            style.font = .init(.value, .boldSystemFont(ofSize: 20))
            let cloned = style.copy() as! LKRenderRichStyle
            XCTAssertTrue(style.font == cloned.font)
        }
    }

    func testNodeCopy() throws {
        if true {
            let node = Node(
                id: "1", classNames: ["1.1"],
                style: LKRichStyle()
                    .backgroundColor(UIColor.black)
                    .display(.inlineBlock)
            )
            let cloned = node.copy() as! Node
            XCTAssertFalse(node === cloned)
            // id
            XCTAssertTrue(node.id == cloned.id)
//            XCTAssertTrue(node.id.withCString({ $0.pointee }) != cloned.id.withCString({ $0.pointee }))
            // classNames
            XCTAssertTrue(node.classNames == cloned.classNames)
//            XCTAssertTrue(
//                node.classNames.withUnsafeBufferPointer({ $0.baseAddress }) != cloned.classNames.withUnsafeBufferPointer({ $0.baseAddress })
//            )
            // style
            XCTAssertTrue(node.style !== cloned.style)
            XCTAssertTrue(node.style.storage.backgroundColor == cloned.style.storage.backgroundColor)
            XCTAssertTrue(node.style.storage.display == cloned.style.storage.display)
        }
    }

    func testDeepCloneWithinBoundary() throws {
        if true {
            let source = LKRichElement(id: "1", tagName: TagName.p, classNames: ["1.1", "1.2"])
            let cloned = source.copy() as! LKRichElement
            core.deepCloneWithinBoundary(source: source, boundary: [(nil, nil)], cloned: cloned)
            XCTAssertTrue(source !== cloned)
            XCTAssertTrue(source.id == cloned.id)
            XCTAssertTrue(source.tagName.typeID == cloned.tagName.typeID)
            XCTAssertTrue(source.classNames == cloned.classNames)
//            XCTAssertTrue(source.style.storage == cloned.style.storage)
        }
        //                   root(p)
        //      ele1(p)             ele2 (p)   ele3(p)
        // ele1_1(at) ele1_2(t)   ele2_1(p)    ele3_1(t)
        //                    ele2_1_1(t) ele2_1_2(at)
        let root = LKRichElement(id: "root", tagName: TagName.p, classNames: ["root"])
        let ele1 = LKRichElement(id: "1", tagName: TagName.p, classNames: ["1"])
        let ele2 = LKRichElement(id: "2", tagName: TagName.p, classNames: ["2"])
        let ele3 = LKRichElement(id: "3", tagName: TagName.p, classNames: ["3"])
        root.children([ele1, ele2, ele3])
        let ele1_1 = LKRichElement(id: "1_1", tagName: TagName.p, classNames: ["1_1"])
        let ele1_2 = LKRichElement(id: "1_2", tagName: TagName.p, classNames: ["1_2"])
        ele1.children([ele1_1, ele1_2])
        let ele2_1 = LKRichElement(id: "2_1", tagName: TagName.p, classNames: ["2_1"])
        ele2.children([ele2_1])
        let ele3_1 = LKRichElement(id: "3_1", tagName: TagName.p, classNames: ["3_1"])
        ele3.children([ele3_1])
        let ele2_1_1 = LKRichElement(id: "2_1_1", tagName: TagName.p, classNames: ["2_1_1"])
        let ele2_1_2 = LKRichElement(id: "2_1_2", tagName: TagName.p, classNames: ["2_1_2"])
        ele2_1.children([ele2_1_1, ele2_1_2])
        if true {
            // left: ele1_1, right: ele2_1_2
            let cloned = root.copy() as! LKRichElement
            core.deepCloneWithinBoundary(
                source: root,
                boundary: core.getBoundary(ancestor: root, leftLeaf: ele1_1, rightLeaf: ele2_1_2),
                cloned: cloned
            )
            XCTAssertTrue(cloned.id == "root" && cloned !== root)
            XCTAssertTrue(cloned.subElements.map({ $0.id }) == ["1", "2"])
            XCTAssertTrue(cloned.subElements[0] !== root.subElements[0] && cloned.subElements[1] !== root.subElements[1])
            XCTAssertTrue(cloned.subElements[0].subElements.map({ $0.id }) == ["1_1", "1_2"])
            XCTAssertTrue(
                cloned.subElements[0].subElements[0] !== root.subElements[0].subElements[0]
                && cloned.subElements[0].subElements[1] !== root.subElements[0].subElements[1]
            )
            XCTAssertTrue(cloned.subElements[1].subElements.map({ $0.id }) == ["2_1"])
            XCTAssertTrue(cloned.subElements[1].subElements[0] !== root.subElements[1].subElements[0])
            XCTAssertTrue(cloned.subElements[0].subElements[0].subElements.map({ $0.id }) == [])
            XCTAssertTrue(cloned.subElements[0].subElements[1].subElements.map({ $0.id }) == [])
            XCTAssertTrue(cloned.subElements[1].subElements[0].subElements.map({ $0.id }) == ["2_1_1", "2_1_2"])
            XCTAssertTrue(
                cloned.subElements[1].subElements[0].subElements[0] !== root.subElements[1].subElements[0].subElements[0]
                && cloned.subElements[1].subElements[0].subElements[1] !== root.subElements[1].subElements[0].subElements[1]
            )
        }
        if true {
            // left: ele1_1, right: ele3_1
            let cloned = root.copy() as! LKRichElement
            core.deepCloneWithinBoundary(
                source: root,
                boundary: core.getBoundary(ancestor: root, leftLeaf: ele1_1, rightLeaf: ele3_1),
                cloned: cloned
            )
            XCTAssertTrue(cloned.id == "root")
            XCTAssertTrue(cloned.subElements.map({ $0.id }) == root.subElements.map({ $0.id }))
            XCTAssertTrue(cloned.subElements[0].subElements.map({ $0.id }) == ele1.subElements.map({ $0.id }))
            XCTAssertTrue(cloned.subElements[1].subElements.map({ $0.id }) == ele2.subElements.map({ $0.id }))
            XCTAssertTrue(cloned.subElements[2].subElements.map({ $0.id }) == ele3.subElements.map({ $0.id }))
            XCTAssertTrue(cloned.subElements[0].subElements[0].subElements.map({ $0.id }) == ele1_1.subElements.map({ $0.id }))
            XCTAssertTrue(cloned.subElements[0].subElements[1].subElements.map({ $0.id }) == ele1_2.subElements.map({ $0.id }))
            XCTAssertTrue(cloned.subElements[1].subElements[0].subElements.map({ $0.id }) == ele2_1.subElements.map({ $0.id }))
            XCTAssertTrue(cloned.subElements[1].subElements[0].subElements[0].subElements.map({ $0.id }) == ele2_1_1.subElements.map({ $0.id }))
            XCTAssertTrue(cloned.subElements[1].subElements[0].subElements[1].subElements.map({ $0.id }) == ele2_1_2.subElements.map({ $0.id }))
            XCTAssertTrue(cloned.subElements[2].subElements[0].subElements.map({ $0.id }) == ele3_1.subElements.map({ $0.id }))

        }
    }

    func testPerformanceExample() throws {
        self.measure {
        }
    }

}

func isEqualAndNotSame(_ element1: LKRichElement, _ element2: LKRichElement) -> Bool {
    return element1 !== element2
        && element1.id == element2.id
        && element1.classNames == element2.classNames
        && element1.tagName.typeID == element2.tagName.typeID
        && element1.isBlock == element2.isBlock
        && element1.isInline == element2.isInline
}
