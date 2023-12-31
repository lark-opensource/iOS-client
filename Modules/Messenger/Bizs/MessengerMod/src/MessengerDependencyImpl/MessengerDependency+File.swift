//
//  MessengerMockDependency+File.swift
//  LarkMessenger
//
//  Created by kangsiwan on 2020/5/27.
//

import Foundation
import LarkFile
import LarkModel
import LarkMessengerInterface
import EENavigator
import Swinject
import LarkContainer

#if !CCMMod
public final class FileDependencyImpl: FileDependency {
    public init(resolver: Resolver) { }

    public func jumpToSpace(fileURL: URL, name: String?, fileType: String?, from: UIViewController) { }

    public func showQuataAlertFromVC(_ vc: UIViewController) { }

    public func canOpenSDKPreview(fileName: String, fileSize: Int64) -> Bool { false }

    public func openSDKPreview(
        message: Message,
        chat: Chat?,
        fileInfo: FileContentBasicInfo?,
        from: NavigatorFrom,
        supportForward: Bool,
        canSaveToDrive: Bool,
        browseFromWhere: FileBrowseFromWhere
    ) { }

    public func getLocalPreviewController(fileName: String, fileType: String?, fileUrl: URL, fileID: String, messageId: String) -> UIViewController { UIViewController() }

    public func driveSDKPreviewLocalFile(fileName: String,
                                         fileUrl: URL,
                                         appID: String,
                                         from: NavigatorFrom) { }
}

#else
import UIKit
import Homeric
import RxRelay
import RxSwift
import LarkFile
import LarkModel
import EENavigator
import LarkContainer
import SpaceInterface
import LKCommonsLogging
import LKCommonsTracker
import LarkAccountInterface
import LarkMessengerInterface
#if MailMod
import LarkMailInterface
#endif
import LarkSDKInterface
import LarkUIKit

public final class FileDependencyImpl: FileDependency {
    private let resolver: UserResolver
    private let disposeBag: DisposeBag = DisposeBag()

    private static let logger = Logger.log(FileDependencyImpl.self, category: "FileDependencyImpl")
    public init(resolver: UserResolver) {
        self.resolver = resolver
    }

    public func jumpToSpace(fileURL: URL, name: String?, fileType: String?, from: UIViewController) {
        let entity = DriveLocalFileEntity(fileURL: fileURL, name: name, fileType: fileType, canExport: true)
        let body = DriveLocalFileControllerBody(files: [entity], index: 0)
        let nav = from.navigationController ?? (from as? UINavigationController)
        resolver.navigator.pop(from: from, animated: false) {
            if let nav = nav {
                self.resolver.navigator.push(body: body, naviParams: nil, from: nav, animated: false, completion: nil)
            }
        }
    }

    public func showQuataAlertFromVC(_ vc: UIViewController) {
        (try? resolver.resolve(assert: QuotaAlertService.self))?.showQuotaAlert(type: .saveToSpace, from: vc)
    }

    public func canOpenSDKPreview(fileName: String, fileSize: Int64) -> Bool {
        let options = (try? resolver.resolve(assert: DriveSDK.self))?.canOpen(fileName: fileName, fileSize: UInt64(fileSize), appID: "1001")
        if options?.isSupport ?? false {
            FileDependencyImpl.logger.error("open file with DriveSDK")
            return true
        }
        FileDependencyImpl.logger.error("open file with LarkFile")
        return false
    }

    public func openSDKPreview(
        message: Message,
        chat: Chat?,
        fileInfo: FileContentBasicInfo?,
        from: NavigatorFrom,
        supportForward: Bool,
        canSaveToDrive: Bool,
        browseFromWhere: FileBrowseFromWhere
    ) {
        // 消息链接化场景会使用传过来的chat，不能用message.channel.id去拉，无权限场景可能拉失败
        if let chat = chat {
            self.innerOpenSDKPreview(
                message: message,
                chat: chat,
                fileInfo: fileInfo,
                from: from,
                supportForward: supportForward,
                canSaveToDrive: canSaveToDrive,
                browseFromWhere: browseFromWhere
            )
            return
        }

        (try? resolver.resolve(assert: ChatAPI.self))?
            .fetchChat(by: message.channel.id, forceRemote: false)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] chat in
                guard let self = self, let chat = chat else {
                    Self.logger.error("openSDKPreview fetch miss chat \(message.channel.id)")
                    return
                }
                self.innerOpenSDKPreview(
                    message: message,
                    chat: chat,
                    fileInfo: fileInfo,
                    from: from,
                    supportForward: supportForward,
                    canSaveToDrive: canSaveToDrive,
                    browseFromWhere: browseFromWhere
                )
            }, onError: { error in
                Self.logger.error("openSDKPreview fetch chat error \(message.channel.id)", error: error)
            }).disposed(by: self.disposeBag)
    }

    private func innerOpenSDKPreview(
        message: Message,
        chat: Chat,
        fileInfo: FileContentBasicInfo?,
        from: NavigatorFrom,
        supportForward: Bool,
        canSaveToDrive: Bool,
        browseFromWhere: FileBrowseFromWhere
    ) {
        func convertDictionaryToJSONString(_ dict: NSDictionary) -> String {
            if let data = try? JSONSerialization.data(withJSONObject: dict, options: []) {
                return String(data: data, encoding: String.Encoding.utf8) ?? ""
            } else {
                FileDependencyImpl.logger.error("message_id && chat_id both are nil")
                return ""
            }
        }

        var dict = ["msg_id": message.id, "chat_id": message.channel.id]
        let onlineFile: DriveSDK.OnlineFile
        var supportSaveToSpace = canSaveToDrive
        var supportImportAsOnlineFile: Bool = true
        var isForwardPriview = false
        var senderTenantId = message.fromChatter?.tenantId
        if senderTenantId == nil {
            senderTenantId = try? self.resolver.resolve(type: ChatterAPI.self).getChatterFromLocal(id: message.fromId)?.tenantId
        }
        var tenantIDInt64: Int64?
        if let tenantID = senderTenantId, let id = Int64(tenantID) {
            tenantIDInt64 = id
        }
        switch browseFromWhere {
        case .file(let extra):
            if let forwardPriview = extra["forwardPriview"] as? Bool,
               forwardPriview == true {
                supportSaveToSpace = false
                supportImportAsOnlineFile = false
                isForwardPriview = true
            }
            if let content = message.content as? FileContent {
                // 消息链接化场景需要使用previewID做鉴权
                if let authToken = content.authToken {
                    dict["preview_token"] = authToken
                }
                // 消息链接化场景嵌套文件夹里的文件预览需要根文件的Key做鉴权
                dict["auth_file_key"] = content.key
                onlineFile = DriveSDK.OnlineFile(fileName: content.name,
                                                 fileID: content.key,
                                                 msgID: message.id,
                                                 uniqueID: content.key,
                                                 senderTenantID: tenantIDInt64,
                                                 extraAuthInfo: convertDictionaryToJSONString(dict as NSDictionary),
                                                 isEncrypted: content.filePreviewStage == .encrypted)
            } else {
                assertionFailure("parameters is wrong")
                onlineFile = DriveSDK.OnlineFile(
                    fileName: "",
                    fileID: "",
                    msgID: "",
                    uniqueID: nil,
                    senderTenantID: nil,
                    extraAuthInfo: nil,
                    isEncrypted: false
                )
            }
        case .folder:
            // TODO: @zhaojiachen 文件夹内的文件预览暂不支持「保存到云空间」，因为老的接口目前不支持
            supportSaveToSpace = false
            // 文件夹内的文件暂不支持转在线文档
            supportImportAsOnlineFile = false
            if let fileInfo = fileInfo {
                // 消息链接化场景需要使用previewID做鉴权
                if let authToken = fileInfo.authToken {
                    dict["preview_token"] = authToken
                }
                // 消息链接化场景嵌套文件夹里的文件预览需要根文件的Key做鉴权
                dict["auth_file_key"] = fileInfo.authFileKey
                onlineFile = DriveSDK.OnlineFile(fileName: fileInfo.name,
                                                 fileID: fileInfo.key,
                                                 msgID: message.id,
                                                 uniqueID: fileInfo.key,
                                                 senderTenantID: tenantIDInt64,
                                                 extraAuthInfo: convertDictionaryToJSONString(dict as NSDictionary),
                                                 isEncrypted: fileInfo.filePreviewStage == .encrypted)
            } else {
                assertionFailure("parameters is wrong")
                onlineFile = DriveSDK.OnlineFile(
                    fileName: "",
                    fileID: "",
                    msgID: "",
                    uniqueID: nil,
                    senderTenantID: nil,
                    extraAuthInfo: nil,
                    isEncrypted: false
                )
            }
        }

        let messageCanSaveToSpace = (message.disabledAction.actions[Int32(MessageDisabledAction.Action.saveToSpace.rawValue)] == nil)
        let canSaveToSpace = supportSaveToSpace && !chat.enableRestricted(.download) && messageCanSaveToSpace
        let supportConfig = SupportConfig(forward: supportForward && !chat.enableRestricted(.forward),
                                          saveToSpace: canSaveToSpace,
                                          importAsOnlineFile: supportImportAsOnlineFile,
                                          openOtherApp: !chat.enableRestricted(.download))
        if let from = from.fromViewController {
            var isHandledByMail = false
            #if MailMod
            if ["eml", "msg"].contains((onlineFile.fileName as NSString).pathExtension.lowercased()),
               let mailInterface = try? self.resolver.resolve(type: LarkMailInterface.self),
               mailInterface.canOpenIMFile(fileName: onlineFile.fileName) {
                // Email类型：eml, msg文件使用MailSDK预览
                // TODO: 后续优化,统一走DriveSDK预览,Mail这边提供eml解析和渲染的能力
                if isForwardPriview {
                    /// 转发预览暂不支持eml文件
                    FileDependencyImpl.logger.info("eml files are not supported in forward preview")
                    return
                }
                FileDependencyImpl.logger.info("open eml file with MailSDK")

                let imp = (try? self.resolver.resolve(assert: DriveSDKDependencyBridge.self, arguments: message, fileInfo, browseFromWhere))?.moreDependency.provider
                imp.flatMap { mailInterface.openEMLFromIM(fileProvider: MailSDKEMLProviderDecorator(providerImp: $0), from: from) }
                isHandledByMail = true
            }
            #endif
            if !isHandledByMail {
                // DriveSDK 预览
                guard let bridge = try? self.resolver.resolve(type: DriveSDKDependencyBridge.self, arguments: message, fileInfo, browseFromWhere) else { return }
                let dependency = DriveSDKDependencyDecorator(
                    dependencyBridge: bridge,
                    supportConfig: supportConfig
                )
                if isForwardPriview {
                    let imFile = DriveSDK.IMFile(fileName: onlineFile.fileName,
                                                 fileID: onlineFile.fileID,
                                                 msgID: onlineFile.msgID,
                                                 uniqueID: onlineFile.uniqueID,
                                                 senderTenantID: onlineFile.senderTenantID,
                                                 extraAuthInfo: onlineFile.extraAuthInfo,
                                                 dependency: dependency,
                                                 isEncrypted: onlineFile.isEncrypted)
                    let naviBarConfig = DriveSDKNaviBarConfig(titleAlignment: .center, fullScreenItemEnable: true)
                    let previewVc = (try? self.resolver.resolve(assert: DriveSDK.self))?.createIMFileController(imFile: imFile, appID: "1001", naviBarConfig: naviBarConfig)
                    previewVc.flatMap { self.resolver.navigator.present($0, wrap: LkNavigationController.self, from: from) }
                } else {
                    (try? self.resolver.resolve(assert: DriveSDK.self))?.open(onlineFile: onlineFile, from: from, appID: "1001", dependency: dependency)
                }
            }
        } else {
            assertionFailure("must have from vc")
        }
    }

    public func getLocalPreviewController(fileName: String, fileType: String?, fileUrl: URL, fileID: String, messageId: String) -> UIViewController {
        guard let bridge = try? self.resolver.resolve(assert: DriveSDKLocalDependencyBridge.self, argument: messageId) else { return UIViewController() }
        let dependency = DriveSDKLocalPreviewDependencyDecorator(
            dependencyBridge: bridge
        )
        let localFile = DriveSDKLocalFile(
            fileName: fileName,
            fileType: fileType,
            fileURL: fileUrl,
            fileId: fileID,
            dependency: dependency
        )
        return (try? self.resolver.resolve(assert: DriveSDK.self))?.localPreviewController(
            for: localFile,
            appID: "1003", /// 密聊文件本地预览
            thirdPartyAppID: nil,
            naviBarConfig: DriveSDKNaviBarConfig(titleAlignment: .center, fullScreenItemEnable: true)
        ) ?? UIViewController()
    }

    public func driveSDKPreviewLocalFile(fileName: String,
                                         fileUrl: URL,
                                         appID: String,
                                         from: NavigatorFrom) {
        let file = DriveSDKLocalFileV2(fileName: fileName,
                                       fileType: nil,
                                       fileURL: fileUrl,
                                       fileId: "",
                                       dependency: DrivceSDKPreviewLocalFileDependencyImpl())
        let config = DriveSDKNaviBarConfig(titleAlignment: .center, fullScreenItemEnable: false)
        let body = DriveSDKLocalFileBody(files: [file],
                                         index: 0,
                                         appID: appID,
                                         thirdPartyAppID: nil,
                                         naviBarConfig: config)
        self.resolver.navigator.present(body: body,
                                        wrap: LkNavigationController.self,
                                        from: from)
    }

    fileprivate struct DrivceSDKPreviewLocalFileDependencyImpl: DriveSDKDependency {
        var actionDependency: DriveSDKActionDependency = LocalFilePreviewActionDependencyImpl()
        var moreDependency: DriveSDKMoreDependency = LocalFilePreviewMoreDependencyImpl()

        // 配置外部控制事件,本地文件不需要根据外部条件改变预览状态
        struct LocalFilePreviewActionDependencyImpl: DriveSDKActionDependency {
            var closePreviewSignal: Observable<Void> { .never() }
            var stopPreviewSignal: Observable<Reason> { .never() }
        }
        // 配置更多功能选项
        struct LocalFilePreviewMoreDependencyImpl: DriveSDKMoreDependency {
            var moreMenuVisable: Observable<Bool> { .just(false) }
            var moreMenuEnable: Observable<Bool> { .just(false) }
            var actions: [DriveSDKMoreAction] { [] }
        }
    }
}

public final class DriveSDKDependencyDecorator: SpaceInterface.DriveSDKDependency {
    public let actionDependency: DriveSDKActionDependency
    public let moreDependency: DriveSDKMoreDependency

    public init(dependencyBridge: DriveSDKDependencyBridge,
                supportConfig: SupportConfig) {
        moreDependency = DriveSDKMoreDependencyDecorator(imp: dependencyBridge.moreDependency,
                                                         supportConfig: supportConfig)
        actionDependency = DriveSDKActionDependencyDecorator(imp: dependencyBridge.actionDependency)
    }
}

final class DriveSDKActionDependencyDecorator: DriveSDKActionDependency {
    var stopPreviewSignal: Observable<Reason> {
        return self.imp.stopPreviewSignal.map { (reasonBridge) -> Reason in
            return DriveSDKStopReason(reason: reasonBridge.reason, image: reasonBridge.image)
        }
    }
    var closePreviewSignal: Observable<Void> {
        return self.imp.closePreviewSignal
    }

    let imp: DriveSDKActionDependencyBridge

    init(imp: DriveSDKActionDependencyBridge) {
        self.imp = imp
    }
}

public struct SupportConfig {
    let forward: Bool
    let saveToSpace: Bool
    // 支持支持转在线文档，目前只支持excel和word
    let importAsOnlineFile: Bool
    let openOtherApp: Bool
}

final class DriveSDKMoreDependencyDecorator: DriveSDKMoreDependency {
    var moreMenuVisable: Observable<Bool> {
        return self.imp.moreMenuVisable.map { $0 }
    }
    var moreMenuEnable: Observable<Bool> { .just(true) }

    var actions: [DriveSDKMoreAction] {
        var moreActions: [DriveSDKMoreAction] = []
        if supportConfig.saveToSpace {
            moreActions.append(
                .saveToSpace(handler: { state in
                    self.trackSaveToSpace(state)
                })
            )
        }
        if supportConfig.forward {
            moreActions.append(
                .forward(handler: { vc, _  in
                    self.imp.handleForward(vc: vc)
                })
            )
        }
        if supportConfig.importAsOnlineFile {
            moreActions.append(.convertToOnlineFile)
        }
        if supportConfig.openOtherApp {
            moreActions.append(.openWithOtherApp(fileProvider: self.provider))
        }
        return moreActions
    }

    // 点击保存到云盘
    private func trackSaveToSpace(_ state: DKSaveToSpaceState) {
        // unsave: 未保存到云盘，更多按钮显示"保存到云盘"
        // saved: 已经保存到云盘，更多按钮显示"在云文档查看"
        // unable: 无法进行保存到云盘的操作
        var str: String
        switch state {
        case .unsave: str = "unsave"
        case .saved: str = "saved"
        case .unable: str = "unable"
        }
        Tracker.post(TeaEvent(Homeric.CLICK_SAVE_CLOUDDISK, category: "driver", params: ["saveToSpaceState": str]))
    }

    let imp: DriveSDKMoreDependencyBridge
    let provider: SDKFileProviderDecorator
    let supportConfig: SupportConfig

    init(imp: DriveSDKMoreDependencyBridge,
         supportConfig: SupportConfig) {
        self.imp = imp
        self.supportConfig = supportConfig
        self.provider = SDKFileProviderDecorator(providerImp: imp.provider)
    }
}

final class SDKFileProviderDecorator: DriveSDKFileProvider {
    let imp: DriveSDKFileProviderBridge

    var localFileURL: URL? {
        return self.imp.localFileURL
    }
    var fileSize: UInt64 {
        return self.imp.fileSize
    }

    func download() -> Observable<DriveSDKDownloadState> {
        return self.imp.download().map { (bridgeState) -> DriveSDKDownloadState in
            switch bridgeState {
            case .downloading(let progress):
                return DriveSDKDownloadState.downloading(progress: progress)
            case .success(let fileURL):
                return DriveSDKDownloadState.success(fileURL: fileURL)
            case .interrupted(let reason):
                return DriveSDKDownloadState.interrupted(reason: reason)
            }
        }
    }

    /// 下载操作前置拦截
    func canDownload(fromView: UIView?) -> Observable<Bool> {
        self.imp.canDownload(fromView: fromView)
    }

    func cancelDownload() {
        self.imp.cancelDownload()
    }

    init(providerImp: DriveSDKFileProviderBridge) {
        self.imp = providerImp
    }
}

#if MailMod
// MARK: MailSDK 预览EML文件
final class MailSDKEMLProviderDecorator: LarkMailEMLProvider {
    let imp: DriveSDKFileProviderBridge

    var localFileURL: URL? {
        return self.imp.localFileURL
    }
    var fileSize: UInt64 {
        return self.imp.fileSize
    }

    func download() -> Observable<LarkMailEMLDownloadState> {
        return self.imp.download().map { (bridgeState) -> LarkMailEMLDownloadState in
            switch bridgeState {
            case .downloading(let progress):
                return LarkMailEMLDownloadState.downloading(progress: progress)
            case .success(let fileURL):
                return LarkMailEMLDownloadState.success(fileURL: fileURL)
            case .interrupted(let reason):
                return LarkMailEMLDownloadState.interrupted(reason: reason)
            }
        }
    }

    func cancelDownload() {
        self.imp.cancelDownload()
    }

    init(providerImp: DriveSDKFileProviderBridge) {
        self.imp = providerImp
    }
}
#endif

// MARK: DrivesSDK 本地预览
final class DriveSDKLocalPreviewDependencyDecorator: DriveSDKLocalPreviewDependency {
    let actionDependency: DriveSDKActionDependency
    let moreDependency: DriveSDKLocalMoreDependency

    init(dependencyBridge: DriveSDKLocalDependencyBridge) {
        moreDependency = DriveSDKLocalMoreDependencyDecorator(imp: dependencyBridge.moreDependency)
        actionDependency = DriveSDKActionDependencyDecorator(imp: dependencyBridge.actionDependency)
    }
}

final class DriveSDKLocalMoreDependencyDecorator: DriveSDKLocalMoreDependency {
    var moreMenuVisable: Observable<Bool> { return self.imp.moreMenuVisable }
    var moreMenuEnable: Observable<Bool> { return self.imp.moreMenuEnable }

    var actions: [DriveSDKLocalMoreAction] {
        // 目前 IM 文件预览仅密聊接入
        return [.openWithOtherApp(customAction: nil)]
    }

    let imp: DriveSDKLocalMoreDependencyBridge

    init(imp: DriveSDKLocalMoreDependencyBridge) {
        self.imp = imp
    }
}
#endif
