//
//  TestUtils.swift
//  LKRichViewDevEEUnitTest
//
//  Created by qihongye on 2022/12/6.
//

import UIKit
import Foundation
import XCTest
@testable import LKRichView

func assertEqual(_ concrete: CGRect, _ expect: CGRect) {
    XCTAssertTrue(concrete ~= expect, "concrete{\(concrete)} is not equal to expect{\(expect)}")
}

@discardableResult
func assertConcreteSize(_ size: CGSize, desc: String, element: LKRichElement, styleSheets: [CSSStyleSheet]) -> RenderObject {
    let core = LKRichViewCore(styleSheets: styleSheets)
    let ro = core.createRenderer(element)
    XCTAssertNotNil(ro)
    core.load(renderer: ro)
    let concreteResult = core.layout(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
    XCTAssertNotNil(concreteResult)
    XCTAssertTrue(concreteResult! ~= size, "\(desc)(\(element.name)): \(concreteResult!) is not equal to \(size)")
    return ro!
}
