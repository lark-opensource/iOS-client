//
//  CommentAPIPluginTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by huayufan on 2022/11/3.
//
//swiftlint:disable file_length


@testable import SKCommon
@testable import SKComment
import XCTest
import RxSwift
import RxCocoa
import OHHTTPStubs
@testable import SKFoundation
import SpaceInterface
import SKInfra

class CommentAPIPluginTests: XCTestCase, TestCommentDataSource {
   
    var apiType: CommentAPIAdaperType = .webview
    
    lazy var apiPlugin = CommentAPIPlugin(api: self)
    
    var content = CommentAPIContent([:])
    
    var disposeBag = DisposeBag()
    
    var testScheduler: CommentSchedulerServer?
    
    var states: [CommentState] = []
    
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        let scheduler = CommentSchedulerServer()
        scheduler.connect(plugins: [CommentFloatDataPlugin(),
                                    CommentReactionPlugin(),
                                    apiPlugin])
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
        AssertionConfigForTest.reset()
    }

    // swiftlint:disable function_body_length
    func testAPI() {
        initData()
        
        let imgInfo = CommentImageInfo(uuid: UUID().uuidString,
                         token: "doc1234566778",
                         src: "https://www.baidu.com/abc.jpg",
                         originalSrc: "https://www.baidu.com/abc2.jpg")
        let commentContent = CommentContent(content: "123",
                                            imageInfos: [imgInfo],
                                            pcmData: nil,
                                            pcmDataTime: nil,
                                            attrContent: NSAttributedString(string: "123"),
                                            isAudio: false)
        guard let comment = scheduler?.fastState.activeComment else {
            XCTFail("fastState comment is nil")
            return
        }
        comment.parentType = "1"
        comment.parentToken = "abc"
        comment.position = "1"
        let item = comment.commentList.last!
        let wrapper = CommentWrapper(commentItem: item, comment: comment)
        
        // ===== 1. add new Comment =====
        comment.isNewInput = true
        apiType = .webview
        scheduler?.dispatch(action: .api(.addComment(commentContent, wrapper), nil))
        chechParmas(keys: [.commentId, .imageList, .content, .isWhole], notNilStringKeys: [.commentId, .content], errorMsg: "web addComment did not pass")
        
        apiType = .rn
        scheduler?.dispatch(action: .api(.addComment(commentContent, wrapper), nil))
        chechParmas(keys: [.content,
                           .comment_id,
                           .rnIsWhole,
                           .quote,
                           .rnParentType,
                           .rnParentToken,
                           .localCommentId,
                           .type,
                           .bizParams,
                           .position,
                           .extra],
                    notNilStringKeys: [.content, .comment_id, .quote, .rnParentType, .rnParentToken, .localCommentId],
                    errorMsg: "rn addComment did not pass")
        
        clearContent()
        
        // ===== 2. add reply =====
        comment.isNewInput = false
        apiType = .webview
        scheduler?.dispatch(action: .api(.addComment(commentContent, wrapper), nil))
        chechParmas(keys: [.commentId, .content, .imageList, .isWhole], notNilStringKeys: [.commentId, .content], errorMsg: "web add reply did not pass")
        
        apiType = .rn
        scheduler?.dispatch(action: .api(.addComment(commentContent, wrapper), nil))
        chechParmas(keys: [.content,
                           .comment_id,
                           .rnIsWhole,
                           .type,
                           .bizParams,
                           .position,
                           .extra],
                    notNilStringKeys: [.content, .comment_id],
                    errorMsg: "rn add reply did not pass")
        
        
        clearContent()
        // ===== 3. edit =====
        apiType = .webview
        scheduler?.dispatch(action: .api(.editComment(commentContent, wrapper), nil))
        chechParmas(keys: [.commentId, .replyId, .content, .imageList], notNilStringKeys: [.commentId, .content, .replyId], errorMsg: "web edit did not pass")
        clearContent()
        
        apiType = .rn
        scheduler?.dispatch(action: .api(.editComment(commentContent, wrapper), nil))
        chechParmas(keys: [.content,
                           .comment_id,
                           .rnReplyId,
                           .bizParams,
                           .extra],
                    notNilStringKeys: [.content, .comment_id, .rnReplyId],
                    errorMsg: "rn edit did not pass")
        
        clearContent()

        // ===== 4. retry =====
        apiType = .webview
        scheduler?.dispatch(action: .api(.retry(item), nil))
        chechParmas(keys: [.commentId, .replyId], notNilStringKeys: [.commentId, .replyId], errorMsg: "web retry did not pass")
        clearContent()
        
        apiType = .rn
        scheduler?.dispatch(action: .api(.retry(item), nil))
        chechParmas(keys: [.content,
                           .comment_id,
                           .rnIsWhole,
                           .type,
                           .bizParams,
                           .position], notNilStringKeys: [.comment_id, .position], errorMsg: "rn retry did not pass")
        
        clearContent()
        // ===== 5. delete =====
        apiType = .webview
        scheduler?.dispatch(action: .api(.delete(item), nil))
        chechParmas(keys: [.commentId, .replyId], notNilStringKeys: [.commentId, .replyId], errorMsg: "web delete did not pass")
        clearContent()

        apiType = .rn
        scheduler?.dispatch(action: .api(.delete(item), nil))
        chechParmas(keys: [.comment_id, .rnReplyId], notNilStringKeys: [.comment_id, .rnReplyId], errorMsg: "rn delete did not pass")
        
        clearContent()
        // ===== 6. resolveComment =====
        apiType = .webview
        scheduler?.dispatch(action: .api(.resolveComment(commentId: comment.commentID, activeCommentId: comment.commentID), nil))
        chechParmas(keys: [.commentId, .activeCommentId], notNilStringKeys: [.commentId, .activeCommentId], errorMsg: "web resolveComment did not pass")
        clearContent()

        apiType = .rn
        scheduler?.dispatch(action: .api(.resolveComment(commentId: comment.commentID, activeCommentId: comment.commentID), nil))
        chechParmas(keys: [.comment_id, .activeCommentId, .finish], notNilStringKeys: [.comment_id, .activeCommentId], errorMsg: "rn resolveComment did not pass")
        
        clearContent()

        // ===== 7. switchCard =====
        apiType = .webview
        scheduler?.dispatch(action: .api(.switchCard(commentId: comment.commentID, height: 400), nil))
        chechParmas(keys: [.comment_id, .from, .height], notNilStringKeys: [.comment_id, .from], errorMsg: "web switchCard did not pass")
        clearContent()
        
        apiType = .rn
        scheduler?.dispatch(action: .api(.switchCard(commentId: comment.commentID, height: 400), nil))
        chechParmas(keys: [.comment_id, .from, .height, .page], notNilStringKeys: [.comment_id, .from], errorMsg: "rn switchCard did not pass")
        
        clearContent()
        
        // ===== 8. cancel =====
        apiType = .webview
        scheduler?.dispatch(action: .api(.cancelPartialNewInput, nil))
        chechParmas(keys: [.type], notNilStringKeys: [.type], errorMsg: "cancelPartialNewInput not pass")
        clearContent()
        
        scheduler?.dispatch(action: .api(.cancelGloablNewInput, nil))
        chechParmas(keys: [.type], notNilStringKeys: [.type], errorMsg: "cancelGloablNewInput not pass")
        clearContent()
        
        scheduler?.dispatch(action: .api(.closeComment, nil))
        chechParmas(keys: [.type], notNilStringKeys: [.type], errorMsg: "closeComment not pass")
        clearContent()
        
        // ===== 9. reaction =====
        apiType = .webview
        scheduler?.dispatch(action: .api(.addReaction(reactionKey: "HAPPY", item: item), nil))
        chechParmas(keys: [.reactionKey, .replyId], notNilStringKeys: [.reactionKey, .replyId], errorMsg: "addReaction not pass")
        clearContent()
        
        scheduler?.dispatch(action: .api(.removeReaction(reactionKey: "HAPPY", item: item), nil))
        chechParmas(keys: [.reactionKey, .replyId], notNilStringKeys: [.reactionKey, .replyId], errorMsg: "removeReaction not pass")
        clearContent()
        
        scheduler?.dispatch(action: .api(.addContentReaction(reactionKey: "HAPPY", item: item), nil))
        chechParmas(keys: [.reactionKey, .commentId], notNilStringKeys: [.reactionKey, .commentId], errorMsg: "addContentReaction not pass")
        clearContent()
        
        scheduler?.dispatch(action: .api(.removeContentReaction(reactionKey: "HAPPY", item: item), nil))
        chechParmas(keys: [.reactionKey, .commentId], notNilStringKeys: [.reactionKey, .commentId], errorMsg: "removeContentReaction not pass")
        clearContent()

        
        // ===== 10. translate =====
        apiType = .webview
        scheduler?.dispatch(action: .api(.translate(item), nil))
        chechParmas(keys: [.commentId, .replyId], notNilStringKeys: [.commentId, .replyId], errorMsg: "web translate not pass")
        clearContent()
        
        apiType = .rn
        scheduler?.dispatch(action: .api(.translate(item), nil))
        chechParmas(keys: [.comment_id, .rnReplyId], notNilStringKeys: [.comment_id, .rnReplyId], errorMsg: "rn translate not pass")
        clearContent()
        
        
        // ===== 11. activateImageChange =====
        apiType = .webview
        scheduler?.dispatch(action: .api(.activateImageChange(item: item, index: 0), nil))
        chechParmas(keys: [.commentId, .replyId, .index], notNilStringKeys: [.commentId, .replyId], errorMsg: "rn activateImageChange not pass")
        clearContent()
        
        // ===== 12. readMessage =====
        apiType = .webview
        scheduler?.dispatch(action: .api(.readMessage(item), nil))
        chechParmas(keys: [.msgIds], notNilStringKeys: [], errorMsg: "readMessage not pass")
        clearContent()
    
        item.updateInteractionType(.reaction)
        scheduler?.dispatch(action: .api(.readMessage(item), nil))
        chechParmas(keys: [.commentId], notNilStringKeys: [.commentId], errorMsg: "readMessage not pass")
        clearContent()
        
        
        // ===== 13. onMention =====
        apiType = .webview
        let atInfo = AtInfo(type: .doc, href: "https://www.baidu.com", token: "123", at: "111")
        atInfo.avatarUrl = "https://www.baidu.com"
        atInfo.name = "Jack"
        atInfo.cnName = "Jack"
        atInfo.enName = "Jack"
        atInfo.enName = "Jack"
        atInfo.unionId = "234"
        atInfo.department = "ByteDance"
        atInfo.id = UUID().uuidString
        scheduler?.dispatch(action: .api(.didMention(atInfo), nil))
        chechParmas(keys: [.id,
                           .avatarUrl,
                           .name,
                           .cnName,
                           .enName,
                           .unionId,
                           .department],
                    notNilStringKeys: [ .id,
                                        .avatarUrl,
                                        .name,
                                        .cnName,
                                        .enName,
                                        .unionId,
                                        .department],
                    errorMsg: "onMention not pass")
        clearContent()
        
       // ===== 14. magicShareScroll =====
        apiType = .webview
        let info = CommentScrollInfo(commentId: "a", replyId: "b", replyPercentage: 0.2)
        scheduler?.dispatch(action: .api(.magicShareScroll(info), nil))
        chechParmas(keys: [.curCommentId, .replyId, .replyPercentage], notNilStringKeys: [.curCommentId, .replyId], errorMsg: "magicShareScroll not pass")
        clearContent()
        
        // ===== 15. contentBecomeInvisibale =====
        scheduler?.dispatch(action: .api(.contentBecomeInvisibale(info), nil))
        chechParmas(keys: [.curCommentId], notNilStringKeys: [.curCommentId], errorMsg: "contentBecomeInvisibale not pass")
        clearContent()

        // ===== 16. anchorLinkSwitch =====
        scheduler?.dispatch(action: .api(.anchorLinkSwitch(commentId: "123"), nil))
        chechParmas(keys: [.commentId], notNilStringKeys: [.commentId,], errorMsg: "anchorLinkSwitch not pass")
        clearContent()
    }
    
    func testAt() {
        initData()
        let uid = "123"
        let netExpect = expectation(description: "requestAtUserPermission net")
        AssertionConfigForTest.disableAssertWhenTesting()
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.suitePermissionUserMget)
            return contain
        }, response: { _ in
            netExpect.fulfill()
            AssertionConfigForTest.reset()
            return HTTPStubsResponse(jsonObject: ["code": 4, "msg": "failure", "data": ["permissions_v2": [uid: 1]]], statusCode: 200, headers: ["Content-Type": "application/json"])
        })
        
        let atExpect = expectation(description: "requestAtUserPermission")
        let action = CommentAction.api(.requestAtUserPermission([uid])) { (_, error) in
            atExpect.fulfill()
            XCTAssertNil(error)
        }
        scheduler?.dispatch(action: action)
        wait(for: [atExpect, netExpect], timeout: 2, enforceOrder: false)
        clearContent()
    }

    func chechParmas(keys: [CommentAPIContent.APIKey], notNilStringKeys: [CommentAPIContent.APIKey], errorMsg: String = "") {
        let res = self.content.parsing(keys)
        XCTAssertEqual(res.count, keys.count, errorMsg)
        for k in notNilStringKeys {
            if let value = res[k.rawValue] as? String {
                XCTAssertTrue(!value.isEmpty, errorMsg + " \(k.rawValue) can not be nil")
            } else {
                XCTFail(errorMsg + " \(k.rawValue) can not be nil")
            }
        }
    }
    
    func clearContent() {
        self.content = CommentAPIContent([:])
    }

    func testInviteUser() {
        let data = initData()
        let expect = expectation(description: "test params")
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.suitePermissionCollaboratorsCreate)
            return contain
        }, response: { _ in
            expect.fulfill()
            return HTTPStubsResponse(jsonObject: ["code": 0, "msg": "", "data": [:]], statusCode: 200, headers: ["Content-Type": "application/json"])
        })

        let expect1 = expectation(description: "test params")
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.suitePermissionUserMget)
            return contain
        }, response: { _ in
            expect1.fulfill()
            return HTTPStubsResponse(jsonObject: ["code": 0, "msg": "success", "data": ["permissions_v2": ["123": 1]]], statusCode: 200, headers: ["Content-Type": "application/json"])
        })
        
        
        let docsKey = AtUserDocsKey(token: data.docsInfo?.token ?? "", type: .docX)
        let permission = AtUserPermission(sKDocsKey: docsKey)
        let mask: UserPermissionMask = .read
        let atInfo = AtInfo(type: .user, href: "feishu.com/docx/cniawdeiqow", token: "123", at: "xx")
        atInfo.id = "123"
        permission.updateUserPermissionCache(key: "123", value: mask)
        AtPermissionManager.shared.atUserArray[docsKey] = permission
        NetConfig.shared.baseUrl = "feishu.com"
        scheduler?.dispatch(action: .api(.inviteUserRequest(atInfo: atInfo, sendLark: false), nil))
        
        let expect2 = expectation(description: "test refreshAtUserText")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
            var containState = false
            for state in self.states {
                if case .refreshAtUserText = state {
                    containState = true
                }
            }
            NetConfig.shared.baseUrl = ""
            XCTAssertTrue(containState)
            expect2.fulfill()
        }
        wait(for: [expect, expect1, expect2], timeout: 2)
    }
    
    func testOnMenuClick() {
        let data = initData()
        let comment = data.comments[0]
        let plugin = scheduler?.plugin(with: CommentReactionPlugin.self)
        let link = "https://bytedance.feishu.cn/docx/DeRfdG9M1orMyIxdG1RcAPelnOd?comment_anchor=true&comment_id={commentId}"
        plugin?.resolveAndCopyMenuAction(.shareAnchorLink, comment, link, UIView(), nil)
        chechParmas(keys: [.commentId, .menuId], notNilStringKeys: [.commentId, .menuId])
        clearContent()
        
        plugin?.resolveAndCopyMenuAction(.copyAnchorLink, comment, link, UIView(), nil)
        chechParmas(keys: [.commentId, .menuId], notNilStringKeys: [.commentId, .menuId])
        clearContent()
    }
}


extension CommentAPIPluginTests: CommentAPIAdaper {
    func clickQuoteMenu(_ content: CommentAPIContent) {
        self.content = content
    }
    
    func addComment(_ content: CommentAPIContent) {
        self.content = content
        if apiType == .rn {
            let data = RNCommentData()
            data.comments = [Comment()]
            content.resonse?(data)
        }
    }
    
    func addReply(_ content: CommentAPIContent) {
        self.content = content
    }
    
    func updateReply(_ content: CommentAPIContent) {
        self.content = content
    }
    
    func deleteReply(_ content: CommentAPIContent) {
        self.content = content
    }
    
    func resolveComment(_ content: CommentAPIContent) {
        self.content = content
    }
    
    func retry(_ content: CommentAPIContent) {
        self.content = content
    }
    
    func translate(_ content: CommentAPIContent) {
        self.content = content
    }
    
    func addReaction(_ content: CommentAPIContent) {
        self.content = content
    }
    
    func removeReaction(_ content: CommentAPIContent) {
        self.content = content
    }
    
    func setDetailPanel(_ content: CommentAPIContent) {
        self.content = content
    }
    
    func getReactionDetail(_ content: CommentAPIContent) {
        self.content = content
    }
    
    func readMessage(_ content: CommentAPIContent) {
        self.content = content
    }
    
    func readMessageByCommentId(_ content: CommentAPIContent) {
        self.content = content
    }
    
    func scrollComment(_ content: CommentAPIContent) {
        self.content = content
    }
    
    func activeCommentInvisible(_ content: CommentAPIContent) {
        self.content = content
    }
    
    func addContentReaction(_ content: CommentAPIContent) {
        self.content = content
    }
    
    func removeContentReaction(_ content: CommentAPIContent) {
        self.content = content
    }
    
    func getContentReactionDetail(_ content: CommentAPIContent) {
        self.content = content
    }
    
    func close(_ content: CommentAPIContent) {
        self.content = content
    }
    
    func cancelActive(_ content: CommentAPIContent) {
        self.content = content
    }
    
    func switchCard(_ content: CommentAPIContent) {
        self.content = content
    }
    
    func panelHeightUpdate(_ content: CommentAPIContent) {
        if let height: CGFloat = content[.height] {
            self.content.update(params: [.height: height])
        }
    }
    
    func onMention(_ content: CommentAPIContent) {
        self.content = content
    }
    
    func activateImageChange(_ content: CommentAPIContent) {
        self.content = content
    }
    
    func retryAddNewComment(_ content: CommentAPIContent) {
        self.content = content
    }
    
    func anchorLinkSwitch(_ content: CommentAPIContent) {
        self.content = content
    }
}
 
extension CommentAPIPluginTests: CommentServiceContext {
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
