//
//  EmojiPanelResouceTask.swift
//  LarkEmotionKeyboard
//
//  Created by JackZhao on 2022/3/11.
//

import LarkEnv
import Foundation
import BootManager
import LarkContainer

// 拉取表情和Reaction面板上的各类表情
public final class EmojiPanelResouceTask: UserFlowBootTask, Identifiable {

    public override class var compatibleMode: Bool { EmotionKeyboardSetting.userScopeCompatibleMode }

    public static var identify = "EmojiPanelResouceTask"
    // 同时加载&拉取远端表情分类：最近使用+最常使用+默认分类+企业自定义+LarkValues
    public override func execute(_ context: BootContext) {
        let reactionService = EmojiImageService.default
        reactionService?.loadReactions()
    }
}
