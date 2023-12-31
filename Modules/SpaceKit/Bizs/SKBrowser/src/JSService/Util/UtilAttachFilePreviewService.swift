//
//  UtilAttachFilePreviewService.swift
//  SKBrowser
//
//  Created by bupozhuang on 2021/4/29.
//

import UIKit
import SwiftyJSON
import EENavigator
import SKCommon
import SKFoundation
import SKResource
import SpaceInterface
import SKUIKit
import SKInfra

public final class UtilAttachFilePreviewService: BaseJSService {
//    private var bitableCardOpenSuccess = false
//    private var storeParams: [String: Any]?
}

// Reference: https://bytedance.feishu.cn/docx/doxcncv45RuQsY0xuJobwNxwH9g#doxcn2Oa284c4IkMoCMYsYkKpfe
extension UtilAttachFilePreviewService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.utilAttachFilePreview]
    }

    public func handle(params: [String: Any], serviceName: String) {
        handleService(params: params, serviceName: serviceName)
    }

    private func handleService(params: [String: Any], serviceName: String) {
        DocsLogger.info("UtilAttachFilePreviewService handle \(serviceName)", traceId: self.browserTrace?.traceRootId)
        guard let token = params["file_token"] as? String,
              let mountPoint = params["mount_point"] as? String,
              let bizID = params["bussinessId"] as? String else {
            DocsLogger.info("参数解析失败")
            return
        }
        guard let previewFrom = DrivePreviewFrom(rawValue: bizID), let app = previewFrom.driveSDKApp else {
            spaceAssertionFailure("preview from is not supported driveSDKApp")
            return
        }
        let mountNodeToken = params["mount_node_token"] as? String
        let extraParams = params["extra"] as? String
        let from_module = params["from_module"] as? String
        let fileName = params["file_name"] as? String
        let fileSize = params["file_size"] as? Int64 ?? 0
        let mimeType = params["file_mime_type"] as? String ?? "unKnown"
        let blockDocsInfo = self.getblockDocsInfo(params: params)

        // VCFollow
        var isInFollow = false
        let browserVC = registeredVC as? BrowserViewController
        if browserVC != nil && browserVC?.isInVideoConference ?? false {
            isInFollow = true
            if previewFrom == .bitableAttach {
                browserVC?.currentTableId = from_module ?? ""
            }
        }

        // 埋点
        let paras = ["status_code": "1",
                     "file_id": DocsTracker.encrypt(id: token),
                     "file_type": mimeType,
                     "file_size": fileSize
        ] as [String: Any]
        DocsTracker.log(enumEvent: .clientAttachmentPreview, parameters: paras)

        let openAttachParam = OpenAttachParam(fileName: fileName,
                                              fileSize: fileSize,
                                              mimeType: mimeType,
                                              fileToken: token,
                                              mountNodeToken: mountNodeToken ?? "",
                                              mountPoint: mountPoint,
                                              isInFollow: isInFollow,
                                              appId: app.rawValue,
                                              srcObjToken: blockDocsInfo?.token,
                                              srcObjType: blockDocsInfo?.type.rawValue,
                                              extraParams: extraParams)

        // 先尝试找到同层附件打开（present 形式），否则再以 Push 的形式新建附件打开
        if presentAttachFile(param: openAttachParam) {
            // 同层附件打开成功，则无需再 Push 附件，这里 return
            return
        }

        // 非同层附件打开（push 形式）
        pushAttachFile(param: openAttachParam)
    }

    /// 同层附件打开（present 形式）
    private func presentAttachFile(param: OpenAttachParam) -> Bool {
        guard param.isInFollow else { return false }
        guard let vcManager = DocsContainer.shared.resolve(DKPreviewVCManagerProtocol.self) else {
            return false
        }
        let identifier = DriveFileBlockIdentifier(fileToken: param.fileToken,
                                                  mountNodePoint: param.mountNodeToken,
                                                  mountPoint: param.mountPoint,
                                                  isInVCFollow: param.isInFollow)
        // 从 VCManager 找到同层渲染的 VC
        guard let vc = vcManager.getPreviewVC(with: identifier.id, params: nil), vc.view.superview != nil,
              let blockComponent = vc.fileBlockComponent else { return false }

        DocsLogger.info("UtilAttachFilePreviewService: Found drive fileBlockVC, id: \(identifier.id)")

        let browserVC = registeredVC as? BrowserViewController
        let currentAttachMountToken = browserVC?.spaceFollowAPIDelegate?.currentFollowAttachMountToken
        // 与当前打开的不是同个附件才弹出附件
        guard currentAttachMountToken != param.mountNodeToken else { return true }

        // 当前 TopMost 是 BrowserVC 才以 present 形式打开附件，否则以 Push 形式，避免与当前展示的评论冲突，导致评论关闭
        let isBrowserVCNow = self.topMostOfBrowserVC() is BrowserViewController
        guard isBrowserVCNow else { return false }

        if currentAttachMountToken != nil {
            // 主动调用退出当前的附件
            browserVC?.spaceFollowAPIDelegate?.follow(nil, onOperate: .exitAttachFile)
        }
        let enterFullModeResult = blockComponent.enterFullMode()
        DocsLogger.info("UtilAttachFilePreviewService: enterFullMode result \(enterFullModeResult), id: \(identifier.id)")
        return enterFullModeResult
    }

    /// 非同层附件打开（push 形式）
    private func pushAttachFile(param: OpenAttachParam) {
        let hostToken = param.srcObjToken ?? self.hostDocsInfo?.token
        let file = DriveSDKAttachmentFile(fileToken: param.fileToken,
                                          hostToken: hostToken,
                                          mountNodePoint: param.mountNodeToken,
                                          mountPoint: param.mountPoint,
                                          fileType: nil,
                                          name: param.fileName,
                                          authExtra: param.extraParams,
                                          urlForSuspendable: nil, // 不支持悬浮窗
                                          dependency: CCMFileDependencyImpl())
        let naviBarConfig = DriveSDKNaviBarConfig(titleAlignment: .leading, fullScreenItemEnable: true)

        var body = DriveSDKAttachmentFileBody(files: [file],
                                              index: 0,
                                              appID: param.appId,
                                              isCCMPremission: false,
                                              isInVCFollow: param.isInFollow,
                                              naviBarConfig: naviBarConfig)
        if let hostToken {
            body.tenantID = hostDocsInfo?.getBlockTenantId(srcObjToken: hostToken)
        } else {
            body.tenantID = hostDocsInfo?.tenantID
        }
        body.attachmentDelegate = self
        var naviParams = NaviParams()
        naviParams.forcePush = true
        let animated = !param.isInFollow
        let browserVC = registeredVC as? BrowserViewController
        let currentAttachMountToken = browserVC?.spaceFollowAPIDelegate?.currentFollowAttachMountToken
        if currentAttachMountToken != nil {
            // 主动调用退出当前的附件
            browserVC?.spaceFollowAPIDelegate?.follow(nil, onOperate: .exitAttachFile)
        }
        // 需在 Push 前获取当前的 VC，因为上面会先退出当前附件，一开始获取到的 fromVC 不一定是正确的
        //同时因为时序问题，在Push出附件时，当前的VC可能是同层ContainerVC或者图片浏览的VC（因为这些VC正在关闭，所以使用topMostOfBrowserVCWithoutDismissing获取正确的VC）
        topMostOfBrowserVCWithoutDismissing { [weak self] topVC in
            guard let fromVC = topVC else {
                spaceAssertionFailure("UtilAttachFilePreviewService --- from VC cannot be nil")
                return
            }
            DocsLogger.info("UtilAttachFilePreviewService --- start push attach, fromVC: \(fromVC)")
            self?.model?.userResolver.navigator.push(body: body, naviParams: naviParams, from: fromVC, animated: animated) { (_, rsp) in
                if param.isInFollow && rsp.error == nil {
                    if let blockVC = rsp.resource as? DriveFileBlockVCProtocol {
                        blockVC.fileBlockMountToken = FollowModule.boxPreview.rawValue
                    }
                    if let follwableVC = rsp.resource as? FollowableViewController {
                        browserVC?.spaceFollowAPIDelegate?.currentFollowAttachMountToken = FollowModule.boxPreview.rawValue
                        browserVC?.spaceFollowAPIDelegate?.follow(browserVC, add: follwableVC)
                        browserVC?.spaceFollowAPIDelegate?.follow(nil, onOperate: .vcOperation(value: .openOrCloseAttachFile(isOpen: true)))
                    }
                }
            }
        }
    }

    struct OpenAttachParam {
        let fileName: String?
        let fileSize: Int64
        let mimeType: String
        let fileToken: String
        let mountNodeToken: String
        let mountPoint: String
        let isInFollow: Bool
        let appId: String
        let srcObjToken: String? //对应源文档token（如sync block或base block场景）
        let srcObjType: Int?    //对应源文档type（如sync block或base block场景）
        let extraParams: String?
    }
}

extension UtilAttachFilePreviewService: DriveSDKAttachmentDelegate {
    public func onAttachmentClose() {
        DocsLogger.info("notify web attachment exit")
        self.model?.jsEngine.callFunction(DocsJSCallBack.onAttachFileExit, params: [:], completion: nil)
    }
}
