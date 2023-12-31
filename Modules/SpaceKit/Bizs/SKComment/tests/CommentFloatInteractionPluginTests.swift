//
//  CommentFloatInteractionPluginTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by huayufan on 2022/11/3.
//  


@testable import SKCommon
@testable import SKComment
import XCTest
import RxSwift
import RxCocoa
import SKFoundation
import SpaceInterface

final class CommentFloatInteractionPluginTests:  XCTestCase, TestCommentDataSource {
    
    
    var disposeBag = DisposeBag()
    
    var testScheduler: CommentSchedulerServer?
    
    var states: [CommentState] = []
    
    var panelHeightUpdateContent = CommentAPIContent([:])
    
    var reactionContent = CommentAPIContent([:])
    
    var willDisplayConetent = CommentAPIContent([:])
    
    var switchConetent = CommentAPIContent([:])
    
    var scrollConetent = CommentAPIContent([:])

    var pattern: CommentModulePattern = .float

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        let scheduler = CommentSchedulerServer()
        scheduler.connect(plugins: [CommentFloatDataPlugin(),
                                    CommentFloatInteractionPlugin(),
                                    CommentImagePlugin(),
                                    CommentReactionPlugin(),
                                    CommentStatistPlugin(),
                                    CommentMenuPlugin(),
                                    CommentAPIPlugin(api: self),
                                    CommentStatistPlugin(),
                                    CommentDraftPlugin()])
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

        reactionContent = CommentAPIContent([:])
        panelHeightUpdateContent = CommentAPIContent([:])
        AssertionConfigForTest.reset()
        SpaceTranslationCenter.standard.config = nil
        willDisplayConetent = CommentAPIContent([:])
        switchConetent = CommentAPIContent([:])
        scrollConetent = CommentAPIContent([:])
    }
    
    func testPanelHeightUpdate() {
        initData()
        scheduler?.dispatch(action: .interaction(.panelHeightUpdate(height: 100)))
        XCTAssertTrue(!panelHeightUpdateContent.parsing([.height]).isEmpty)
    }
    
    func testEdit() {
        let commentData = initData()
        guard let item1 = commentData.comments[0].commentList.last else { return }
        scheduler?.dispatch(action: .interaction(.edit(item1)))
        if let mode = scheduler?.fastState.mode {
            if case let .edit(item2) = mode {
                XCTAssertEqual(item2.replyID, item1.replyID)
            } else {
                XCTFail("mode is not edit")
            }
        } else {
            XCTFail("mode is nil")
        }
        
        scheduler?.dispatch(action: .interaction(.tapBlank))
        if let mode = scheduler?.fastState.mode {
            if case .browseMode = mode {
                XCTAssertTrue(true)
            } else {
                XCTFail("mode is not browseMode")
            }
        } else {
            XCTFail("mode is nil")
        }
        
        states.removeAll()
        scheduler?.dispatch(action: .interaction(.tapBlank))
        var isDismiss = false
        for state in states {
            if case .dismiss = state {
                isDismiss = true
            }
        }
        XCTAssertTrue(isDismiss)
    }
    
    func testReply() {
        let commentData = initData()
        guard let item1 = commentData.comments[0].commentList.last else { return }
        scheduler?.dispatch(action: .interaction(.reply(item1)))
        if let mode = scheduler?.fastState.mode {
            if case let .reply(item2) = mode {
                XCTAssertEqual(item2.replyID, item1.replyID)
            } else {
                XCTFail("mode is not reply")
            }
        } else {
            XCTFail("mode is nil")
        }

        scheduler?.dispatch(action: .interaction(.tapBlank))
        if let mode = scheduler?.fastState.mode {
            if case .browseMode = mode {
                XCTAssertTrue(true)
            } else {
                XCTFail("mode is not browseMode")
            }
        } else {
            XCTFail("mode is nil")
        }
        
        
        states.removeAll()
        scheduler?.dispatch(action: .interaction(.tapBlank))
        var isDismiss = false
        for state in states {
            if case .dismiss = state {
                isDismiss = true
            }
        }
        XCTAssertTrue(isDismiss)
    }
    
    func testOtherAction() {
        let commentData = initData()
        guard let item1 = commentData.comments[0].commentList.last else { return }
        item1.status = .unread
        scheduler?.dispatch(action: .interaction(.willDisplayUnread(item1)))
        XCTAssertTrue(!willDisplayConetent.parsing([.msgIds]).isEmpty)
        
        scheduler?.dispatch(action: .interaction(.switchCard(commentId: item1.commentId ?? "", height: 100)))
        XCTAssertTrue(!switchConetent.parsing([.height]).isEmpty)
        
        let info = CommentScrollInfo(commentId: "12", replyId: "34", replyPercentage: 0.1)
        scheduler?.dispatch(action: .interaction(.magicShareScroll(info)))
        XCTAssertTrue(!scrollConetent.parsing([.replyId]).isEmpty)
        
    }
    
    func testFollow() {
        let commentData = initData()
        guard let item1 = commentData.comments[0].commentList.last else { return }
        scheduler?.dispatch(action: .interaction(.reply(item1)))
        if let mode = scheduler?.fastState.mode {
            if case let .reply(item2) = mode {
                XCTAssertEqual(item2.replyID, item1.replyID)
            } else {
                XCTFail("mode is not reply")
            }
        } else {
            XCTFail("mode is nil")
        }
        // 跟随之后要退出回复模式
        scheduler?.dispatch(action: .vcFollowOnRoleChange(role: .follower))
        if let mode = scheduler?.fastState.mode {
            if case .browseMode = mode {
                XCTAssertTrue(true)
            } else {
                XCTFail("mode is not browseMode")
            }
        } else {
            XCTFail("mode is nil")
        }
    }
}

extension CommentFloatInteractionPluginTests: CommentServiceContext {
    var businessDependency: DocsCommentDependency? {
        return nil
    }
    
    var topMost: UIViewController? {
        return UIViewController()
    }
    
    var commentPluginView: UIView {
        return UIView()
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

extension CommentFloatInteractionPluginTests: CommentAPIAdaper {
    func clickQuoteMenu(_ content: CommentAPIContent) {
        
    }
    
    func anchorLinkSwitch(_ content: CommentAPIContent) {

    }
    
    var apiType: CommentAPIAdaperType {
        return.webview
    }
    
    func addComment(_ content: CommentAPIContent) {
        
    }
    
    func addReply(_ content: CommentAPIContent) {
        
    }
    
    func updateReply(_ content: CommentAPIContent) {
        
    }
    
    func deleteReply(_ content: CommentAPIContent) {
        
    }
    
    func resolveComment(_ content: CommentAPIContent) {
        
    }
    
    func retry(_ content: CommentAPIContent) {
        
    }
    
    func translate(_ content: CommentAPIContent) {

    }
    
    func addReaction(_ content: CommentAPIContent) {
        reactionContent = content
    }
    
    func removeReaction(_ content: CommentAPIContent) {
        reactionContent = content
    }
    
    func setDetailPanel(_ content: CommentAPIContent) {
        
    }
    
    func getReactionDetail(_ content: CommentAPIContent) {
        
    }
    
    func readMessage(_ content: CommentAPIContent) {
        willDisplayConetent = content
    }
    
    func readMessageByCommentId(_ content: CommentAPIContent) {
        
    }
    
    func scrollComment(_ content: CommentAPIContent) {
        scrollConetent = content
    }
    
    func activeCommentInvisible(_ content: CommentAPIContent) {
        
    }
    
    func addContentReaction(_ content: CommentAPIContent) {

    }
    
    func removeContentReaction(_ content: CommentAPIContent) {

    }
    
    func getContentReactionDetail(_ content: CommentAPIContent) {
        
    }
    
    func close(_ content: CommentAPIContent) {
        
    }
    
    func cancelActive(_ content: CommentAPIContent) {
        
    }
    
    func switchCard(_ content: CommentAPIContent) {
        switchConetent = content
    }
    
    func panelHeightUpdate(_ content: CommentAPIContent) {
        panelHeightUpdateContent = content
    }
    
    func onMention(_ content: CommentAPIContent) {
        
    }
    
    func activateImageChange(_ content: CommentAPIContent) {
        
    }
    
    func retryAddNewComment(_ content: CommentAPIContent) {
        
    }
}
