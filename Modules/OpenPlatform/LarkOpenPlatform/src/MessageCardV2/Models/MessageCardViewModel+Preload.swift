//
//  MessageCardViewModel+Preload.swift
//  LarkOpenPlatform
//
//  Created by zhangjie.alonso on 2023/1/10.
//

import Foundation
#if MeegoMod
import LarkMeegoInterface
#endif
import LarkModel
import LKCommonsLogging
import LarkMessageBase

// MARK: 生命周期业务预加载
extension MessageCardViewModel {
    
    func setupBizsEnv(message: LarkModel.Message) {
        DispatchQueue.global().async { [weak self] in
            self?.setupMeegoEnvIfNeed(message: message)
            self?.preLoadMicroAppIfNeed(message: message)
        }
    }
    
    fileprivate func preLoadMicroAppIfNeed(message: LarkModel.Message) {
        if let content = message.content as? CardContent,
           content.extraInfo.gadgetConfig.isPreload,
           content.extraInfo.gadgetConfig.cliIds.count > 0 {
            let cliIds =  content.extraInfo.gadgetConfig.cliIds
            handleGadgetCardExposed(appIds: cliIds)
        }
    }
    
    fileprivate func handleGadgetCardExposed(appIds: [String]) {
        // todo 小程序预加载接口，需要要异步延迟加载
        logger.info("preload microApp messageID: \(message.id)  app_ids: \(appIds)")
        // 按理应该感知具体的scene是哪个，但这里还在数据处理阶段，而真实的scene是跟点击区域有关的，因此在这里只能把潜在的scene都传过去
        //1007    从单人聊天会话中小程序消息卡片打开        移动端&PC端
        //1008    从多人聊天会话中小程序消息卡片打开        移动端&PC端
        //1009    从单人聊天会话里消息中链接或者按钮打开     移动端&PC端
        //1010    从多人聊天会话里消息中链接或者按钮打开     移动端&PC端
        //1511    消息卡片末尾应用标识链接打开小程序        移动端&PC端
        //https://open.feishu.cn/document/uYjL24iN/uQzMzUjL0MzM14CNzMTN
         NotificationCenter.default.post(name: NSNotification.Name(rawValue: "kGadgetPreRunNotificationName"),
                                         object: nil,
                                         userInfo: ["appid": appIds.last,"scenes":[1007,1009,1008,1010,1511]])
    }
    
    private func setupMeegoEnvIfNeed(message: LarkModel.Message) {
        #if MeegoMod
        guard let content = message.content as? LarkModel.CardContent else {
            logger.error("Unexpected message.content type\(message.content.self)")
            return
        }
        guard content.extraInfo.hasMeegoConfig && content.extraInfo.meegoConfig.hasIsPreload && content.extraInfo.meegoConfig.isPreload else {
            logger.info("meegoConfig is nil or isPreload is false")
            return
        }
        logger.info("Card: \(message.id) setupMeegoEnv")
        let meegoService = (self.context as? PageContext)?.resolver.resolve(LarkMeegoService.self)
        meegoService?.handleMeegoCardExposed(message: message)
        #endif
    }
}
