//
//  RenderTextContextSpec.swift
//  LKRichViewDevEEUnitTest
//
//  Created by qihongye on 2019/9/20.
//

// swiftlint:disable
import UIKit
import Foundation
import XCTest

@testable import LKRichView

// swiftlint:disable all

extension CFRange: Equatable {
    public static func == (_ lhs: CFRange, _ rhs: CFRange) -> Bool {
        return lhs.location == rhs.location && lhs.length == rhs.length
    }
}

enum TagName: LKRichElementTag {
    case p
    case at

    var typeID: Int8 {
        switch self {
        case .p:
            return 0
        case .at:
            return 1
        }
    }
}

class RenderTextContextSpec: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_RenderInlineContext_HorizontalTcolorfulBlue_10000() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let element = LKBlockElement(tagName: TagName.p)
        element.style.display(.block).width(.point(500))
        let element1 = LKTextElement(text: """
Code review can have an important function of teaching developers something new about a language, a framework, or general software design principles. It's always fine to leave comments that help a developer learn something new. Sharing knowledge is part of improving the code health of a system over time. Just keep in mind that if your comment is purely educational, but not critical to meeting the standards described in this document, prefix it with "Nit: " or otherwise indicate that it's not mandatory for the author to resolve it in this CL.
""")
        element1.style.fontSize(.point(20))
        let element2 = LKTextElement(text: """
CR有一个重要的功能是它可以教会开发者一些语言、框架、通用软件设计原则相关的新东西。留下帮助开发者学习新东西的评论总是好的。分享知识是持续的提高系统代码质量的一部分。请记住，如果你的评论只是单纯教育性质的，不是那些能在这篇文章中找到的规范，那么请在前面加一个“Nit:”或者注明作者不需要解决它。
""")
        element2.style.fontSize(.point(14))
        element.children([element1, element2])
        let renderer = element.createRenderer()
        print(renderer.layout(CGSize(width: 500, height: 500), context: nil))
        XCTAssert(renderer.layout(CGSize(width: 500, height: 500), context: nil) ~= CGSize(width: 500, height: 343.36))
    }

    func testNormal中日韩() {

    }

    func test_RenderInlineContext_Normal中文() {

    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
