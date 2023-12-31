//
//  MessageActionHandler.swift
//  LarkOpenPlatform
//
//  Created by lilun.ios on 2020/9/14.
//

import EENavigator
import RxSwift
import SwiftyJSON
import LKCommonsLogging
import LKCommonsTracker
import RoundedHUD
import LarkMessengerInterface
import LarkAppLinkSDK
import Swinject
import LarkSDKInterface
import LarkOPInterface
import LarkAccountInterface
import LarkModel
import LarkContainer

/// 按照参数进入导索页面
class MessageActionHandler: NSObject {
    private static let logger = Logger.log(AppNotSupportHandler.self,
                                           category: "MessageActionHandler")
    static let unknownMessageType: Int = 0
    static let keyChatID = "chatid"
    static let keyTargetList = "list"
    static let messageActionInfo = "message_action_info"
    static let keyTargetListKeyboard = "keyboard_action"
    static let keyTargetMessageAction = "message_action"
    private let bag = DisposeBag()
    func handle(appLink: AppLink, resolver: UserResolver) {
        MessageActionHandler.logger.info("MessageActionHandler handle start url \(appLink.url)")
        var queryParameters: [String: String] = [:]
        if let components = URLComponents(url: appLink.url, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems {
            for queryItem in queryItems {
                queryParameters[queryItem.name] = queryItem.value
            }
        }
        guard let listAction = queryParameters[MessageActionHandler.keyTargetList] else {
            MessageActionHandler.logger.error("MessageActionHandler handle applink no listAction \(queryParameters)")
            OPMonitor(AppLinkMonitorCode.invalidApplink)
                .setAppLink(appLink)
                .flush()
            return
        }
        /// Message Action
        if listAction == MessageActionHandler.keyTargetMessageAction {
            guard let messageActionInfoEncode = queryParameters[MessageActionHandler.messageActionInfo] else {
                let errorMsg = "MessageActionHandler handle applink no messageActionInfo"
                MessageActionHandler.logger.error(errorMsg)
                reportMsgActionOpen(errMsg: errorMsg)
                return
            }
            guard let messageActionInfo = messageActionInfoEncode.removingPercentEncoding else {
                let errorMsg = "MessageActionHandler handle messageActionInfo can't decode \(messageActionInfoEncode)"
                MessageActionHandler.logger.error(errorMsg)
                reportMsgActionOpen(errMsg: errorMsg)
                return
            }
            let messageActionJson = JSON(parseJSON: messageActionInfo)
            guard let isMultiSelect = messageActionJson["isMultiSelect"].bool,
                  let messageIds = messageActionJson["messageIds"].arrayObject as? [String],
                  let chatId = messageActionJson["chatId"].string else {
                let errorMsg = "MessageActionHandler handle messageActionInfo can't decode \(messageActionInfoEncode)"
                MessageActionHandler.logger.error(errorMsg)
                reportMsgActionOpen(errMsg: errorMsg)
                return
            }
            H5Applink.logger.info("MessageActionHandler handle applink message action \(messageActionInfo)")
            openMessageActionList(isMultiSelect: isMultiSelect, messageIds: messageIds, chatId: chatId, resolver: resolver)
            reportMsgActionOpen(errMsg: nil)
        }
    }
    /// 上报打开Message Action
    private func reportMsgActionOpen(errMsg: String?) {
        let openMsgAction = OPMonitor(EPMJsOpenPlatformGadgetAppMsgActionCode.message_action_event)
        if let _err = errMsg {
            openMsgAction
                .addCategoryValue(MessageActionPlusMenuDefines.monitorKeyOpenMsgActionFailReason, _err)
                .setResultTypeFail()
                .flush()
        } else {
            openMsgAction
                .setResultTypeSuccess()
                .flush()
        }
    }
    private func openMessageActionList(isMultiSelect: Bool,
                                       messageIds: [String],
                                       chatId: String,
                                       resolver: UserResolver) {
        let userID = resolver.userID
        let context = MessageActionContextItem(chatId: chatId,
                                               messageIds: messageIds,
                                               user: userID,
                                               ttCode: "")
        MessageCardSession.shared().recordOpenMessageAction(context: context)
        let pageIndexVC = MoreAppListViewController(resolver: resolver,
                                                       bizScene: .msgAction,
                                                       fromScene: .message_action,
                                                       chatId: chatId,
                                                       actionContext: context) {
        } openAvailableApp: { (_, _) -> Bool in
            return false
        }
        if let fromVC = Navigator.shared.mainSceneWindow?.fromViewController {
            resolver.navigator.push(pageIndexVC, from: fromVC)
        } else {
            H5Applink.logger.error("openMessageActionList handle applink can not push vc because no fromViewController")
        }
        reportOpenMessageAction(resolver: resolver,
                                messageIds: messageIds,
                                bag: pageIndexVC.disposeBag)
    }
    /// 上报点击message action
    private func reportOpenMessageAction(resolver: UserResolver,
                                         messageIds: [String],
                                         bag: DisposeBag) {
        guard let messageService: MessageContentService = try? resolver.resolve(assert: MessageContentService.self) else {
            Self.logger.error("MessageActionHandler: messageService is nil")
            return
        }
        messageService.getMessageContent(messageIds: messageIds)?
            .subscribe(onNext: { (messageMap) in
                let typeArray = messageIds.map { [](messageId) -> Int in
                    return (messageMap[messageId]?.type ?? .unknown).rawValue
                }
                let params = [ParamKey.message_type: typeArray.description]
                TeaReporter(eventKey: TeaReporter.key_action_click_more)
                    .withUserInfo(resolver: resolver)
                    .withInfo(params: params)
                    .report()
            }).disposed(by: bag)
    }
    
    deinit {
        MessageActionHandler.logger.info("messageActionHandler deinit")
    }
}
