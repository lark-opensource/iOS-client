//
//  DKReadingDataModule.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/8/22.
//

import Foundation
import SKCommon
import SKFoundation
import RxSwift
import RxCocoa
import EENavigator
import UniverseDesignToast
import SKResource
import UIKit
import SKUIKit
import LarkUIKit

class DKReadingDataModule: DKBaseSubModule {
    /// 文档统计信息请求
    private var readingDataRequest: ReadingDataRequest?
    private var readingDataCallback: DriveGetReadingDataCallback?
    
    private var readingCache: DocsReadingInfoModel?
    
    private weak var readingDataViewController: ReadingDetailControllerType?
    var navigator: DKNavigatorProtocol
    private let networkStauts: SKNetStatusService
    init(hostModule: DKHostModuleType,
         networkStauts: SKNetStatusService = DocsNetStateMonitor.shared,
         navigator: DKNavigatorProtocol = Navigator.shared) {
        self.navigator = navigator
        self.networkStauts = networkStauts
        super.init(hostModule: hostModule)
    }
    deinit {
        DocsLogger.driveInfo("DKReadingDataModule -- deinit")
    }
    override func bindHostModule() -> DKSubModuleType {
        super.bindHostModule()
        guard let host = hostModule else { return self }
        host.subModuleActionsCenter.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] action in
            guard let self = self else {
                return
            }

            if case .openReadingData = action {
                self.openReadingData()
            }
        }).disposed(by: bag)
        return self
    }
    
    /// 打开文件信息页面
    func openReadingData() {
        guard let hostVC = hostModule?.hostController else {
            spaceAssertionFailure("hostVC not found")
            return
        }
        
        let newReadingPanelType = DocDetailInfoViewController.supportDocTypes
        if newReadingPanelType.contains(docsInfo.inherentType) {
            // 新版的`文档信息`
            getReadingData()
            
            let vc = DocDetailInfoViewController(docsInfo: docsInfo,
                                                 hostView: hostVC.view,
                                                 permission: permissionInfo.userPermissions,
                                                 // TODO: PermissionSDK: refactor with permissionService
                                                 permissionService: nil)
            vc.supportOrientations = hostVC.supportedInterfaceOrientations
            var cacheData: [DocsReadingData] = []
            if let detailsModel = readingCache {
                cacheData.append(.details(detailsModel))
            }
            let fileMeta = [ReadingItemInfo(.fileType, fileInfo.type.uppercased()),
                            ReadingItemInfo(.fileSize, FileSizeHelper.memoryFormat(fileInfo.size))]
            cacheData.append(.fileMeta(fileMeta))
            if !cacheData.isEmpty {
                vc.refreshCache(cacheData)
            }
            vc.needRefresh = { [weak self] type in
                switch type {
                case .all, .onlyDetails:
                    self?.readingDataRequest?.request()
                case .onlyWords:
                    break
                @unknown default:
                    break
                }
            }
            vc.openDocumentActivity = { [weak self] _, _ in
                self?.showOperationHistoryPanel()
            }
            vc.watermarkConfig.needAddWatermark = docsInfo.shouldShowWatermark
            readingDataViewController = vc
            let nav = LkNavigationController(rootViewController: vc)
            if SKDisplay.pad, hostVC.isMyWindowRegularSize() {
                nav.modalPresentationStyle = .formSheet
            } else {
                nav.modalPresentationStyle = .overFullScreen
            }
            navigator.present(vc: nav, from: hostVC, animated: false)
            
        } else {
            // 旧版的`文档信息`
            getReadingData()
            DocsLogger.warning("[doc detail] goto old page, hostVC:\(hostVC) type:\(docsInfo.inherentType)")
//            let vc = ReadingDataViewController(docsInfo,
//                                               readingPanelInfo: genReadingFakeData(),
//                                               hostSize: hostVC.view.bounds.size,
//                                               fromVC: hostVC)
//            vc.watermarkConfig.needAddWatermark = docsInfo.shouldShowWatermark
//            Navigator.shared.present(vc, from: hostVC, animated: false)
//            self.readingDataViewController = vc
        }
        
        // Drive业务埋点：文档信息阅读数功能
        DriveStatistic.clientContentManagement(action: DriveStatisticAction.readingDataPage,
                                               fileId: fileInfo.fileToken,
                                               additionalParameters: hostModule?.additionalStatisticParameters)
        // 如果无网则弹Toast提示操作错误
        if !networkStauts.isReachable {
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_OperateFailed, on: hostVC.view.window ?? hostVC.view)
            return
        }
    }
    
    func getReadingData() {
        readingDataRequest = ReadingDataRequest(docsInfo)
        readingDataRequest?.dataSource = self
        readingDataRequest?.request()
    }

    // MARK: - Reading Data
    func genReadingFakeData() -> [ReadingPanelInfo] {
        var fakeData = ReadingDataRequest.fakeData(info: docsInfo)
        fakeData.insert(genFileReadingPanelInfo(), at: 0)
        return fakeData
    }

    func genFileReadingPanelInfo() -> ReadingPanelInfo {
        var firstPanel = ReadingPanelInfo()
        firstPanel.title = BundleI18n.SKResource.Drive_Drive_FileGeneral
        firstPanel.info = [ReadingItemInfo(.fileType, fileInfo.type.uppercased()),
                           ReadingItemInfo(.fileSize, FileSizeHelper.memoryFormat(fileInfo.size))]
        return firstPanel
    }
    
    private func showOperationHistoryPanel() {
        guard let hostVC = hostModule?.hostController else {
            spaceAssertionFailure()
            return
        }
        let token = docsInfo.objToken
        let type = docsInfo.type
        DocumentActivityAPI.open(objToken: token, objType: type, from: hostVC) { vc in
            Navigator.shared.present(vc, from: hostVC, animated: true)
        }.disposed(by: bag)
    }
}

// MARK: - ReadingDataFrontDataSource
extension DKReadingDataModule: ReadingDataFrontDataSource {
    func requestData(request: ReadingDataRequest, docs: DocsInfo, finish: @escaping (ReadingInfo) -> Void) {
        DocsLogger.driveInfo("request reading data finish")
        let info = ReadingInfo()
        finish(info)
    }

    func requestRefresh(info: DocsReadingData?, data: [ReadingPanelInfo], avatarUrl: String?, error: Bool) {
        if let readingData = info {
            switch readingData {
            case .details(let docsReadingInfoModel):
                if docsReadingInfoModel != nil {
                   self.readingCache = docsReadingInfoModel
                }
            case .words, .fileMeta:// FIXME: use unknown default setting to fix warning
                break
            @unknown default:
                break
            }
        }
        if error {
            DocsLogger.warning("request reading data fail")
            return
        }
        // update data
        var pannelData = data
        pannelData.insert(self.genFileReadingPanelInfo(), at: 0)
        self.readingDataViewController?.refresh(info: info, data: pannelData, avatarUrl: avatarUrl, success: !error)
    }
}
