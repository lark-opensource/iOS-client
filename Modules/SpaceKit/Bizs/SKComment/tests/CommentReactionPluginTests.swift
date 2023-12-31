//
//  CommentReactionPluginTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by huayufan on 2022/11/3.
//  


@testable import SKCommon
@testable import SKFoundation
@testable import SKComment
import XCTest
import RxSwift
import RxCocoa
import LarkReactionView
import SKFoundation
import SpaceInterface


class CommentReactionPluginTests: XCTestCase, TestCommentDataSource {

    
    var disposeBag = DisposeBag()
    
    var testScheduler: CommentSchedulerServer?
    
    var states: [CommentState] = []
    
    var blockReactionContent = CommentAPIContent([:])
    
    var reactionContent = CommentAPIContent([:])
    
    var translateConetent = CommentAPIContent([:])
    
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        UserScopeNoChangeFG.setMockFG(key: "ccm.mobile.comment_translate_config", value: true)
        let scheduler = CommentSchedulerServer()
        scheduler.connect(plugins: [CommentFloatDataPlugin(),
                                    CommentImagePlugin(),
                                    CommentReactionPlugin(),
                                    CommentStatistPlugin(),
                                    CommentMenuPlugin(),
                                    CommentAPIPlugin(api: self),
                                    CommentStatistPlugin()])
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
        blockReactionContent = CommentAPIContent([:])
        AssertionConfigForTest.reset()
        SpaceTranslationCenter.standard.config = nil
        translateConetent = CommentAPIContent([:])
    }
    
    
    func testReaction() {
        let commentData = testComment()
        XCTAssertNotNil(commentData)
        guard let data = commentData else {
            return
        }
        let item = data.comments[0].commentList[1]
        testScheduler?.dispatch(action: .updateData(data))
        testScheduler?.dispatch(action: .interaction(.showReaction(item: item, location: .zero, cell: UIView(), trigerView: UIView())))

        let currentReplyId = item.replyID
        
        let expect = expectation(description: "testReaction")
        
        testScheduler?.dispatch(action: .ipc(.fetchMenuKeys, { [weak self] value, _ in
            guard let self = self else { return }
            var dismissKeys: [String] = []
            expect.fulfill()
            if let keys = value as? [String],
               !keys.isEmpty {
                var found = false
                for key in keys {
                    let menuKey = key.split(separator: "_").map(String.init)
                    guard menuKey.count == 2 else {
                        continue
                    }
                    let replyId = menuKey[1]
                    if replyId == currentReplyId {
                        found = true
                        dismissKeys.append(key)
                    }
                }
                XCTAssertTrue(found)
                if !dismissKeys.isEmpty {
                    self.scheduler?.dispatch(action: .ipc(.dismisMunu(keys: dismissKeys), nil))
                }
            }
        }))
        wait(for: [expect], timeout: 1, enforceOrder: false)
        
        
        let expect2 = expectation(description: "testReaction")
        testScheduler?.dispatch(action: .interaction(.showBlockReaction(item: item, location: .zero, cell: UIView(), trigerView: UIView())))
        testScheduler?.dispatch(action: .ipc(.fetchMenuKeys, { [weak self] value, _ in
            guard let self = self else { return }
            var dismissKeys: [String] = []
            expect2.fulfill()
            if let keys = value as? [String],
               !keys.isEmpty {
                var found = false
                for key in keys {
                    let menuKey = key.split(separator: "_").map(String.init)
                    guard menuKey.count == 2 else {
                        continue
                    }
                    let replyId = menuKey[1]
                    if replyId == currentReplyId {
                        found = true
                        dismissKeys.append(key)
                    }
                }
                XCTAssertTrue(found)
            }
        }))
        wait(for: [expect2], timeout: 1, enforceOrder: false)
    }
    
    func testClickReaction() {
        let commentData = testComment()
        XCTAssertNotNil(commentData)
        guard let data = commentData else {
            return
        }
        let item = data.comments[0].commentList[1]
        testScheduler?.dispatch(action: .updateData(data))
        let user = ReactionUser(id: testDocsInfo.commentUser?.id ?? "1", name: "Jack")
        testScheduler?.dispatch(action: .interaction(.clickReaction(item, ReactionInfo.init(reactionKey: "HAPPY", users: [user]), .icon)))
        XCTAssertFalse(reactionContent.parsing([.reactionKey]).isEmpty)
        
        item.updateInteractionType(.reaction)
        testScheduler?.dispatch(action: .interaction(.clickReaction(item, ReactionInfo(reactionKey: "HAPPY", users: [user]), .icon)))
        XCTAssertFalse(blockReactionContent.parsing([.reactionKey]).isEmpty)
        
    }
    
    func testClickReactionPermission() {
        let commentData = testComment(permission: [.canCopy])
        XCTAssertNotNil(commentData)
        guard let data = commentData else {
            return
        }
        let item = data.comments[0].commentList[1]
        testScheduler?.dispatch(action: .updateData(data))
        let user = ReactionUser(id: testDocsInfo.commentUser?.id ?? "1", name: "Jack")
        testScheduler?.dispatch(action: .interaction(.clickReaction(item, ReactionInfo.init(reactionKey: "HAPPY", users: [user]), .icon)))
        XCTAssertTrue(reactionContent.parsing([.reactionKey]).isEmpty)
    }
    
    func testTranslate() {
        // cancel
        let data = initData()
        guard let item = data.comments[0].commentList.last else {
            return
        }
        CommentTranslationTools.shared.remove(store: item)
        scheduler?.dispatch(action: .interaction(.clickTranslationIcon(item)))
        XCTAssertTrue(CommentTranslationTools.shared.contain(store: item))
        
        // translate
        SpaceTranslationCenter.standard.config = SpaceTranslationCenter.Config(autoTranslate: false, displayType: .bothShow, enableCommentTranslate: true)
        
        guard let plugin = scheduler?.plugin(with: CommentReactionPlugin.self) else {
            return
        }
        
        plugin.translateComment(item)
        let replyId: String? = translateConetent[.replyId]
        XCTAssertNotNil(replyId)
        XCTAssertFalse(CommentTranslationTools.shared.contain(store: item))
        
        CommentTranslationTools.shared.add(store: item)
        item.translateContent = "123"
        plugin.translateComment(item)
        XCTAssertFalse(CommentTranslationTools.shared.contain(store: item))
    }
}

extension CommentReactionPluginTests: DocsCommentDependency {
    var commentDocsInfo: CommentDocsInfo {
        return testDocsInfo
    }
    
    var businessConfig: CommentBusinessConfig {
        .init(translateConfig: CommentBusinessConfig.TranslateConfig.init(autoTranslate: false, displayType: .bothShow, enableCommentTranslate: true))
    }
}

extension CommentReactionPluginTests: CommentServiceContext {
    var businessDependency: DocsCommentDependency? {
        return self
    }
    
    var topMost: UIViewController? {
        return UIViewController()
    }
    
    var commentPluginView: UIView {
        return UIView()
    }
    
    var pattern: CommentModulePattern {
        .aside
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

extension CommentReactionPluginTests: CommentAPIAdaper {
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
        self.translateConetent = content
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
        
    }
    
    func readMessageByCommentId(_ content: CommentAPIContent) {
        
    }
    
    func scrollComment(_ content: CommentAPIContent) {
        
    }
    
    func activeCommentInvisible(_ content: CommentAPIContent) {
        
    }
    
    func addContentReaction(_ content: CommentAPIContent) {
        blockReactionContent = content
    }
    
    func removeContentReaction(_ content: CommentAPIContent) {
        blockReactionContent = content
    }
    
    func getContentReactionDetail(_ content: CommentAPIContent) {
        
    }
    
    func close(_ content: CommentAPIContent) {
        
    }
    
    func cancelActive(_ content: CommentAPIContent) {
        
    }
    
    func switchCard(_ content: CommentAPIContent) {
        
    }
    
    func panelHeightUpdate(_ content: CommentAPIContent) {
        
    }
    
    func onMention(_ content: CommentAPIContent) {
        
    }
    
    func activateImageChange(_ content: CommentAPIContent) {
        
    }
    
    func retryAddNewComment(_ content: CommentAPIContent) {
        
    }
}
