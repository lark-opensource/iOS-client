//
//  ForwardComponentService.swift
//  LarkMessengerInterface
//
//  Created by ByteDance on 2023/5/17.
//

import UIKit
import Foundation
import RxSwift
import LarkModel
import LarkSDKInterface
import Swinject
import LarkAccountInterface
import RustPB
import UniverseDesignToast
import LKCommonsLogging
import LarkFeatureGating
import LarkContainer

//转发通用组件建设新定义的转发结果参数，用于回调给业务方
public typealias ForwardResults = Result<[ForwardResultItem?], Error>
// 转发结果，已选ChatID，已选UserID, 发送前时间（用来计算埋点数据）
public typealias ForwardComponentResult = (forwardResults: ForwardResults,
                                           chatIDs: [String]?,
                                           userIDs: [String]?,
                                           beforeSendTime: CFTimeInterval)
// [目标chatID, 转发结果], 转发权限拦截信息
public typealias ForwardComponentResponse = ([ForwardResultItem?], Im_V1_FilePermCheckBlockInfo?)
// 组件通过该回调将ForwardComponentResult回调给业务方
public typealias ForwardResultCallback = ((ForwardComponentResult?) -> Void)?
// 转发组件转发执行的报错类型
public enum SendForwardMessageError: Error {
    // 一般情况下是取不到self
    case requestRelease
    case containerResolveError
}

public typealias ForwardResultItem = ForwardItemParam

public struct ForwardTargetConfig {
    public let includeConfigs: [EntityConfigType]
    public let enabledConfigs: [EntityConfigType]
    public let enableTargetPreview: Bool
    public let disadledBlock: ForwardItemDisabledBlock?
    public init(includeConfigs: [EntityConfigType] = [ForwardUserEntityConfig(),
                                                      ForwardGroupChatEntityConfig(),
                                                      ForwardBotEntityConfig(),
                                                      ForwardThreadEntityConfig()],
                enabledConfigs: [EntityConfigType] = [ForwardUserEnabledEntityConfig(),
                                                      ForwardGroupChatEnabledEntityConfig(),
                                                      ForwardBotEnabledEntityConfig(),
                                                      ForwardThreadEnabledEntityConfig()],
                enableTargetPreview: Bool = true,
                disabledBlock: ForwardItemDisabledBlock? = nil) {
        self.includeConfigs = includeConfigs
        self.enabledConfigs = enabledConfigs
        self.enableTargetPreview = enableTargetPreview
        self.disadledBlock = disabledBlock
    }
}

public struct ForwardChooseConfig {
    public let enableSwitchSelectMode: Bool
    public let isDefaultSingleSelectMode: Bool
    public let maxSelectCount: Int
    public let cancelMultiSelectCallback: (() -> Void)?
    public init(enableSwitchSelectMode: Bool = true,
                isDefaultSingleSelectMode: Bool = true,
                maxSelectCount: Int = 10,
                cancelMultiSelectCallback: (() -> Void)? = nil) {
        self.enableSwitchSelectMode = enableSwitchSelectMode
        self.isDefaultSingleSelectMode = isDefaultSingleSelectMode
        self.maxSelectCount = maxSelectCount
        self.cancelMultiSelectCallback = cancelMultiSelectCallback
    }
}

public struct ForwardCommonConfig {
    public let enableCreateGroupChat: Bool
    public let enableShowRecentForward: Bool
    public let enabelContentPreview: Bool
    public let titleBarText: String?
    public let forwardTrackScene: ForwardScene
    public let forwardSuccessText: String?
    public let permissions: [RustPB.Basic_V1_Auth_ActionType]?
    public let dismissAction: (() -> Void)?
    public let forwardResultCallback: ForwardResultCallback
    public init(enableCreateGroupChat: Bool = true,
                enableShowRecentForward: Bool = true,
                enabelContentPreview: Bool = true,
                titleBarText: String? = nil,
                forwardTrackScene: ForwardScene = .unknown,
                permissions: [RustPB.Basic_V1_Auth_ActionType]? = nil,
                forwardSuccessText: String? = nil,
                dismissAction: (() -> Void)? = nil,
                forwardResultCallback: ForwardResultCallback = nil) {
        self.enableCreateGroupChat = enableCreateGroupChat
        self.enableShowRecentForward = enableShowRecentForward
        self.enabelContentPreview = enabelContentPreview
        self.titleBarText = titleBarText
        self.forwardTrackScene = forwardTrackScene
        self.forwardSuccessText = forwardSuccessText
        self.permissions = permissions
        self.dismissAction = dismissAction
        self.forwardResultCallback = forwardResultCallback
    }
}

public struct ForwardAdditionNoteConfig {
    public let enableAdditionNote: Bool
    public let enableAdditionNoteMention: Bool
    public init(enableAdditionNote: Bool = true,
                enableAdditionNoteMention: Bool = true) {
        self.enableAdditionNote = enableAdditionNote
        self.enableAdditionNoteMention = enableAdditionNoteMention
    }
}

/// 给ForwardAlert提供必要的View以及行为、属性等
open class ForwardAlertConfig: UserResolverWrapper {
    public let content: ForwardAlertContent
    public let userResolver: UserResolver
    public weak var targetVc: UIViewController?

    required public init(userResolver: UserResolver, content: ForwardAlertContent) {
        self.userResolver = userResolver
        self.content = content
    }

    open func getAlertControllerTitle() -> String? {
        return nil
    }

    open func getAlertControllerConfirmButtonText() -> String? {
        return nil
    }

    open func getContentView() -> UIView? {
        return nil
    }

    open func beforeShowAlertController() {

    }

    open func allertCancelAction() {

    }

    /// 用来判断能否处理该类型的content，如果可以处理，才能生成相应的AlertConfig
    ///
    /// - Parameter content:
    /// - Returns:
    open class func canHandle(content: ForwardAlertContent) -> Bool {
        return false
    }
}

/// commonConfig和alertConfig部分参数转发无法提供默认实现，需要业务传入；其他config转发提供默认实现
public struct ForwardConfig {
    public let targetConfig: ForwardTargetConfig
    public let chooseConfig: ForwardChooseConfig
    public let addtionNoteConfig: ForwardAdditionNoteConfig
    public let commonConfig: ForwardCommonConfig
    public let alertConfig: ForwardAlertConfig
    public init(alertConfig: ForwardAlertConfig,
                commonConfig: ForwardCommonConfig = ForwardCommonConfig(),
                targetConfig: ForwardTargetConfig = ForwardTargetConfig(),
                addtionNoteConfig: ForwardAdditionNoteConfig = ForwardAdditionNoteConfig(),
                chooseConfig: ForwardChooseConfig = ForwardChooseConfig()) {
        self.alertConfig = alertConfig
        self.commonConfig = commonConfig
        self.targetConfig = targetConfig
        self.addtionNoteConfig = addtionNoteConfig
        self.chooseConfig = chooseConfig
    }
}

public enum ForwardScene: String {
    case transmitSingleMessage
    case transmitMergeMessages
    case transmitBatchMessages
    case sendText
    case sendGroupCardForward
    case sendUserCard
    case sendFile
    case sendImage
    case sendImages
    case sendVideo
    case sendFolderCopy
    case sendEmojiStoreCard
    case sendPublicThread
    case sendTodoDetail
    case sendMeetingCard
    case sendMomentPost
    case sendEmail
    case sendEmailAttachment
    case sendCalendar
    case sendOpenPlatformPreviewCard
    case sendOpenPlatformAppCard
    case unknown
}

public enum ForwardContentParam {
    case transmitSingleMessage(param: MessageForwardParam)
    case transmitMergeMessage(param: MergeForwardParam)
    case transmitBatchMessage(param: BatchForwardParam)
    case sendImageMessage(param: SendImageForwardParam)
    case sendMultipleImageMessage(param: SendMultiImageForwardParam)
    case sendUserCardMessage(param: SendUserCardForwardParam)
    case sendGroupCardMessage(param: SendGroupCardForwardParam)
    case sendTextMessage(param: SendTextForwardParam)
    case sendFileMessage(param: SendFileForwardParam)
}

public typealias GetForwardContentCallback = (() -> Observable<ForwardContentParam>)?

// ForwardParams
public struct MessageForwardParam {
    public let type: TransmitType
    public let originMergeForwardId: String?
    public init(type: TransmitType,
                originMergeForwardId: String?) {
        self.type = type
        self.originMergeForwardId = originMergeForwardId
    }
}

public struct MergeForwardParam {
    public let messageIds: [String]
    public let quasiTitle: String
    public let needQuasiMessage: Bool
    public let originMergeForwardId: String?
    public let type: Basic_V1_MergeFowardMessageType?
    // 私有话题帖子转发和合并转发共用一套转发链路，转发内容为帖子时需要传入threadID
    public let threadID: String?
    // default false, close server limite verity
    public let limited: Bool
    public init(messageIds: [String],
                quasiTitle: String,
                needQuasiMessage: Bool = true,
                originMergeForwardId: String? = nil,
                type: Basic_V1_MergeFowardMessageType? = nil,
                threadID: String? = nil,
                limited: Bool = false) {
        self.messageIds = messageIds
        self.quasiTitle = quasiTitle
        self.needQuasiMessage = needQuasiMessage
        self.originMergeForwardId = originMergeForwardId
        self.type = type
        self.threadID = threadID
        self.limited = limited
    }
}

public struct BatchForwardParam {
    public let messageIds: [String]
    public let originMergeForwardId: String?
    public init(messageIds: [String],
                originMergeForwardId: String? = nil) {
        self.messageIds = messageIds
        self.originMergeForwardId = originMergeForwardId
    }
}

public struct SendImageForwardParam {
    public let sourceImage: UIImage
    public init(sourceImage: UIImage) {
        self.sourceImage = sourceImage
    }
}

public struct SendMultiImageForwardParam {
    public let imagePaths: [URL]
    public init(imagePaths: [URL]) {
        self.imagePaths = imagePaths
    }
}

public struct SendUserCardForwardParam {
    public let shareChatterId: String
    public init(shareChatterId: String) {
        self.shareChatterId = shareChatterId
    }
}

public struct SendGroupCardForwardParam {
    public let shareChatId: String
    public init(shareChatId: String) {
        self.shareChatId = shareChatId
    }
}

public struct SendTextForwardParam {
    public let textContent: String
    public init(textContent: String) {
        self.textContent = textContent
    }
}

public struct SendFileForwardParam {
    public let filePath: String
    public let fileName: String
    public init(filePath: String,
                fileName: String) {
        self.filePath = filePath
        self.fileName = fileName
    }
}
