//
//  NewAudioKeyboardContainer.swift
//  LarkAudio
//
//  Created by kangkang on 2023/9/14.
//

import Foundation
import LarkContainer
import LarkBaseKeyboard
import LarkKeyboardView

extension LarkBaseKeyboard.LarkKeyboard {
    final class CreateAudioConfig {
        // 键盘将要出现的时机
        let keyboardAppearCallback: () -> Void
        // 权限不通过，并且不是第一次鉴权（在设置中手动关了）会提示用户跳转设置打开
        let checkPermissionCallback: (Bool, Bool) -> Void
        // 点击时机
        let tappedBlock: () -> Void
        let audioToTextView: (AudioToTextViewStopDelegate?) -> Void
        init(keyboardAppearCallback: @escaping () -> Void,
             checkPermissionCallback: @escaping (Bool, Bool) -> Void,
             audioToTextView: @escaping (AudioToTextViewStopDelegate?) -> Void,
             tappedBlock: @escaping () -> Void) {
            self.keyboardAppearCallback = keyboardAppearCallback
            self.tappedBlock = tappedBlock
            self.checkPermissionCallback = checkPermissionCallback
            self.audioToTextView = audioToTextView
        }
    }

    static func createNewAudio(userResolver: UserResolver, audioVM: AudioContainerViewModel, config: CreateAudioConfig) -> InputKeyboardItem {
        let keyboardItem = keyboard(iconColor: audioVM.iconColor, recognizeEnable: audioVM.recognizeEnable, audioWithTextEnable: audioVM.audioWithTextEnable)

        let checkPermissionBlock: (@escaping (_ allow: Bool, _ firstTime: Bool) -> Void) -> Void = { callback  in
            var firstTime = false
            (try? userResolver.resolve(assert: AudioRecordManager.self))?.checkPermissionAndSetupRecord { (allow) in
                let isFirstTime = firstTime
                callback(allow, isFirstTime)
            }
            firstTime = true
        }

        let keyboardViewBlock = { () -> UIView in
            var viewItems: [AudioKeyboardItemViewDelegate] = []
            var vmItems: [(KeyboardProvider, RecognizeLanguageManager.RecognizeType)] = []

            // 语音加文字
            if audioVM.audioWithTextEnable {
                let vm = AudioAndTextViewModel(userResolver: userResolver, chatID: audioVM.chat.id, keyboard: audioVM.keyboard)
                let audioAndTextView = NewAudioAndTextView(userResolver: userResolver, vm: vm, chatName: audioVM.chat.name, openType: .tapPanel)
                viewItems.append(audioAndTextView)
                vmItems.append((vm, .audioWithText))
            }

            // 录音
            let recordVM = RecordViewModel(userResolver: userResolver, supportStreamUpLoad: audioVM.supportStreamUpLoad, chatID: audioVM.chat.id, keyboard: audioVM.keyboard)
            let recordView = NewRecordView(userResolver: userResolver, vm: recordVM, openType: .tapPanel)
            viewItems.append(recordView)
            vmItems.append((recordVM, .audio))

            // 语音转文字
            if audioVM.recognizeEnable {
                let audioToTextVM = AudioToTextViewModel(userResolver: userResolver, chat: audioVM.chat, keyboard: audioVM.keyboard)
                let audioToTextView = NewAudioToTextView(userResolver: userResolver, vm: audioToTextVM, openType: .tapPanel)
                viewItems.append(audioToTextView)
                vmItems.append((audioToTextVM, .text))
            }

            audioVM.viewModels = vmItems
            let pageView = ContainerPageView(items: viewItems)
            pageView.keyboardHeight = keyboardItem.height
            return pageView
        }

        let longPressBlock = { (gesture: UILongPressGestureRecognizer) in
            AudioContainerViewModel.logger.info("long press block, type: \(RecognizeLanguageManager.shared.recognitionType)")
            let audioWithTextBlock = {
                let audioAndTextVM = AudioAndTextViewModel(userResolver: userResolver, chatID: audioVM.chat.id, keyboard: audioVM.keyboard)
                let view = NewAudioAndTextView(userResolver: userResolver, vm: audioAndTextVM, chatName: audioVM.chat.name, openType: .pressPanel(gesture))
                AudioContainerViewModel.logger.info("long press audioWithText block \(view)")
            }
            let audioBlock = {
                let recordVM = RecordViewModel(userResolver: userResolver, supportStreamUpLoad: audioVM.supportStreamUpLoad, chatID: audioVM.chat.id, keyboard: audioVM.keyboard)
                let view = NewRecordView(userResolver: userResolver, vm: recordVM, openType: .pressPanel(gesture))
                AudioContainerViewModel.logger.info("long press audio block \(view)")
            }
            let audioToTextBlock = {
                let audioToTextVM = AudioToTextViewModel(userResolver: userResolver, chat: audioVM.chat, keyboard: audioVM.keyboard)
                let view = NewAudioToTextView(userResolver: userResolver, vm: audioToTextVM, openType: .pressPanel(gesture))
                AudioContainerViewModel.logger.info("long press audioToText block \(view)")
                config.audioToTextView(view)
            }
            switch RecognizeLanguageManager.shared.recognitionType {
            case .audioWithText:
                if audioVM.audioWithTextEnable {
                    audioWithTextBlock()
                } else {
                    audioBlock()
                }
            case .audio:
                audioBlock()
            case .text:
                if audioVM.recognizeEnable {
                   audioToTextBlock()
                } else {
                    audioBlock()
                }
            }
        }

        let tapHandler: (KeyboardPanelEvent) -> Void = { event in
            switch event.type {
            case .tap:
                config.tappedBlock()
                event.keyboardSelect()
            case .longPress:
                AudioContainerViewModel.logger.info("long press begin")
                checkPermissionBlock { (allow: Bool, firstTime: Bool) in
                    config.checkPermissionCallback(allow, firstTime)
                    let from = audioVM.keyboard?.audiokeybordPanelView()
                    AudioContainerViewModel.logger.info("check permission: \(allow) \(firstTime)")
                    if allow, !firstTime, AudioUtils.checkCallingState(userResolver: userResolver, from: from?.window),
                       AudioUtils.checkByteViewState(userResolver: userResolver, from: from?.window),
                       (RecognizeLanguageManager.shared.recognitionType == .text ? AudioUtils.checkNetworkConnection(view: from) : true),
                       let longPress = event.button.gestureRecognizers?.compactMap({ (gesture) -> UILongPressGestureRecognizer? in
                           guard let longPress = gesture as? UILongPressGestureRecognizer else { return nil }
                           return longPress
                       }).first {
                        longPressBlock(longPress)
                    }
                }
            default: break
            }
        }

        let selectedAction = { () -> Bool in
            var result = false
            checkPermissionBlock { (allow: Bool, firstTime: Bool) in
                config.checkPermissionCallback(allow, firstTime)
                result = allow
            }
            if result {
                config.keyboardAppearCallback()
            }
            return result
        }

        return InputKeyboardItem(
            key: KeyboardItemKey.voice.rawValue,
            keyboardViewBlock: keyboardViewBlock,
            keyboardHeightBlock: { keyboardItem.height },
            keyboardIcon: keyboardItem.icons,
            onTapped: tapHandler,
            selectedAction: selectedAction
        )
    }

    public static func keyboard(iconColor: UIColor?, recognizeEnable: Bool, audioWithTextEnable: Bool) -> KeyboardInfo {
        let tintColor: UIColor = iconColor ?? UIColor.ud.N500
        lazy var audioWithText = KeyboardInfo(icon: Resources.new_voice_with_text_icon, selectedIcon: Resources.new_voice_with_text_icon_select, unenableIcon: nil, tintColor: tintColor)
        lazy var audio = KeyboardInfo(icon: Resources.voice_bottombar, selectedIcon: Resources.voice_bottombar_selected, unenableIcon: nil, tintColor: tintColor)
        lazy var text = KeyboardInfo(icon: Resources.voice_text_icon, selectedIcon: Resources.voice_text_icon_select, unenableIcon: nil, tintColor: tintColor)
        switch RecognizeLanguageManager.shared.recognitionType {
        case .audioWithText:
            if audioWithTextEnable {
                return audioWithText
            } else {
                return audio
            }
        case .audio:
            return audio
        case .text:
            if recognizeEnable {
                return text
            } else {
                return audio
            }
        }
     }
}
