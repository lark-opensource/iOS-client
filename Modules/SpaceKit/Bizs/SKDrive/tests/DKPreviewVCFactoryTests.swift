//
//  DKPreviewVCFactoryTests.swift
//  SKDrive-Unit-Tests
//
//  Created by bupozhuang on 2022/3/15.
//

import XCTest
import RxSwift
import RxCocoa
import SKCommon
import SpaceInterface
import SKUIKit
import SKFoundation
@testable import SKDrive

class DKPreviewVCFactoryTests: XCTestCase {
    var parentVC: BaseViewController!
    var mockDel: DriveBizViewControllerDelegate = DriveBizDelegateMock()
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        parentVC = BaseViewController()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        AssertionConfigForTest.reset()
    }

    func testPreviewVCWithPDF() {
        let context = DKPreviewVCFactoryContext(mainVC: parentVC,
                                                hostModule: MockHostModule(),
                                                delegate: mockDel,
                                                areaCommentDelegate: nil,
                                                screenModeDelegate: nil,
                                                isiOSAppOnMacSystem: false,
                                                previewFromScene: nil,
                                                permissionService: MockUserPermissionService(),
                                                disposeBag: DisposeBag())
        let previewVCFactory = DKPreviewVCFactory(context: context)
        let url = SKFilePath.driveLibraryDir.appendingRelativePath("xxx").appendingRelativePath("xxx.pdf")
        let previewInfo = DKFilePreviewInfo.local(data: DKFilePreviewInfo.LocalPreviewData(url: url,
                                                                                           originFileType: .pdf,
                                                                                           fileName: "xxx.pdf",
                                                                                           previewFrom: .docsList,
                                                                                           additionalStatisticParameters: nil))
        let vc = previewVCFactory.previewVC(previewInfo: previewInfo, previewFileType: .pdf, isInVCFollow: false)
        XCTAssertNotNil(vc)
        XCTAssertTrue(vc!.isKind(of: DrivePDFViewController.self))
    }
    
    func testPreviewVCWithPDFDowngradeToQuicklook() {
        let curBundle = Bundle(for: type(of: self))
        guard let url = curBundle.url(forResource: "big", withExtension: "pdf") else {
            XCTFail("test file not found")
            return
        }
        let context = DKPreviewVCFactoryContext(mainVC: parentVC,
                                                hostModule: MockHostModule(),
                                                delegate: mockDel,
                                                areaCommentDelegate: nil,
                                                screenModeDelegate: nil,
                                                isiOSAppOnMacSystem: false,
                                                previewFromScene: nil,
                                                permissionService: MockUserPermissionService(),
                                                disposeBag: DisposeBag())
        let previewVCFactory = DKPreviewVCFactory(context: context)
        let urlPath = SKFilePath(absUrl: url)
        let previewInfo = DKFilePreviewInfo.local(data: DKFilePreviewInfo.LocalPreviewData(url: urlPath,
                                                                                           originFileType: .pdf,
                                                                                           fileName: "big.pdf",
                                                                                           previewFrom: .docsList,
                                                                                           additionalStatisticParameters: nil))
        let vc = previewVCFactory.previewVC(previewInfo: previewInfo, previewFileType: .pdf, isInVCFollow: false)
        XCTAssertNotNil(vc)
        XCTAssertTrue(vc!.isKind(of: DriveQLPreviewController.self))
    }
    
    func testPreviewVCWithLinearImage() {
        // 图片预览需要当前的frame不会零
        parentVC.view.frame = CGRect(origin: .zero, size: CGSize(width: 10, height: 10))

        let context = DKPreviewVCFactoryContext(mainVC: parentVC,
                                                hostModule: MockHostModule(),
                                                delegate: mockDel,
                                                areaCommentDelegate: nil,
                                                screenModeDelegate: nil,
                                                isiOSAppOnMacSystem: false,
                                                previewFromScene: nil,
                                                permissionService: MockUserPermissionService(),
                                                disposeBag: DisposeBag())
        let previewVCFactory = DKPreviewVCFactory(context: context)
        let meta = DriveFileMeta(size: 1024,
                                 name: "test",
                                 type: "jpg",
                                 fileToken: "testtoken",
                                 mountNodeToken: "mountNodeToken",
                                 mountPoint: "mountPoint",
                                 version: "version",
                                 dataVersion: "dataversion",
                                 source: .other,
                                 tenantID: nil,
                                 authExtra: nil)
        let preview = getPreview()

        let dependency = DKImageDownloaderDependencyImpl(fileInfo: DriveFileInfo(fileMeta: meta),
                                                         filePreview: preview,
                                                         isLatest: true,
                                                         cacheService: MockCacheService())
        let previewInfo = DKFilePreviewInfo.linearizedImage(dependency: dependency)
        let vc = previewVCFactory.previewVC(previewInfo: previewInfo, previewFileType: .jpg, isInVCFollow: false)
        XCTAssertNotNil(vc)
        XCTAssertTrue(vc!.isKind(of: DriveImageViewController.self))
    }
    
    func testPreviewVCWithWPS() {
        let context = DKPreviewVCFactoryContext(mainVC: parentVC,
                                                hostModule: MockHostModule(),
                                                delegate: mockDel,
                                                areaCommentDelegate: nil,
                                                screenModeDelegate: nil,
                                                isiOSAppOnMacSystem: false,
                                                previewFromScene: nil,
                                                permissionService: MockUserPermissionService(),
                                                disposeBag: DisposeBag())
        let previewVCFactory = DKPreviewVCFactory(context: context)
        let info = DriveWPSPreviewInfo(fileId: "", fileType: .doc, appId: "2", authExtra: nil)
        let previewInfo = DKFilePreviewInfo.webOffice(info: info)
        let vc = previewVCFactory.previewVC(previewInfo: previewInfo, previewFileType: .doc, isInVCFollow: false)
        _ = vc?.view
        XCTAssertTrue(vc!.isKind(of: DriveWPSPreviewController.self))
    }

    func testPreviewVCWithWPSInAttachScene() {
        let context = DKPreviewVCFactoryContext(mainVC: parentVC,
                                                hostModule: MockAttachSceneHostModule(),
                                                delegate: mockDel,
                                                areaCommentDelegate: nil,
                                                screenModeDelegate: nil,
                                                isiOSAppOnMacSystem: false,
                                                previewFromScene: nil,
                                                permissionService: MockUserPermissionService(),
                                                disposeBag: DisposeBag())
        let previewVCFactory = DKPreviewVCFactory(context: context)
        let info = DriveWPSPreviewInfo(fileId: "", fileType: .doc, appId: "2", authExtra: nil)
        let previewInfo = DKFilePreviewInfo.webOffice(info: info)
        let vc = previewVCFactory.previewVC(previewInfo: previewInfo, previewFileType: .doc, isInVCFollow: false)
        _ = vc?.view
        XCTAssertTrue(vc!.isKind(of: DriveWPSPreviewController.self))
    }

    func testPreviewVCWithArchive() {
        let context = DKPreviewVCFactoryContext(mainVC: parentVC,
                                                hostModule: MockHostModule(),
                                                delegate: mockDel,
                                                areaCommentDelegate: nil,
                                                screenModeDelegate: nil,
                                                isiOSAppOnMacSystem: false,
                                                previewFromScene: nil,
                                                permissionService: MockUserPermissionService(),
                                                disposeBag: DisposeBag())
        let previewVCFactory = DKPreviewVCFactory(context: context)
        let viewModel = DriveArchivePreviewViewModel(fileID: "", fileName: "aa.zip", archiveContent: nil, previewFrom: .docsList, additionalStatisticParameters: [:])
        let previewInfo = DKFilePreviewInfo.archive(viewModel: viewModel)
        let vc = previewVCFactory.previewVC(previewInfo: previewInfo, previewFileType: .zip, isInVCFollow: false)
        XCTAssertTrue(vc!.isKind(of: DriveArchivePreviewController.self))
    }
    
    func testPreviewVCWithHTML() {
        let context = DKPreviewVCFactoryContext(mainVC: parentVC,
                                                hostModule: MockHostModule(),
                                                delegate: mockDel,
                                                areaCommentDelegate: nil,
                                                screenModeDelegate: nil,
                                                isiOSAppOnMacSystem: false,
                                                previewFromScene: nil,
                                                permissionService: MockUserPermissionService(),
                                                disposeBag: DisposeBag())
        let previewVCFactory = DKPreviewVCFactory(context: context)
        let info = DriveHTMLPreviewInfo(fileToken: "",
                                        dataVersion: "",
                                        extraInfo: "",
                                        fileSize: 1024,
                                        fileName: "aa.xls",
                                        canCopy: BehaviorRelay<Bool>(value: true),
                                        authExtra: nil,
                                        mountPoint: "")
        let previewInfo = DKFilePreviewInfo.excelHTML(info: info)
        let vc = previewVCFactory.previewVC(previewInfo: previewInfo, previewFileType: .xls, isInVCFollow: false)
        _ = vc?.view
        XCTAssertTrue(vc!.isKind(of: DriveHtmlPreviewViewController.self))
    }
    
    func testPreviewVCWithStreamVideo() {
        let context = DKPreviewVCFactoryContext(mainVC: parentVC,
                                                hostModule: MockHostModule(),
                                                delegate: mockDel,
                                                areaCommentDelegate: nil,
                                                screenModeDelegate: nil,
                                                isiOSAppOnMacSystem: false,
                                                previewFromScene: nil,
                                                permissionService: MockUserPermissionService(),
                                                disposeBag: DisposeBag())
        let previewVCFactory = DKPreviewVCFactory(context: context)
        let onlineURL = URL(string: "ttps://internal-api-space.feishu-boe.cn/space/api/box/stream/download/preview")
        let video = DriveVideo(type: .online(url: onlineURL!),
                               info: nil,
                               title: "video_480.ogg",
                               size: 1734919,
                               cacheKey: "cacheKey",
                               authExtra: nil)
        let previewInfo = DKFilePreviewInfo.streamVideo(video: video)
        
        let vc = previewVCFactory.previewVC(previewInfo: previewInfo, previewFileType: .ogg, isInVCFollow: false)
        XCTAssertTrue(vc!.isKind(of: DriveVideoPlayerViewController.self))
    }
    
    // isiOSAppOnMacSystem 下卡片模式下预览iwork返回nil
    func testPreviewIworkInMacSystemWithNil() {
        let hostModule = MockHostModule()
        hostModule.isFromCardMode = true
        let curBundle = Bundle(for: type(of: self))
        guard let url = curBundle.url(forResource: "test", withExtension: "key") else {
            XCTFail("test file not found")
            return
        }
        let context = DKPreviewVCFactoryContext(mainVC: parentVC,
                                                hostModule: hostModule,
                                                delegate: mockDel,
                                                areaCommentDelegate: nil,
                                                screenModeDelegate: nil,
                                                isiOSAppOnMacSystem: true,
                                                previewFromScene: nil,
                                                permissionService: MockUserPermissionService(),
                                                disposeBag: DisposeBag())
        let previewVCFactory = DKPreviewVCFactory(context: context)
        let urlPath = SKFilePath(absUrl: url)
        let previewInfo = DKFilePreviewInfo.local(data: DKFilePreviewInfo.LocalPreviewData(url: urlPath,
                                                                                           originFileType: .pages,
                                                                                           fileName: "xxx.pages",
                                                                                           previewFrom: .docsList,
                                                                                           additionalStatisticParameters: nil))
        let vc = previewVCFactory.previewVC(previewInfo: previewInfo, previewFileType: .pages, isInVCFollow: false)
        XCTAssertNil(vc)
    }
    
    func testPreviewPngWithThumbImage() {
        parentVC.view.frame = CGRect(origin: .zero, size: CGSize(width: 10, height: 10))
        let context = DKPreviewVCFactoryContext(mainVC: parentVC,
                                                hostModule: MockHostModule(),
                                                delegate: mockDel,
                                                areaCommentDelegate: nil,
                                                screenModeDelegate: nil,
                                                isiOSAppOnMacSystem: false,
                                                previewFromScene: nil,
                                                permissionService: MockUserPermissionService(),
                                                disposeBag: DisposeBag())
        let previewVCFactory = DKPreviewVCFactory(context: context)
        let preview = getPreview()
        let meta = metaData(size: 1024, fileName: "name.png")
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let fileInfoReplay = ReplaySubject<Result<DKFileProtocol, Error>>.create(bufferSize: 2)
        let downloader = MockPreviewDownloader()
        let cacheService = MockCacheService()
        let dependency = DriveThumbImageViewModelDependencyImpl(fileInfoReplay: fileInfoReplay,
                                                                image: UIImage(),
                                                                downloader: downloader,
                                                                retryFetchFileInfo: {},
                                                                cacheSource: .standard,
                                                                previewType: .similarFiles,
                                                                networkReachable: Observable<Bool>.just(false),
                                                                cacheService: cacheService)
        let previewInfo = DKFilePreviewInfo.thumbnail(dependency: dependency)
        let vc = previewVCFactory.previewVC(previewInfo: previewInfo, previewFileType: .png, isInVCFollow: false)
        XCTAssertNotNil(vc)
        XCTAssertTrue(vc!.isKind(of: DriveImageViewController.self))
    }
    
    private func getPreview() -> DriveFilePreview {
        let dic = ["status": 0,
                   "extra": "",
                   "preview_file_size": 1024,
                   "preview_url": "https://internal-api.feishu.cn/xxx"] as [String: Any]
        let data = try? JSONSerialization.data(withJSONObject: dic, options: [])
        let filePreview = try? JSONDecoder().decode(DriveFilePreview.self, from: data!)
        return filePreview!
    }

}


class DriveBizDelegateMock: NSObject, DriveBizViewControllerDelegate {
    var context: [String: Any]?
    var fileID: String? {
        return nil
    }
    
    func unSupport(_ bizViewController: UIViewController, reason: DriveUnsupportPreviewType, type: DriveOpenType) {
        
    }
    
    func previewFailed(_ bizViewController: UIViewController, needRetry: Bool, type: DriveOpenType, extraInfo: [String: Any]?) {
        
    }
    
    func statistic(action: DriveStatisticAction, source: DriveStatisticActionSource) {
        
    }
    
    func statistic(event: DocsTrackerEventType, params: [String: Any]) {
        
    }
    
    func clickEvent(_ event: DocsTrackerEventType, clickEventType: ClickEventType, params: [String: Any]) {
        
    }
    
    func openSuccess(type: DriveOpenType) {
        
    }
    
    func exitPreview(result: DriveBizViewControllerOpenResult, type: DriveOpenType) {
        
    }
    
    func append(leftBarButtonItems: [DriveNavBarItemData], rightBarButtonItems: [DriveNavBarItemData]) {
        
    }
    
    func stageBegin(stage: DrivePerformanceRecorder.Stage) {
        
    }
    
    func stageEnd(stage: DrivePerformanceRecorder.Stage) {
        
    }
    
    func reportStage(stage: DrivePerformanceRecorder.Stage, costTime: Double) {
        
    }
    
    func invokeDriveBizAction(_ action: DriveBizViewControllerAction) {
        
    }
}
