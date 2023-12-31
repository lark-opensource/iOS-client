//
//  DKMainViewModelTests.swift
//  SKDrive_Tests
//
//  Created by ByteDance on 2022/9/27.
//

import XCTest
import SKFoundation
import SKCommon
import RxSwift
import RxCocoa
import LarkDocsIcon
@testable import SKDrive
@testable import SKFoundation
import SpaceInterface

final class DKMainViewModelTests: XCTestCase {
    let bag = DisposeBag()
    override func setUp() {
        AssertionConfigForTest.disableAssertWhenTesting()
        UserScopeNoChangeFG.setMockFG(key: "ccm.mobile.sensitivitylabel.forcedlabel", value: true)
        UserScopeNoChangeFG.setMockFG(key: "ccm.doc.dlp_enable", value: true)
        UserScopeNoChangeFG.setMockFG(key: "ccm.mobile.permission.secret_auto", value: true)
        super.setUp()
    }

    override func tearDown() {
        AssertionConfigForTest.reset()
        super.tearDown()
    }


    func testGetTitle() {
        let cellVM = MockCellVM(title: "title", fileID: "fileID", fileType: .pdf, shouldShowWatermark: true)
        let sut = DKMainViewModel(files: [cellVM], initialIndex: 0, supportLandscape: true)
        XCTAssertEqual(sut.title, "title")
    }
    
    func testGetToken() {
        let cellVM = MockCellVM(title: "title", fileID: "fileID", fileType: .pdf, shouldShowWatermark: true)
        let sut = DKMainViewModel(files: [cellVM], initialIndex: 0, supportLandscape: true)
        XCTAssertEqual(sut.objToken, "fileID")
    }
    
    func testGetFileType() {
        let cellVM = MockCellVM(title: "title", fileID: "fileID", fileType: .pdf, shouldShowWatermark: true)
        let sut = DKMainViewModel(files: [cellVM], initialIndex: 0, supportLandscape: true)
        XCTAssertEqual(sut.fileType, .pdf)
    }
    
    func testGetPreviewFrom() {
        let cellVM = MockCellVM(title: "title", fileID: "fileID", fileType: .pdf, shouldShowWatermark: true)
        let sut = DKMainViewModel(files: [cellVM], initialIndex: 0, supportLandscape: true)
        XCTAssertEqual(sut.previewFrom, .unknown)
    }
    
    func testSubtitle() {
        let cellVM1 = MockCellVM(title: "title", fileID: "fileID1", fileType: .png, shouldShowWatermark: true)
        let cellVM2 = MockCellVM(title: "title", fileID: "fileID2", fileType: .png, shouldShowWatermark: true)

        let sut = DKMainViewModel(files: [cellVM1, cellVM2], initialIndex: 0, supportLandscape: true)
        sut.setupCellViewModel(vm: cellVM1)
        XCTAssertEqual(sut.subTitle, "1/2")
    }
    
    func testReadyToStartWhenSetupViewModel() {
        let cellVM = MockCellVM(title: "title", fileID: "fileID", fileType: .pdf, shouldShowWatermark: true)
        let sut = DKMainViewModel(files: [cellVM], initialIndex: 0, supportLandscape: true)
        let expect = expectation(description: "wait for start")
        sut.readyToStart.drive { _ in
            expect.fulfill()
        }.disposed(by: bag)
        sut.setupCellViewModel(vm: cellVM)
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testShouldShowCommentBar() {
        let cellVM = MockCellVM(title: "title", fileID: "fileID", fileType: .pdf, shouldShowWatermark: true)
        let sut = DKMainViewModel(files: [cellVM], initialIndex: 0, supportLandscape: true)
        XCTAssertTrue(sut.shouldShowCommentBar)
    }
    
    func testShouldShowWaterMark() {
        let cellVM = MockCellVM(title: "title", fileID: "fileID", fileType: .pdf, shouldShowWatermark: true)
        let sut = DKMainViewModel(files: [cellVM], initialIndex: 0, supportLandscape: true)
        XCTAssertTrue(sut.shouldShowWatermark)
    }

    func testGetAdditionalStatisticParameters() {
        let cellVM = MockCellVM(title: "title", fileID: "fileID", fileType: .pdf, shouldShowWatermark: true)
        let sut = DKMainViewModel(files: [cellVM], initialIndex: 0, supportLandscape: true)
        sut.additionalStatisticParameters = [:]
        XCTAssertNotNil(sut.additionalStatisticParameters)
    }
    
    func testReloadData() {
        let cellVM1 = MockCellVM(title: "title1.png", fileID: "fileID1", fileType: .png, shouldShowWatermark: true)
        let cellVM2 = MockCellVM(title: "title2.png", fileID: "fileID2", fileType: .png, shouldShowWatermark: true)
        let sut = DKMainViewModel(files: [cellVM1, cellVM2], initialIndex: 0, supportLandscape: true)
        let expect = expectation(description: "wait for reload")

        sut.reloadData.drive(onNext: { index in
            XCTAssertEqual(index, 0)
            expect.fulfill()
        }).disposed(by: bag)
        // 改变文件类型为非图片
        cellVM1.fileType = .pdf
        sut.setupCellViewModel(vm: cellVM1, mockFG: true)
        let meta = metaData(size: 1024, fileName: "name.pdf")
        let fileInfo = DriveFileInfo(fileMeta: meta)
        // 触发列表改变
        sut.hostModule?.fileInfoRelay.accept(fileInfo)
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testNumberOfFiles() {
        let cellVM = MockCellVM(title: "title", fileID: "fileID", fileType: .pdf, shouldShowWatermark: true)
        let sut = DKMainViewModel(files: [cellVM], initialIndex: 0, supportLandscape: true)
        XCTAssertEqual(sut.numberOfFiles(), 1)
    }
    
    func testChangeModeCalled() {
        let cellVM = MockCellVM(title: "title", fileID: "fileID", fileType: .pdf, shouldShowWatermark: true)
        let sut = DKMainViewModel(files: [cellVM], initialIndex: 0, supportLandscape: true)
        sut.didChangeMode(.card)
        sut.willChangeMode(.card)
        sut.changingMode(.card)
        XCTAssertTrue(cellVM.callDidChangeMode && cellVM.callWillChangeMode && cellVM.callChanggingMode)
    }
    
    func testCellViewModelAtIndex() {
        let cellVM1 = MockCellVM(title: "title", fileID: "fileID1", fileType: .png, shouldShowWatermark: true)
        let cellVM2 = MockCellVM(title: "title", fileID: "fileID2", fileType: .png, shouldShowWatermark: true)
        let sut = DKMainViewModel(files: [cellVM1, cellVM2], initialIndex: 0, supportLandscape: true)
        var vm = sut.cellViewModel(at: 0)
        XCTAssertEqual(vm.fileID, cellVM1.fileID)
        vm = sut.cellViewModel(at: 1)
        XCTAssertEqual(vm.fileID, cellVM2.fileID)
        vm = sut.cellViewModel(at: 2)
        XCTAssertEqual(vm.fileID, cellVM1.fileID)
    }
    
    func testTitleOfIndex() {
        let cellVM = MockCellVM(title: "title", fileID: "fileID", fileType: .pdf, shouldShowWatermark: true)
        let sut = DKMainViewModel(files: [cellVM], initialIndex: 0, supportLandscape: true)
        
        XCTAssertEqual(sut.title(of: 0), cellVM.title)
        XCTAssertEqual(sut.title(of: 1), "")
    }
    
    func testOpenTypeQuickLookDisableMultipleFile() {
        let cellVM1 = MockCellVM(title: "title", fileID: "fileID1", fileType: .png, shouldShowWatermark: true)
        let cellVM2 = MockCellVM(title: "title", fileID: "fileID2", fileType: .png, shouldShowWatermark: true)
        let sut = DKMainViewModel(files: [cellVM1, cellVM2], initialIndex: 0, supportLandscape: true)
        
        let expect = expectation(description: "wait relaod")
        sut.reloadData.drive(onNext: { _ in
            expect.fulfill()
        }).disposed(by: bag)
        sut.setupCellViewModel(vm: cellVM1)
        cellVM1.previewActionRelay.onNext(.openSuccess(openType: .quicklook))
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
        XCTAssertEqual(sut.numberOfFiles(), 1)
    }
    
    func testBulletinShouldClose() {
            let cellVM = MockCellVM(title: "title", fileID: "fileID", fileType: .pdf, shouldShowWatermark: true)
            let sut = DKMainViewModel(files: [cellVM], initialIndex: 0, supportLandscape: true)
            let bulletinView = BulletinView()
            bulletinView.info = BulletinInfo(id: "", content: [:], startTime: 1, endTime: 2, products: [])
            sut.shouldClose(bulletinView)
            NotificationCenter.default.rx
                .notification(DocsBulletinManager.bulletinCloseNotification)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    XCTAssertTrue(true)
                })
                .disposed(by: bag)
        }
        
        
        func testBulletinOpenLink() {
            let cellVM = MockCellVM(title: "title", fileID: "fileID", fileType: .pdf, shouldShowWatermark: true)
            let sut = DKMainViewModel(files: [cellVM], initialIndex: 0, supportLandscape: true)
            let bulletinView = BulletinView()
            bulletinView.info = BulletinInfo(id: "", content: [:], startTime: 1, endTime: 2, products: [])
            let fileUrl = URL(fileURLWithPath: "https://www.feishu.cn/")
            sut.shouldOpenLink(bulletinView, url: fileUrl)
            NotificationCenter.default.rx
                .notification(DocsBulletinManager.bulletinOpenLinkNotification)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    XCTAssertTrue(true)
                })
                .disposed(by: bag)
        }
        
        func testPrepareShowBulletin() {
            let cellVM = MockCellVM(title: "title", fileID: "fileID", fileType: .pdf, shouldShowWatermark: true)
            let sut = DKMainViewModel(files: [cellVM], initialIndex: 0, supportLandscape: true)
            sut.prepareShowBulletin()
            NotificationCenter.default.rx
                .notification(DocsBulletinManager.bulletinRequestShowIfNeeded)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    XCTAssertTrue(true)
                })
                .disposed(by: bag)
        }
        
        func testBannerRefresh() {
            let cellVM = MockCellVM(title: "title", fileID: "fileID", fileType: .pdf, shouldShowWatermark: true)
            let sut = DKMainViewModel(files: [cellVM], initialIndex: 0, supportLandscape: true)
            sut.bannerRefresh()
            NotificationCenter.default.rx
                .notification(DocsBulletinManager.bulletinRequestRefresh)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    XCTAssertTrue(true)
                })
                .disposed(by: bag)
        }
        
        func testBulletinOpenWebLink() {
            let cellVM = MockCellVM(title: "title", fileID: "fileID", fileType: .pdf, shouldShowWatermark: true)
            let sut = DKMainViewModel(files: [cellVM], initialIndex: 0, supportLandscape: true)
            let bulletinView = BulletinView()
            bulletinView.info = BulletinInfo(id: "", content: [:], startTime: 1, endTime: 2, products: [])
            let fileUrl = URL(fileURLWithPath: "https://www.feishu.cn/")
            sut.shouldOpenLink(bulletinView, url: fileUrl)
            sut.previewAction.subscribe(onNext: {[weak self] action in
                guard let self = self else { return }
                if case .openURL(_) = action {
                    XCTAssertTrue(true)
                }
            }).disposed(by: bag)
        }
        
        func testBulletinOpenFileLink() {
            let cellVM = MockCellVM(title: "title", fileID: "fileID", fileType: .pdf, shouldShowWatermark: true)
            let sut = DKMainViewModel(files: [cellVM], initialIndex: 0, supportLandscape: true)
            let bulletinView = BulletinView()
            bulletinView.info = BulletinInfo(id: "", content: [:], startTime: 1, endTime: 2, products: [])
            let fileUrl = URL(fileURLWithPath: "https://bytedance.feishu.cn/file/boxcnkIztWA3k06tq1H1N8/Codelife.pdf")
            sut.shouldOpenLink(bulletinView, url: fileUrl)
            sut.previewAction.subscribe(onNext: {[weak self] action in
                guard let self = self else { return }
                if case .open(_, _) = action {
                    XCTAssertTrue(true)
                }
            }).disposed(by: bag)
        }
        
        func testCanHandle() {
            let cellVM = MockCellVM(title: "title", fileID: "fileID", fileType: .pdf, shouldShowWatermark: true)
            let sut = DKMainViewModel(files: [cellVM], initialIndex: 0, supportLandscape: true)
            XCTAssertTrue(sut.canHandle([DKMainViewModel.bulletinIdentifier]))
        }
        
        func testBulletinShouldShow() {
            let cellVM = MockCellVM(title: "title", fileID: "fileID", fileType: .pdf, shouldShowWatermark: true)
            let sut = DKMainViewModel(files: [cellVM], initialIndex: 0, supportLandscape: true)
            let bulletinView = BulletinView()
            bulletinView.info = BulletinInfo(id: "", content: [:], startTime: 1, endTime: 2, products: [])
            sut.bulletinShouldShow(bulletinView.info!)
            sut.previewAction.subscribe(onNext: {[weak self] action in
                guard let self = self else { return }
                if case .showNotice(_) = action {
                    XCTAssertTrue(true)
                }
            }).disposed(by: bag)
        }
        
        func testBulletinbulletinShouldClose() {
            let cellVM = MockCellVM(title: "title", fileID: "fileID", fileType: .pdf, shouldShowWatermark: true)
            let sut = DKMainViewModel(files: [cellVM], initialIndex: 0, supportLandscape: true)
            sut.bulletinShouldClose(nil)
            sut.previewAction.subscribe(onNext: {[weak self] action in
                guard let self = self else { return }
                if case .closeBulletin(_) = action {
                    XCTAssertTrue(true)
                }
            }).disposed(by: bag)
        }

}

class MockCellVM: DKFileCellViewModelType {
    var permissionService: UserPermissionService = MockUserPermissionService()
    var previewFromScene: SKCommon.DrivePreviewFrom = .im
    
    let canReadAndCanCopyRelay = BehaviorRelay<(Bool, Bool)>(value: (true, true))
    let previewActionRelay = ReplaySubject<DKPreviewAction>.create(bufferSize: 0)
    let previewStateRelay = ReplaySubject<DKFilePreviewState>.create(bufferSize: 0)
    var callDidChangeMode: Bool = false
    var callWillChangeMode: Bool = false
    var callChanggingMode: Bool = false
    
    var hostModule: SKDrive.DKHostModuleType? = MockHostModule(permissionMask: UserPermissionMask.mockPermisson())
    
    var isInVCFollow: Bool = false
    
    func startPreview(hostContainer: UIViewController) {
        
    }
    
    func willChangeMode(_ mode: SKCommon.DrivePreviewMode) {
        callWillChangeMode = true
    }
    
    func changingMode(_ mode: SKCommon.DrivePreviewMode) {
        callChanggingMode = true
    }
    
    func didChangeMode(_ mode: SKCommon.DrivePreviewMode) {
        callDidChangeMode = true
    }
    
    func reset() {
        
    }
    
    var previewStateUpdated: RxCocoa.Driver<SKDrive.DKFilePreviewState> {
        return previewStateRelay.asDriver(onErrorJustReturn: .loading)
    }
    
    var previewAction: RxSwift.Observable<SKDrive.DKPreviewAction> {
        return previewActionRelay.asObservable()
    }
    
    var naviBarViewModel = ReplaySubject<DKNaviBarViewModel>.create(bufferSize: 1)
    
    var canReadAndCanCopy: RxSwift.Observable<(Bool, Bool)>? {
        return canReadAndCanCopyRelay.asObservable()
    }
    
    var performanceRecorder: SKDrive.DrivePerformanceRecorder
    
    var statisticsService: SKDrive.DKStatisticsService
    
    var shouldShowWatermark: Bool
    
    func update(additionLeftBarItems: [SKDrive.DriveNavBarItemData], additionRightBarItems: [SKDrive.DriveNavBarItemData]) {
        
    }
    
    func handle(previewAction: SKDrive.DKPreviewAction) {
        
    }
    
    func handleBizPreviewUnsupport(type: SKDrive.DriveUnsupportPreviewType) {
        
    }
    
    func handleBizPreviewFailed(canRetry: Bool) {
        
    }
    
    func handleBizPreviewDowngrade() {
        
    }
    
    func handleOpenFileSuccessType(openType: SKDrive.DriveOpenType) {
        
    }

    func didResumeVCFullWindow() {

    }

    var fileType: LarkDocsIcon.DriveFileType
    
    var fileID: String
    
    var urlForSuspendable: String?
    
    var title: String
    
    init(title: String, fileID: String, fileType: DriveFileType, shouldShowWatermark: Bool) {
        self.title = title
        self.fileType = fileType
        self.fileID = fileID
        self.shouldShowWatermark = shouldShowWatermark
        self.statisticsService = DKStatistics(appID: "1001",
                                              fileID: fileID,
                                              fileType: fileType,
                                              previewFrom: .docsList,
                                              mountPoint: nil,
                                              isInVCFollow: false,
                                              isAttachMent: true,
                                              statisticInfo: nil)
        
        self.performanceRecorder = DrivePerformanceRecorder(fileToken: fileID,
                                                            fileType: fileType.rawValue,
                                                            sourceType: .other,
                                                            additionalStatisticParameters: nil)
    }
}
