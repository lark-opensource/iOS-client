//
//  DocsFeedViewModelTests.swift
//  SpaceDemoTests
//
//  Created by chensi(陈思) on 2022/3/15.
//  Copyright © 2022 Bytedance. All rights reserved.


import XCTest
@testable import SKCommon
@testable import SKResource
import RxSwift
import RxRelay
import RxCocoa
@testable import SKFoundation
import SpaceInterface
import LarkContainer
import SKInfra
import OHHTTPStubs

class DocsFeedViewModelTests: XCTestCase {

    private var _adminAllowCopyFG = false
    private var _ownerAllowCopyFG = false
    
    /// 被测对象
    var testObj: DocsFeedViewModel!
    
    let disposeBag = DisposeBag()
    
    let mockToken = "mockToken"
    
    var mockMessages = [FeedMessageModel]()
    
    var cellClickExpectation: XCTestExpectation!
    
    /// 预期 testObj 发出 BrowserFullscreenMode 通知
    var fullScreenNotiExpectation: XCTestExpectation!
    
    var clickProfile = false
    
    class TestPasteboard: FeedPasteboardType {

        var pastedString: String = ""
    
        init() {}
    
        func copyString(_ string: String) {
            self.pastedString = string
        }
    }
    
    var pasteboard = TestPasteboard()
    
    class TestTool: CommentTranslationToolProtocol {
        var translatedStore: [String: Bool] = [:]
        func add(store: CommentTranslationStore) {
            translatedStore[store.key] = true
        }
        
        func remove(store: CommentTranslationStore) {
            translatedStore.removeValue(forKey: store.key)
        }
        
        func contain(store: CommentTranslationStore) -> Bool {
            return translatedStore[store.key] ?? false
        }
    }
    
    static let commentTranslationTool: CommentTranslationToolProtocol = TestTool()

    var clearMessageIds: [String] = []

    var api = MockDocsFeedAPI()
    
    override func setUp() {
        UserScopeNoChangeFG.setMockFG(key: "ccm.mobile.feed_auto_scroll_to_first_unread_message", value: true)
        DocsContainer.shared.register(CommentTranslationToolProtocol.self) { _ in
            return DocsFeedViewModelTests.commentTranslationTool
        }.inObjectScope(.container)
        AssertionConfigForTest.disableAssertWhenTesting()
        super.setUp()
        clickProfile = false
        clearMessageIds = []
        self.api = MockDocsFeedAPI()
        api.clickMessageAction = { [weak self] in
            self?.cellClickExpectation.fulfill()
        }
        api.clearMessageIds = { [weak self] ids in
            self?.clearMessageIds = ids
        }
        api.clickProfileAction = { [weak self] in
            self?.clickProfile = true
        }
        
        testObj = DocsFeedViewModel(api: api,
                                    from: FeedFromInfo(),
                                    docsInfo: DocsInfo(type: .unknownDefaultType, objToken: mockToken),
                                    pasteboardType: pasteboard,
                                    param: nil,
                                    controller: UIViewController())
        testObj.permissionDataSource = self
        
        let trigger = BehaviorRelay<[String: Any]>(value: [:])
        let eventDrive = PublishRelay<FeedPanelViewController.Event>()
        let input = DocsFeedViewModel.Input(trigger: trigger, eventDrive: eventDrive, scrollEndRelay: PublishRelay<[IndexPath]>())
        _ = testObj.transform(input: input)
        
        let path = Bundle(for: type(of: self)).path(forResource: "feed_response", ofType: "json")!
        let string = try? String(contentsOf: URL(fileURLWithPath: path))
        let jsonData = (string ?? "").data(using: .utf8) ?? Data()
        let fullDict = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
        let data_obj = fullDict?["data"] as? [String: Any]
        let list_obj = (data_obj?["message"] as? [[String: Any]]) ?? []
        let list_data = try? JSONSerialization.data(withJSONObject: list_obj, options: [])
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let models = try? decoder.decode([FeedMessageModel].self, from: list_data ?? Data())
        
        mockMessages = models ?? [FeedMessageModel]()
        mockMessages.forEach { model in
            model.getContentConfig { _ in
            }
        }
        testObj.updateMessages(.cache(mockMessages)) // 填充数据
        
//        testObj.output?.showHUD.subscribe(onNext: { (element: DocsFeedViewModel.HUDType) in
//            if case .tips(BundleI18n.SKResource.Doc_Feed_Comment_Resolve) = element {
//                self.cellClickExpectation.fulfill()
//            }
//        }, onError: { error in
//            XCTFail(error.localizedDescription)
//        }).disposed(by: disposeBag)
    }

    override func tearDown() {
        AssertionConfigForTest.reset()
        HTTPStubs.removeAllStubs()
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testHandleCopy() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let reset: () -> Void = { [weak self] in
            self?.pasteboard.pastedString = ""
        }
        
        _ = self.ownerAllowCopy() // 覆盖率
        
        var result = [Bool]()
        
        reset()
        _adminAllowCopyFG = true
        _ownerAllowCopyFG = true
        testObj.handleCopy(indexPath: IndexPath(row: 0, section: 0), event: FeedCommentCell.Event.content(.copy))
        let result1 = pasteboard.pastedString
        let expected1 = mockMessages.first?.contentAttiString?.string ?? ""
        result.append(result1 == expected1)
        
        reset()
        _adminAllowCopyFG = true
        _ownerAllowCopyFG = false
        testObj.handleCopy(indexPath: IndexPath(row: 0, section: 0), event: FeedCommentCell.Event.content(.copy))
        let result2 = pasteboard.pastedString
        let expected2 = ""
        result.append(result2 == expected2)
        
        reset()
        _adminAllowCopyFG = false
        _ownerAllowCopyFG = false
        testObj.handleCopy(indexPath: IndexPath(row: 0, section: 0), event: FeedCommentCell.Event.content(.copy))
        let result3 = pasteboard.pastedString
        let expected3 = ""
        result.append(result3 == expected3)
        
        XCTAssert(!result.allSatisfy { $0 == true }) // CAC管控会导致失败
    }
    
    func testHandleCopyCAC() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let reset: () -> Void = { [weak self] in
            self?.pasteboard.pastedString = ""
        }
        
        _ = self.ownerAllowCopy() // 覆盖率
        
        let validateResult = CCMSecurityPolicyService.ValidateResult(allow: true, validateSource: .securityAudit)
        var result = [Bool]()
        
        reset()
        _adminAllowCopyFG = true
        _ownerAllowCopyFG = true
        testObj._handleCopy(indexPath: IndexPath(row: 0, section: 0), event: FeedCommentCell.Event.content(.copy), validateResult: validateResult)
        let result1 = pasteboard.pastedString
        let expected1 = mockMessages.first?.contentAttiString?.string ?? ""
        result.append(result1 == expected1)
        
        reset()
        _adminAllowCopyFG = true
        _ownerAllowCopyFG = false
        testObj._handleCopy(indexPath: IndexPath(row: 0, section: 0), event: FeedCommentCell.Event.content(.copy), validateResult: validateResult)
        let result2 = pasteboard.pastedString
        let expected2 = ""
        result.append(result2 == expected2)
        
        reset()
        _adminAllowCopyFG = false
        _ownerAllowCopyFG = false
        testObj._handleCopy(indexPath: IndexPath(row: 0, section: 0), event: FeedCommentCell.Event.content(.copy), validateResult: validateResult)
        let result3 = pasteboard.pastedString
        let expected3 = ""
        result.append(result3 == expected3)
        
        XCTAssert(result.allSatisfy { $0 == true })
    }
    
    func testHandleTranslate() {
        
        let index = 0
        let path = IndexPath(row: index, section: 0)
        let message = mockMessages[index]
        
        Self.commentTranslationTool.add(store: message)
        testObj.handleTranslate(indexPath: path)
        
        
        XCTAssertFalse(Self.commentTranslationTool.contain(store: message))
    }
    
    func testHandleShowOriginal() {
        
        let index = 0
        let path = IndexPath(row: index, section: 0)
        let message = mockMessages[index]
        Self.commentTranslationTool.remove(store: message)
        testObj.handleShowOriginal(indexPath: path)
        
        
        XCTAssertTrue(Self.commentTranslationTool.contain(store: message))
    }
    
    func testHandleCellClickEvent() {

        cellClickExpectation = self.expectation(description: "cellClick 未满足")
        // cellClickExpectation.expectedFulfillmentCount = 2 // hud被满足 & clickMessageAction被执行

        let index = 0
        let path = IndexPath(row: index, section: 0)
        testObj.handleCellClickEvent(path)

        wait(for: [cellClickExpectation], timeout: 5)
    }
    
    func testHandleDismiss() {
        
        let name = Notification.Name.BrowserFullscreenMode
        fullScreenNotiExpectation = expectation(forNotification: name, object: nil, handler: { (noti) in
            let enterFullscreen = noti.userInfo?["enterFullscreen"] as? Bool ?? false
            let token = noti.userInfo?["token"] as? String
            if !enterFullscreen, token == self.mockToken, self.testObj.status == .cancel {
                return true
            } else {
                return false
            }
        })
        
        testObj.handleDismiss()
        
        wait(for: [fullScreenNotiExpectation], timeout: 10)
    }

    func testHandleCellEvent() {
         // return逻辑
         pasteboard.pastedString = ""
         let indexPath = IndexPath(row: 1000, section: 0)
         testObj.handleCellEvent(indexPath: indexPath, event: .content(.copy))
         XCTAssertTrue(pasteboard.pastedString.isEmpty)
    }
    
    func testLog() {
        mockMessages[0].status = .unread
        mockMessages[1].status = .unread
        mockMessages[3].status = .unread
        XCTAssertEqual(testObj.findUnreadMessage(mockMessages, isCache: false).count, 3)
    }


    func testHandleTapAvatarEvent() {
         // 正常打开
         clickProfile = false
         let indexPath = IndexPath(row: 0, section: 0)
         testObj.handleTapAvatarEvent(indexPath)
         XCTAssertTrue(clickProfile)
         
        // 打开失败
        clickProfile = false
        let indexPath2 = IndexPath(row: 100, section: 100)
        testObj.handleTapAvatarEvent(indexPath2)
        XCTAssertFalse(clickProfile)
    }
    
    func testScrollToFirst() {
        let expectation = self.expectation(description: "testScrollToFirst")
        
       
        let eventDrive = PublishRelay<FeedPanelViewController.Event>()
        let scrollEndRelay = PublishRelay<[IndexPath]>()
        let output = testObj.transform(input: DocsFeedViewModel.Input(trigger: BehaviorRelay<[String : Any]>(value: [:]), eventDrive: eventDrive, scrollEndRelay: scrollEndRelay))
    
        eventDrive.accept(.viewDidLoad(panelHeight: 100))
        mockMessages[0].status = .unread
        testObj.updateMessages(.server(mockMessages)) // 填充数据
        testObj.shouldScrollToFirstUnread = true
        
        output.scrollToItem.subscribe(onNext: { _ in
            expectation.fulfill()
        }).disposed(by: disposeBag)


        mockMessages[1].status = .unread
        mockMessages[3].status = .unread
        testObj.updateMessages(.server(mockMessages)) // 填充数据
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testClearBadge() {
        mockMessages[1].status = .unread
        testObj.clearBadge(with: mockMessages[1], at: IndexPath(row: 1, section: 0))
        XCTAssertTrue(!clearMessageIds.isEmpty)
    }
    
    func testCellWillDisplay() {
        let expectation = self.expectation(description: "testScrollToFirst")
        
       
        let eventDrive = PublishRelay<FeedPanelViewController.Event>()
        let scrollEndRelay = PublishRelay<[IndexPath]>()
        let output = testObj.transform(input: DocsFeedViewModel.Input(trigger: BehaviorRelay<[String : Any]>(value: [:]), eventDrive: eventDrive, scrollEndRelay: scrollEndRelay))
        

        mockMessages[0].status = .unread
        testObj.updateMessages(.server(mockMessages)) // 填充数据

        eventDrive.accept(.cellWillDisplay(indexPath: IndexPath(row: 0, section: 0)))
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 3) {
            expectation.fulfill()
            XCTAssertEqual(self.mockMessages[0].status, .read)
        }
        
        wait(for: [expectation], timeout: 4)
    }
    
    func testToggleMute() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.feedMute)
            return contain
        }, response: { _ in
            let string = """
            {
                "code": 0,
                "message": "",
                "data": {}
            }
            """
            return HTTPStubsResponse(data: string.data(using: .utf8) ?? Data(),
                                     statusCode: 200,
                                     headers: ["Content-Type": "application/json"])
        })
        
        let expectation = self.expectation(description: "toggleMute")
        expectation.expectedFulfillmentCount = 2
        _toggleMute(true, expectation: expectation)
        _toggleMute(false, expectation: expectation)
        wait(for: [expectation], timeout: 3)
    }
    
    private func _toggleMute(_ mute: Bool, expectation: XCTestExpectation) {
        testObj.toggleMuteState(mute)
        testObj.output?.muteToggleIsMute.subscribe(onNext: { value in
            if value == mute {
                expectation.fulfill()
            }
        }).disposed(by: disposeBag)
    }
}

extension DocsFeedViewModelTests: CCMCopyPermissionDataSource {
    
    func ownerAllowCopy() -> Bool {
        _ownerAllowCopyFG
    }
    
    func adminAllowCopyFG() -> Bool {
        _adminAllowCopyFG
    }
    
    func canPreview() -> Bool {
        return false
    }

    public func getCopyPermissionService() -> UserPermissionService? {
        nil
    }
}
