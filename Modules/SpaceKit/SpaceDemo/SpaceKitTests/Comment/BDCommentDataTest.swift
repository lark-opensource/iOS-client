//
//  BDCommentDataTest.swift
//  DocsTests
//
//  Created by xurunkang on 2019/7/29.
//  Copyright © 2019 Bytedance. All rights reserved.

import XCTest
import SwiftyJSON
@testable import SpaceKit

class BDCommentDataTest: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    private func jsonToCommentData() -> CommentData? {
        let path = Bundle(for: BDCommentDataTest.self).path(forResource: "BDCommentData", ofType: "json")
        let commentDataJSON = URL(fileURLWithPath: path!)

        guard let data = try? Data(contentsOf: commentDataJSON),
            let json = try? JSON(data: data) else {
            return nil
        }

        guard let params = json.dictionaryObject else {
            return nil
        }

        let docsInfo = DocsInfo(type: .doc, objToken: "")

        let commentData = CommentConstructor.constructCommentData(params,
                                                       docsInfo: docsInfo,
                                                       chatID: nil)

        return commentData
    }

    // 测试纯文字
    func testPureText() {
        guard let text = jsonToCommentData()?.comments.first?.commentList.first?.content else {
            XCTAssert(false)
            return
        }

        XCTAssertEqual(text, "纯文字")
    }

    // 测试语音
    func testVoice() {
        guard
            let audioDuration = jsonToCommentData()?.comments[1].commentList.first?.audioDuration,
            let audioFileToken = jsonToCommentData()?.comments[1].commentList.first?.audioFileToken
        else {
            XCTAssert(false)
            return
        }

        XCTAssertEqual(audioDuration, 5131)
        XCTAssertEqual(audioFileToken, "boxcn0XhKdSF2z4w9VMozxRObfd")
    }

    // 表情
    func textReaction() {
        guard
            let reaction = jsonToCommentData()?.comments[2].commentList.first?.reactions
        else {
            XCTAssert(false)
            return
        }

        XCTAssertEqual(reaction.count, 1)
        XCTAssertEqual(reaction[0].reactionKey, "THUMBSUP")
    }

    // 测试编辑
    func testEdit() {
        guard
            let modify = jsonToCommentData()?.comments[3].commentList.first?.modify
        else {
            XCTAssert(false)
            return
        }

        XCTAssertEqual(modify, 1)
    }
}
