//
//  DriveHTMLPreviewViewModel.swift
//  SKECM
//
//  Created by zenghao on 2021/1/18.
//

import UIKit
import SwiftyJSON
import SKCommon
import SKFoundation
import SKResource
import RxSwift
import RxCocoa

protocol DriveHTMLRenderDelegate: AnyObject {

    func loadHTMLFileURL(_: URL, baseURL: URL?)
    func evaluateJavaScript(_: String, completionHandler: ((Any?, Error?) -> Void)?)
    
    func webViewRenderSuccess()
    func webViewRenderFailed()
    func fileUnsupport(reason: DriveUnsupportPreviewType)
}

struct DriveHTMLPreviewInfo {
    let fileToken: String       // 必须字段，文件 token
    let dataVersion: String?    // 可选字段，nil 则标识最新版本
    let extraInfo: String       // 必须字段，HTML 预览中标识 tab 相关数据
    let canCopy: BehaviorRelay<Bool>         // 必须字段，是否有复制权限
    let fileSize: UInt64
    let fileName: String
    let authExtra: String?
    let mountPoint: String
    
    init(fileToken: String,
         dataVersion: String?,
         extraInfo: String,
         fileSize: UInt64,
         fileName: String,
         canCopy: BehaviorRelay<Bool>,
         authExtra: String?,
         mountPoint: String) {
        self.fileToken = fileToken
        self.dataVersion = dataVersion
        self.extraInfo = extraInfo
        self.fileSize = fileSize
        self.fileName = fileName
        self.canCopy = canCopy
        self.authExtra = authExtra
        self.mountPoint = mountPoint
    }
}

class DriveHTMLPreviewViewModel {
    private let renderQueue = DispatchQueue(label: "drive.html.preview")
    weak var renderDelegate: DriveHTMLRenderDelegate?
    private var htmlTemplateURL: URL? {
        return DriveModule.getPreviewResourceURL(name: "excel", extensionType: "html")
    }
    
    // 缓存的html tab 内容，可以被清空:fileID + htmlTab + dataVersion
    private let htmlInfo: DriveHTMLPreviewInfo
    private let dataProvider: DriveHTMLDataProvider
    
    // 下载数据
    private var tabId: Int = 0
    private let disposeBag = DisposeBag()
    
    // MARK: - Permission
    /// 是否有复制权限
    private(set) var canCopy: BehaviorRelay<Bool>
    
    // MARK: security copy
    private let token: String?
    private let hostToken: String?
    private let canEditRelay: BehaviorRelay<Bool>
    private let enableCopySecurity: Bool
    private let copyManager: DriveCopyMananger
    var needSecurityCopy: Driver<(String?, Bool)> {
        let encryptId = ClipboardManager.shared.getEncryptId(token: hostToken)
        let referenceToken = encryptId ?? token
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            return copyManager.monitorCopyPermission(token: referenceToken, allowSecurityCopy: enableCopySecurity)
        } else {
            return copyManager.needSecurityCopyAndCopyEnable(token: referenceToken,
                                                             canEdity: canEditRelay,
                                                             canCopy: canCopy,
                                                             enableSecurityCopy: enableCopySecurity)
        }
    }
    
    init(htmlInfo: DriveHTMLPreviewInfo,
         hostToken: String?,  // 附件宿主token, 用于单文档复制保护
         canEdit: BehaviorRelay<Bool>,
         enableCopySecurity: Bool = LKFeatureGating.securityCopyEnable,
         copyManager: DriveCopyMananger) {
        self.htmlInfo = htmlInfo
        self.canCopy = htmlInfo.canCopy
        self.canEditRelay = canEdit
        self.enableCopySecurity = enableCopySecurity
        self.token = htmlInfo.fileToken
        self.hostToken = hostToken
        self.dataProvider = DriveHTMLDataProvider(fileToken: htmlInfo.fileToken,
                                                  dataVersion: htmlInfo.dataVersion,
                                                  fileSize: htmlInfo.fileSize,
                                                  authExtra: htmlInfo.authExtra,
                                                  mountPoint: htmlInfo.mountPoint)
        self.copyManager = copyManager
//        self.canExport.distinctUntilChanged().subscribe(onNext: { [weak self] export in
//            self?.updatePermissionToJS(canExport: export)
//        }).disposed(by: disposeBag)
    }
    
    func loadContent() {
        renderQueue.async {
            self.prepareWebContent()
        }
    }
    
    // TODO: - howie, 动态配置
    func sendInitialDataToJS() {
        let baseInfo: [String: Any] = ["index": tabId, // 初始tabId（可选）
                                       "previewExtra": htmlInfo.extraInfo, // 后端preview/get接口，返回的extra字段
                                       "platform": "mobile", // 运行环境，传'mobile'
                                       "copyable": false, // 是否可复制
                                       "perTabMaxSize": DriveFeatureGate.excelHtmlTabPreviewMaxSize, // 每个子表最大可预览size，单位 Byte
                                       "sizeExceededTipsText": BundleI18n.SKResource.Drive_Drive_PreviewOversize // 子表过大时显示的提示文案
                                       
        ]
        let initalData: [String: Any] = ["key": "setInitialData",
                                         "value": baseInfo]
        
        
        sendDataToJS(data: initalData)
    }
    
    func getCachedTabData(subId: String) {
        guard let cachedData = dataProvider.getData(subId: subId) else {
            reqeuseTabData(subId: subId)
            return
        }
        
        let payload = String(decoding: cachedData, as: UTF8.self)
        sendCachedDataToJS(subId: subId, data: payload, hasMore: false)
        DocsLogger.driveInfo("getCachedTabData: \(cachedData.count)", extraInfo: ["subId": subId,
                                                                             "token": DocsTracker.encrypt(id: htmlInfo.fileToken)])
    }
    
    func updatePermission(canCopy: Bool) {
        self.canCopy.accept(canCopy)
    }
    
    func updatePermissionToJS(canCopy: Bool) {
        let data: [String: Any] = ["key": "setCopyable",
                                   "value": canCopy]
        
        DocsLogger.driveInfo("updatePermissionToJS, canCopy: \(canCopy)")
        sendDataToJS(data: data)
    }
    
    private func reqeuseTabData(subId: String) {
        DocsLogger.driveInfo("reqeuseTabData: \(subId)")
        
        dataProvider.fetchTabData(subId: subId)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] (data) in
                guard let self = self else { return }
                
                let payload = String(decoding: data, as: UTF8.self)
                self.sendCachedDataToJS(subId: subId, data: payload, hasMore: false)
                self.dataProvider.saveData(subId: subId, data: data, fileName: self.htmlInfo.fileName)
                DocsLogger.driveInfo("reqeuseTabData succeed with data: \(data.count)")
            } onError: { (error) in
                DocsLogger.error("reqeuseTabData failed with error: \(error)")
                // webview 需要触发end fetch 的逻辑
                self.sendCachedDataToJS(subId: subId, data: "", hasMore: false)
                self.renderDelegate?.webViewRenderFailed()
            }.disposed(by: disposeBag)
    }
    
    private func sendCachedDataToJS(subId: String, data: String, hasMore: Bool) {
        // TODO: - howie, 添加分片逻辑
        let maxSize = 100 * 1024
        
        
        let baseInfo: [String: Any] = ["subId": subId,
                                       "data": data,
                                       "hasMore": hasMore
        ]
        let data: [String: Any] = ["key": "setCachedData",
                                   "value": baseInfo]
        
        sendDataToJS(data: data)
    }
    
    private func sendDataToJS(data: [String: Any]) {
        guard let transformedContent = data.toJSONString()?.toBase64() else {
            assertionFailure("can not get initalData")
            DocsLogger.error("can not get initalData")
            return
        }
        
        DocsLogger.driveInfo("drive.html.preview --- sendDataToJS, count: \(transformedContent.count)")
    
        DispatchQueue.main.async {
            self.renderDelegate?.evaluateJavaScript("triggerJSEvent('\(transformedContent)')") { (result, error) in
                DocsLogger.driveInfo("drive.html.preview --- sendDataToJS success with result", extraInfo: ["result": result as Any,
                                                                                                       "error": error ?? "no error"])
                
            }
        }
    }
}

extension DriveHTMLPreviewViewModel {
    private func prepareWebContent() {
        DocsLogger.driveInfo("drive.html.preview --- prepare web content")
        guard let templateURL = htmlTemplateURL else {
            assertionFailure("drive.html.preview --- failed to get template url")
            DocsLogger.error("drive.html.preview --- failed to get template url")
            return
        }
        
        DispatchQueue.main.async {
            self.renderDelegate?.loadHTMLFileURL(templateURL, baseURL: templateURL.deletingLastPathComponent())
        }
    }
    
}
