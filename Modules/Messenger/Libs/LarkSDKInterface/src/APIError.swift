//
//  APIError.swift
//  Lark
//
//  Created by Sylar on 2017/12/24.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkRustClient
import LarkFoundation
import UniverseDesignToast
import RoundedHUD

/// 新版 Error https://bytedance.feishu.cn/docx/doxcn99FEHGKL5vxRbWarBI0WRI?from=space_home_recent
public struct APIError {
    public var type: APIError.TypeEnum
    @available(*, deprecated, message: "use errorCode instead")
    public var code: Int32
    public var status: Int32
    public var errorCode: Int32
    public var displayMessage: String
    public var debugMessage: String
    @available(*, deprecated, message: "use displayMessage instead")
    public var serverMessage: String
    public var extraString: String

    public init(code: Int32, errorCode: Int32, status: Int32, displayMessage: String,
                serverMessage: String, debugMessage: String, extraString: String = "") {
        self.code = code
        self.errorCode = errorCode
        self.displayMessage = displayMessage
        self.serverMessage = serverMessage
        self.type = TypeEnum(code, message: displayMessage)
        self.status = status
        self.debugMessage = debugMessage
        self.extraString = extraString
    }

    public init(type: APIError.TypeEnum) {
        self.code = 0
        self.errorCode = 0
        self.displayMessage = ""
        self.serverMessage = ""
        self.type = type
        self.status = 0
        self.debugMessage = ""
        self.extraString = ""
    }
}

extension APIError {

    public enum TypeEnum {
        case unknowError                                         // 未知错误
        case unknownBusinessError(message: String)               // 未知的业务错误类型(from liblark)
        case forbidSetName(messge: String)                       // 没权限改用户名字
        case sensitiveUserName(messge: String)                   // 名字审查不通过
        case noPermission(message: String)                       // 无权限。未明确归类的无权限错误。
        case notAddMemberPermission(message: String)             // 不在 Chat 里面，不能增加群成员
        case addUserToP2pChat(message: String)                   // 不能在 P2p chat 中增加成员
        case noDeleteMemberPermission(message: String)           // 不在 Chat 里面，不能删除群成员
        case onlyGroupChatCanChangeName(message: String)         // 只有 GroupChat 可以修改群名称
        case changeForzenChatName(message: String)               // 归档的 Chat 不能够再修改群名称
        case noChangeChatNamePermission(message: String)         // 不在 Chat 中不能够修改群名称
        case noPullMemberListPermission(message: String)         // 不在 Chat 中不能拉取群成员列表
        case noPullMessagePermission(message: String)            // 不在 Chat 中不能拉取消息
        case sendMessageInForzenChat(message: String)            // chat 被删除或者归档，不能再发送消息
        case notInSameOrganization(message: String)              // 不在同一个组织
        case chatShareMessageExpired(message: String)            // 群分享已过期
        case hadJoinedChat(message: String)                      // 通过群分享加入一个已经加入的群
        case chatMemberHadFull(message: String)                  // 群人数超限制，加入失败
        case transferGroupOwnerFailed(message: String)           // 群主转让失败
        case groupChatDissolved(message: String)                 // 群已经解散
        case onlyAdminCanAddMemer(message: String)               // 因群主设置“仅群主可添加”导致的加人失败
        case chatNotSupportShare(message: String)                // 群主设置了“群不可被分享”导致分享失败
        case messageRecallOverTime(message: String)              // 撤回超时的消息, 提示错误信息
        case reserved(message: String)                           // 预留
        case p2pChatWithoutSelf(message: String)                 // p2p chat 应该包括创建者自己
        case p2pChatWithMultipleMember(message: String)          // 创建 p2p chat 时不应该传入两个以上的 user
        case wrongChatType(message: String)                      // 错误的会话类型
        case chatNotExist(message: String)                       // 没能根据 chat_id 找到对应的 chat
        case chatDescriptionTooLong(message: String)             // 群描述长度超出限制
        case updateAvatarFailed(message: String)                 // 群头像更新失败
        case messageTooLarge(message: String)                    // 消息内容大小超过限制
        case userHadJoined(message: String)                      // 用户已经在群中，重复的加群请求
        case noMessagePermission(message: String)                // 已经不是联系人，无法发送消息
        case noApplyPermission(message: String)                  // 对方设置隐私设置，无法添加联系人
        case groupQRCodeExpired(message: String)                 // 群二维码已过期，无法加群
        case groupOrSharerDismiss(message: String)               // 群已解散/分享者退群
        case createGroupFailed(message: String)                  // 由于名称重复创建公开群失败
        case createGroupSigleLetterFailed(message: String)       // 创建单字母的群名称创建失败
        case noSecretChatPermission(message: String)             // 无密聊权限

        // swiftlint:disable number_separator
        case sdkReserved(message: String)                        // 预留
        case unauthorized(message: String)                       // 未认证
        case noAccessAuthentication(message: String)             // 没权限访问
        case dirPathIsFolder(message: String)                    // 路径是文件夹 - 创建文件类型假消息返回
        case fetchVerifyCodeFailed(message: String)              // 获取验证码失败 - 直接取LarkError中的message展示
        case resourceNotFound(message: String)                   // 没有找到资源 - 比如使用一个无效的key，来下载文件
        case resourceHasBeenRemoved(message: String)             // 资源已被删除，不再可用
        case checkVerifyCodeFailed(message: String)              // 验证码验证失败 - 直接取LarkError中的DisplayMessage显示
        case networkIsNotAvailable                               // 网络不可用
        case remoteRequestTimeout                                // 请求服务端数据超时
        case encrypCallNotSupport                                // 不支持加密通话

        case internalRustClientError                             // RustClient内部错误

        case transformFailure(message: String)                   // 有数据但是无法转换
        case banned(message: String)                             // 群主已开启仅群主或特定成员可发言
        case resetContactTokenQuick                              // 刷新二维码过快

        case redPacketZeroLeft(message: String)                  // 红包已经抢完
        case redPacketGrabbedAlready(message: String)            // 红包已经抢过了
        case redPacketOverDue(message: String)                   // 红包过期了
        case cjPayAccountNeedUpgrade(message: String)            // 财经账号需要升级

        case entityIncompleteData(message: String)               // Entity中的数据不全
        case noResourcesInServerResponse                         // 服务器返回结果中没有Resources数据
        case readStatusIncompleteData(message: String)           // 已读未读状态数据缺失
        case qrcodeStatusUnusual(message: String)                // 二维码状态异常
        case prepareSendMessageFailure(message: String)          // 发送消息准备工作错误
        case messagePackTypeNotSupport(type: String)             // 不支持该类型消息的Packer
        case mobileFormatIncorrect(message: String)              // 手机号码格式错误
        case emailFormatIncorrect(message: String)               // 手机号码格式错误

        case requestOverFrequency(message: String)               // 请求超过一定频率
        case invalidFaceToFaceToken(message: String)             // 无效的面对面建群token
        case invalidMedia(message: String)                       // 有过期的图片或者视频

        case announcementAPIInvalid                              // 提示旧版本用户升级，否则无法编辑群公告
        case urgentLimited(message: String)                       // 加急次数达到限制
        case chatMemberHadFullForPay(message: String)            // 付费相关群人数到达上限
        case chatMemberHadFullForCertificationTenant(message: String) // 已认证租户群人数达上限场景
        case newVersionFeature(message: String)                  // 此功能已升级，本次修改失败，请升级最新版本后操作
        case addMemberFailedWithApprove(message: String)         // 添加失败，群主已开启入群验证，请升级最新版本填写加人申请
        // 该群为企业内部群，暂不支持外部成员加入
        case internalGroupNotSupportExternalMemberJoin(message: String)
        case appreveDisable(message: String)                    // 未开启入群申请
        case notUrgetToAllWhoIsExecutive(message: String)           // 所有被加急的人都是高管
        case notUrgetToPartWhoIsExecutive(message: String)         // 被加急的人部分是高管
        case noSecretChatUrgentPermission(message: String)       // 密聊 无加急 权限

        case recognitionWithEmptyResult                         // 语音没有识别出文字

        case externalCoordinateCtl(message: String)               // 主体被管控不能与外部联系人协作
        case targetExternalCoordinateCtl(message: String)         // 客体被管控不能与外部联系人协作

        // thread
        case notDeleteThreadWhenOverTime(message: String)           // 删除thread中的topic
        case topicHasClosed(message: String)                     // 话题已经被关闭
        case forwardThreadReachLimit(message: String)            // 合并转发话题回复数量超出限制
        case forwardThreadTooLargeFail(message: String)          // 合并转发话题内容太大失败

        case createAnonymousMessageSettingClose(message: String) // 匿名能力被群主关闭
        case createAnonymousMessageNoMore(message: String)       // 没有匿名的余额了

        case editMessageNotInValidTime(message: String)          //二次编辑超出有效期

        //withdrawAddMember
        case withdrawPermissionExpired(message: String)          //没有撤回权限
        case forbidWithdrawGroupOwner(message: String)           //不能撤销群主
        case joinTokenNotSet(message: String)                    //通过二维码加群，如果旧版不传join token，则使二维码失效时，会返回该错误码
        case forbidDisbaleShareChat(message: String)             //无法撤回群分享

        case illegalContent(message: String)                     //发送不合法的内容

        case forbidPutP2PChat(message: String)                   //无权限和对方创建单聊，包括密聊单聊
        case forbidPutP2PChats(message: String)                  //无权限和选择用户列表创建单聊
        case forbidPutUrgent(message: String)                    //没有权限进行加急

        case cloudDiskFull                                       //达到租户资源上限

        case collaborationAuthFailedBlocked(message: String)     // 鉴权失败屏蔽对方
        case collaborationAuthFailedBeBlocked(message: String)     // 鉴权失败被对方屏蔽
        case collaborationAuthFailedNoRights(message: String)    // 鉴权失败未授权
        case collaborationNoSendMessageToMyAi(message: String)   // 没有权限给 MYAI 发消息

        case staticResourceFrozenByAdmin(message: String) // 静态资源被管理员冻结，无法下载，需要联系管理员进行恢复
        case staticResourceShreddedByAdmin(message: String)   // 静态资源被管理员删除，并已过期销毁c
        case staticResourceDeletedByAdmin(message: String) // 静态资源被管理员（ka脚本）删除
        case storageSpaceReachedLimit(message: String)   // 存储空间达到限制

        case securityControlDeny(message: String)                // 权限中台鉴权失败
        case strategyControlDeny(message: String)               // 策略引擎鉴权失败
        case addChatChatterApplyAreadyProcessed(message: String)   // 进群申请已经被处理

        case linkAddNonCertifiedTenantRefuse(message: String)    // 限制非认证租户群聊扩散, 链接
        case qrCodeAddNonCertifiedTenantRefuse(message: String)  // 限制非认证租户群聊扩散, 二维码
        case shareCardAddNonCertifiedTenantRefuse(message: String) // 限制非认证租户群聊扩散, 群名片
        case noFileSharePermission(message: String) // 资源类型消息因为权限导致发送失败
        case willOverflowAfterBindChat(message: String) // 绑定群后超过上限//绑定群后超过上限
        case willOverflowAfterAddMember(message: String) // 添加成员后超过上限
        case invalidCipherFailedToSendMessage(message: String) // 密钥被删除，发送消息失败
        case invalidCipherFailedToUploadFile(message: String) // 密钥被删除，上传文件失败

        case messageDlpFailedToSendMessage(message: String) // DLP检测不通过,消息发送失败

        case momentsNoOfficialUserPermission(message: String) // 公司圈用户没有官方号的使用权限

        case chatOnTimeDelMsgSettingAuthFail(message: String) // 会话定时删除权限关闭

        case myAiAlreadyInitSuccess(message: String) // MyAI已经Onboarding过

        case myAiAlreadyNewTopic(message: String) // 已开启新话题，发个指令试试

        /// 客户端专用
        case clientErrorRiskFileDisableDownload                          // 安全风险文件资源，客户端专用

        // Reference: https://wiki.bytedance.net/pages/viewpage.action?pageId=88686455
        public init(_ errorCode: Int32, message: String) {
            switch errorCode {
            case 4000: self = .noPermission(message: message)
            case 4001: self = .notAddMemberPermission(message: message)
            case 4002: self = .addUserToP2pChat(message: message)
            case 4003: self = .noDeleteMemberPermission(message: message)
            case 4004: self = .onlyGroupChatCanChangeName(message: message)
            case 4005: self = .changeForzenChatName(message: message)
            case 4006: self = .noChangeChatNamePermission(message: message)
            case 4007: self = .noPullMemberListPermission(message: message)
            case 4008: self = .noPullMessagePermission(message: message)
            case 4009: self = .sendMessageInForzenChat(message: message)
            case 4010: self = .notInSameOrganization(message: message)
            case 4011: self = .chatShareMessageExpired(message: message)
            case 4012: self = .hadJoinedChat(message: message)
            case 4013: self = .chatMemberHadFull(message: message)
            case 4014: self = .onlyAdminCanAddMemer(message: message)
            case 4015: self = .chatNotSupportShare(message: message)
            case 4016: self = .messageRecallOverTime(message: message)
            case 4018: self = .groupChatDissolved(message: message)
            case 4020: self = .forbidSetName(messge: message)
            case 4026: self = .linkAddNonCertifiedTenantRefuse(message: message)
            case 4027: self = .qrCodeAddNonCertifiedTenantRefuse(message: message)
            case 4028: self = .shareCardAddNonCertifiedTenantRefuse(message: message)
            case 4029: self = .noFileSharePermission(message: message)
            case 4036: self = .resetContactTokenQuick
            case 4037: self = .internalGroupNotSupportExternalMemberJoin(message: message)
            case 4038: self = .transformFailure(message: message)
            case 4042: self = .banned(message: message)
            case 4043: self = .notUrgetToAllWhoIsExecutive(message: message)
            case 4044: self = .notUrgetToPartWhoIsExecutive(message: message)
            case 4046: self = .withdrawPermissionExpired(message: message)
            case 4047: self = .notDeleteThreadWhenOverTime(message: message)
            case 4048: self = .forbidWithdrawGroupOwner(message: message)
            case 4049: self = .joinTokenNotSet(message: message)
            case 4050: self = .forbidDisbaleShareChat(message: message)
            case 4051: self = .forbidPutP2PChat(message: message)
            case 4052: self = .forbidPutP2PChats(message: message)
            case 4053: self = .forbidPutUrgent(message: message)
            case 4403: self = .redPacketZeroLeft(message: message)
            case 4404: self = .redPacketGrabbedAlready(message: message)
            case 4405: self = .redPacketOverDue(message: message)
            // nolint-next-line: magic_number -- 检测误报，统一写法
            case 4411: self = .cjPayAccountNeedUpgrade(message: message)
            case 5000: self = .sdkReserved(message: message)
            case 5001: self = .p2pChatWithoutSelf(message: message)
            case 5002: self = .p2pChatWithMultipleMember(message: message)
            case 5003: self = .wrongChatType(message: message)
            case 5004: self = .chatNotExist(message: message)
            case 5005: self = .chatDescriptionTooLong(message: message)
            case 5006: self = .updateAvatarFailed(message: message)
            case 5007: self = .messageTooLarge(message: message)
            case 5008: self = .userHadJoined(message: message)
            case 5009: self = .noMessagePermission(message: message)
            case 5010: self = .noApplyPermission(message: message)
            case 5011: self = .mobileFormatIncorrect(message: message)
            case 5012: self = .emailFormatIncorrect(message: message)
            case 5015: self = .groupQRCodeExpired(message: message)
            case 5016: self = .groupOrSharerDismiss(message: message)
            case 5019: self = .createGroupFailed(message: message)
            /// 参考文档 https://bytedance.feishu.cn/docs/doccnwd0f6BTg8kbdLp4UI
            case 5020: self = .addMemberFailedWithApprove(message: message)
            case 5027: self = .appreveDisable(message: message)
            case 5029: self = .recognitionWithEmptyResult
            case 5030: self = .topicHasClosed(message: message)
            case 5031: self = .createGroupSigleLetterFailed(message: message)
            case 5040: self = .forwardThreadReachLimit(message: message)
            case 5041: self = .forwardThreadTooLargeFail(message: message)
            case 5054: self = .createAnonymousMessageSettingClose(message: message)
            case 5055: self = .createAnonymousMessageNoMore(message: message)
            case 5104: self = .editMessageNotInValidTime(message: message)
            case 5200: self = .announcementAPIInvalid
            case 5555: self = .newVersionFeature(message: message)
            case 5566: self = .illegalContent(message: message)
            case 5567: self = .sensitiveUserName(messge: message)
            case 5601: self = .staticResourceFrozenByAdmin(message: message)
            case 5602: self = .staticResourceShreddedByAdmin(message: message)
            case 5607: self = .staticResourceDeletedByAdmin(message: message)
            case 5650: self = .requestOverFrequency(message: message)
            case 5651: self = .invalidFaceToFaceToken(message: message)
            case 5664: self = .invalidMedia(message: message)
            case 5701: self = .addChatChatterApplyAreadyProcessed(message: message)
            case 6001: self = .urgentLimited(message: message)
            case 6002: self = .chatMemberHadFullForPay(message: message)
            case 6003: self = .noSecretChatPermission(message: message)
            case 6004: self = .noSecretChatUrgentPermission(message: message)
            case 7010: self = .chatMemberHadFullForCertificationTenant(message: message)
            case 10000: self = .sdkReserved(message: message)
            case 10001: self = .unauthorized(message: message)
            case 10002: self = .noAccessAuthentication(message: message)
            case 10003: self = .dirPathIsFolder(message: message)
            case 10004: self = .fetchVerifyCodeFailed(message: message)
            case 10005: self = .resourceNotFound(message: message)
            case 10006: self = .resourceHasBeenRemoved(message: message)
            case 10007: self = .checkVerifyCodeFailed(message: message)
            case 10008: self = .networkIsNotAvailable
            case 10009: self = .remoteRequestTimeout
            // swiftlint:disable duplicate_conditions
            case 10019: self = .storageSpaceReachedLimit(message: message)
            //507是服务端返回的错误码，10019是SDK要返回的错误码
            case 10019, 507: self = .cloudDiskFull
            // swiftlint:enable duplicate_conditions
            case 260000: self = .collaborationAuthFailedBlocked(message: message)
            case 260001: self = .collaborationAuthFailedNoRights(message: message)
            case 260003: self = .collaborationAuthFailedBeBlocked(message: message)
            case 260008: self = .externalCoordinateCtl(message: message)
            case 260009: self = .targetExternalCoordinateCtl(message: message)
            case 260014: self = .collaborationNoSendMessageToMyAi(message: message)
            case 900406: self = .encrypCallNotSupport
            case 321000: self = .securityControlDeny(message: message)
            case 321001: self = .strategyControlDeny(message: message)
            case 311100: self = .invalidCipherFailedToSendMessage(message: message)
            case 311103: self = .invalidCipherFailedToUploadFile(message: message)
            case 311120: self = .messageDlpFailedToSendMessage(message: message)
            case 330301: self = .momentsNoOfficialUserPermission(message: message)
            case 400003: self = .willOverflowAfterBindChat(message: message)
            case 400004: self = .willOverflowAfterAddMember(message: message)
            case 450001: self = .chatOnTimeDelMsgSettingAuthFail(message: message)
            case 500100: self = .myAiAlreadyInitSuccess(message: message)
            case 500101: self = .myAiAlreadyNewTopic(message: message)
            default: self = .unknownBusinessError(message: message)
            }
        }
    }
}

// MARK: - CustomStringConvertible

extension APIError: CustomStringConvertible {
    public var description: String {
        var errorMessage = "code: \(self.errorCode), type: \(self.type)"
        if !self.displayMessage.isEmpty {
            errorMessage += ", displayMessage: \(self.displayMessage)"
        }
        if !self.serverMessage.isEmpty,
            self.serverMessage != self.displayMessage {
            errorMessage += ", serverMessage: \(self.serverMessage)"
        }
        return errorMessage
    }
}

extension APIError.TypeEnum: CustomStringConvertible {
    public var description: String {
        switch self {
        case .resetContactTokenQuick:
            return "刷新二维码过快"
        case .transformFailure(let message):
            return "有数据但是无法转换, \(message)"
        case .entityIncompleteData(let message):
            return "Entity中的数据不全: \(message)"
        case .noResourcesInServerResponse:
            return "服务器返回结果中没有Resources数据"
        case .readStatusIncompleteData(let message):
            return "Rust返回ReadStatus数据不全: \(message)"
        case .qrcodeStatusUnusual(let message):
            return "\(message)"
        case .prepareSendMessageFailure(let message):
            return "发消息前的错误: \(message)"
        case .messagePackTypeNotSupport(let type):
            return "不支持该类型\(type)消息的AggregateMessagePacker"
        case .unknowError:
            return "未知错误"
        case .unknownBusinessError(let message):
            return message
        case .noPermission:
            return "无权限，未明确归类的无权限错误"
        case .notAddMemberPermission:
            return "不在Chat里面，不能增加群成员"
        case .addUserToP2pChat:
            return "不能在P2p chat中增加成员"
        case .noDeleteMemberPermission:
            return "不在Chat里面，不能删除群成员"
        case .onlyGroupChatCanChangeName:
            return "只有GroupChat可以修改群名称"
        case .changeForzenChatName:
            return "归档的Chat不能够再修改群名称"
        case .noChangeChatNamePermission:
            return "不在Chat中不能够修改群名称"
        case .noPullMemberListPermission:
            return "不在Chat中不能拉取群成员列表"
        case .noPullMessagePermission:
            return "不在Chat中不能拉取消息"
        case .sendMessageInForzenChat:
            return "Chat被删除或者归档，不能再发送消息"
        case .notInSameOrganization:
            return "不在同一个组织"
        case .chatShareMessageExpired:
            return "群分享已过期"
        case .hadJoinedChat:
            return "通过群分享加入一个已经加入的群"
        case .chatMemberHadFull(message: let message):
            return message
        case .transferGroupOwnerFailed:
            return "群主转让失败"
        case .onlyAdminCanAddMemer:
            return "因群主设置“仅群主可添加”导致的加人失败"
        case .chatNotSupportShare:
            return "群主设置了“群不可被分享”导致分享失败"
        case .messageRecallOverTime:
            return "消息超过时间限制, 撤回失败"
        case .reserved:
            return "预留错误"
        case .redPacketZeroLeft(message: let message):
            return message
        case .redPacketGrabbedAlready(message: let message):
            return message
        case .redPacketOverDue(message: let message):
            return message
        case .cjPayAccountNeedUpgrade(message: let message):
            return message
        case .p2pChatWithoutSelf:
            return "p2p Chat应该包括创建者自己"
        case .p2pChatWithMultipleMember:
            return "创建p2p Chat时不应该传入两个以上的User"
        case .wrongChatType:
            return "错误的会话类型"
        case .chatNotExist:
            return "没能根据ChatId找到对应的Chat"
        case .chatDescriptionTooLong:
            return "群描述长度超出限制"
        case .updateAvatarFailed:
            return "群头像更新失败"
        case .messageTooLarge:
            return "消息内容大小超过限制"
        case .internalGroupNotSupportExternalMemberJoin(message: let message):
            return message
        case .userHadJoined:
            return "用户已经在群中，重复的加群请求"
        case .noMessagePermission:
            return "已经不是联系人，无法发送消息"
        case .sdkReserved:
            return "Rust-sdk reserved error，please contact rust-sdk team members"
        case .unauthorized:
            return "未认证"
        case .noAccessAuthentication:
            return "没权限访问.(资源授权失败。比如，你不在某个Chat里，去下载 chat 里的文件)"
        case .dirPathIsFolder:
            return "路径是文件夹.(创建文件类型假消息返回)"
        case .fetchVerifyCodeFailed:
            return "获取验证码失败.(直接取 LarkError中的message展示)"
        case .resourceNotFound:
            return "未找到资源.(没有找到资源。比如使用一个无效的key，来下载文件)"
        case .resourceHasBeenRemoved:
            return "资源已被删除.(资源被删除，不再可用)"
        case .checkVerifyCodeFailed:
            return "服务端验证短信验证码失败"
        case .remoteRequestTimeout:
            return "请求服务端数据超时"
        case .encrypCallNotSupport:
            return "不支持加密通话，请升级"
        case .internalRustClientError:
            return "RustClient内部错误"
        case .networkIsNotAvailable:
            return "网络不可用"
        case .noApplyPermission:
            return "对方设置隐私设置，无法添加联系人"
        case .mobileFormatIncorrect:
            return "手机号码格式错误"
        case .emailFormatIncorrect:
            return "邮箱格式错误"
        case .groupQRCodeExpired:
            return "群二维码已过期"
        case .groupOrSharerDismiss:
            return "群已解散或者二维码分享者已退群"
        case .announcementAPIInvalid:
            return "修改群公告接口已失效，请升级"
        case .banned:
            return "群主已开启仅群主或特定成员可发言"
        case .groupChatDissolved(message: let message):
            return message
        case .requestOverFrequency(message: let message):
            return message
        case .invalidFaceToFaceToken(message: let message):
            return message
        case .invalidMedia(message: let message):
            return message
        case .createGroupFailed(message: let message):
            return message
        case .createGroupSigleLetterFailed(message: let message):
            return message
        case .noSecretChatPermission(message: let message):
            return message
        case .urgentLimited(message: let message):
            return message
        case .chatMemberHadFullForPay(let messgae):
            return messgae
        case .chatMemberHadFullForCertificationTenant(let messgae):
            return messgae
        case .newVersionFeature(let message),
             .addMemberFailedWithApprove(let message),
             .appreveDisable(let message):
            return message
        case .notUrgetToAllWhoIsExecutive(let message):
            return message
        case .notUrgetToPartWhoIsExecutive(let message):
            return message
        case .notDeleteThreadWhenOverTime(let message):
            return message
        case .noSecretChatUrgentPermission(let message):
            return message
        case .withdrawPermissionExpired(let message):
            return message
        case .forbidWithdrawGroupOwner(let message):
            return message
        case .joinTokenNotSet(let message):
            return message
        case .forbidDisbaleShareChat(let message):
            return message
        case .topicHasClosed(let message):
            return message
        case .forwardThreadTooLargeFail(let message):
            return message
        case .createAnonymousMessageSettingClose(let message):
            return message
        case .createAnonymousMessageNoMore(let message):
            return message
        case .editMessageNotInValidTime(let message):
            return message
        case .forwardThreadReachLimit(let message):
            return message
        case .recognitionWithEmptyResult:
            return "语音识别结果为空"
        case .illegalContent(let message):
            return message
        case .forbidSetName(let messge):
            return messge
        case .sensitiveUserName(let messge):
            return messge
        case .forbidPutP2PChat(let message):
            return message
        case .forbidPutP2PChats(let message):
            return message
        case .forbidPutUrgent(let message):
            return message
        case .cloudDiskFull:
            return "达到租户资源上限"
        case .collaborationAuthFailedBlocked(let message):
            return message
        case .collaborationAuthFailedBeBlocked(let message):
            return message
        case .collaborationAuthFailedNoRights(let message):
            return message
        case .collaborationNoSendMessageToMyAi(let message):
            return message
        case .staticResourceFrozenByAdmin(message: let message):
            return message
        case .staticResourceShreddedByAdmin(message: let message):
            return message
        case .staticResourceDeletedByAdmin(message: let message):
            return message
        case .securityControlDeny(message: let message):
            return message
        case .strategyControlDeny(message: let message):
            return message
        case .externalCoordinateCtl(message: let message):
            return message
        case .targetExternalCoordinateCtl(message: let message):
            return message
        case .storageSpaceReachedLimit(message: let message):
            return message
        case .addChatChatterApplyAreadyProcessed(message: let message):
            return message
        case .linkAddNonCertifiedTenantRefuse(message: let message):
            return message
        case .qrCodeAddNonCertifiedTenantRefuse(message: let message):
            return message
        case .shareCardAddNonCertifiedTenantRefuse(message: let message):
            return message
        case .noFileSharePermission(message: let message):
            return message
        case .willOverflowAfterAddMember(message: let message):
            return message
        case .willOverflowAfterBindChat(message: let message):
            return message
        case .invalidCipherFailedToSendMessage(message: let message):
            return message
        case .invalidCipherFailedToUploadFile(message: let message):
            return message
        case .messageDlpFailedToSendMessage(message: let message):
            return message
        case .momentsNoOfficialUserPermission(message: let message):
            return message
        case .chatOnTimeDelMsgSettingAuthFail(message: let message):
            return message
        case .myAiAlreadyInitSuccess(message: let message):
            return message
        case .myAiAlreadyNewTopic(message: let message):
            return message
        case .clientErrorRiskFileDisableDownload:
            return "风险管控文件不可下载"
        }
    }
}

// MARK: - CustomDebugStringConvertible

extension APIError: CustomDebugStringConvertible {
    public var debugDescription: String {
        return self.description
    }
}

extension APIError.TypeEnum: CustomDebugStringConvertible {
    public var debugDescription: String {
        return self.description
    }
}

// MARK: - LocalizedError

extension APIError: LocalizedError {}

extension Error {
    public func transformToAPIError() -> Error {
        if self is APIError {
            return self
        }
        return self.asWrappedError().push({ (error) -> Error in
            guard let err = error as? RCError else {
                return APIError(type: .unknowError)
            }
            switch err {
            case .businessFailure(let errorInfo):
                return APIError(
                    code: errorInfo.code,
                    errorCode: errorInfo.errorCode,
                    status: errorInfo.errorStatus,
                    displayMessage: errorInfo.displayMessage,
                    serverMessage: errorInfo.serverMessage,
                    debugMessage: errorInfo.debugMessage,
                    extraString: errorInfo.errorExtra
                )
            default:
                return APIError(type: .internalRustClientError)
            }
        })
    }
}

@available(*, deprecated, message: "Use UniverseDesignToast")
extension RoundedHUD {

    @discardableResult
    public class func showFailure(with text: String, on view: UIView, error: Error) -> RoundedHUD {
        let errorMessage = RoundedHUD.errorMessage(with: text, error: error)
        return RoundedHUD.showFailure(with: errorMessage, on: view)
    }

    @discardableResult
    public class func showFailureIfNeeded(on view: UIView, error: Error) -> RoundedHUD? {
        if let apiError = error.underlyingError as? APIError {
            if !apiError.serverMessage.isEmpty {
                return RoundedHUD.showFailure(with: apiError.serverMessage, on: view)
            } else if !apiError.displayMessage.isEmpty {
                return RoundedHUD.showFailure(with: apiError.displayMessage, on: view)
            }
        }
        return nil
    }

    public func showFailure(with text: String, on view: UIView, error: Error) {
        let errorMessage = RoundedHUD.errorMessage(with: text, error: error)
        self.showFailure(with: errorMessage, on: view)
    }

    private static func errorMessage(with text: String, error: Error) -> String {
        if let apiError = error.underlyingError as? APIError {
            if !apiError.serverMessage.isEmpty {
                /// 开启 fg, 且可以取得 APIError serverMessage 不为空
                /// 使用服务器返回错误
                return apiError.serverMessage
            }
            if !apiError.displayMessage.isEmpty {
                return apiError.displayMessage
            }
        }
        return text
    }
}

extension UDToast {

    @discardableResult
    public class func showFailure(with text: String, on view: UIView, error: Error) -> UDToast {
        let errorMessage = UDToast.errorMessage(with: text, error: error)
        return UDToast.showFailure(with: errorMessage, on: view)
    }

    @discardableResult
    public class func showFailureIfNeeded(on view: UIView, error: Error) -> UDToast? {
        if let apiError = error.underlyingError as? APIError {
            if !apiError.serverMessage.isEmpty {
                return UDToast.showFailure(with: apiError.serverMessage, on: view)
            } else if !apiError.displayMessage.isEmpty {
                return UDToast.showFailure(with: apiError.displayMessage, on: view)
            }
        }
        return nil
    }

    public func showFailure(with text: String, on view: UIView, error: Error) {
        let errorMessage = UDToast.errorMessage(with: text, error: error)
        self.showFailure(with: errorMessage, on: view)
    }

    public static func errorMessage(with text: String, error: Error) -> String {
        if let apiError = error.underlyingError as? APIError {
            if !apiError.serverMessage.isEmpty {
                /// 开启 fg, 且可以取得 APIError serverMessage 不为空
                /// 使用服务器返回错误
                return apiError.serverMessage
            }
            if !apiError.displayMessage.isEmpty {
                return apiError.displayMessage
            }
        }
        return text
    }
}
// swiftlint:enable number_separator
