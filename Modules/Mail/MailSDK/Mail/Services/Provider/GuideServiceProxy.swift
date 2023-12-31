//
//  GuideServiceProxy.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/8/27.
//

import Foundation
import LarkGuide
import RxRelay
import LarkAIInfra

public protocol GuideServiceProxy {
    var guideService: NewGuideService? { get }
}

public protocol MyAIServiceProxy {
    var isAIEnable: Bool { get }
    var aiNickName: String { get }
    var aiDefaultName: String { get }
    var aiNickNameRelay: BehaviorRelay<String>  { get }
    var chatModeAIImage: UIImage? { get }
    var needOnboarding: Bool { get }
    func launchChatMode(chatID: Int64,
                        chatModeID: Int64,
                        mailContent: String?,
                        isTrim: Bool?,
                        accountId: String,
                        bizIds: String,
                        labelId: String,
                        openRag: Bool,
                        callback: ((MyAIChatModeConfig.PageService) -> Void)?)
    func openAIOnboarding(vc: UIViewController,
                          onSuccess: ((_ chatId: Int64) -> Void)?,
                          onError: ((_ error: Error?) -> Void)?,
                          onCancel: (() -> Void)?)
}
