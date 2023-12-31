//
//  LynxViewModelFactory.swift.swift
//  LarkSearchCore
//
//  Created by sunyihe on 2022/6/29.
//

import UIKit
import Foundation
import ServerPB
import LKCommonsLogging
import Lynx
import EENavigator
import LarkContainer

/// LynxViewModel工厂
public struct LynxViewModelFactory {

    public init() {
    }

    public func createFullPageLynxViewModel(channelName: String,
                                            templateName: String,
                                            json: String,
                                            supportOrientations: UIInterfaceOrientationMask) -> FullPageLynxViewModel {
        return FullPageLynxViewModel(json: json,
                                     templateName: templateName,
                                     channelName: channelName,
                                     supportOrientations: supportOrientations)
    }

    // swiftlint:disable:next function_parameter_count
    public func createTopicViewModel(userResolver: UserResolver,
                                     cardId: String,
                                     json: String,
                                     templateName: String,
                                     vcSize: CGSize,
                                     scene: ServerPB_Enterprise_entitiy_GetEnterpriseTopicRequest.Scene,
                                     chatId: String?,
                                     msgId: String?,
                                     isSharing: Bool,
                                     supportOrientations: UIInterfaceOrientationMask,
                                     passThroughAction: ((String) -> Void)?,
                                     clientArgs: String?,
                                     analysisParams: String?,
                                     didTapApplink: ((URL) -> Void)?,
                                     completion: ((Data?) -> Void)?
    ) -> TopicLynxViewModel {
        return TopicLynxViewModel(userResolver: userResolver,
                                  cardId: cardId,
                                  json: json,
                                  templateName: templateName,
                                  vcSize: vcSize,
                                  scene: scene,
                                  chatId: chatId,
                                  msgId: msgId,
                                  isSharing: isSharing,
                                  supportOrientations: supportOrientations,
                                  passThroughAction: passThroughAction,
                                  clientArgs: clientArgs,
                                  analysisParams: analysisParams,
                                  didTapApplink: didTapApplink,
                                  completion: completion)
    }
}

public protocol LynxViewModelProtocol: AnyObject {

    ///卡片主体
    var json: String { get set }

    ///卡片名称
    var templateName: String { get set }

    var supportOrientations: UIInterfaceOrientationMask { get set }

    /// 加载模板。一些场景下可能需要更新数据，在这里实现
    func loadTemplate(lynxView: LynxView)

    /// 将FullPageVC赋给自己，因为Dependency里可能需要使用
    func loadHostVC(hostVC: UIViewController)
}

/// 用于通用场景下的LynxViewModel
final public class FullPageLynxViewModel: LynxViewModelProtocol {
    public var json: String
    public var templateName: String
    public var channelName: String
    public var supportOrientations: UIInterfaceOrientationMask

    public weak var hostVC: UIViewController?

    public init(json: String,
                templateName: String,
                channelName: String,
                supportOrientations: UIInterfaceOrientationMask) {
        self.json = json
        self.templateName = templateName
        self.channelName = channelName
        self.supportOrientations = supportOrientations
    }

    public func loadHostVC(hostVC: UIViewController) {
        self.hostVC = hostVC
    }

    public func loadTemplate(lynxView: LynxView) {
        if var data = LynxTemplateData(json: self.json) {
            ASTemplateManager.loadTemplateWithData(templateName: templateName,
                                                   channel: channelName,
                                                   initData: data,
                                                   lynxView: lynxView,
                                                   resultCallback: nil)
        }
    }

    public func openShare(msgContent: String, title: String, callBack: @escaping LynxCallbackBlock) {}
}

/// 用于im&doc场景下的LynxViewModel
final public class TopicLynxViewModel: LynxViewModelProtocol {
    public var json: String
    public var templateName: String
    public let cardId: String
    public var chatId: String?
    public var msgId: String?
    public var isSharing: Bool
    public var vcSize: CGSize
    public let scene: ServerPB_Enterprise_entitiy_GetEnterpriseTopicRequest.Scene
    public var supportOrientations: UIInterfaceOrientationMask
    /// 用于老版iPad卡片，现已不再使用，暂时保留
    public weak var menuVC: UIViewController?
    public weak var hostVC: UIViewController?

    public var passThroughAction: ((String) -> Void)?
    /// doc下用于透传数据
    public var clientArgs: String?
    public var analysisParams: String?
    public var didTapApplink: ((URL) -> Void)?
    public let userResolver: UserResolver
    public var completion: ((Data?) -> Void)?

    public init(userResolver: UserResolver,
                cardId: String,
                json: String,
                templateName: String,
                vcSize: CGSize,
                scene: ServerPB_Enterprise_entitiy_GetEnterpriseTopicRequest.Scene,
                chatId: String?,
                msgId: String?,
                isSharing: Bool,
                supportOrientations: UIInterfaceOrientationMask,
                passThroughAction: ((String) -> Void)?,
                clientArgs: String?,
                analysisParams: String?,
                didTapApplink: ((URL) -> Void)?,
                completion: ((Data?) -> Void)?) {
        self.userResolver = userResolver
        self.json = json
        self.templateName = templateName
        self.cardId = cardId
        self.vcSize = vcSize
        self.scene = scene
        self.chatId = chatId
        self.msgId = msgId
        self.isSharing = isSharing
        self.supportOrientations = supportOrientations
        self.passThroughAction = passThroughAction
        self.analysisParams = analysisParams
        self.clientArgs = clientArgs
        self.didTapApplink = didTapApplink
        if enablePostTrack() {
            self.completion = completion
        }
    }

    private func enablePostTrack() -> Bool {
        return SearchRemoteSettings.shared.enablePostStableTracker
    }
    public func loadHostVC(hostVC: UIViewController) {
        self.hostVC = hostVC
    }

    public func loadTemplate(lynxView: LynxView) {
        if var data = LynxTemplateData(json: self.json) {
            if let analysisParams = self.analysisParams {
                if let analysisParamsData = analysisParams.data(using: .utf8),
                   let analysisParamsJson = try? JSONSerialization.jsonObject(with: analysisParamsData) as? [String: Any] {
                    let params = ["analysisParams": analysisParamsJson]
                    if let jsonData = try? JSONSerialization.data(withJSONObject: params),
                       let dataString = String(data: jsonData, encoding: String.Encoding.utf8) {
                        data.update(dataString, forKey: "ClientArgs")
                    }
                }
            }
            if let clientArgs = self.clientArgs {
                data.update(clientArgs, forKey: "ClientArgs")
            }
            ASTemplateManager.loadTemplateWithData(templateName: templateName,
                                                   channel: ASTemplateManager.EnterpriseWordChannel,
                                                   initData: data,
                                                   lynxView: lynxView,
                                                   resultCallback: (enablePostTrack() ? completion : nil))
        }
    }

    // doc忽略词条
    public func sendCardActionPassThrough(jsonString: String) {
        passThroughAction?(jsonString)
    }
}
