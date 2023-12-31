//
//  UtilFilePreviewService.swift
//  SKBrowser
//
//  Created by bytedance on 2018/10/9.
//

import UIKit
import SwiftyJSON
import EENavigator
import SKCommon
import SKFoundation
import SKResource
import SpaceInterface
import RxSwift
import SKUIKit
import SKInfra

public final class UtilFilePreviewService: BaseJSService {
    private var getPreviewUrlRequest: DocsRequest<JSON>?
    private var tosDownloadUrlRequest: DocsRequest<JSON>?

    private func handlePreviewModel(_ file: FilePreviewModel) {
        //ScreeenToPortrait.forceInterfaceOrientationIfNeed(to: .portrait)
        // 新逻辑 -> 直接用 drive 打开
        if file.mountType == .tos {
            openFileByDrive(file)
            return
        }

        DispatchQueue.main.once {
            FilePreviewService.cleanCacheIfNeeded() // 清理缓存
        }

        if FilePreviewService.checkIfLocalFileExisted(file: file) { // 文件已存在就直接打开
            openFilePreviewController(file)
        } else { // 不存在就发请求
            downloadFile(file)
        }
    }
}

extension UtilFilePreviewService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.utilFilePreview]
    }

    public func handle(params: [String: Any], serviceName: String) {
        
        DocsLogger.info("UtilFilePreviewService handle \(serviceName)")
        
        guard let data = try? JSONSerialization.data(withJSONObject: params, options: []),
            let previewModel = try? JSONDecoder().decode(FilePreviewModel.self, from: data) else {
                DocsLogger.info("previewModel 解析失败", extraInfo: ["params": params])
                return
        }

        handlePreviewModel(previewModel)

        let paras = ["status_code": "1",
                     "file_id": DocsTracker.encrypt(id: previewModel.id),
                     "file_type": previewModel.type.rawValue,
                     "file_size": previewModel.size
            ] as [String: Any]
        DocsTracker.log(enumEvent: .clientAttachmentPreview, parameters: paras)
    }
}

// Private Method
extension UtilFilePreviewService {

    private func openFilePreviewController(_ filePreviewModel: FilePreviewModel) {
        let filePreviewController = FilePreviewViewController(filePreviewModel: filePreviewModel)
        navigator?.pushViewController(filePreviewController)
    }

    private func downloadFile(_ filePreviewModel: FilePreviewModel) {
        // 如果是 tos 的直接走 drive 打开
        if filePreviewModel.mountType == .tos {
            openFileByDrive(filePreviewModel)
            return
        }

        // 判断网络状态
        if DocsNetStateMonitor.shared.accessType == .wifi { // wifi 直接下载
            if filePreviewModel.mountType == .jianguoyun {
                sendGetPreviewUrlRequest(filePreviewModel)
            } else if filePreviewModel.mountType == .tos {
                downloadFileFromTOS(filePreviewModel)
            }
        } else if DocsNetStateMonitor.shared.accessType != .notReachable {
            showAlert(filePreviewModel)

            // 弹窗事件上报
            let paras = ["status_code": "1",
                         "file_id": DocsTracker.encrypt(id: filePreviewModel.id),
                         "file_type": filePreviewModel.type.rawValue,
                         "file_size": filePreviewModel.size
                ] as [String: Any]
            DocsTracker.log(enumEvent: .clientAttachmentAlert, parameters: paras)
        }
    }

    private func openFileByDrive(_ filePreviewModel: FilePreviewModel) {
        var isInFollow = false
        let browserVC = registeredVC as? BrowserViewController
        if browserVC != nil && browserVC?.isInVideoConference ?? false {
            isInFollow = true
        }
        
        guard let previewFrom = DrivePreviewFrom(rawValue: filePreviewModel.previewFrom), let app = previewFrom.driveSDKApp else {
            spaceAssertionFailure("preview from is not supported driveSDKApp")
            return
        }
        let file = DriveSDKAttachmentFile(fileToken: filePreviewModel.driveKey,
                                          hostToken: self.model?.browserInfo.docsInfo?.objToken,
                                          mountNodePoint: filePreviewModel.mountNodeToken,
                                          mountPoint: filePreviewModel.mountPoint,
                                          fileType: nil,
                                          name: filePreviewModel.name,
                                          authExtra: nil,
                                          urlForSuspendable: nil, // 不支持悬浮窗
                                          dependency: CCMFileDependencyImpl())
        
        let naviBarConfig = DriveSDKNaviBarConfig(titleAlignment: .leading, fullScreenItemEnable: true)
        var body = DriveSDKAttachmentFileBody(files: [file],
                                              index: 0,
                                              appID: app.rawValue,
                                              isCCMPremission: true,
                                              isInVCFollow: isInFollow,
                                              naviBarConfig: naviBarConfig)
        body.tenantID = hostDocsInfo?.tenantID
        body.attachmentDelegate = self
        let animated = !isInFollow
        DocsLogger.info("UtilFilePreviewService attach openFileByDrive")
        let currentAttachMountToken = browserVC?.spaceFollowAPIDelegate?.currentFollowAttachMountToken
        guard currentAttachMountToken != filePreviewModel.mountNodeToken else {
            // 避免前端重复发送打开相同附件
            DocsLogger.info("AttachFollow: UtilFilePreviewService already push same file")
            return
        }
        if currentAttachMountToken != nil {
            // 主动调用退出当前的附件
            DocsLogger.info("UtilFilePreviewService exit last file")
            browserVC?.spaceFollowAPIDelegate?.follow(nil, onOperate: .exitAttachFile)
        }
        
        // 需在 Push 前获取当前的 VC，因为上面会先退出当前附件，一开始获取到的 fromVC 不一定是正确的
        // 同时因为时序问题，在Push出附件时，当前的VC可能是同层ContainerVC或者图片浏览的VC（因为这些VC正在关闭，所以使用topMostOfBrowserVCWithoutDismissing获取正确的VC）
        topMostOfBrowserVCWithoutDismissing { [weak self] topVC in
            guard var fromVC = topVC else {
                spaceAssertionFailure("UtilFilePreviewService --- from VC cannot be nil")
                return
            }
            DocsLogger.info("UtilFilePreviewService --- start push attach, fromVC: \(fromVC)")
            self?.model?.userResolver.navigator.push(body: body, from: fromVC, animated: animated) { (_, rsp) in
                if isInFollow && rsp.error == nil {
                    if let blockVC = rsp.resource as? DriveFileBlockVCProtocol {
                        blockVC.fileBlockMountToken = filePreviewModel.mountNodeToken
                    }
                    if let follwableVC = rsp.resource as? FollowableViewController {
                        browserVC?.spaceFollowAPIDelegate?.currentFollowAttachMountToken = filePreviewModel.mountNodeToken
                        browserVC?.spaceFollowAPIDelegate?.follow(browserVC, add: follwableVC)
                        browserVC?.spaceFollowAPIDelegate?.follow(nil, onOperate: .vcOperation(value: .openOrCloseAttachFile(isOpen: true)))
                    }
                }
            }
        }
    }

    private func showAlert(_ file: FilePreviewModel) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: BundleI18n.SKResource.Doc_Facade_Cancel, style: .default, handler: { (_) in
            // 取消使用流量查看上报
            let paras = ["status_code": "1",
                         "file_id": DocsTracker.encrypt(id: file.id),
                         "file_type": file.type.rawValue,
                         "file_size": file.size
                ] as [String: Any]
            DocsTracker.log(enumEvent: .clientAttachmentAlertGoon, parameters: paras)
        })
        cancelAction.setValue(UIColor.ud.N1000, forKey: "titleTextColor")

        let okAction = UIAlertAction(title: BundleI18n.SKResource.Doc_Doc_ContinueLook, style: .default, handler: { [weak self] (_) in

            if file.mountType == .jianguoyun {
                self?.sendGetPreviewUrlRequest(file)
            } else if file.mountType == .tos {
                self?.downloadFileFromTOS(file)
            }

            // 使用流量查看上报
            let paras = ["status_code": "1",
                         "file_id": DocsTracker.encrypt(id: file.id),
                         "file_type": file.type.rawValue,
                         "file_size": file.size
                ] as [String: Any]
            DocsTracker.log(enumEvent: .clientAttachmentAlertCancel, parameters: paras)
        })
        let message = NSMutableAttributedString(string: BundleI18n.SKResource.Doc_Doc_NotInWIFI)
        message.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)], range: NSRange(location: 0, length: message.length))
        alert.setValue(message, forKey: "attributedMessage")

        alert.addAction(okAction)
        alert.addAction(cancelAction)

        navigator?.presentViewController(alert, animated: true, completion: nil)
    }

    // 新逻辑，下载存储在 TOS 里面的文件
    private func downloadFileFromTOS(_ filePreviewModel: FilePreviewModel) {

        let tosDownloadUrl = OpenAPI.docs.baseUrl +
            OpenAPI.APIPath.driveOriginalFileDownload +
            "\(filePreviewModel.driveKey)?" +
            "mount_node_token=\(filePreviewModel.mountNodeToken)" +
            "&mount_point=\(filePreviewModel.mountPoint)"
        var file = filePreviewModel
        file.setUrl(tosDownloadUrl)
        openFilePreviewController(file)
    }

    // 旧逻辑，兼容坚果云的文件
    private func sendGetPreviewUrlRequest(_ filePreviewModel: FilePreviewModel) {
        // 发起请求获取下载地址
        guard let model = self.model else {
            DocsLogger.info("model 为 nil")
            return
        }

        guard let token = hostDocsInfo?.objToken else {
            DocsLogger.info("docsInfo 为 nil")
            return
        }

        let params = ["token": token, "drive_file_key": filePreviewModel.driveKey]

        var headers = ["content-type": "applicaiton/json"]
        headers.merge(model.requestAgent.requestHeader) { (current, _) in current }

        getPreviewUrlRequest?.cancel()
        getPreviewUrlRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.getDownloadUrl, params: params)
            .set(encodeType: .jsonEncodeDefault)
            .set(headers: headers)
            .start { [weak self] (data, error) in
                if let e = error {
                    DocsLogger.info("解析错误", extraInfo: ["error": e])
                    return
                }

                guard let data = data, let downloadUrl = data["data"]["downloadurl"].string else {
                    DocsLogger.info("data 转换错误了")
                    return
                }

                var file = filePreviewModel
                file.setUrl(downloadUrl)

                self?.openFilePreviewController(file)
            }
    }
}


extension UtilFilePreviewService: DriveSDKAttachmentDelegate {
    public func onAttachmentClose() {
        DocsLogger.info("notify web attachment exit")
        self.model?.jsEngine.callFunction(DocsJSCallBack.onFileExit, params: [:], completion: nil)
    }
}
