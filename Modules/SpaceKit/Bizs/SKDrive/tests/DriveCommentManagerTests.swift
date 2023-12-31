//
//  DriveCommentManagerTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by chensi(陈思) on 2022/9/8.
//  


import XCTest
@testable import SKCommon
@testable import SKDrive
@testable import SKFoundation
import RxSwift
import RxCocoa
import SpaceInterface

class DriveCommentManagerTests: XCTestCase {
    
    var disposeBag = DisposeBag()
    var hostVC =  UIViewController()
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func test_prepare_handleMessageFeedFromLark() {
        
        let meta = DriveFileMeta(size: 1024,
                                 name: "test.mp4",
                                 type: "mp4",
                                 fileToken: "testtoken",
                                 mountNodeToken: "mountNodeToken",
                                 mountPoint: "mountPoint",
                                 version: "version",
                                 dataVersion: "dataversion",
                                 source: .other,
                                 tenantID: "",
                                 authExtra: nil)
        let fileinfo = DriveFileInfo(fileMeta: meta)
        let docsInfo = DocsInfo(type: .file, objToken: "mockToken")
        let mgr = DriveCommentManager(canComment: true,
                                      canShowCollaboratorInfo: true,
                                      canPreviewProvider: { true },
                                      docsInfo: docsInfo,
                                      fileInfo: fileinfo,
                                      feedFromInfo: nil)
        let response: [String: Any] = [:]
        mgr.updateMessages([])
        mgr.prepare_handleMessageFeedFromLark(response)
        XCTAssert(mgr.currentMessages?.isEmpty ?? true)
    }
    let docsInfo = DocsInfo(type: .file, objToken: "mockToken")
    
    var commentManager: DriveCommentManager {
        let meta = DriveFileMeta(size: 1024,
                                 name: "test.mp4",
                                 type: "mp4",
                                 fileToken: "testtoken",
                                 mountNodeToken: "mountNodeToken",
                                 mountPoint: "mountPoint",
                                 version: "version",
                                 dataVersion: "dataversion",
                                 source: .other,
                                 tenantID: "",
                                 authExtra: nil)
        let fileinfo = DriveFileInfo(fileMeta: meta)
        let mgr = DriveCommentManager(canComment: true,
                                      canShowCollaboratorInfo: true,
                                      canPreviewProvider: { true },
                                      docsInfo: docsInfo,
                                      fileInfo: fileinfo,
                                      feedFromInfo: nil)
        return mgr
    }
    
    var commentData: CommentData {
        let comment = Comment()
        comment.commentID = "123"
        let item = CommentItem()
        item.replyID = "456"
        comment.commentList = [item]
        return CommentData(comments: [comment], currentPage: 1, style: .backV2, docsInfo: docsInfo, commentType: .card, commentPermission: [])
    }
    
    func testUpdate() {
        var switchComment = ""

        let mgr = commentManager
        mgr.commentVCSwitchToComment.subscribe (onNext: { id in
            switchComment = id
        }).disposed(by: disposeBag)
        mgr.showComment(commentId: "123", hostVC: hostVC, isFromFeed: false)
        mgr.commentAdapter.commentUpdate?(commentData, ["1"])
        mgr.showComment(commentId: "123", hostVC: hostVC, isFromFeed: false)
        let testUpdateExpect = expectation(description: "testUpdate")
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 1) {
            testUpdateExpect.fulfill()
            XCTAssertEqual(switchComment, "123")
        }
        
        wait(for: [testUpdateExpect], timeout: 2, enforceOrder: false)
    }
    
    func testShowComment() {
        let mgr = commentManager
        var switchComment = ""
        mgr.commentVCSwitchToComment.subscribe (onNext: { id in
            switchComment = id
        }).disposed(by: disposeBag)
        
        mgr.showComment(commentId: "", hostVC: UIViewController(), isFromFeed: false)
        mgr.commentAdapter.commentUpdate?(commentData, ["1"])
        XCTAssertTrue(mgr.commentModule?.isVisiable == true)

        mgr.showComment(commentId: "123", hostVC: UIViewController(), isFromFeed: false)
        mgr.didCopyCommentContent()
        XCTAssertEqual(switchComment, "123")
        
        XCTAssertEqual(mgr.ownerAllowCopy(), mgr.canCopy)
        XCTAssertEqual(mgr.canPreview(), mgr.canPreviewProvider())
        
        if case .permit = mgr.externalCopyPermission {
            XCTFail("externalCopyPermission error")
        }
    }
    
    func testCallFunction() {
        let mgr = commentManager
        var dismiss = false
        mgr.commentAdapter.commentVCDismissed = {
            dismiss = true
        }
        var page = 0
        var id = ""
        mgr.commentAdapter.commentVCDidSwitchToPage = { (p, i) in
            page = p
            id = i
        }
        mgr.callFunction(for: .cancel, params: ["type": "show_cards"])
        XCTAssertTrue(dismiss)
        
        mgr.callFunction(for: .panelHeightUpdate, params: ["height": 200])
        
        mgr.callFunction(for: .switchCard, params: ["comment_id": "123", "page": 1])
        XCTAssertEqual(page, 1)
        XCTAssertEqual(id, "123")
        
        
        var messageIds: [String] = []
        mgr.commentAdapter.messageDidRead = { ids in
            messageIds = ids
        }
        mgr.callFunction(for: .readMessage, params: ["msgIds": ["123", "456"]])
        
        XCTAssertEqual(messageIds.count, 2)
        //  不处理
        mgr.callFunction(for: .addContentReaction, params: [:])
    }
    
    func testUpdateContextEqual() {
        let mgr = commentManager
        let docsInfo = DocsInfo(type: .file, objToken: "mockToken")
        let context = UploadCommentContext(docsInfo: docsInfo, canComment: true, canCopy: false, canRead: true, canShowCollaboratorInfo: false, canPreview: true)
        let meta = DriveFileMeta(size: 1024,
                                 name: "test.mp4",
                                 type: "mp4",
                                 fileToken: "testtoken",
                                 mountNodeToken: "mountNodeToken",
                                 mountPoint: "mountPoint",
                                 version: "version",
                                 dataVersion: "dataversion",
                                 source: .other,
                                 tenantID: "",
                                 authExtra: nil)
        let fileinfo = DriveFileInfo(fileMeta: meta)
        mgr.update(context: context, fileInfo: fileinfo)
        XCTAssertFalse(mgr.likeDataManager.canShowCollaboratorInfo)
    }
    
    func testUpdateContextNotEqual() {
        let mgr = commentManager
        let docsInfo = DocsInfo(type: .file, objToken: "Token")
        let context = UploadCommentContext(docsInfo: docsInfo, canComment: true, canCopy: true, canRead: false, canShowCollaboratorInfo: true, canPreview: true)
        let meta = DriveFileMeta(size: 1024,
                                 name: "test.mp4",
                                 type: "mp4",
                                 fileToken: "testtoken",
                                 mountNodeToken: "mountNodeToken",
                                 mountPoint: "mountPoint",
                                 version: "version",
                                 dataVersion: "dataversion",
                                 source: .other,
                                 tenantID: "",
                                 authExtra: nil)
        let fileinfo = DriveFileInfo(fileMeta: meta)
        mgr.update(context: context, fileInfo: fileinfo)
        XCTAssertTrue(mgr.likeDataManager.canShowCollaboratorInfo)
    }
    
    func testGetCanManage() {
        let mgr = commentManager
        let result = mgr.canManageDriveMeta()
        XCTAssertFalse(result)
    }
    
    func testGetCanEdit() {
        let mgr = commentManager
        let result = mgr.canEdit()
        XCTAssertFalse(result)
    }
}
