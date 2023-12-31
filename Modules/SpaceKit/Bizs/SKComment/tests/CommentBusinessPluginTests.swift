//
//  CommentBusinessPluginTests.swift
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
@testable import SKFoundation
import SpaceInterface

class CommentBusinessPluginTests: XCTestCase, TestCommentDataSource {
    
    var content = CommentAPIContent([:])
    
    var disposeBag = DisposeBag()
    
    var testScheduler: CommentSchedulerServer?
    
    var states: [CommentState] = []
    
    var businessConfig = CommentBusinessConfig()
    
    var anchorLinkContent = CommentAPIContent([:])
    
    var openQR = false
    var openDocsURL = false
    var openUserProfile = false
    
    var pattern: CommentModulePattern = .aside

    override func setUp() {
        super.setUp()
        UserScopeNoChangeFG.setMockFG(key: "ccm.gpe.comment.anchor_link_mobile", value: true)
        
        AssertionConfigForTest.disableAssertWhenTesting()
        let scheduler = CommentSchedulerServer()
        scheduler.connect(plugins: [CommentFloatDataPlugin(),
                                    CommentImagePlugin(),
                                    CommentReactionPlugin(),
                                    CommentStatistPlugin(),
                                    CommentMenuPlugin(),
                                    CommentStatistPlugin(),
                                    CommentBusinessPlugin(),
                                    CommentAPIPlugin(api: self)])
        scheduler.apply(context: self)
        self.testScheduler = scheduler
        testScheduler?.state.skip(1).subscribe(onNext: { [weak self] (state) in
            self?.states.append(state)
        }).disposed(by: disposeBag)
    }
    
    var menuPlugin: CommentMenuPlugin?
    var textPlugin: CommentTextPlugin?
    
    var receiveForcePortraint: Bool?

    override func tearDown() {
        super.tearDown()
        disposeBag = DisposeBag()
        self.scheduler?.plugin(with: CommentFloatDataPlugin.self)?.commentSections = []
        states.removeAll()
        AssertionConfigForTest.reset()
        openQR = false
        openDocsURL = false
        openUserProfile = false
        anchorLinkContent = CommentAPIContent([:])
        pattern = .aside
        receiveForcePortraint = nil
    }

    func testURL() {
        guard let url = URL(string: "https://bytedance.feishu.cn/docx/DeRfdG9M1orMyIxdG1RcAPelnOd") else {
            return
        }
        let tuple = url.docs.isCommentAnchorLink
        XCTAssertTrue(!tuple.isCommentAnchor)
        
        guard let url2 = URL(string: "https://bytedance.feishu.cn/docx/DeRfdG9M1orMyIxdG1RcAPelnOd?comment_anchor=true&comment_id=1234456") else {
            return
        }
        let tuple2 = url2.docs.isCommentAnchorLink
        XCTAssertTrue(tuple2.isCommentAnchor)
        XCTAssertTrue(!tuple2.commentId.isEmpty)
    }

    func testClickURL() {
        let commentData = initData()
        businessConfig = CommentBusinessConfig(canOpenURL: false, canOpenProfile: false, canCopyCommentLink: true)
        guard let url = URL(string: "https://bytedance.feishu.cn/docx/DeRfdG9M1orMyIxdG1RcAPelnOd") else {
            return
        }
        testDocsInfo.objToken = commentData.docsInfo?.objToken ?? "NWbsdIn9cok3Lzxws8ickr7Nn9f"
        let urlStr = testDocsInfo.urlForSuspendable()
        guard let url2 = URL(string: "\(urlStr)?comment_anchor=true&comment_id=1234456") else {
            return
        }
        // 正常打开文档
        scheduler?.dispatch(action: .interaction(.clickURL(url)))
        XCTAssertTrue(openDocsURL)
        openDocsURL = false

        // 调用api
        scheduler?.dispatch(action: .interaction(.clickURL(url2)))
        XCTAssertFalse(anchorLinkContent.parsing([.commentId]).isEmpty)
        anchorLinkContent = CommentAPIContent([:])

        // 点击当前文档，走通用逻辑打开文档，提示在通用逻辑处处理
        guard let url3 = URL(string: urlStr) else {
            return
        }
        scheduler?.dispatch(action: .interaction(.clickURL(url3)))
        XCTAssertTrue(openDocsURL)
        XCTAssertTrue(anchorLinkContent.parsing([.commentId]).isEmpty)
    }
    
    func testCommentBusinessConfig() {
        initData()
        // 在外部打开
        businessConfig = CommentBusinessConfig(canOpenURL: false, canOpenProfile: false, canCopyCommentLink: true)
        guard let url = URL(string: "https://bytedance.feishu.cn/docx/DeRfdG9M1orMyIxdG1RcAPelnOd") else {
            return
        }
        scheduler?.dispatch(action: .interaction(.clickURL(url)))
        XCTAssertTrue(openDocsURL)
        openDocsURL = false

        scheduler?.dispatch(action: .ipc(.clickReactionName(userId: "1", from: nil), nil))
        XCTAssertTrue(openUserProfile)
        openUserProfile = false

        businessConfig = CommentBusinessConfig()
        scheduler?.dispatch(action: .interaction(.clickURL(url)))
        XCTAssertFalse(openDocsURL)
        openDocsURL = false

        scheduler?.dispatch(action: .ipc(.clickReactionName(userId: "1", from: nil), nil))
        XCTAssertFalse(openUserProfile)
        openUserProfile = false
        
        // QR在webview内由外部处理
        pattern = .aside
        scheduler?.dispatch(action: .interaction(.scanQR("1")))
        XCTAssertTrue(openQR)
        openQR = false
        
        pattern = .float
        scheduler?.dispatch(action: .interaction(.scanQR("1")))
        XCTAssertTrue(openQR)
        openQR = false
        

        // drive 在内部处理
        pattern = .drive
        scheduler?.dispatch(action: .interaction(.scanQR("1")))
        XCTAssertFalse(openQR)
    }

    func testKeepPotraint() {
        initData()
        testScheduler?.dispatch(action: .interaction(.keepPotraint(force: true)))
        XCTAssertTrue(receiveForcePortraint == true)
    }
}

extension CommentBusinessPluginTests: DocsCommentDependency {
    
    var commentDocsInfo: CommentDocsInfo {
        return testDocsInfo
    }
    
    func scanQR(code: String) {
        openQR = true
    }
    
    func openDocs(url: URL) {
        openDocsURL = true
    }
    
    func showUserProfile(userId: String, from: UIViewController?) {
        openUserProfile = true
    }

    func forcePortraint(force: Bool) {
        receiveForcePortraint = true
    }
}

extension CommentBusinessPluginTests: CommentAPIAdaper {
    func clickQuoteMenu(_ content: CommentAPIContent) {

    }
    
    var apiType: CommentAPIAdaperType {
        return .webview
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

    }
    
    func removeReaction(_ content: CommentAPIContent) {

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

    }
    
    func panelHeightUpdate(_ content: CommentAPIContent) {

    }
    
    func onMention(_ content: CommentAPIContent) {

    }
    
    func activateImageChange(_ content: CommentAPIContent) {

    }
    
    func retryAddNewComment(_ content: CommentAPIContent) {

    }
    
    func anchorLinkSwitch(_ content: CommentAPIContent) {
        anchorLinkContent = content
    }

}

extension CommentBusinessPluginTests: CommentServiceContext {
    var businessDependency: DocsCommentDependency? {
        return self
    }
    
    var topMost: UIViewController? {
        return nil
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
