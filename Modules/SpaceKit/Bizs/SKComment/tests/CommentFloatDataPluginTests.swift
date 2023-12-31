//
//  CommentFloatDataPluginTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by huayufan on 2022/9/15.
//


@testable import SKCommon
@testable import SKComment
import XCTest
import RxSwift
import RxCocoa
import SpaceInterface

class CommentFloatDataPluginTests: XCTestCase, TestCommentDataSource {
    
    var disposeBag = DisposeBag()
    
    var testScheduler: CommentSchedulerServer?
    
    var states: [CommentState] = []
    
    override func setUp() {
        super.setUp()
        let scheduler = CommentSchedulerServer()
        scheduler.connect(plugins: [CommentFloatDataPlugin(),
                                    CommentFloatInteractionPlugin(),
                                    CommentMenuPlugin()])
        scheduler.apply(context: self)
        self.testScheduler = scheduler
        testScheduler?.state.skip(1).subscribe(onNext: { [weak self] (state) in
            self?.states.append(state)
        }).disposed(by: disposeBag)
    }

    override func tearDown() {
        super.tearDown()
        disposeBag = DisposeBag()
        self.scheduler?.plugin(with: CommentFloatDataPlugin.self)?.commentSections = []
        states.removeAll()
    }
    
    // MARK: 测试无权限不显示输入框bar
    func testPermission() {
        let permission: CommentPermission = [.canCopy]
        guard let data = testComment(permission: permission) else {
            XCTFail("data is nil")
            return
        }
        testScheduler?.dispatch(action: .updateData(data))
        var foundRefreshFloatBarView = false
        for state in states {
            if case let .refreshFloatBarView(show, _) = state {
                foundRefreshFloatBarView = true
                XCTAssertEqual(show, false, "no permission can not show text bar")
            }
        }
        XCTAssertTrue(foundRefreshFloatBarView, "should update text bar UI")
    }
    
    // MARK: - 测试Feed点击跳转到对应的评论
    func testHilighted() {
        guard let data = testComment() else {
            XCTFail("data is nil")
            return
        }
        testScheduler?.dispatch(action: .updateData(data))
        var foundFoucus = false
        for state in states {
            if case let .foucus(indexPath, _, highlight) = state {
                foundFoucus = true
                XCTAssertEqual(indexPath, IndexPath(row: 5, section: 0), "foucus indexPath error")
                XCTAssertEqual(highlight, true, "foucus should highlighted")
            }
        }
        XCTAssertTrue(foundFoucus, "should foucus to detail comment")
    }
    
    // MARK: - 测试解决评论自动滚动到下一条
    func testAutoScrollNextComment() {
        guard let data = testComment() else {
            XCTFail("data is nil")
            return
        }
        let currentPage = data.currentPage ?? -1
        testScheduler?.dispatch(action: .updateData(data))
        states.removeAll()
        
        // case 1: 删除当前评论
        let testData2 = testComment { self.deleteComment(params: $0) }
        guard let data2 = testData2 else {
            XCTFail("data2 is nil")
            return
        }
        
        // 清空数据状态
        data2.currentPage = nil
        data2.currentCommentPos = nil
        data2.currentCommentID = nil
        data2.currentReplyID = nil
        
        // 开始更新评论
        testScheduler?.dispatch(action: .updateData(data2))
        var foundSyncPageData = false
        for state in states {
            if case let .syncPageData(_, page) = state {
                foundSyncPageData = true
                // 删除的并非最后一条，下一条评论的page的之前的应该是类似的
                XCTAssertEqual(page, currentPage, "next page error")
            }
        }
        XCTAssertTrue(foundSyncPageData, "should find SyncPageData")
        foundSyncPageData = false
        states.removeAll()
        
        // case 2: 大量评论被删除时，保证是指向最后一页（当前并非显示第一页的场景）
        // 构造当前激活的评论被删除
        let testData3 = testComment { self.keepRangeComment(params: $0, range: 0..<3) }
        let testData4 = testComment { self.keepRangeComment(params: $0, range: 1..<2) }
        guard let data3 = testData3, let data4 = testData4 else {
            XCTFail("data2 is nil")
            return
        }
        
        // 只保留两条评论数据
        data3.currentPage = nil
        data3.currentCommentPos = nil
        data3.currentCommentID = nil
        data3.currentReplyID = nil
        
        // 开始更新评论
        testScheduler?.dispatch(action: .updateData(data3))
        for state in states {
            if case let .syncPageData(_, page) = state {
                foundSyncPageData = true
                // 指向最后一条
                XCTAssertEqual(page, 2, "next page error")
            }
        }
        XCTAssertTrue(foundSyncPageData, "should find SyncPageData")
        
        
        // case 3:  删除只剩下一条的时候，显示当前最后一条
        foundSyncPageData = false
        states.removeAll()
        data4.currentPage = nil
        data4.currentCommentPos = nil
        data4.currentCommentID = nil
        data4.currentReplyID = nil
        // 开始更新评论
        testScheduler?.dispatch(action: .updateData(data4))
        for state in states {
            if case let .syncPageData(_, page) = state {
                foundSyncPageData = true
                // 指向仅剩的一条
                XCTAssertEqual(page, 0, "next page error")
            }
        }
        XCTAssertTrue(foundSyncPageData, "should find SyncPageData")
    }
    
    // MARK: - 测试无评论自动关闭面板
    func testEmptyClosePanel() {
        let data = CommentData(comments: [],
                         currentPage: nil,
                         style: .backV2,
                         docsInfo: testDocsInfo,
                         commentType: .card,
                         commentPermission: [])
        let expect = expectation(description: "close self")
        testScheduler?.dispatch(action: .updateData(data))
        for state in states {
            if case .dismiss = state {
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
    
    // MARK: - 测试自己发送的评论滚动到底部显示
    func testScrollToOwnComment() {
        initData()
        states.removeAll()
        
        guard let data = testComment(), let currentPage = data.currentPage else {
            XCTFail("data is invalid")
            return
        }
        data.currentReplyID = nil
        // 模拟在当前激活的评论下新增一条回复
        let comment = data.comments[currentPage]
        let ownItem = CommentItem()
        ownItem.replyID = "1234"
        ownItem.commentId = comment.commentID
        ownItem.userID = User.current.info?.userID ?? ""
        comment.commentList.append(ownItem)
        
        testScheduler?.dispatch(action: .updateData(data))
        let expect = expectation(description: "testScrollToOwnComment")
        for state in states {
            if case let .foucus(indexPath, _, _) = state {
                XCTAssertEqual(indexPath.row, comment.commentList.count - 1)
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
    
    // MARK: - 测试上下翻页
    func testPreAndNext() {
       let data = initData()
       let initPage = data.currentPage ?? 0
       var commentSections: [CommentSection] = []
       var comments = states.compactMap { state in
            if case let .syncPageData(data, page) = state {
                commentSections = data
                return data[CommentIndex(page)]
            }
            return nil
       }
        XCTAssertEqual(comments.count, 1)
        XCTAssertFalse(commentSections.isEmpty)
        
        var comment = comments[0]
        let beginComment = comment
        
        //  ================== 测试往下翻页 ========================
        
        // 剩余可以翻页的次数
        var left = commentSections.count - initPage - 1
        var loopPage = 0
        var containToast = false
        for i in 0...left {
            scheduler?.dispatch(action: .interaction(.goNextPage(current: comment)))

            comments = states.compactMap { state in
                 if case let .nextPaging(page) = state {
                     loopPage = page
                     return commentSections[CommentIndex(page)]
                 } else if case .toast = state {
                     containToast = true
                 }
                return nil
            }
            if i == left { // 需要弹提示
                XCTAssertTrue(containToast)
            } else { // 正常翻页
                XCTAssertEqual(comments.count, 1)
                comment = comments[0]
                XCTAssertEqual(initPage + i + 1, loopPage)
            }
            states.removeAll()
        }
        
        
        //  ================== 测试往上翻页 ========================
        comment = beginComment
        left = initPage // 0 1
        for i in 0...left {
            scheduler?.dispatch(action: .interaction(.goPrePage(current: comment)))

            comments = states.compactMap { state in
                 if case let .prePaging(page) = state {
                     loopPage = page
                     return commentSections[CommentIndex(page)]
                 } else if case .toast = state {
                     containToast = true
                 }
                return nil
            }
            if left == i { // 需要弹提示
                XCTAssertTrue(containToast)
            } else { // 正常翻页
                XCTAssertEqual(comments.count, 1)
                comment = comments[0]
                XCTAssertEqual(initPage - i - 1, loopPage)
            }
            states.removeAll()
        }
    }
    
    func testScollComment() {
        let commentData = initData()
        guard let commentId = commentData.currentCommentID,
              let replyId = commentData.currentReplyID else {
            return
        }
        scheduler?.dispatch(action: .scrollComment(commentId: commentId, replyId: replyId, percent: 0.1))
        var foundScrollToItem = false
        for state in states {
            if case let .scrollToItem(indexPath, percent) = state {
                foundScrollToItem = true
                XCTAssertEqual(percent, 0.1, "testScollComment percent error")
                XCTAssertEqual(indexPath.section, 0, "testScollComment section must be 0")
            }
        }
        XCTAssertTrue(foundScrollToItem)
        
        states.removeAll()
        foundScrollToItem = false
        scheduler?.dispatch(action: .scrollComment(commentId: commentId, replyId: "IN_HEADER", percent: 0.1))
        for state in states {
            if case let .scrollToItem(indexPath, percent) = state {
                foundScrollToItem = true
                XCTAssertEqual(percent, 0.1, "testScollComment percent error")
                XCTAssertEqual(indexPath, IndexPath(row: 0, section: 0))
            }
        }
        XCTAssertTrue(foundScrollToItem)
        
        
        states.removeAll()
        foundScrollToItem = false
        scheduler?.dispatch(action: .scrollComment(commentId: "abc", replyId: "xxxx", percent: 0.1))
        for state in states {
            if case .scrollToItem = state {
                foundScrollToItem = true
            }
        }
        XCTAssertFalse(foundScrollToItem)
    }
    
    func testModeChange() {
        let inputModel = CommentShowInputModel(isWhole: false, token: "xxxxx", type: .new)
        scheduler?.dispatch(action: .updateNewInputData(inputModel))
        if case .newInput = scheduler?.fastState.mode {
            XCTAssertTrue(true)
        } else {
            XCTFail("mode should be newInput")
        }
        
        initData()
        if case .browseMode = scheduler?.fastState.mode {
            XCTAssertTrue(true)
        } else {
            XCTFail("mode should be browseMode")
        }
    }
    
}

extension CommentFloatDataPluginTests: CommentServiceContext {
    var businessDependency: DocsCommentDependency? {
        return nil
    }
    
    var topMost: UIViewController? {
        return nil
    }
    
    var commentPluginView: UIView {
        return UIView()
    }
    
    var pattern: CommentModulePattern {
        return .float
    }
    
    
    var docsInfo: DocsInfo? {
        testDocsInfo
    }
    
    var scheduler: CommentSchedulerType? {
        testScheduler
    }
    
    var tableView: UITableView? { CustomTableView() }
    
    var vcToolbarHeight: CGFloat { 0 }
}
