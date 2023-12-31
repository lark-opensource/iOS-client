//
//  DocsFeedViewModelDriveTests.swift
//  SpaceDemoTests
//
//  Created by chensi(陈思) on 2022/3/14.
//  Copyright © 2022 Bytedance. All rights reserved.


import XCTest
@testable import SKCommon
@testable import SKUIKit
import RxSwift
import RxRelay

class DocsFeedViewModelDriveTests: XCTestCase {

    /// 被测对象
    var testObj: DocsFeedViewModel!
    
    /// 预期 testObj 发出 BrowserFullscreenMode 通知
    var fullScreenNotiExpectation: XCTestExpectation!
    
    /// 预期 testObj 收到 CommentFeedV2Back 通知
    var gapStateNotiExpectation: XCTestExpectation!
    
    let mockToken = "fakeToken"
    
    let disposeBag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        
        testObj = DocsFeedViewModel(api: MockDocsFeedAPI(),
                                    from: FeedFromInfo(),
                                    docsInfo: DocsInfo(type: .unknownDefaultType, objToken: mockToken),
                                    param: nil,
                                    controller: UIViewController())
        
        let trigger = BehaviorRelay<[String: Any]>(value: [:])
        let eventDrive = PublishRelay<FeedPanelViewController.Event>()
        let input = DocsFeedViewModel.Input(trigger: trigger, eventDrive: eventDrive, scrollEndRelay: PublishRelay<[IndexPath]>())
        _ = testObj.transform(input: input)
        
        let gapState = DraggableViewController.GapState.max
        testObj.output?.gapStateRelay.subscribe(onNext: { (element: DraggableViewController.GapState) in
            if element == gapState {
                self.gapStateNotiExpectation.fulfill()
            } else {
                XCTFail("GapState异常：\(element)")
            }
        }, onError: { error in
            XCTFail(error.localizedDescription)
        }).disposed(by: disposeBag)
    }

    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSetupNotification() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let name = Notification.Name.BrowserFullscreenMode
        fullScreenNotiExpectation = expectation(forNotification: name, object: nil, handler: { (noti) in
            let enterFullscreen = noti.userInfo?["enterFullscreen"] as? Bool ?? false
            let token = noti.userInfo?["token"] as? String
            if enterFullscreen, token == self.mockToken {
                return true
            } else {
                return false
            }
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            self.testObj.setupNotification()
        })
        
        wait(for: [fullScreenNotiExpectation], timeout: 10)
    }
    
    func testChangeGapStatus() {
        
        gapStateNotiExpectation = self.expectation(description: "DocsFeedViewModelDriveTest gapStateNoti未得到预期")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            let gapState = DraggableViewController.GapState.max
            NotificationCenter.default.post(name: Notification.Name.CommentFeedV2Back,
                                            object: nil,
                                            userInfo: ["gapState": gapState])
        })
        
        wait(for: [gapStateNotiExpectation], timeout: 10)
    }
    
}
