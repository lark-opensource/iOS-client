//
//  CommentDiffDataPluginTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by huayufan on 2022/8/31.
//  


@testable import SKCommon
@testable import SKComment
import XCTest
import RxSwift
import RxCocoa
import SKFoundation
import LarkWebViewContainer
import SpaceInterface
import SKInfra

class CommentDiffDataPluginTests: XCTestCase, TestCommentDataSource {
    
    var testScheduler: CommentSchedulerServer?
    
    var isCanSendComment: Bool = true
    
    var isShowComment: Bool = true

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        DocsContainer.shared.register(DocCommonDownloadProtocol.self) { _ in
            return CommentImagePluginTests.TestDocCommonDownload()
        }.inObjectScope(.container)
        
        DocsContainer.shared.register(SpaceDownloadCacheProtocol.self) { _ in
            return CommentImagePluginTests.DocCommonCacheTest()
        }.inObjectScope(.container)
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }
    
    func testArrayExtension() {
        let plugin = CommentDiffDataPlugin()
        
        let commentData = testComment()
        XCTAssertNotNil(commentData)
        guard let data = commentData else {
            return
        }
        let commentId = data.currentCommentID ?? "-"
        
        data.comments.forEach({ $0.addFooter() })
        
        XCTAssertTrue(!data.comments.isEmpty)
        XCTAssertNil(data.comments[0].commentList.safe(index: -100))
        XCTAssertNil(data.comments[1].commentList.safe(index: -1))
        XCTAssertNil(data.comments[0].commentList.safe(index: 1000))
        
        let sections = plugin.constructArraySection(data.comments)
        plugin.commentSections = sections
        
        // test  activeComment
        let activeComment = sections.activeComment
        XCTAssertEqual(activeComment?.comment.commentID, commentId)
        XCTAssertEqual(activeComment?.index, 87)
        
        // test subscript
        let indexPath = sections["7152477472011862044", "7156565371088797699"]
        XCTAssertEqual(indexPath, IndexPath(row: 2, section: 20))
        let indexPath2 = sections["7156556571076460548", nil]
        XCTAssertEqual(indexPath2, IndexPath(row: 0, section: 10))
        
        
        let item = sections[IndexPath(row: 2, section: 0)]
        XCTAssertEqual(item?.commentId, "7156555634962350082")
        XCTAssertEqual(item?.replyID, "7156564662870949892")
        XCTAssertNil(sections[IndexPath(row: 200, section: 10)])
        
        let comment = sections[CommentIndex(2)]
        XCTAssertEqual(comment?.commentID, "7143120258331656193")
        XCTAssertNil(sections[CommentIndex(1000)])
        
        let item2 = sections.modifiableItem?.item
        XCTAssertNotNil(item)
        XCTAssertTrue(item2?.uiType == .footer)
        
        sections.setFoucus()
        XCTAssertTrue(item2?.viewStatus.isFirstResponser == true)
        
        sections.setResign()
        XCTAssertTrue(item2?.viewStatus.isFirstResponser == false)
        
        // test overFlow
        XCTAssertNil(sections[CommentIndex(-100)])
        XCTAssertNil(sections[CommentIndex(1000)])
    }
    
    func testAsideDiff() {
        let inputService = CommentInputService(gadgetInfo: testDocsInfo,
                                 dependency: CommentOpenPluginDependencyImp(topViewController: nil),
                                 delegate: GadgetJSServicesManager())
        let api = CommentWebAPIAdaper(commentService: inputService)
        let module = AsideCommentModule(dependency: inputService,
                                        apiAdaper: api)
        
        let commentData = testComment()
        XCTAssertNotNil(commentData)
        guard let data = commentData else {
            return
        }
        module.update(data)
        
        // 构造协同数据
        guard let data2 = testComment() else {
            XCTFail("data is nil")
            return
        }
        let commentId = data2.currentCommentID ?? ""

        // 删除第一条评论，构造协同数据
        data2.comments.first?.commentList.removeFirst()
        data2.currentCommentPos = nil
        data2.currentReplyID = nil
        
        let comment5 = data2.comments[5]
        let comment8 = data2.comments[8]
        
        let tempList = comment5.commentList
        let tempId = comment5.commentID
        let tempQuote = comment5.quote
        
        comment5.commentList = comment8.commentList
        comment5.commentID = comment8.commentID
        comment5.quote = comment8.quote
        
        comment8.commentList = tempList
        comment8.commentID = tempId
        comment8.quote = tempQuote
        
        module.update(data2)
        let expect = expectation(description: "testAsideDiff")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            expect.fulfill()
        }
        wait(for: [expect], timeout: 4, enforceOrder: false)
    }
}
