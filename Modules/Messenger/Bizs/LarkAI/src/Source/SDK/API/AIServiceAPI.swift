//
//  AIServiceAPI.swift
//  LarkSDKInterface
//
//  Created by bytedance on 2020/7/14.
//

import Foundation
import RxSwift
import LarkModel
import RustPB
import ServerPB
import LarkMessengerInterface

public protocol AIServiceAPI {
    /// 获取智能补全信息
    /// - Parameters:
    ///   - chatId: 会话id
    ///   - prefix: 输入的内容
    ///   - locale: 本地化设置 ex: 'en_US', 'zh_CN'
    ///   - scene:  触发场景 详见 SmartComposeScene
    func getSmartCompose(chatId: String, prefix: String, scene: SmartComposeScene) -> Observable<Ai_V1_GetSmartComposeResponse>

    /// 纠错信息
    func getSmartCorrect(chatID: String, texts: [String], scene: String) -> Observable<ServerPB_Correction_AIGetTextCorrectionResponse>
}
