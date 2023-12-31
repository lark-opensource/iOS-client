//
//  ChatScreenProtectService.swift
//  LarkMessageCore
//
//  Created by zc09v on 2022/7/11.
//

import UIKit
import Foundation
import LarkSafety
import LarkMessengerInterface
import RxCocoa
import RxSwift
import LarkModel
import LKCommonsLogging
import LarkContainer
import LarkSDKInterface
import LarkCore
import LarkSceneManager
import LarkMessageBase
import LarkFeatureGating

public class ChatScreenProtectService: PageService, UserResolverWrapper {
    private static let logger: Log = Logger.log(ChatScreenProtectService.self, category: "ChatScreenProtectService")
    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    private static let debouncer: Debouncer = Debouncer()
    private var screenCaptured: ((Bool) -> Void)?
    private var disposeBag = DisposeBag()
    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?

    private var enable: Bool = false {
        didSet {
            Self.logger.info("chatTrace screenProtect enable didSet \(enable)")
            guard oldValue != enable else { return }
            if isRecording {
                //如果正在录制，是否开启监控也会影响是否对外部产生screenCaptured回调
                Self.logger.info("chatTrace screenProtect enable didSet isRecording is true")
                self.screenCaptured?(enable)
            }
        }
    }
    private var forceEnable: Bool = false
    /// 当前是否正在录屏
    private var isRecording: Bool = false {
        didSet {
            Self.logger.info("chatTrace screenProtect isRecording didSet \(isRecording)")
            guard oldValue != isRecording else { return }
            if enable {
                Self.logger.info("chatTrace screenProtect isRecording didSet enable is true")
                self.screenCaptured?(isRecording)
            }
        }
    }

    private var chatId: String = ""
    // 外部决定是否使用SecureView
    private var useSecureView: Bool = false
    // 内部决定SecureView是否可用，fg + 系统版本配置
    private lazy var supportSecureView: Bool = {
        let fg = self.userResolver.fg.staticFeatureGatingValue(with: "im.chat.secure.ios.screenshot.protection")
        var versionIsOK: Bool = false
        if let versionRange = self.userGeneralSettings?.chatSecureViewEnableConfig?.versionRange {
            let systemVersion = UIDevice.current.systemVersion
            Self.logger.info("chatTrace supportSecureView \(fg) \(systemVersion) \(versionRange)")
            if systemVersion >= versionRange.min && systemVersion <= versionRange.max {
                versionIsOK = true
            }
        }
        return fg && versionIsOK
    }()
    private var secureViewHasdException: Bool = false

    public var secureViewIsWork: Bool {
        return useSecureView && supportSecureView && !secureViewHasdException
    }

    private var getTargetVC: () -> UIViewController?

    // 部分场景，需要外部告知视图是否有遮挡，比如vc遮挡会话
    public var protectedTargetIsShow: Bool = true
    public let userResolver: UserResolver

    public init(chatId: String,
                getTargetVC: @escaping () -> UIViewController?,
                forceEnable: Bool = false,
                useSecureView: Bool = false,
                userResolver: UserResolver) {
        self.chatId = chatId
        self.getTargetVC = getTargetVC
        self.forceEnable = forceEnable
        self.enable = forceEnable
        self.useSecureView = useSecureView
        self.userResolver = userResolver
    }

    convenience public init(chat: BehaviorRelay<Chat>,
                            getTargetVC: @escaping () -> UIViewController?,
                            forceEnable: Bool = false,
                            useSecureView: Bool = false,
                            userResolver: UserResolver) {
        self.init(chatId: chat.value.id,
                  getTargetVC: getTargetVC,
                  forceEnable: forceEnable,
                  useSecureView: useSecureView,
                  userResolver: userResolver)
        self.set(chat: chat)
    }

    public func set(chat: BehaviorRelay<Chat>) {
        guard !self.chatId.isEmpty else {
            return
        }
        self.chatId = chat.value.id
        let chatValue = chat.value
        if !forceEnable {
            self.enable = chatValue.enableRestricted(.screenshot)
            Self.logger.info("chatTrace screenProtect enable \(self.enable)")
            chat.map({ chat -> Bool in
                    return chat.enableRestricted(.screenshot)
                })
                .distinctUntilChanged()
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] enable in
                    self?.enable = enable
                }).disposed(by: self.disposeBag)
        }
    }

    public func observe(screenCaptured: @escaping (Bool) -> Void) {
        guard self.screenCaptured == nil else {
            return
        }
        self.screenCaptured = screenCaptured
        if UIScreen.main.isCaptured {
            self.isRecording = true
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(screenCapturedDidChange),
                                               name: UIScreen.capturedDidChangeNotification,
                                               object: nil)
    }

    public func observeEnterBackground(targetVC: UIViewController?) {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(enterBackGround),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(enterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }

    @objc
    private func screenCapturedDidChange(_ notification: Notification) {
        guard let screen = notification.object as? UIScreen else { return }
        self.isRecording = screen.isCaptured
    }

    @objc
    private func enterBackGround() {
        guard let window = self.getTargetVC()?.view.window, self.enable else {
            return
        }
        LarkSafetyTools.shared.addWindowBlurView(in: window)
    }

    @objc
    private func enterForeground() {
        LarkSafetyTools.shared.removeWindowBlurView()
    }

    public func pageWillAppear() {
        self.observeScreenshotNotification()
    }

    public func pageWillDisappear() {
        self.removeScreenshotNotification()
    }

    @available(iOS 13.0, *)
    public func setSecureView(targetVC: UIViewController) {
        guard useSecureView, supportSecureView else {
            return
        }
        let field = UITextField()
        field.isSecureTextEntry = true
        guard let internalView = field.subviews.first else {
            self.secureViewHasdException = true
            Self.logger.info("chatTrace screenProtect supportSecureView hasException")
            return
        }
        internalView.subviews.forEach { $0.removeFromSuperview() }
        internalView.isUserInteractionEnabled = true
        internalView.frame = targetVC.view.frame
        internalView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        targetVC.view = internalView
    }

    private func observeScreenshotNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didTakeScreenshot),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
    }

    private func removeScreenshotNotification() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )
    }

    @objc
    private func didTakeScreenshot() {
        guard self.enable, protectedTargetIsShow else {
            return
        }
        guard self.currentSceneIsForeground(), !self.chatId.isEmpty else { return }
        // 在多 Scene 情况下系统会发送多次 userDidTakeScreenshotNotification
        // 在多 Scene 情况下可以同时打开多个相同会话
        // 因此这里进行 debounce 处理
        Self.debouncer.debounce(
            indentify: self.chatId,
            duration: 0.3,
            action: { [weak self] in
                guard let self = self else { return }
                self.chatAPI?
                    .userTakeScreenshot(chatId: self.chatId)
                    .subscribe()
                    .disposed(by: self.disposeBag)
            })
    }

    private func currentSceneIsForeground() -> Bool {
        if #available(iOS 13.0, *),
           SceneManager.shared.supportsMultipleScenes,
           let scene = self.getTargetVC()?.currentScene() {
            return scene.activationState == .foregroundActive || scene.activationState == .foregroundInactive
        }
        return true
    }
}
