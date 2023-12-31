//
//  KeyboardPanelVoiceSubModule.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/4/6.
//

import UIKit
import LarkOpenKeyboard
import LarkKeyboardView
import LarkOpenIM
import LarkFoundation
/**
 larkAudio组件不够纯净，会依赖Message的一些组件。比如：LarkAccountInterface, LarkMessengerInterface 等
 larkAudio的一些回调 AudioDataInfo 在larkSendMessage(无法依赖)中
 func audiokeybordSendMessage(_ audioData: AudioDataInfo)
 */

open class KeyboardPanelVoiceSubModule<C:KeyboardContext, M:KeyboardMetaModel>: BaseKeyboardPanelDefaultSubModule<C, M> {

    open override var panelItemKey: KeyboardItemKey {
        return .voice
    }

    open override func canHandle(model: M) -> Bool {
        return !Utils.isiOSAppOnMacSystem
    }

    open func handleAudioKeyboardAppear() {
        return self.context.keyboardAppearForSelectedPanel(item: KeyboardItemKey.voice)
    }

    open func audiokeyboardRecordIndicatorShowIn() -> UIViewController? {
        return self.context.displayVC.navigationController ?? self.context.displayVC
    }
}
