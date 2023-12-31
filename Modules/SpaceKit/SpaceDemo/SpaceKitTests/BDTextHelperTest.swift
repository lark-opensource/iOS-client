//
//  BDTextHelperTest.swift
//  DocsTests
//
//  Created by xurunkang on 2019/8/15.
//  Copyright © 2019 Bytedance. All rights reserved.

import XCTest
@testable import SpaceKit

class BDTextHelperTest: XCTestCase {

    private func attributedText(_ text: String) -> NSAttributedString {
        return AtInfo.attrString(
            encodeString: text,
            attributes: [.font: UIFont.systemFont(ofSize: 16)]
            ).docs.urlAttributed
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testEqualSingleLine() {
        let helper = TextHelper()
        // XS 一行的宽度
        let xsWidth: CGFloat = 283.0
        let equalText = attributedText("123456789124345678784646434431")
        let res = helper.calculateAttributedTextLines(equalText, with: xsWidth)
        let exp: CGFloat = 1.0

        XCTAssert( res == exp )
    }

    func testEqualTwoLines() {
        let helper = TextHelper()
        // XS 两行的宽度
        let xsWidth: CGFloat = 283.0
        let equalText = attributedText("123456789124345678784646434431123456789124345678784646434431")
        let res = helper.calculateAttributedTextLines(equalText, with: xsWidth)

        XCTAssert( res >= 1.99 )
        XCTAssert( res <= 2.01 )
    }

    func testGreaterThanSingleLine() {
        let helper = TextHelper()
        // XS 一行的宽度
        let xsWidth: CGFloat = 283.0
        let greaterText = attributedText("123456789124345678784646434431A")
        let res = helper.calculateAttributedTextLines(greaterText, with: xsWidth)
        let exp: CGFloat = 1.0

        XCTAssert( res > exp )
    }

    func testLessThanSingleLine() {
        let helper = TextHelper()
        // XS 一行的宽度
        let xsWidth: CGFloat = 283.0
        let lessText = attributedText("12345678912434567878464643443")
        let res = helper.calculateAttributedTextLines(lessText, with: xsWidth)
        let exp: CGFloat = 1.0

        XCTAssert( res < exp )
    }

}
