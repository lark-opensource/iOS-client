//
//  UploadImageV2Service.swift
//  SpaceKit
//
//  Created by xurunkang on 2019/7/18.
//  

import Foundation
import SKCommon
import SKFoundation
import SKUIKit
import EENavigator
import SpaceInterface

final class UploadImageV2Service: BaseJSService {

    private let uploadFileAdapter = UploadFileAdapter() // 上传文件工具

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        uploadFileAdapter.objToken = model.browserInfo.docsInfo?.objToken
        model.browserViewLifeCycleEvent.addObserver(self)
    }

    deinit {
        uploadFileAdapter.cancelAllTask()
    }
}

extension UploadImageV2Service: BrowserViewLifeCycleEvent {
    func browserWillClear() {
        uploadFileAdapter.cancelAllTask()
    }
}

extension UploadImageV2Service: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.uploadImage, .uploadFile, .cancelUploadFile]
    }

    func handle(params: [String: Any], serviceName: String) {

        let service = DocsJSService(rawValue: serviceName)

        switch service {
        case .uploadImage, .uploadFile:
            uploadFile(params: params)
        case .cancelUploadFile:
            deleteUploadFile(params: params)
        default:
            break
        }
    }
}

private extension UploadImageV2Service {
    private func deleteUploadFile(params: [String: Any]) {
        uploadFileAdapter.deleteUploadfile(params: params)
    }

    private func uploadFile(params: [String: Any]) {
        guard
            let uuids = params["uuids"] as? [String],
            let callback = params["callback"] as? String
            else {
                DocsLogger.info("UploadImageV2Service, params failure", component: LogComponents.uploadFile)
                return
        }
        let showQuota = params["showFullQuata"] as? Bool ?? true // 默认nattive处理超限弹框
        var params = params
        if let requestHeader = model?.requestAgent.requestHeader {
            params["request-header"] = requestHeader
        }

        let firstUUid = uuids.first ?? "" // 目前uuids不会有多个，因为数据结构不支持
        DocsLogger.info("UploadImageV2Service, begin, uuid=\(firstUUid.encryptToken)", component: LogComponents.uploadFile)

        uploadFileAdapter.uploadFile(for: params) { [weak self] (progress) in
            guard let self = self else { return }
            //只有前端传了参数 process：true，才回调参数
            let canCallback = params["progress"] as? Bool
            if canCallback == true {
                self.notifyFEUploadResult(callback, params: progress)
            } else {
                DocsLogger.info("UploadImageV2Service not callback progress , uuid=\(firstUUid.encryptToken)", component: LogComponents.uploadFile)
            }
        } completion: { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success(let(_, data)):
                DocsLogger.info("UploadImageV2Service, end, success, uuid=\(firstUUid.encryptToken)", component: LogComponents.uploadFile)
                self.notifyFEUploadResult(callback, params: data)
            case .failure(let error):
                var errorCode: Int = -1
                let message: String = "err"
                if let uploadErr = error as? UploadError {
                    switch uploadErr {
                    case .driveError(let errCode):
                        errorCode = errCode
                    default: break
                    }
                } else {
                    let nsError = error as NSError
                    if nsError.code != 0 {
                        errorCode = nsError.code
                    }
                }
                let showQuota = self.handleFullQuota(errorCode: errorCode, showQuota: showQuota, uploadParams: params)
                self.notifyFEUploadResult(callback, params: ["code": errorCode,
                                                              "message": message,
                                                              "uuid": firstUUid,
                                                              "showQuotaAlert": showQuota])
                DocsLogger.info("UploadImageV2Service, end, failure, uuid=\(firstUUid.encryptToken)", error: error, component: LogComponents.uploadFile)
            }
        }

        DocsTracker.log(enumEvent: .imgPickerStartUploadImage, parameters: ["count": uuids.count]) // 埋点
    }

    // 通知前端上传图片的信息
    private func notifyFEUploadResult(_ callback: String, params: [String: Any]) {
        model?.jsEngine.callFunction(DocsJSCallBack(callback), params: params, completion: nil)
    }
    
    // 超限弹框处理
    private func handleFullQuota(errorCode: Int, showQuota: Bool, uploadParams: [String: Any]) -> Bool {
        guard showQuota else {
            DocsLogger.info("fronend will deal with the quota error")
            return false
        }
        guard let from = registeredVC else {
            DocsLogger.error("registeredVC not found")
            return false
        }
        if errorCode == DocsNetworkError.Code.uploadLimited.rawValue {
            if QuotaAlertPresentor.shared.enableTenantQuota {
                QuotaAlertPresentor.shared.showQuotaAlert(type: .upload, from: from)
            }
            
            return QuotaAlertPresentor.shared.enableTenantQuota
        } else if errorCode == DocsNetworkError.Code.rustUserUploadLimited.rawValue {
            if QuotaAlertPresentor.shared.enableUserQuota {
                let mountInfo = mountInfo(from: uploadParams)
                var bizParmas: SpaceBizParameter?
                if let token = mountInfo.mountNodeToken, let type = mountInfo.docsType, let module = type.module {
                        let bizParams = SpaceBizParameter(module: module, fileID: token, fileType: type)
                }

                QuotaAlertPresentor.shared.showUserQuotaAlert(mountNodeToken: mountInfo.mountNodeToken,
                                                              mountPoint: mountInfo.mountPoint,
                                                              from: from,
                                                              bizParams: bizParmas)
            }
            return QuotaAlertPresentor.shared.enableUserQuota
        } else {
            return false
        }
    }
    
    private func mountInfo(from parmas: [String: Any]) -> (mountNodeToken: String?, mountPoint: String?, docsType: DocsType?) {
        guard let uploadParams = parmas["uploadParams"] as? [String: Any],
              let mountNodeToken = uploadParams["mount_node_token"] as? String,
              let mountPoint = uploadParams["mount_point"] as? String else {
            return (nil, nil, nil)
        }
        var docsType: DocsType?
        if let objType = uploadParams["obj_type"] as? Int {
            docsType = DocsType(rawValue: objType)
        }
        return (mountNodeToken, mountPoint, docsType)
    }
}
