//
//  CommentTextPluginTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by huayufan on 2022/11/3.
//


@testable import SKCommon
@testable import SKUIKit
@testable import SKComment
import XCTest
import RxSwift
import RxCocoa
@testable import SKFoundation
import SpaceInterface

class CommentTextPluginTests: XCTestCase, TestCommentDataSource {

    
    var disposeBag = DisposeBag()
    
    var testScheduler: CommentSchedulerServer?
    
    var states: [CommentState] = []
    
    var pattern: CommentModulePattern = .float
    
    var replyConetent = CommentAPIContent([:])
    var editConetent = CommentAPIContent([:])

    lazy var textPlugin: CommentTextPlugin = {
        return CommentTextPlugin()
    }()
    
    override func setUp() {
        super.setUp()
        
        let scheduler = CommentSchedulerServer()
        
        scheduler.connect(plugins: [CommentFloatDataPlugin(),
                                    CommentImagePlugin(),
                                    textPlugin,
                                    CommentFloatInteractionPlugin(),
                                    CommentDraftPlugin(),
                                    CommentAPIPlugin(api: self)])
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
        pattern = .float
        replyConetent = CommentAPIContent([:])
        editConetent = CommentAPIContent([:])
        isWhole = nil
    }
    
    
    func testCanSupportInviteUser() {
        XCTAssertTrue(textPlugin.canSupportInviteUser(DocsInfo(type: .docX, objToken: "123")))
        XCTAssertFalse(textPlugin.canSupportInviteUser(DocsInfo(type: .file, objToken: "123")))
        
        let docInfo = DocsInfo(type: .docX, objToken: "123")
        docInfo.appId = "123"
        XCTAssertFalse(textPlugin.canSupportInviteUser(docInfo))
        XCTAssertFalse(textPlugin.canSupportInviteUser(nil))
    }
    
    func testResignInputView() {
        textPlugin.resignInputView()
        var containDismiss = false
        for state in states {
            if case .dismiss = state {
                containDismiss = true
            }
        }
        XCTAssertTrue(containDismiss)
    }

    func testViewDidEndEditing() {
        pattern = .float

        let data = initData()
        let item = data.comments[0].commentList[0]
        let textView = AtInputTextView(dependency: textPlugin, font: UIFont.systemFont(ofSize: 10), ignoreRotation: false)
        states.removeAll()
        scheduler?.dispatch(action: .ipc(.setFloatCommentMode(mode: .reply(item)), nil))
        scheduler?.dispatch(action: .interaction(.textViewDidEndEditing(textView)))
        // 输入完成要变成浏览模式
        if case .browseMode = scheduler?.fastState.mode {
            XCTAssertTrue(true)
        } else {
            XCTFail("browseMode")
        }
        states.removeAll()
        
        var containDismiss = false
        guard let model = inputModel else { return }
        scheduler?.dispatch(action: .updateNewInputData(model))
//        model.markSended()
        scheduler?.dispatch(action: .ipc(.setFloatCommentMode(mode: .newInput(model)), nil))
        scheduler?.dispatch(action: .interaction(.textViewDidEndEditing(textView)))
        for state in states {
            if case .dismiss = state {
                containDismiss = true
            }
        }
        XCTAssertTrue(containDismiss)


        states.removeAll()
        pattern = .aside
        scheduler?.uninstall(plugins: [CommentFloatDataPlugin.self])
        scheduler?.connect(plugins: [CommentAsideDataPlugin()])
        scheduler?.apply(context: self)
        
        initData()
        containDismiss = false
        scheduler?.dispatch(action: .interaction(.textViewDidEndEditing(textView)))
        for state in states {
            if case .dismiss = state {
                containDismiss = true
            }
        }
        XCTAssertFalse(containDismiss)
    }

    func testAtListViewInToolView() {
        pattern = .aside
        XCTAssertFalse(textPlugin.atListViewInToolView)

        pattern = .drive
        XCTAssertTrue(textPlugin.atListViewInToolView)

        pattern = .float
        initData()
        XCTAssertTrue(textPlugin.atListViewInToolView)
        
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        guard let inputModel = inputModel else { return }
        scheduler?.dispatch(action: .updateNewInputData(inputModel))
        if isPad {
            textPlugin.docsInfo?.isInVideoConference = false
            XCTAssertTrue(textPlugin.atListViewInToolView)
        } else {
            XCTAssertTrue(textPlugin.atListViewInToolView)
        }
    }
    
    var isWhole: Bool?

    var inputModel: CommentShowInputModel? {
        func loadMockParams() -> [String: Any] {
            guard let path = Bundle(for: CommentTextPluginTests.self).path(forResource: "CommentNewInput", ofType: "plist"),
               let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
                   return [:]
            }
            guard var plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
                return [:]
            }
            if let setWhole = self.isWhole {
                plist["is_whole"] = setWhole
            }
            return plist
        }
        guard let data = try? JSONSerialization.data(withJSONObject: loadMockParams(), options: []) else {
            XCTFail("JSONSerialization fail")
            return nil
        }
        guard let model = try? JSONDecoder().decode(CommentShowInputModel.self, from: data) else {
            XCTFail("JSONDecoder fail")
            return nil
        }
        return model
    }

    func testInviteDone() {
        pattern = .float
        scheduler?.dispatch(action: .ipc(.inviteUserDone, nil))
        var containShowTextInvite = false
        for state in states {
            if case .refreshAtUserText = state {
                containShowTextInvite = true
            }
        }
        XCTAssertTrue(containShowTextInvite)
        states.removeAll()
        
        scheduler?.uninstall(plugins: [CommentFloatDataPlugin.self])
        scheduler?.connect(plugins: [CommentAsideDataPlugin()])
        scheduler?.apply(context: self)
        initData()
        scheduler?.dispatch(action: .ipc(.inviteUserDone, nil))
        containShowTextInvite = false
        for state in states {
            if case .refreshAtUserText = state {
                containShowTextInvite = true
            }
        }
        XCTAssertTrue(containShowTextInvite)
    }
    
    func testAtInputTextType() {
        pattern = .float
        
        initData()
        XCTAssertEqual(AtInputTextType.reply, textPlugin.atInputTextType)
        
        guard let inputModel = inputModel else { return }
        scheduler?.dispatch(action: .updateNewInputData(inputModel))
        XCTAssertEqual(AtInputTextType.add, textPlugin.atInputTextType)
        
        pattern = .aside
        
        scheduler?.uninstall(plugins: [CommentFloatDataPlugin.self])
        scheduler?.connect(plugins: [CommentAsideDataPlugin()])
        scheduler?.apply(context: self)
        initData()
        XCTAssertEqual(AtInputTextType.reply, textPlugin.atInputTextType)

        textPlugin.scheduler?.fastState.activeComment?.isNewInput = true
        XCTAssertEqual(AtInputTextType.add, textPlugin.atInputTextType)
        
        pattern = .drive
        XCTAssertEqual(AtInputTextType.reply, textPlugin.atInputTextType)
    }
    
    func testCardComment() {
        let commentData = initData()
        let comment = commentData.comments[0]
        guard let item = comment.commentList.last else { return }
        let content = CommentContent(content: "xxxx",
                                     imageInfos: nil,
                                     pcmData: nil,
                                     pcmDataTime: nil,
                                     attrContent: NSAttributedString(string: "xxxx"),
                                     isAudio: false)
        pattern = .float

        // browseMode
        let textView = AtInputTextView(dependency: textPlugin, font: UIFont.systemFont(ofSize: 10), ignoreRotation: false)
        textPlugin.didSendCommentContent(textView, content: content)
        XCTAssertFalse(replyConetent.parsing([.commentId]).isEmpty)
        replyConetent = CommentAPIContent([:])

        // replyMode
        scheduler?.dispatch(action: .interaction(.reply(item)))
        textPlugin.didSendCommentContent(textView, content: content)
        XCTAssertFalse(replyConetent.parsing([.commentId]).isEmpty)
        
        // editMode
        scheduler?.dispatch(action: .interaction(.edit(item)))
        textPlugin.didSendCommentContent(textView, content: content)
        XCTAssertFalse(editConetent.parsing([.commentId]).isEmpty)
    }
    
    func testAsideComment() {
        pattern = .aside
        let commentData = initData()
        let comment = commentData.comments[0]
        guard let item = comment.commentList.last else { return }
        scheduler?.uninstall(plugins: [CommentFloatDataPlugin.self,
                                       CommentFloatInteractionPlugin.self])
        scheduler?.connect(plugins: [CommentAsideDataPlugin(),
                                     CommentAsideInteractionPlugin()])
        scheduler?.apply(context: self)
        
        let content = CommentContent(content: "xxxx",
                                     imageInfos: nil,
                                     pcmData: nil,
                                     pcmDataTime: nil,
                                     attrContent: NSAttributedString(string: "xxxx"),
                                     isAudio: false)

        // replyMode
        scheduler?.dispatch(action: .interaction(.reply(item)))
        item.viewStatus = .reply(isFirstResponser: false)
        let textView = AtInputTextView(dependency: textPlugin, font: UIFont.systemFont(ofSize: 10), ignoreRotation: false)
        textView.commentWrapper = CommentWrapper(commentItem: item, comment: comment)
        textPlugin.didSendCommentContent(textView, content: content)
        XCTAssertFalse(replyConetent.parsing([.commentId]).isEmpty)
        
        // editMode
        scheduler?.dispatch(action: .interaction(.edit(item)))
        item.viewStatus = .edit(isFirstResponser: false)
        textView.commentWrapper = CommentWrapper(commentItem: item, comment: comment)
        textPlugin.didSendCommentContent(textView, content: content)
        XCTAssertFalse(editConetent.parsing([.commentId]).isEmpty)
    }
    
    func testSupportAtSubtypeTag() {
        UserScopeNoChangeFG.setMockFG(key: "ccm.mobile.comment_wiki_link_icon_enable", value: false)
        pattern = .float
        
        isWhole = true
        guard let inputModel = self.inputModel else { return }
        scheduler?.dispatch(action: .updateNewInputData(inputModel))
        XCTAssertFalse(textPlugin.supportAtSubtypeTag)
        UserScopeNoChangeFG.setMockFG(key: "ccm.mobile.comment_wiki_link_icon_enable", value: true)
        XCTAssertFalse(textPlugin.supportAtSubtypeTag)
        
        
        isWhole = false
        guard let inputModel2 = self.inputModel else { return }
        scheduler?.dispatch(action: .updateNewInputData(inputModel2))
        XCTAssertTrue(textPlugin.supportAtSubtypeTag)
        
        UserScopeNoChangeFG.setMockFG(key: "ccm.mobile.comment_wiki_link_icon_enable", value: false)
        XCTAssertFalse(textPlugin.supportAtSubtypeTag)
    }
    
    func testKeyboardChange() {
        pattern = .aside
        scheduler?.uninstall(plugins: [CommentFloatDataPlugin.self])
        scheduler?.connect(plugins: [CommentAsideDataPlugin()])
        scheduler?.apply(context: self)
        let data = initData()
        let info = testDocsInfo
        info.isInVideoConference = true
        scheduler?.plugin(with: CommentAsideDataPlugin.self)?.docsInfo = info
        let item = data.comments[0].commentList[1]
        scheduler?.dispatch(action: .vcFollowOnRoleChange(role: .follower))
        var userInfo: [AnyHashable : Any] = [:]
        let testRect = CGRect(x: 0, y: 0, width: 375, height: 250)
        userInfo[UIResponder.keyboardFrameEndUserInfoKey] = NSValue(cgRect: testRect)
        userInfo[UIResponder.keyboardFrameBeginUserInfoKey] = NSValue(cgRect: testRect)
        userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] = UIView.AnimationCurve.linear.rawValue
        userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] = 0.0
        let option = Keyboard().keyboardOptions(fromNotificationDictionary: userInfo, event: Keyboard.KeyboardEvent.didShow)
        textPlugin.handleAsideKeyBoardChange(options: option, item: item)
        var containScrollAboveKeyboard = false
        for state in states {
            if case .scrollAboveKeyboard = state {
                containScrollAboveKeyboard = true
            }
        }
        XCTAssertFalse(containScrollAboveKeyboard)
        states.removeAll()
    
        scheduler?.dispatch(action: .vcFollowOnRoleChange(role: .none))
        textPlugin.handleAsideKeyBoardChange(options: option, item: item)
        containScrollAboveKeyboard = false
        
        for state in states {
            if case .scrollAboveKeyboard = state {
                containScrollAboveKeyboard = true
            }
        }
        XCTAssertTrue(containScrollAboveKeyboard)
        
    }
    
    func testDidCopyCommentContent() {
        textPlugin.didCopyCommentContent()
    }
}

extension CommentTextPluginTests: CommentServiceContext {
    var businessDependency: DocsCommentDependency? {
        return nil
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

extension CommentTextPluginTests: CommentAPIAdaper {
    func clickQuoteMenu(_ content: CommentAPIContent) {

    }
    
    func anchorLinkSwitch(_ content: CommentAPIContent) {

    }
    
    var apiType: CommentAPIAdaperType {
        return .webview
    }
    
    func addComment(_ content: CommentAPIContent) {

    }
    
    func addReply(_ content: CommentAPIContent) {
        replyConetent = content
    }
    
    func updateReply(_ content: CommentAPIContent) {
        editConetent = content
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
}
