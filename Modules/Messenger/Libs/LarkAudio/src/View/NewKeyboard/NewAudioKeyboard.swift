//
//  AudioKeyboard.swift
//  Pods
//
//  Created by lichen on 2018/7/27.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import UniverseDesignToast
import LarkBaseKeyboard
import LarkKeyboardView
import LarkAlertController
import EENavigator
import LarkSDKInterface
import Reachability
import LarkFeatureGating
import CoreTelephony
import LarkContainer
import LarkMedia
import UniverseDesignDialog

extension LarkBaseKeyboard.LarkKeyboard {

    final class NewAudioGestureKeyboardConfig: UserResolverWrapper {
        let userResolver: UserResolver
        let supportRecognize: Bool
        let audioWithTextEnable: Bool
        let iconColor: UIColor?

        // 第一个参数为是否有权限 第二个参数是是有为第一次请求权限
        let checkPermissionCallback: (Bool, Bool) -> Void

        let keyboardAppearCallback: () -> Void

        let uploadIdBlock: () -> String

        let setContainerBlock: (AudioCollectionContainerView) -> Void

        let recognizeService: AudioRecognizeService?

        let tappedBlock: () -> Void

        let longPressKeyboardAudioToTextHandler: (UILongPressGestureRecognizer) -> NewRecognizeAudioTextGestureKeyboard

        weak var recordTextDelegate: RecordWithTextAudioKeyboardDelegate?

        weak var recordDelegate: RecordAudioKeyboardDelegate?

        weak var recordGestureDelegate: RecordAudioGestureKeyboardDelegate?

        weak var recognitionDelegate: RecognitionAudioKeyboardDelegate?

        weak var recognitionGestureDelegate: RecognizeAudioGestureKeyboardDelegate?

        weak var recordWithTextGestureDelegate: RecordAudioTextGestureKeyboardDelegate?

        @ScopedInjectedLazy var byteViewService: AudioDependency?

        init(userResolver: UserResolver,
             supportRecognize: Bool,
             audioWithTextEnable: Bool,
             iconColor: UIColor?,
             recordDelegate: RecordAudioKeyboardDelegate,
             recognitionDelegate: RecognitionAudioKeyboardDelegate,
             recordGestureDelegate: RecordAudioGestureKeyboardDelegate,
             recordTextDelegate: RecordWithTextAudioKeyboardDelegate,
             recognitionGestureDelegate: RecognizeAudioGestureKeyboardDelegate,
             recordWithTextGestureDelegate: RecordAudioTextGestureKeyboardDelegate,
             recognizeService: AudioRecognizeService?,
             uploadIdBlock: @escaping () -> String,
             checkPermissionCallback: @escaping (Bool, Bool) -> Void,
             keyboardAppearCallback: @escaping () -> Void,
             setContainerBlock: @escaping (AudioCollectionContainerView) -> Void,
             tappedBlock: @escaping () -> Void,
             longPressKeyboardAudioToTextHandler: @escaping (UILongPressGestureRecognizer) -> NewRecognizeAudioTextGestureKeyboard) {
            self.userResolver = userResolver
            self.supportRecognize = supportRecognize
            self.audioWithTextEnable = audioWithTextEnable
            self.iconColor = iconColor
            self.recordDelegate = recordDelegate
            self.recognitionDelegate = recognitionDelegate
            self.recordGestureDelegate = recordGestureDelegate
            self.recognitionGestureDelegate = recognitionGestureDelegate
            self.recordWithTextGestureDelegate = recordWithTextGestureDelegate
            self.recordTextDelegate = recordTextDelegate
            self.recognizeService = recognizeService
            self.uploadIdBlock = uploadIdBlock
            self.checkPermissionCallback = checkPermissionCallback
            self.keyboardAppearCallback = keyboardAppearCallback
            self.setContainerBlock = setContainerBlock
            self.tappedBlock = tappedBlock
            self.longPressKeyboardAudioToTextHandler = longPressKeyboardAudioToTextHandler
        }
    }

    static func createNewVoice(userResolver: UserResolver,
                              _ config: NewAudioGestureKeyboardConfig,
                              getFrom: @escaping () -> UIView?) -> InputKeyboardItem {
        let keyboardItem = NewAudioKeyboard.keyboard(
            iconColor: config.iconColor,
            supportRecognition: config.supportRecognize,
            audioWithTextEnable: config.audioWithTextEnable
        )
        let keyboardIcons: (UIImage?, UIImage?, UIImage?) = keyboardItem.icons
        let keyboardHeight: Float = keyboardItem.height
        let supportRecognize = config.supportRecognize
        let audioWithTextEnable = config.audioWithTextEnable

        let checkPermissionBlock: (@escaping (_ allow: Bool, _ firstTime: Bool) -> Void) -> Void = { callback  in
            var firstTime = false
            (try? userResolver.resolve(assert: AudioRecordManager.self))?.checkPermissionAndSetupRecord { (allow) in
                let isFirstTime = firstTime
                callback(allow, isFirstTime)
            }
            firstTime = true
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

        let keyboardViewBlock = { () -> UIView in
            var items: [AudioKeyboardItemViewDelegate] = []

            let recordTextVM = NewAudioWithTextRecordViewModel(
                userResolver: userResolver,
                audioRecognizeService: config.recognizeService,
                from: .audioMenu)

            if config.supportRecognize && config.audioWithTextEnable {
                let recordText = NewRecordWithTextAudioKeyboard(userResolver: userResolver, viewModel: recordTextVM, delegate: config.recordTextDelegate)
                items.append(recordText)
            }

            let recordVM = NewRecordViewModel(userResolver: userResolver, audioRecognizeService: config.recognizeService, uploadIdBlock: config.uploadIdBlock)
            let record = NewRecordAudioKeyboard(userResolver: userResolver, viewModel: recordVM, delegate: config.recordDelegate)
            items.append(record)

            if config.supportRecognize {
                let recognitionVM = NewAudioRecognizeViewModel(
                    userResolver: userResolver,
                    audioRecognizeService: config.recognizeService,
                    from: .audioMenu)
                let recognition = NewRecognitionAudioKeyboard(userResolver: userResolver, viewModel: recognitionVM, delegate: config.recognitionDelegate)
                items.append(recognition)
            }

            let container: AudioCollectionContainerView
            container = ContainerPageView(items: items)
            container.keyboardHeight = keyboardHeight
            config.setContainerBlock(container)
            return container
        }

        let handleLongPressBlock = { (gesture: UILongPressGestureRecognizer) in
            guard let gestureView = gesture.view else { return }
            var keyWindow: UIWindow? = UIApplication.shared.keyWindow
            var windows: [UIWindow] = UIApplication.shared.windows

            if #available(iOS 13.0, *), let scene = getFrom()?.window?.windowScene {
                windows = scene.windows
                if let delegate = scene.delegate as? UIWindowSceneDelegate,
                    let rootWindow = delegate.window.flatMap({ $0 }) {
                    keyWindow = rootWindow
                } else {
                    keyWindow = scene.windows.first
                }
            }

            let hasFirstResponder = keyWindow?.lu.firstResponder() != nil

            let screenSize = Display.sceneSize(for: gesture.view ?? gestureView)

            windows = windows.sorted(by: {
                $0.windowLevel > $1.windowLevel
            })
            if let keyW = keyWindow, windows.contains(keyW) {
                windows.insert(keyW, at: 0)
            }
            if let topWindow = windows.first(where: { (window) -> Bool in
                // 这里需求是 如果出现键盘，浮窗应该可以覆盖键盘，但是可能存在不可见的全屏 UIRemoteKeyboardWindow
                // 这里做额外判断, 只有在存在第一响应者的时候才可以使用 UIRemoteKeyboardWindow
                return window.isHidden == false &&
                    window.bounds.origin == .zero &&
                    window.bounds.size == screenSize &&
                    (window.isOpaque || hasFirstResponder) &&
                    window.alpha > 0
            }) {
                var recordView: UIView = .init()

                if !supportRecognize {
                    AudioTracker.trackLongpressAudioKeyboard(from: .audioButton)
                    let recordVM = NewRecordViewModel(userResolver: userResolver, audioRecognizeService: config.recognizeService, uploadIdBlock: config.uploadIdBlock)
                    recordView = NewRecordAudioGestureKeyboard(userResolver: userResolver, viewModel: recordVM, gesture: gesture, delegate: config.recordGestureDelegate)
                } else {
                    switch RecognizeLanguageManager.shared.recognitionType {
                    case .audioWithText:
                        if audioWithTextEnable {
                            AudioTracker.touchAudioWithText(from: .audioButton)
                            recordView = config.longPressKeyboardAudioToTextHandler(gesture)
                        } else {
                            fallthrough
                        }
                    case .audio:
                        AudioTracker.trackLongpressAudioKeyboard(from: .audioButton)
                        let recordVM = NewRecordViewModel(userResolver: userResolver, audioRecognizeService: config.recognizeService, uploadIdBlock: config.uploadIdBlock)
                        recordView = NewRecordAudioGestureKeyboard(userResolver: userResolver, viewModel: recordVM, gesture: gesture, delegate: config.recordGestureDelegate)
                    case .text:
                        let recognizeVM = NewAudioRecognizeViewModel(userResolver: userResolver, audioRecognizeService: config.recognizeService, from: .audioButton)
                        recordView = NewRecognizeAudioGestureKeyboard(userResolver: userResolver, viewModel: recognizeVM, gesture: gesture, delegate: config.recognitionGestureDelegate)
                    }
                }

                topWindow.addSubview(recordView)
                recordView.snp.makeConstraints({ (maker) in
                    maker.edges.equalToSuperview()
                })
                topWindow.layoutIfNeeded()
            }
        }

        // 检测是否需要弹出网络错误提示
        let showNetworkErrorIfNeeded: () -> Bool = {
            guard let from = getFrom()?.window else {
                assertionFailure("missing route, from window")
                return false
            }
            if !supportRecognize { return true }
            // 普通语音消息不需要判断网络
            switch RecognizeLanguageManager.shared.recognitionType {
            case .audio: return true
            default: break
            }
            guard let reach = Reachability() else { return false }

            if reach.connection == .none {
                let alertController = LarkAlertController()
                alertController.setTitle(text: BundleI18n.LarkAudio.Lark_Chat_AudioToTextNetworkError)
                alertController.addPrimaryButton(text: BundleI18n.LarkAudio.Lark_Legacy_Sure)
                userResolver.navigator.present(alertController, from: from)
                return false
            }
            return true
        }

        let showCallStateErrorIfNeeded: () -> Bool = {
            // 飞书内部 vc 正在运行时，不判断 CTCall
            guard let byteViewService = config.byteViewService else { return false }
            if byteViewService.byteViewHasCurrentModule() ||
                byteViewService.byteViewIsRinging() {
                return true
            }
            guard let from = getFrom()?.window else {
                assertionFailure("missing route, from window")
                return false
            }
            if let calls = AudioKeyboardHelper.getCurrentCalls(),
               !calls.isEmpty {
                AudioKeyboardHelper.logger.info("user is calling")
                let alertController = LarkAlertController()
                alertController.setTitle(text: BundleI18n.LarkAudio.Lark_Chat_VoiceMessageFailedToast)
                alertController.addPrimaryButton(text: BundleI18n.LarkAudio.Lark_Legacy_Sure)
                userResolver.navigator.present(alertController, from: from)
                return false
            }
            return true
        }

        let checkByteViewState: () -> Bool = {
            guard let from = getFrom()?.window else {
                assertionFailure("missing route, from window")
                return false
            }
            guard let byteViewService = config.byteViewService else { return false }
            if byteViewService.byteViewHasCurrentModule() {
                let text = (byteViewService.byteViewIsRinging() == true) ? byteViewService.byteViewInRingingCannotCallVoIPText() : byteViewService.byteViewIsInCallText()
                let alertController = LarkAlertController()
                alertController.setTitle(text: text)
                alertController.addPrimaryButton(text: BundleI18n.LarkAudio.Lark_Legacy_Sure)
                userResolver.navigator.present(alertController, from: from)
                return false
            }
            return true
        }

        let tapHandler: (KeyboardPanelEvent) -> Void = { event in
            switch event.type {
            case .tap:
                config.tappedBlock()
                event.keyboardSelect()
            case .longPress:
                checkPermissionBlock { (allow: Bool, firstTime: Bool) in
                    config.checkPermissionCallback(allow, firstTime)
                    let netErrorOptimizeEnabled: Bool = userResolver.fg.staticFeatureGatingValue(with: "ai.asr.opt.no_network")
                    let firstAllow = netErrorOptimizeEnabled ? RecognizeLanguageManager.shared.recognitionType == .audioWithText || showNetworkErrorIfNeeded() : showNetworkErrorIfNeeded()
                    if allow && !firstTime, let longPress = event.button.gestureRecognizers?.compactMap({ (gesture) -> UILongPressGestureRecognizer? in
                        guard let longPress = gesture as? UILongPressGestureRecognizer else { return nil }
                        return longPress
                    }).first, firstAllow, showCallStateErrorIfNeeded(), checkByteViewState() {
                        AudioMediaLockManager.shared.tryLock(userResolver: userResolver, from: getFrom()?.window, callback: { result in
                            if result {
                                handleLongPressBlock(longPress)
                            }
                        }, interruptedCallback: { _ in
                            longPress.isEnabled = false
                            longPress.isEnabled = true
                        })
                    }
                }
            default:
                break
            }
        }

        return InputKeyboardItem(
            key: KeyboardItemKey.voice.rawValue,
            keyboardViewBlock: keyboardViewBlock,
            keyboardHeightBlock: { keyboardHeight },
            keyboardIcon: keyboardIcons,
            onTapped: tapHandler,
            selectedAction: selectedAction
        )
    }

    @available(iOS 13.0, *)
    private func rootWindowForScene(scene: UIScene) -> UIWindow? {
        guard let scene = scene as? UIWindowScene else {
            return nil
        }
        if let delegate = scene.delegate as? UIWindowSceneDelegate,
            let rootWindow = delegate.window.flatMap({ $0 }) {
            return rootWindow
        }
        return scene.windows.first
    }
}

public final class NewAudioKeyboard {
   public static func keyboard(
        iconColor: UIColor?,
        supportRecognition: Bool = true,
        audioWithTextEnable: Bool = true
    ) -> KeyboardInfo {
        let tintColor: UIColor = iconColor ?? UIColor.ud.N500

        if !supportRecognition {
            return KeyboardInfo(
                icon: Resources.voice_bottombar,
                selectedIcon: Resources.voice_bottombar_selected,
                unenableIcon: nil,
                tintColor: tintColor
            )
        }

        switch RecognizeLanguageManager.shared.recognitionType {
        case .audioWithText:
            if audioWithTextEnable {
                let icon: UIImage
                let selectIcon: UIImage
                icon = Resources.new_voice_with_text_icon
                selectIcon = Resources.new_voice_with_text_icon_select
                return KeyboardInfo(
                    icon: icon,
                    selectedIcon: selectIcon,
                    unenableIcon: nil,
                    tintColor: tintColor
                )
            } else {
                fallthrough
            }
        case .audio:
            return KeyboardInfo(
                icon: Resources.voice_bottombar,
                selectedIcon: Resources.voice_bottombar_selected,
                unenableIcon: nil,
                tintColor: tintColor
            )
        case .text:
            return KeyboardInfo(
                icon: Resources.voice_text_icon,
                selectedIcon: Resources.voice_text_icon_select,
                unenableIcon: nil,
                tintColor: tintColor
            )
        }
    }
}
