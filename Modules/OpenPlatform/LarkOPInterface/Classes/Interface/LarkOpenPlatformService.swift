//
//  OpenPlatformService.swift
//  LarkOPInterface
//
//  Created by bytedance on 2022/9/14.
//

import Foundation
import LarkModel
import RxSwift
import SwiftyJSON
import RustPB
import LarkOpenAPIModel

public protocol KeyBoardItemProtocol {
    var icon: UIImage { get }
    var selectIcon: UIImage? { get }
    var tapped: () -> Void { get set }
    var text: String { get }
    var priority: Int { get }
    var badge: String? { get }
    /// 是否显示红点
    var isShowDot: Bool { get }
    var customViewBlock: ((UIView) -> Void)? { get }
}

public struct SendMessagecardChooseChatModel {
    public let allowCreateGroup: Bool
    public let multiSelect: Bool
    public let confirmTitle: String
    public let externalChat: Bool
    public let withText: Bool
    public let selectType: SelectType
    public let ignoreSelf: Bool
    public let ignoreBot: Bool
    
    
    public init(
        allowCreateGroup: Bool,
        multiSelect: Bool,
        confirmTitle: String,
        externalChat: Bool,
        withText: Bool,
        selectType: SelectType,
        ignoreSelf: Bool,
        ignoreBot: Bool
    ) {
        self.allowCreateGroup = allowCreateGroup
        self.multiSelect = multiSelect
        self.confirmTitle = confirmTitle
        self.externalChat = externalChat
        self.withText = withText
        self.selectType = selectType
        self.ignoreSelf = ignoreSelf
        self.ignoreBot = ignoreBot
    }
}

public enum SelectType: Int {
    case all = 0     //全部
    case group = 1   //群聊
    case user = 2   //单聊
}

//  原作者：tujinqiu msg：小程序发送消息卡片
public enum SendMessageCardErrorCode {
    case noError
    case cardContentFormatError
    case sendFailed
    case userCancel
    case otherError
    case sendTextError
}

/// _ sendTextInfo: [EMASendCardAditionalTextInfo]
public typealias SendMessageCardCallBack = ((_ errCode: SendMessageCardErrorCode,
                                              _ errMsg: String?,
                                              _ failedChatIDs: [String]?,
                                              _ sendCardInfo: [EMASendCardInfo]?,
                                              _ sendTextInfo: [EMASendCardAditionalTextInfo]?) -> Void)

public protocol OpenPlatformService {
    
    /// +号菜单获取小程序列表
    func getKeyBoardApps(chat: Chat, chatViewController: UIViewController?) -> Observable<[KeyBoardItemProtocol]>?
    
    /// 执行take action
    func takeMessageActionV2(
        chatId: String,
        messageIds: [String],
        isMultiSelect: Bool,
        targetVC: UIViewController)
    
    /// h5, mini program get KA user info
    func getUserInfoEx(onSuccess: @escaping ([String: Any]) -> Void, onFail: @escaping (Error) -> Void)
    
    /// return sha256(DeviceID + Salt) , Salt = "littleapp"
    func getOpenPlatformDeviceID() -> String
    
    /// 消息卡片 - 点击 - url添加token - 进入其他地方
    func urlWithTriggerCode(_ sourceUrl: String, _ cardMsgID: String, _ callback: @escaping (String) -> Void)
    
    /// 开放平台初始化
    func setup()
    
    /// 打开bot
    func openBot(botId: String)
    
    /// 获取TriggerCode
    func getTriggerCode(callback: @escaping (String) -> Void)
    
    /// 添加TriggerCode到url中
    func urlAppendTriggerCode(_ sourceUrl: String, _ triggerCode: String, appendOnlyForMiniProgram: Bool) -> String?
    
    /// 获取Trigger上下文
    func getTriggerContext(
        withTriggerCode triggerCode: String,
        block: ((_ dict: [String: Any]?) -> Void)?
    )
    
    //构建分享的Applink链接
    func buildAppShareLink(with appId: String, opTracking: String) -> String
    
    /// 发送卡片
    func sendMessageCard(
        appID:String,
        fromWindow: UIWindow?,
        scene: String,
        triggerCode: String?,
        chatIDs: [String]?,
        cardContent: [AnyHashable: Any],
        withMessage: Bool,
        block: SendMessageCardCallBack?
    )
    
    func chooseChatAndSendMsgCard(
        appid: String,
        cardContent: [AnyHashable: Any],
        model: SendMessagecardChooseChatModel,
        withMessage: Bool,
        res: @escaping SendMessageCardCallBack
    )
    
    func getTriggerMessageIds(triggerCode: String) -> [String]?
    
    /// 查询Message Action中的消息内容 https://bytedance.feishu.cn/docs/doccnaSO7Huz3pAgz26hiWIFA3X#
    func getBlockActionDetail(appID: String,
                              triggerCode: String?,
                              extraInfo: [String: Any]?,
                              complete: @escaping ((Error?, OpenAPIErrnoProtocol?, [String: Any]) -> Void)
    )
    
    /// 打开会话
    func gotoChat(userID: String, fromVC: UIViewController?, completion: ((_ isSuccess: Bool) -> Void)?)
    
    //获得应用头像
    func fetchApplicationAvatarList(appVersion: String, accessToken: String) -> Observable<(Int?, JSON)>
    
    func fetchCardContent() -> LarkModel.CardContent?
    
    func canOpenDocs(url: String) -> Bool
}

public protocol OpenPlatformOuterService {
    func enterChat(chatId: String?, showBadge: Bool, window: UIWindow?)
    
    func enterProfile(userId: String?, window: UIWindow?)
    
    func enterBot(botId: String?, window: UIWindow?)
}
