//
//  DKLocalFileCellViewModelTests.swift
//  SKDrive-Unit-Tests
//
//  Created by bupozhuang on 2022/3/15.
//

import XCTest
import RxSwift
import RxCocoa
import SKFoundation
import SpaceInterface
@testable import SKDrive

class DKLocalFileCellViewModelTests: XCTestCase {
    var bag = DisposeBag()
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFileNotfound() {
        let url = URL(fileURLWithPath: "path/notfound/test.png")
        let sut = createSut(fileName: "test.png", filePath: url)
        sut.startPreview(hostContainer: UIViewController())
        let expect = expectation(description: "start preview local")
        var stateNofoud: DKFilePreviewState = .loading
        sut.previewStateUpdated.drive(onNext: { (state) in
            stateNofoud = state
            expect.fulfill()
            
        }).disposed(by: bag)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        
        if case .setupFailed(_) = stateNofoud {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }
    
    func testFileEmpty() {
        let curBundle = Bundle(for: type(of: self))
        guard let url = curBundle.url(forResource: "empty", withExtension: "xlsx") else {
            XCTAssertTrue(false)
            return
        }
        let sut = createSut(fileName: "empty.xlsx", filePath: url)
        sut.startPreview(hostContainer: UIViewController())
        let expect = expectation(description: "start preview local")
        var stateNofoud: DKFilePreviewState = .loading
        sut.previewStateUpdated.drive(onNext: { (state) in
            stateNofoud = state
            expect.fulfill()
            
        }).disposed(by: bag)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        
        if case .setupFailed(_) = stateNofoud {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }

    func testFileUnsupport() {
        let curBundle = Bundle(for: type(of: self))
        let url = curBundle.url(forResource: "unsupport", withExtension: "x")
        let sut = createSut(fileName: "unsupport.x", filePath: url!)
        let expect = expectation(description: "start preview local")
        sut.startPreview(hostContainer: UIViewController())
        var stateUnsupport: DKFilePreviewState = .loading
        sut.previewStateUpdated.drive(onNext: { (state) in
            stateUnsupport = state
            expect.fulfill()
        }).disposed(by: bag)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        
        if case .setupUnsupport(_, _) = stateUnsupport {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
        
    }
    
    func testFileIsSupport() {
        let curBundle = Bundle(for: type(of: self))
        let url = curBundle.url(forResource: "support", withExtension: "heic")
        let sut = createSut(fileName: "support.heic", filePath: url!)
        let expect = expectation(description: "start preview local")
        sut.startPreview(hostContainer: UIViewController())
        var states = [DKFilePreviewState]()
        sut.previewStateUpdated.drive(onNext: { (state) in
            states.append(state)
            if states.count == 3 {
                expect.fulfill()
            }
            
        }).disposed(by: bag)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        
        XCTAssertTrue(states.count == 3)
        if case .setupPreview(_, _) = states.last {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
        
    }
    
    func testGetter() {
        let curBundle = Bundle(for: type(of: self))
        let url = curBundle.url(forResource: "support", withExtension: "heic")
        let sut = createSut(fileName: "support.heic", filePath: url!)
        
        XCTAssertTrue(sut.title == "support.heic")
        XCTAssertTrue(sut.objToken == "test")
        XCTAssertTrue(sut.fileID == "test" )
        XCTAssertNotNil(sut.canReadAndCanCopy)
        XCTAssertFalse(sut.isInVCFollow)
        XCTAssertNil(sut.urlForSuspendable)
        XCTAssertNil(sut.hostModule)
        XCTAssertFalse(sut.shouldShowWatermark)
    }
    
    func testHandlePreviewFailed() {
        let curBundle = Bundle(for: type(of: self))
        let url = curBundle.url(forResource: "support", withExtension: "heic")
        let sut = createSut(fileName: "support.heic", filePath: url!)
        let expect = expectation(description: "handle failed")

        sut.handleBizPreviewFailed(canRetry: true)
        var state: DKFilePreviewState?
        sut.previewStateUpdated.drive(onNext: { s in
            state = s
            expect.fulfill()
        }).disposed(by: bag)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        if case .setupFailed = state {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }
         
    func testHandlePreviewUnsupport() {
        let curBundle = Bundle(for: type(of: self))
        let url = curBundle.url(forResource: "support", withExtension: "heic")
        let sut = createSut(fileName: "support.heic", filePath: url!)
        let expect = expectation(description: "handle unsupport")

        sut.handleBizPreviewUnsupport(type: .typeUnsupport)
        var state: DKFilePreviewState?
        sut.previewStateUpdated.drive(onNext: { s in
            state = s
            expect.fulfill()
        }).disposed(by: bag)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        if case .setupUnsupport = state {
            XCTAssertTrue(true)
        } else {
            XCTAssertTrue(false)
        }
    }
    
    func testUpdategAdditionItems() {
        let curBundle = Bundle(for: type(of: self))
        let url = curBundle.url(forResource: "support", withExtension: "heic")
        let sut = createSut(fileName: "support.heic", filePath: url!)
        let expect = expectation(description: "update items")
        expect.expectedFulfillmentCount = 2
        sut.update(additionLeftBarItems: [DriveNavBarItemData(type: .notify, enable: true, target: nil, action: #selector(mockAction))],
                   additionRightBarItems: [DriveNavBarItemData(type: .bookmark, enable: true, target: nil, action: #selector(mockAction))])
        sut.naviBarViewModel.subscribe(onNext: {[weak self] vm in
            guard let self = self else { return }
            vm.leftBarItemsUpdated.debug("leftBarItemsUpdated").drive(onNext: { items in
                XCTAssertTrue(items.count == 1)
                expect.fulfill()
            }).disposed(by: self.bag)
            vm.rightBarItemsUpdated.drive(onNext: { items in
                XCTAssertTrue(items.count == 2)
                expect.fulfill()
            }).disposed(by: self.bag)
        }).disposed(by: bag)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    
    func testCustomerUserDefineAction() {
        let curBundle = Bundle(for: type(of: self))
        let url = curBundle.url(forResource: "support", withExtension: "heic")
        guard let url = url else {
            XCTAssertFalse(true)
            return
        }
        let sut = createSut(fileName: "support.heic", filePath: url)
        let expect = expectation(description: "update items")
        expect.expectedFulfillmentCount = 2
        var more: DKMoreViewModel?
        sut.naviBarViewModel.subscribe(onNext: {[weak self] vm in
            guard let self = self else { return }
            vm.rightBarItemsUpdated.drive(onNext: { items in
                more = items[0] as? DKMoreViewModel
                expect.fulfill()
            }).disposed(by: self.bag)
        }).disposed(by: bag)
        if case let .attach(items) = more?.moreType {
            items[1].handler(nil, nil)
        }
        sut.previewAction.subscribe(onNext: { previewAction in
            if case .customUserDefine = previewAction {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testCustomOpenWithOtherApp() {
        let curBundle = Bundle(for: type(of: self))
        let url = curBundle.url(forResource: "support", withExtension: "heic")
        guard let url = url else {
            XCTAssertFalse(true)
            return
        }
        let sut = createSut(fileName: "support.heic", filePath: url)
        let expect = expectation(description: "update items")
        expect.expectedFulfillmentCount = 2
        var more: DKMoreViewModel?
        sut.naviBarViewModel.subscribe(onNext: {[weak self] vm in
            guard let self = self else { return }
            vm.rightBarItemsUpdated.drive(onNext: { items in
                more = items[0] as? DKMoreViewModel
                expect.fulfill()
            }).disposed(by: self.bag)
        }).disposed(by: bag)
        if case let .attach(items) = more?.moreType {
            items[0].handler(nil, nil)
        }
        sut.previewAction.subscribe(onNext: { previewAction in
            if case .openWithOtherApp(_, _, _, _) = previewAction {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testSaveToLocal() {
        let curBundle = Bundle(for: type(of: self))
        let url = curBundle.url(forResource: "support", withExtension: "heic")
        guard let url = url else {
            XCTAssertFalse(true)
            return
        }
        let sut = createSut(fileName: "support.heic", filePath: url)
        let expect = expectation(description: "update items")
        expect.expectedFulfillmentCount = 2
        var more: DKMoreViewModel?
        sut.naviBarViewModel.subscribe(onNext: {[weak self] vm in
            guard let self = self else { return }
            vm.rightBarItemsUpdated.drive(onNext: { items in
                more = items[0] as? DKMoreViewModel
                expect.fulfill()
            }).disposed(by: self.bag)
        }).disposed(by: bag)
        if case let .attach(items) = more?.moreType {
            items[2].handler(nil, nil)
        }
        sut.previewAction.subscribe(onNext: { previewAction in
            if case .completeDownloadToSave(_, _, _) = previewAction {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testShowBanner() {
        var uiActionSubject = PublishSubject<DriveSDKUIAction>()
        let curBundle = Bundle(for: type(of: self))
        guard let url = curBundle.url(forResource: "support", withExtension: "heic") else {
            XCTFail("local file not found")
            return
        }
        let sut = createSut(fileName: "testfile", filePath: url, uiAction: uiActionSubject.asObserver())
        let expect = expectation(description: "wait show banner action")
        sut.previewAction.subscribe(onNext:{ action in
            if case .showCustomBanner(_, _) = action {
                XCTAssertTrue(true)
            } else {
                XCTFail("wrong action \(action)")
            }
            expect.fulfill()
        }).disposed(by: bag)
        uiActionSubject.onNext(.showBanner(banner: UIView(), bannerID: "banner"))
        waitForExpectations(timeout: 1.0)
    }
    
    func testHideBanner() {
        var uiActionSubject = PublishSubject<DriveSDKUIAction>()
        let curBundle = Bundle(for: type(of: self))
        let url = curBundle.url(forResource: "support", withExtension: "heic")
        guard let url = curBundle.url(forResource: "support", withExtension: "heic") else {
            XCTFail("local file not found")
            return
        }
        let sut = createSut(fileName: "testfile", filePath: url, uiAction: uiActionSubject.asObserver())
        let expect = expectation(description: "wait hide banner action")
        sut.previewAction.subscribe(onNext:{ action in
            if case .hideCustomBanner(_) = action {
                XCTAssertTrue(true)
            } else {
                XCTFail("wrong action \(action)")
            }
            expect.fulfill()
        }).disposed(by: bag)
        uiActionSubject.onNext(.hideBanner(bannerID: "banner"))
        waitForExpectations(timeout: 1.0)
    }
    
    private func createSut(fileName: String, filePath: URL, uiAction: Observable<DriveSDKUIAction> = .never()) -> DKLocalFileCellViewModel {
        let file = DriveSDKLocalFileV2(fileName: fileName,
                                       fileType: SKFilePath.getFileExtension(from: fileName),
                                       fileURL: filePath,
                                       fileId: "test",
                                       dependency: TestLocalDependencyImpl(uiAction: uiAction))
        let recorder = DrivePerformanceRecorder(fileToken: "test",
                                                fileType: "jpg",
                                                previewFrom: .secretIM,
                                                sourceType: .localFile,
                                                additionalStatisticParameters: nil)
        let dependency = DKLocalFileDependencyImpl(localFile: file,
                                                   appID: "1003",
                                                   thirdPartyAppID: nil,
                                                   statistics: MockStatisticService(),
                                                   performanceRecorder: recorder,
                                                   moreConfiguration: file.dependency.moreDependency,
                                                   actionProvider: file.dependency.actionDependency)
        return DKLocalFileCellViewModel(dependency: dependency,
                                        permissionService: MockUserPermissionService(),
                                        cacManager: MockCACMangerFile.self)
    }
    
    @objc
    func mockAction() {
        
    }

}


struct TestLocalDependencyImpl: DriveSDKDependency {
    let more = LocalMoreDependencyImpl()
    let action: ActionDependencyImpl
    init(uiAction: Observable<DriveSDKUIAction> = .never()) {
        action = ActionDependencyImpl(uiActionSignal: uiAction)
    }
    var actionDependency: DriveSDKActionDependency {
        return action
    }
    var moreDependency: DriveSDKMoreDependency {
        return more
    }
}

struct LocalMoreDependencyImpl: DriveSDKMoreDependency {
    var moreMenuVisable: Observable<Bool> {
        return .just(true)
    }
    var moreMenuEnable: Observable<Bool> {
        return .just(true)
    }
    var actions: [DriveSDKMoreAction] {
        return [.customOpenWithOtherApp(customAction: nil, callback: nil),
                .customUserDefine(provider: MockDriveSDKCustomMoreActionProvider()),
                .saveToLocal(handler: { _, _  in })]
    }
}

struct ActionDependencyImpl: DriveSDKActionDependency {
    private var closeSubject = PublishSubject<Void>()
    private var stopSubject = PublishSubject<Reason>()
    var uiActionSignal: Observable<DriveSDKUIAction>
    init(uiActionSignal: Observable<DriveSDKUIAction> = .never()) {
        self.uiActionSignal = uiActionSignal
    }
    var closePreviewSignal: Observable<Void> {
        return closeSubject.asObserver().debug("xxxxxxxxx1")
    }
    
    var stopPreviewSignal: Observable<Reason> {
        return stopSubject.asObserver().debug("xxxxxxxxxx1")
    }
}
