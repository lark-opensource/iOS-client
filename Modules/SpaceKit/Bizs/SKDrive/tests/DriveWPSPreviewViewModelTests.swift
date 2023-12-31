//
//  DriveWPSPreviewModelTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by majie.7 on 2022/5/6.
//

import XCTest
import OHHTTPStubs
import SwiftyJSON
import SKFoundation
import SKCommon
import RxSwift
import RxRelay
@testable import SKDrive
import SKInfra

class DriveWPSPreviewViewModelTests: XCTestCase {
    var bag = DisposeBag()
    var context = DriveWPSPreviewInfo.FeatureSettingsContext()
    
    override func setUp() {
        super.setUp()
        // 没有设置baseURL，网路请求会中assert
        AssertionConfigForTest.disableAssertWhenTesting()
    }
    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
        AssertionConfigForTest.reset()
    }
    
    private func createSut() -> DriveWPSPreviewViewModel {
        context.isFeishuPackage = true
        context.language = I18nUtil.currentLanguage
        let info = DriveWPSPreviewInfo(fileToken: "boxcnZED8CL11D1SquK3LNEUmrd",
                                       fileType: .docx,
                                       authExtra: nil,
                                       isEditable: BehaviorRelay(value: true),
                                       context: context)
        let vm = DriveWPSPreviewViewModel(info: info)
        return vm
    }
    
    private func createLarkSut() -> DriveWPSPreviewViewModel {
        context.isFeishuPackage = false
        context.language = "zh-CN"
        context.wpsCenterVersionEnable = false
        let info = DriveWPSPreviewInfo(fileToken: "boxcnZED8CL11D1SquK3LNEUmrd",
                                       fileType: .docx,
                                       authExtra: nil,
                                       isEditable: BehaviorRelay(value: true),
                                       context: context)
        let vm = DriveWPSPreviewViewModel(info: info)
        return vm
    }
    
    private func createLarkSutNoLang() -> DriveWPSPreviewViewModel {
        context.isFeishuPackage = false
        context.language = "xxx"
        context.wpsCenterVersionEnable = false
        let info = DriveWPSPreviewInfo(fileToken: "boxcnZED8CL11D1SquK3LNEUmrd",
                                       fileType: .docx,
                                       authExtra: nil,
                                       isEditable: BehaviorRelay(value: true),
                                       context: context)
        let vm = DriveWPSPreviewViewModel(info: info)
        return vm
    }
    
    private func createSutInIM() -> DriveWPSPreviewViewModel {
        context.isFeishuPackage = true
        context.language = I18nUtil.currentLanguage
        let info = DriveWPSPreviewInfo(fileId: "", fileType: .docx, appId: "123", authExtra: "", context: context)
        let vm = DriveWPSPreviewViewModel(info: info)
        return vm
    }
    
    private func createLarkSutInIM() -> DriveWPSPreviewViewModel {
        context.isFeishuPackage = false
        context.language = "en-US"
        context.wpsCenterVersionEnable = false
        let info = DriveWPSPreviewInfo(fileId: "", fileType: .docx, appId: "123", authExtra: "", context: context)
        let vm = DriveWPSPreviewViewModel(info: info)
        return vm
    }
    
    func testSetupInitialDataSuccess() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.thirdPartyAccessToken)
            return contain
        }, response: { _ in
            HTTPStubsResponse(fileAtPath: OHPathForFile("wpsAccessToken.json", type(of: self))!,
                              statusCode: 200,
                              headers: ["Content-Type": "application/json"])
        })
        let sut = createSut()
        let sutIM = createSutInIM()
        let expect = expectation(description: "test setup initial data")
        expect.expectedFulfillmentCount = 2
        
        sut.receivedMessage.onNext(("getInitialData", ""))
        sutIM.receivedMessage.onNext(("getInitialData", ""))
        
        sut.wpsPreviewState.subscribe(onNext: { event in
            switch event {
            case .needEvaluateJS:
                print("wps test setup initial data")
                XCTAssertTrue(true)
                expect.fulfill()
            default:
                XCTAssertTrue(false)
                expect.fulfill()
            }
        }).disposed(by: bag)
        sutIM.wpsPreviewState.subscribe(onNext: { event in
            switch event {
            case .needEvaluateJS:
                XCTAssertTrue(true)
                expect.fulfill()
            default:
                XCTAssertTrue(false)
                expect.fulfill()
            }
        }).disposed(by: bag)
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    // 针对accessToken正常返回的数据，后端未下发域名场景
    func testSetupInitialDataFailed() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.thirdPartyAccessToken)
            return contain
        }, response: { _ in
            HTTPStubsResponse(fileAtPath: OHPathForFile("wpsAccessToken_emptyData.json", type(of: self))!,
                              statusCode: 200,
                              headers: ["Content-Type": "application/json"])
        })
        let expect = expectation(description: "test wps setup initail data")
        expect.expectedFulfillmentCount = 2
        
        let sut = createSut()
        let sutIM = createSutInIM()
        sut.receivedMessage.onNext(("getInitialData", ""))
        sutIM.receivedMessage.onNext(("getInitialData", ""))
        
        sut.wpsPreviewState.subscribe(onNext: { event in
            print("wps event: \(event)")
            switch event {
            case .throwError:
                XCTAssertTrue(true)
                expect.fulfill()
            default:
                XCTAssertTrue(false)
                expect.fulfill()
            }
        }).disposed(by: bag)
        
        sutIM.wpsPreviewState.subscribe(onNext: { event in
            switch event {
            case .throwError:
                XCTAssertTrue(true)
                expect.fulfill()
            default:
                XCTAssertTrue(false)
                expect.fulfill()
            }
        }).disposed(by: bag)
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    // 针对accessToken 返回正常数据
    func testFetchWPSAccessTokenInNormal() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.thirdPartyAccessToken)
            return contain
        }, response: { _ in
            HTTPStubsResponse(fileAtPath: OHPathForFile("wpsAccessToken.json", type(of: self))!,
                              statusCode: 200,
                              headers: ["Content-Type": "application/json"])
        })
        let expect = expectation(description: "test fetch accessToken")
        expect.expectedFulfillmentCount = 2
        
        let sut = createSut()
        let sutIm = createSutInIM()
       
        sut.fetchWPSAccessToken()
            .subscribe(onSuccess: { result in
                XCTAssertNotNil(result)
                expect.fulfill()
            }, onError: { error in
                XCTAssertNotNil(error)
                expect.fulfill()
            })
            .disposed(by: bag)
        sutIm.fetchWPSAccessToken()
            .subscribe(onSuccess: { result in
                XCTAssertNotNil(result)
                expect.fulfill()
            }, onError: { error in
                XCTAssertNotNil(error)
                expect.fulfill()
            })
            .disposed(by: bag)
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    // 针对accesstoken 返回非错误码的其他状态码
    func testFetchWPSAccessTokenInOtherCode() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.thirdPartyAccessToken)
            return contain
        }, response: { _ in
            HTTPStubsResponse(fileAtPath: OHPathForFile("wpsAccessToken_otherCode.json", type(of: self))!,
                              statusCode: 200,
                              headers: ["Content-Type": "application/json"])
        })
        let expect = expectation(description: "test fetch accessToken")
        expect.expectedFulfillmentCount = 1
        
        let sut = createSut()
        sut.fetchWPSAccessToken()
            .subscribe(onSuccess: { result in
                XCTAssertNotNil(result)
            }, onError: { error in
                XCTAssertNotNil(error)
            })
            .disposed(by: bag)
        sut.wpsPreviewState.subscribe(onNext: { event in
            switch event {
            case .quotaAlert, .mutilGoStopWriting:
                XCTAssertTrue(true)
                expect.fulfill()
            default:
                XCTAssertTrue(false)
                expect.fulfill()
            }
        }).disposed(by: bag)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    //针对accessToken 返回错误码
    func testFetchWPSAccessTokenInErrorCode() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.thirdPartyAccessToken)
            return contain
        }, response: { _ in
            HTTPStubsResponse(fileAtPath: OHPathForFile("wpsAccessToken_error.json", type(of: self))!,
                              statusCode: 200,
                              headers: ["Content-Type": "application/json"])
        })
        let expect = expectation(description: "test fetch accessToken")
        expect.expectedFulfillmentCount = 1
        
        let sut = createSut()
        sut.receivedMessage.onNext(("getInitialData", ""))
        sut.fetchWPSAccessToken()
            .subscribe(onSuccess: { _ in
                XCTAssertTrue(false)
                expect.fulfill()
            }, onError: { _ in
                XCTAssertTrue(true)
                expect.fulfill()
            })
            .disposed(by: bag)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    // 编辑模式下 access token 返回编辑超限错误 wpsEditLimites
    // 预期： 弹toast、降级到只读模式、隐藏编辑按钮
    func testFetchAccessTokenWithEditLimtesWhenEdit() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.thirdPartyAccessToken)
            return contain
        }, response: { _ in
            HTTPStubsResponse(fileAtPath: OHPathForFile("wpsEditLimites.json", type(of: self))!,
                              statusCode: 200,
                              headers: ["Content-Type": "application/json"])
        })
        let expect = expectation(description: "test fetch accessToken")
        expect.expectedFulfillmentCount = 3
        
        let sut = createSut()
        sut.fetchWPSAccessToken()
            .subscribe()
            .disposed(by: bag)
        sut.previewMode = .edit
        // 隐藏按钮
        var showBtn = true
        sut.showEditBtn.drive(onNext: { show in
            print("testEditlimits: show \(show)")
            expect.fulfill()
            showBtn = show
        }).disposed(by: bag)
        // 降级到预览模式
        var downGrade = false
        sut.downgradeToReadOnly.drive(onNext: { () -> Void in
            print("testEditlimits: downgrade")
            expect.fulfill()
            downGrade = true
        }).disposed(by: bag)
        
        // 弹提示toast
        var previewState = DriveWPSPreviewViewModel.WPSPreviewState.loadStatus(isSuccess: true)
        sut.wpsPreviewState.subscribe(onNext: { state in
            print("testEditlimits: state \(state)")
            expect.fulfill()
            previewState = state
        }).disposed(by: bag)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertFalse(showBtn)
        XCTAssertTrue(downGrade)
        if case .toast = previewState {
            XCTAssertTrue(true)
        } else {
            XCTFail("wrong state \(previewState)")
        }
    }
    
        func testFetchWPSAccessTokenInNormalBrand() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.thirdPartyAccessToken)
            return contain
        }, response: { _ in
            HTTPStubsResponse(fileAtPath: OHPathForFile("wpsAccessTokenBrand.json", type(of: self))!,
                              statusCode: 200,
                              headers: ["Content-Type": "application/json"])
        })
        let sut = createLarkSut()
        let sutIM = createLarkSutInIM()
        let expect = expectation(description: "test setup initial data")
        expect.expectedFulfillmentCount = 2
        
        sut.receivedMessage.onNext(("getInitialData", ""))
        sutIM.receivedMessage.onNext(("getInitialData", ""))
        
        sut.wpsPreviewState.subscribe(onNext: { event in
            switch event {
            case .needEvaluateJS:
                print("wps test setup initial data")
                XCTAssertTrue(true)
                expect.fulfill()
            default:
                XCTAssertTrue(false)
                expect.fulfill()
            }
        }).disposed(by: bag)
        sutIM.wpsPreviewState.subscribe(onNext: { event in
            switch event {
            case .needEvaluateJS:
                XCTAssertTrue(true)
                expect.fulfill()
            default:
                XCTAssertTrue(false)
                expect.fulfill()
            }
        }).disposed(by: bag)
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testFetchWPSAccessTokenInNormalBrandLang() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.thirdPartyAccessToken)
            return contain
        }, response: { _ in
            HTTPStubsResponse(fileAtPath: OHPathForFile("wpsAccessTokenBrand.json", type(of: self))!,
                              statusCode: 200,
                              headers: ["Content-Type": "application/json"])
        })
        let sut = createLarkSutNoLang()
        let sutIM = createLarkSutInIM()
        let expect = expectation(description: "test setup initial data")
        expect.expectedFulfillmentCount = 2
        
        sut.receivedMessage.onNext(("getInitialData", ""))
        sutIM.receivedMessage.onNext(("getInitialData", ""))
        
        sut.wpsPreviewState.subscribe(onNext: { event in
            switch event {
            case .needEvaluateJS:
                print("wps test setup initial data")
                XCTAssertTrue(true)
                expect.fulfill()
            default:
                XCTAssertTrue(false)
                expect.fulfill()
            }
        }).disposed(by: bag)
        sutIM.wpsPreviewState.subscribe(onNext: { event in
            switch event {
            case .needEvaluateJS:
                XCTAssertTrue(true)
                expect.fulfill()
            default:
                XCTAssertTrue(false)
                expect.fulfill()
            }
        }).disposed(by: bag)
        
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    // 只读模式下 access token 返回编辑超限错误 wpsEditLimites 不处理
    func testFetchAccessTokenWithEditLimtesWhenReadOnly() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.thirdPartyAccessToken)
            return contain
        }, response: { _ in
            HTTPStubsResponse(fileAtPath: OHPathForFile("wpsEditLimites.json", type(of: self))!,
                              statusCode: 200,
                              headers: ["Content-Type": "application/json"])
        })
        let expect = expectation(description: "test fetch accessToken")
        expect.expectedFulfillmentCount = 1
        
        let sut = createSut()
        sut.fetchWPSAccessToken()
            .subscribe()
            .disposed(by: bag)
        sut.previewMode = .readOnly
        // 隐藏按钮
        var showBtn = true
        sut.showEditBtn.drive(onNext: { show in
            expect.fulfill()
            showBtn = show
        }).disposed(by: bag)

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(showBtn)
    }
    
    // save limited push
    func testReciveSaveLimtedPush() {
        context.isFeishuPackage = true
        context.language = I18nUtil.currentLanguage
        let info = DriveWPSPreviewInfo(fileToken: "boxcnZED8CL11D1SquK3LNEUmrd",
                                       fileType: .docx,
                                       authExtra: nil,
                                       isEditable: BehaviorRelay(value: true),
                                       context: context)
        let pushManager = MockStablePushManager()
        let vm = DriveWPSPreviewViewModel(info: info, pushManagerProvider: { _ in
            return pushManager
        })
        var downgrade = false
        vm.previewMode = .edit
        let expect = expectation(description: "recieve push")
        vm.downgradeToReadOnly.drive(onNext: {
            downgrade = true
            expect.fulfill()
        }).disposed(by: bag)
        pushManager.push(data: ["operation": "DRIVE_THIRD_EVENT_boxcnZED8CL11D1SquK3LNEUmrd",
                                "body": ["data":
                                            "{\"event_type\": \"save\", \"file_token\": \"boxcnZED8CL11D1SquK3LNEUmrd\", \"biz_code\": 90001081, \"edit_limit\": 10485760}"
                                        ]
                               ],
                         tag: "DRIVE_THIRD_EVENT_boxcnZED8CL11D1SquK3LNEUmrd")
        
        XCTAssertTrue(downgrade)
        waitForExpectations(timeout: 5) { error in
            XCTAssertNil(error)
        }
    }

    func testCheckIframeUrl() {
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.thirdPartyAccessToken)
            return contain
        }, response: { _ in
            HTTPStubsResponse(fileAtPath: OHPathForFile("wpsAccessToken_emptyData.json", type(of: self))!,
                              statusCode: 200,
                              headers: ["Content-Type": "application/json"])
        })
        let expect = expectation(description: "test wps setup initail data")
        expect.expectedFulfillmentCount = 2

        let sut = createSut()
        let sutIM = createSutInIM()
        sut.receivedMessage.onNext(("getInitialData", ""))
        sutIM.receivedMessage.onNext(("getInitialData", ""))
        sut.receivedMessage.onNext(("getWpsIframeUrlHeadData", ""))
        sutIM.receivedMessage.onNext(("getWpsIframeUrlHeadData", ""))

        sut.wpsPreviewState.subscribe(onNext: { event in
            print("wps event: \(event)")
            switch event {
            case .throwError:
                XCTAssertTrue(true)
                expect.fulfill()
            default:
                XCTAssertTrue(false)
                expect.fulfill()
            }
        }).disposed(by: bag)

        sutIM.wpsPreviewState.subscribe(onNext: { event in
            switch event {
            case .throwError:
                XCTAssertTrue(true)
                expect.fulfill()
            default:
                XCTAssertTrue(false)
                expect.fulfill()
            }
        }).disposed(by: bag)

        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
}

class MockStablePushManager: StablePushManagerProtocol {
    weak var delegate: StablePushManagerDelegate?
    func push(data: [String: Any], tag: String) {
        delegate?.stablePushManager(self, didReceivedData: data, forServiceType: tag, andTag: tag)
    }
    func register(with handler: StablePushManagerDelegate) {
        self.delegate = handler
    }
    func unRegister() {
        self.delegate = nil
    }
}
