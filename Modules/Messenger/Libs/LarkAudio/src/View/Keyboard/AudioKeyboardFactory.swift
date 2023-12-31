//
//  AudioKeyboardFactory.swift
//  LarkAudio
//
//  Created by 李晨 on 2019/7/24.
//

import UIKit
import LarkModel
import Foundation
import LarkCore
import LarkKeyboardView
import LarkUIKit
import UniverseDesignDialog
import EENavigator
import LarkBaseKeyboard
import LarkContainer
import LarkNavigator

public final class AudioKeyboardFactory {
    // swiftlint:disable function_parameter_count
    public static func createVoiceKeyboardItem(userResolver: UserResolver,
                                               chat: Chat,
                                               audioToTextEnable: Bool,
                                               audioWithTextEnable: Bool,
                                               supportStreamUpLoad: Bool,
                                               sendMessageDelegate: AudioSendMessageDelegate,
                                               helperDelegate: AudioKeyboardHelperDelegate,
                                               iconColor: UIColor,
                                               audioToTextView: @escaping (AudioToTextViewStopDelegate?) -> Void,
                                               recordPanel: (AudioRecordPanelProtocol?) -> Void,
                                               updateIconCallBack: (((UIImage?, UIImage?, UIImage?)) -> Void)?,
                                               tappedBlock: @escaping () -> Void) -> InputKeyboardItem {
        if userResolver.fg.staticFeatureGatingValue(with: "messenger.input.audio.improvements"),
           userResolver.fg.staticFeatureGatingValue(with: "messenger.new.audio.technology") {
            return AudioKeyboardFactory.createNewVoiceItem(
                userResolver: userResolver, audioVM: createAudioContainerViewModel(
                    recognizeEnable: audioToTextEnable, audioWithTextEnable: audioWithTextEnable, supportStreamUpLoad: supportStreamUpLoad, keyboard: sendMessageDelegate,
                    chat: chat, iconColor: iconColor, userResolver: userResolver, recordPanel: recordPanel, updateIconCallBack: updateIconCallBack),
                audioToTextView: audioToTextView, tappedBlock: tappedBlock)
        }
        if userResolver.fg.staticFeatureGatingValue(with: "messenger.input.audio.improvements") {
            return AudioKeyboardFactory.createVoice(
                userResolver: userResolver, iconColor, createAudioKeyboardNewHelper(
                    userResolver: userResolver, chat: chat, iconColor: iconColor, audioToTextEnable: audioToTextEnable, audioWithTextEnable: audioWithTextEnable, keyboard: helperDelegate,
                    recordPanel: recordPanel, updateIconCallBack: updateIconCallBack),
                supportStreamUpLoad, tappedBlock: tappedBlock)
        }
        return AudioKeyboardFactory.buildVoice(
            userResolver: userResolver, iconColor, createAudioKeyboardHelper(
                userResolver: userResolver, chat: chat, iconColor: iconColor, audioToTextEnable: audioToTextEnable, audioWithTextEnable: audioWithTextEnable, keyboard: helperDelegate,
                recordPanel: recordPanel, updateIconCallBack: updateIconCallBack),
            supportStreamUpLoad, tappedBlock: tappedBlock)
    }
    // swiftlint:enable function_parameter_count

    private static func createAudioContainerViewModel(recognizeEnable: Bool,
                                                      audioWithTextEnable: Bool,
                                                      supportStreamUpLoad: Bool,
                                                      keyboard: AudioSendMessageDelegate,
                                                      chat: Chat,
                                                      iconColor: UIColor,
                                                      userResolver: UserResolver,
                                                      recordPanel: (AudioRecordPanelProtocol?) -> Void,
                                                      updateIconCallBack: (((UIImage?, UIImage?, UIImage?)) -> Void)?) -> AudioContainerViewModel {
        let vm = AudioContainerViewModel(recognizeEnable: recognizeEnable, audioWithTextEnable: audioWithTextEnable,
                                         supportStreamUpLoad: supportStreamUpLoad, chat: chat, iconColor: iconColor,
                                         userResolver: userResolver, updateIconCallBack: updateIconCallBack)
        vm.keyboard = keyboard
        recordPanel(nil)
        return vm
    }

    private static func createAudioKeyboardHelper(userResolver: UserResolver,
                                                  chat: Chat,
                                                  iconColor: UIColor,
                                                  audioToTextEnable: Bool,
                                                  audioWithTextEnable: Bool,
                                                  keyboard: AudioKeyboardHelperDelegate,
                                                  recordPanel: (AudioRecordPanelProtocol) -> Void,
                                                  updateIconCallBack: (((UIImage?, UIImage?, UIImage?)) -> Void)?) -> AudioKeyboardHelper {
        let helper = AudioKeyboardHelper(userResolver: userResolver, chat: chat, audioToTextEnable: audioToTextEnable, audioWithTextEnable: audioWithTextEnable)
        helper.iconTintColor = iconColor
        helper.delegate = keyboard
        helper.updateIconCallBack = updateIconCallBack
        recordPanel(helper)
        return helper
    }

    private static func createAudioKeyboardNewHelper(userResolver: UserResolver,
                                                     chat: Chat,
                                                     iconColor: UIColor,
                                                     audioToTextEnable: Bool,
                                                     audioWithTextEnable: Bool,
                                                     keyboard: AudioKeyboardHelperDelegate,
                                                     recordPanel: (AudioRecordPanelProtocol) -> Void,
                                                     updateIconCallBack: (((UIImage?, UIImage?, UIImage?)) -> Void)?) -> NewAudioKeyboardHelper {
        let helper = NewAudioKeyboardHelper(userResolver: userResolver, chat: chat, audioToTextEnable: audioToTextEnable, audioWithTextEnable: audioWithTextEnable)
        helper.iconTintColor = iconColor
        helper.delegate = keyboard
        helper.updateIconCallBack = updateIconCallBack
        recordPanel(helper)
        return helper
    }

    public static func createNewVoiceItem(userResolver: UserResolver,
                                          audioVM: AudioContainerViewModel,
                                          audioToTextView: @escaping (AudioToTextViewStopDelegate?) -> Void,
                                          tappedBlock: @escaping () -> Void) -> InputKeyboardItem {
        let config = LarkKeyboard.CreateAudioConfig(
            keyboardAppearCallback: {
                audioVM.keyboard?.handleAudioKeyboardAppear()
                AudioKeyboardDataService.shared.fetchSpeechConfigData(userResolver: userResolver)
            }, checkPermissionCallback: { [weak audioVM] (allow, isFirstTime) in
                guard !allow, !isFirstTime else { return }
                guard let vc = audioVM?.keyboard?.audiokeyboardRecordIndicatorShowIn() else { return }
                DispatchQueue.main.async(execute: {
                    AudioKeyboardFactory.showAudioPermissionAlert(navigator: userResolver.navigator, rootVC: vc)
                })
            }, audioToTextView: audioToTextView, tappedBlock: tappedBlock)
        return LarkKeyboard.createNewAudio(userResolver: userResolver, audioVM: audioVM, config: config)
    }

    public static func createVoice(userResolver: UserResolver,
                                   _ iconColor: UIColor?,
                                   _ audioHelper: NewAudioKeyboardHelper,
                                   _ supportStreamUpLoad: Bool,
                                   tappedBlock: @escaping () -> Void) -> InputKeyboardItem {
        let config = LarkKeyboard.NewAudioGestureKeyboardConfig(
            userResolver: userResolver,
            supportRecognize: !audioHelper.chat.isCrypto && audioHelper.audioToTextEnable,
            audioWithTextEnable: !audioHelper.chat.isCrypto && audioHelper.audioWithTextEnable,
            iconColor: iconColor,
            recordDelegate: audioHelper,
            recognitionDelegate: audioHelper,
            recordGestureDelegate: audioHelper,
            recordTextDelegate: audioHelper,
            recognitionGestureDelegate: audioHelper,
            recordWithTextGestureDelegate: audioHelper,
            recognizeService: audioHelper.audioRecognizeService,
            uploadIdBlock: { [weak audioHelper] in
                guard let audioHelper = audioHelper else { return "" }

                if !supportStreamUpLoad {
                    return ""
                }
                return (try? audioHelper.resourceAPI?.fetchUploadID(
                    chatID: audioHelper.chat.id,
                    language: RecognizeLanguageManager.shared.recognitionLanguage
                )) ?? ""
            },
            checkPermissionCallback: { [weak audioHelper] (allow, isFirstTime) in
                if !allow && !isFirstTime {
                    DispatchQueue.main.async(execute: {
                        guard let audioHelper = audioHelper,
                            let rootVC = audioHelper.delegate?.audiokeyboardRecordIndicatorShowIn() else {
                                return
                        }
                        AudioKeyboardFactory.showAudioPermissionAlert(navigator: userResolver.navigator, rootVC: rootVC)
                    })
                }
            },
            keyboardAppearCallback: { [weak audioHelper] in
                audioHelper?.delegate?.handleAudioKeyboardAppear()
                AudioKeyboardDataService.shared.fetchSpeechConfigData(userResolver: userResolver)
            },
            setContainerBlock: { [weak audioHelper] (container) in
                audioHelper?.audioContainer = container
            },
            tappedBlock: {
                tappedBlock()
            }, longPressKeyboardAudioToTextHandler: audioHelper.longPressKeyboardAudioToTextHandler)
        return LarkKeyboard.createNewVoice(userResolver: userResolver, config, getFrom: { return audioHelper.delegate?.audiokeybordPanelView() })

    }

    public static func buildVoice(userResolver: UserResolver,
                                  _ iconColor: UIColor?,
                                  _ audioHelper: AudioKeyboardHelper,
                                  _ supportStreamUpLoad: Bool,
                                  tappedBlock: @escaping () -> Void) -> InputKeyboardItem {
        let macInputStyle = audioHelper
            .delegate?
            .audiokeybordPanelView()
            .macInputStyle ?? false
        let config = LarkKeyboard.AudioGestureKeyboardConfig(
            userResolver: userResolver,
            supportRecognize: !audioHelper.chat.isCrypto && audioHelper.audioToTextEnable,
            audioWithTextEnable: !audioHelper.chat.isCrypto && audioHelper.audioWithTextEnable,
            iconColor: iconColor,
            macInputStyle: macInputStyle,
            recordDelegate: audioHelper,
            recognitionDelegate: audioHelper,
            recordGestureDelegate: audioHelper,
            recordTextDelegate: audioHelper,
            recognitionGestureDelegate: audioHelper,
            recordWithTextGestureDelegate: audioHelper,
            recognizeService: audioHelper.audioRecognizeService,
            uploadIdBlock: { [weak audioHelper] in
                guard let audioHelper = audioHelper else { return "" }

                if !supportStreamUpLoad {
                    return ""
                }
                return (try? audioHelper.resourceAPI?.fetchUploadID(
                    chatID: audioHelper.chat.id,
                    language: RecognizeLanguageManager.shared.recognitionLanguage
                )) ?? ""
            },
            checkPermissionCallback: { [weak audioHelper] (allow, isFirstTime) in
                if !allow && !isFirstTime {
                    DispatchQueue.main.async(execute: {
                        guard let audioHelper = audioHelper,
                            let rootVC = audioHelper.delegate?.audiokeyboardRecordIndicatorShowIn() else {
                                return
                        }
                        AudioKeyboardFactory.showAudioPermissionAlert(navigator: userResolver.navigator, rootVC: rootVC)
                    })
                }
            },
            keyboardAppearCallback: { [weak audioHelper] in
                audioHelper?.delegate?.handleAudioKeyboardAppear()
                AudioKeyboardDataService.shared.fetchSpeechConfigData(userResolver: userResolver)
            },
            setContainerBlock: { [weak audioHelper] (container) in
                audioHelper?.audioContainer = container
            },
            tappedBlock: {
                tappedBlock()
            }, longPressKeyboardAudioToTextHandler: audioHelper.longPressKeyboardAudioToTextHandler)
        return LarkKeyboard.buildNewVoice(userResolver: userResolver, config, getFrom: { return audioHelper.delegate?.audiokeybordPanelView() })
    }

    static func showAudioPermissionAlert(navigator: Navigatable, rootVC: UIViewController) {
        let dialog = UDDialog.noPermissionDialog(title: BundleI18n.LarkAudio.Lark_Core_MicrophoneAccess_Title,
                                                 detail: BundleI18n.LarkAudio.Lark_Core_MicrophoneAccessForVoiceMessage_Desc())
        navigator.present(dialog, from: rootVC)
    }
}
