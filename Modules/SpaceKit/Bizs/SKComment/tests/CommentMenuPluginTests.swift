//
//  CommentMenuPluginTests.swift
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
import SpaceInterface

final class CommentMenuPluginTests: XCTestCase, TestCommentDataSource {
    
    var content = CommentAPIContent([:])
    
    var disposeBag = DisposeBag()
    
    var testScheduler: CommentSchedulerServer?
    
    var states: [CommentState] = []
    
    var menuPlugin: CommentMenuPlugin?
    var textPlugin: CommentTextPlugin?
    
    var pattern: CommentModulePattern = .float
    
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
        
        
        if testScheduler == nil {
            let mnplugin = CommentMenuPlugin()
            menuPlugin = mnplugin
            let tPlugin = CommentTextPlugin()
            textPlugin = tPlugin
            let scheduler = CommentSchedulerServer()
            scheduler.connect(plugins: [CommentFloatDataPlugin(),
                                        mnplugin,
                                        tPlugin,
                                        CommentReactionPlugin()])
            scheduler.apply(context: self)
            self.testScheduler = scheduler
            testScheduler?.state.skip(1).subscribe(onNext: { [weak self] (state) in
                self?.states.append(state)
            }).disposed(by: disposeBag)
        }
    }

    override func tearDown() {
        super.tearDown()
        disposeBag = DisposeBag()
        self.scheduler?.plugin(with: CommentFloatDataPlugin.self)?.commentSections = []
        self.scheduler?.dispatch(action: .ipc(.removeAllMenu, nil))
        states.removeAll()
    }
    
    class TestUIViewController: UIViewController {
        var triggerDismiss = false
        override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
            super.dismiss(animated: flag, completion: completion)
            triggerDismiss = true
        }
    }
    
    func testRemoveAllMenu() {
        
        let vc1 = TestUIViewController()
        
        let vc2 = TestUIViewController()
        
        let wrapper1 = MenuWeakWrapper(menuVC: vc1, identifier: "123")
        let wrapper2 = MenuWeakWrapper(menuVC: vc2, identifier: "abc")
        scheduler?.dispatch(action: .ipc(.setMenu(wrapper1), nil))
        scheduler?.dispatch(action: .ipc(.setMenu(wrapper2), nil))
        scheduler?.dispatch(action: .removeAllMenu)
        
        let expect = expectation(description: "testLoadImagefailed")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
            expect.fulfill()
            XCTAssertTrue(vc1.triggerDismiss)
            XCTAssertTrue(vc2.triggerDismiss)
        }
        wait(for: [expect], timeout: 2, enforceOrder: false)
    }
    
    func testShowTextInvite() {
        AssertionConfigForTest.disableAssertWhenTesting()
        initData()
        let atInfo = AtInfo(type: .docx, href: "", token: "123", at: "333")
        textPlugin?.showInvitePopoverTips(at: atInfo, rect: .zero, inView: UIView())
        let expect = expectation(description: "testShowTextInvite")
        testScheduler?.dispatch(action: .ipc(.fetchMenuKeys, { value, _ in
            if let keys = value as? [String],
               !keys.isEmpty {
                expect.fulfill()
                let isContain = keys.contains { $0 == CommentMenuKey.invitePopup.rawValue }
                XCTAssertTrue(isContain)
            }
            AssertionConfigForTest.reset()
        }))
        wait(for: [expect], timeout: 2, enforceOrder: false)
    }
    
    func testResolve() {
        let commentData = initData()
        let comment = commentData.comments[0]
        
        pattern = .float
        scheduler?.dispatch(action: .updateCopyTemplateURL(urlString: "https://bytedance.feishu.cn/docx/DeRfdG9M1orMyIxdG1RcAPelnOd?comment_anchor=true&comment_id={commentId}"))
        scheduler?.dispatch(action: .interaction(.clickResolve(comment: comment, trigerView: UIView())))
        let expect = expectation(description: "testResolve")
        testScheduler?.dispatch(action: .ipc(.fetchMenuKeys, { value, _ in
            if let keys = value as? [String],
               !keys.isEmpty {
                expect.fulfill()
                let isContain = keys.contains { $0 == comment.menuKey }
                XCTAssertTrue(isContain)
            }
            AssertionConfigForTest.reset()
        }))
        wait(for: [expect], timeout: 2, enforceOrder: false)
        
        self.scheduler?.dispatch(action: .ipc(.removeAllMenu, nil))
        
        pattern = .aside
        scheduler?.uninstall(plugins: [CommentFloatDataPlugin.self])
        scheduler?.connect(plugins: [CommentAsideDataPlugin()])
        
        
        let commentData2 = initData()
        let comment2 = commentData2.comments[0]
        scheduler?.dispatch(action: .updateCopyTemplateURL(urlString: "https://bytedance.feishu.cn/docx/DeRfdG9M1orMyIxdG1RcAPelnOd?comment_anchor=true&comment_id={commentId}"))
        scheduler?.dispatch(action: .interaction(.clickQuoteMore(comment: comment, trigerView: UIView())))
        let expect2 = expectation(description: "testResolve2")
        testScheduler?.dispatch(action: .ipc(.fetchMenuKeys, { value, _ in
            if let keys = value as? [String],
               !keys.isEmpty {
                expect2.fulfill()
                let isContain = keys.contains { $0 == comment2.menuKey }
                XCTAssertTrue(isContain)
            }
            AssertionConfigForTest.reset()
        }))
        wait(for: [expect2], timeout: 2, enforceOrder: false)
        
        self.scheduler?.dispatch(action: .ipc(.removeAllMenu, nil))
    }
    
    func testInnerResolve() {
        UserScopeNoChangeFG.setMockFG(key: "ccm.mobile.comment_plugin_architecture_enable", value: false)
        let commentData = initData()
        let comment = commentData.comments[0]
        guard let item = comment.commentList.last else { return }
        pattern = .float
        scheduler?.dispatch(action: .updateCopyTemplateURL(urlString: ""))
        scheduler?.dispatch(action: .interaction(.reply(item)))
        scheduler?.dispatch(action: .interaction(.clickResolve(comment: comment, trigerView: UIView())))
        let expect = expectation(description: "testInnerResolve")
        testScheduler?.dispatch(action: .ipc(.fetchMenuKeys, { value, _ in
            if let keys = value as? [String],
               !keys.isEmpty {
                expect.fulfill()
                let isContain = keys.contains { $0 == comment.menuKey }
                XCTAssertTrue(isContain)
            }
            AssertionConfigForTest.reset()
        }))
        wait(for: [expect], timeout: 2, enforceOrder: false)
        
        if let mode = scheduler?.fastState.mode {
            if case .browseMode = mode {
                XCTAssertTrue(true)
            } else {
                XCTFail("browseMode is need")
            }
        }
    }
    
    func testShowContentInvite() {
        initData()
        
        pattern = .float
        let atInfo = AtInfo(type: .docx, href: "", token: "1", at: "2")
        scheduler?.dispatch(action: .interaction(.showContentInvite(at: atInfo, rect: .zero, rectInView: UIView())))
        let expect = expectation(description: "testShowContentInvite")
        testScheduler?.dispatch(action: .ipc(.fetchMenuKeys, { value, _ in
            if let keys = value as? [String],
               !keys.isEmpty {
                expect.fulfill()
                let isContain = keys.contains { $0 == CommentMenuKey.invitePopup.rawValue }
                XCTAssertTrue(isContain)
            }
            AssertionConfigForTest.reset()
        }))
        wait(for: [expect], timeout: 2, enforceOrder: false)
        self.scheduler?.dispatch(action: .ipc(.removeAllMenu, nil))
        
        pattern = .aside
        let oldValue = User.current.info
        
        User.current.reloadUserInfo(UserInfo("123"))
        scheduler?.dispatch(action: .interaction(.showContentInvite(at: atInfo, rect: .zero, rectInView: UIView())))
        let expect2 = expectation(description: "testShowContentInvite2")
        testScheduler?.dispatch(action: .ipc(.fetchMenuKeys, { value, _ in
            if let keys = value as? [String],
               !keys.isEmpty {
                expect2.fulfill()
                let isContain = keys.contains { $0 == CommentMenuKey.invitePopup.rawValue }
                XCTAssertTrue(isContain)
            }
            AssertionConfigForTest.reset()
        }))
        wait(for: [expect2], timeout: 2, enforceOrder: false)
        self.scheduler?.dispatch(action: .ipc(.removeAllMenu, nil))
        if let ov = oldValue {
            User.current.reloadUserInfo(ov)
        }
    }

    func testDeleteMenu() {
        let commentData = initData()
        let comment = commentData.comments[0]
        guard let item = comment.commentList.last else { return }
        pattern = .float
        scheduler?.dispatch(action: .interaction(.clickSendingDelete(item)))
        
        let expect = expectation(description: "testDeleteMenu")
        testScheduler?.dispatch(action: .ipc(.fetchMenuKeys, { value, _ in
            if let keys = value as? [String],
               !keys.isEmpty {
                expect.fulfill()
                let isContain = keys.contains { $0 == item.menuKey }
                XCTAssertTrue(isContain)
            }
            AssertionConfigForTest.reset()
        }))
        wait(for: [expect], timeout: 2, enforceOrder: false)
    }

    
    func testInsertInputImageMenu() {
        initData()
        pattern = .aside
        scheduler?.dispatch(action: .interaction(.insertInputImage(maxCount: 9, callback: { _ in
            
        })))
        
        let expect = expectation(description: "testInsertMenu")
        testScheduler?.dispatch(action: .ipc(.fetchMenuKeys, { value, _ in
            if let keys = value as? [String],
               !keys.isEmpty {
                expect.fulfill()
                let isContain = keys.contains { $0 == CommentMenuKey.imagePicker.rawValue }
                XCTAssertTrue(isContain)
            }
            AssertionConfigForTest.reset()
        }))
        wait(for: [expect], timeout: 2, enforceOrder: false)
    }
    
    func testHandelMention() {
        initData()
        guard let textPlugin = self.textPlugin else { return }
        pattern = .aside
        let textView = AtInputTextView(dependency: textPlugin, font: UIFont.systemFont(ofSize: 10), ignoreRotation: true)
        scheduler?.dispatch(action: .interaction(.mention(atInputTextView: textView, rect: .zero)))
        
        let expect = expectation(description: "testInsertMenu")
        testScheduler?.dispatch(action: .ipc(.fetchMenuKeys, { value, _ in
            if let keys = value as? [String],
               !keys.isEmpty {
                expect.fulfill()
                let isContain = keys.contains { $0 == CommentMenuKey.mention.rawValue }
                XCTAssertTrue(isContain)
            }
            AssertionConfigForTest.reset()
        }))
        wait(for: [expect], timeout: 2, enforceOrder: false)
        
        menuPlugin?.handleHideMention()
    }

    
    
    func testMention() {
        initData()
        let config = AtDataSource.Config(chatID: nil,
                                         sourceFileType: .minutes,
                                         location: .minutes,
                                         token: "xxxxx")
        let atDataSource = AtDataSource(config: config)
        let requestType = AtDataSource.RequestType.atViewFilter
        let vc = AtListContainerViewController(atDataSource,
                                               type: .minutes,
                                               requestType: requestType,
                                               showCancel: false)
        let wrapper = MenuWeakWrapper(menuVC: vc, identifier: CommentMenuKey.mention.rawValue)
        scheduler?.dispatch(action: .ipc(.setMenu(wrapper), nil))
        scheduler?.dispatch(action: .interaction(.mentionKeywordChange(keyword: "xx")))
    }
}

extension CommentMenuPluginTests: DocsCommentDependency {
    var commentDocsInfo: CommentDocsInfo {
        return testDocsInfo
    }
    
    var businessConfig: CommentBusinessConfig {
        return CommentBusinessConfig(canOpenURL: true, canOpenProfile: true, canCopyCommentLink: true)
    }
}

extension CommentMenuPluginTests: CommentServiceContext {
    var businessDependency: DocsCommentDependency? {
        return self
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
