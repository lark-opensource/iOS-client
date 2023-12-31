//
//  InMeetPresentationViewController+Press.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/11/2.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import ByteViewCommon

extension InMeetPresentationViewController {
    func registerKeyboardPresses() {
        // 所有键盘功能只允许在 iPad 上使用
        guard Display.pad else { return }
        let muteHandler = InMeetKeyboardMuteHandler(resolver: viewModel.resolver)
        if viewModel.meeting.setting.supportsKeyboardMute {
            // 长按空格取消静音
            keyboardRegistry.register(processor: muteHandler)
        }
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let press = presses.first else {
            super.pressesBegan(presses, with: event)
            return
        }

        var shouldPassThrough = true
        for processor in keyboardRegistry.processors {
            if processor.shouldHandle(press: press, stage: .begin) {
                shouldPassThrough = shouldPassThrough && processor.keyPressBegan(press)
            }
        }

        if shouldPassThrough {
            super.pressesBegan(presses, with: event)
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let press = presses.first else {
            super.pressesEnded(presses, with: event)
            return
        }

        var shouldPassThrough = true
        for processor in keyboardRegistry.processors {
            if processor.shouldHandle(press: press, stage: .end) {
                shouldPassThrough = shouldPassThrough && processor.keyPressEnded(press)
            }
        }

        if shouldPassThrough {
            super.pressesEnded(presses, with: event)
        }
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let press = presses.first else {
            super.pressesCancelled(presses, with: event)
            return
        }

        var shouldPassThrough = true
        for processor in keyboardRegistry.processors {
            if processor.shouldHandle(press: press, stage: .cancel) {
                shouldPassThrough = shouldPassThrough && processor.keyPressEnded(press)
            }
        }

        if shouldPassThrough {
            super.pressesCancelled(presses, with: event)
        }
    }
}
