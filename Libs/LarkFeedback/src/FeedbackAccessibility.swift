//
//  FeedbackAccessibility.swift
//  LarkFeedback
//
//  Created by kongkaikai on 2021/4/1.
//

import Foundation
import BDFeedBack
import LarkReleaseConfig
import LKCommonsLogging
import LarkAccountInterface
import LarkDebugExtensionPoint
import LarkSuspendable
import RxSwift
import EEAtomic
import EENavigator

// 用来确保 DebugItems 只执行一次
private let InnerOnce = AtomicOnce()

// 接入文档： https://bytedance.feishu.cn/docs/doccn2quPU8YijE7A9vcyGpJtXg

/// 支持验证Feedback是否可用的能力，
/// 实现改协议即直接调用默认的实现即可
protocol FeedbackAccessibility: AnyObject {

    /// 日志处理的属性
    static var logger: LKCommonsLogging.Log { get }

    /// 验证Feedback是否可用
    func verifyFeedbackAccessibility()

    /// 重置Feedback状态
    func clearFeedbackState(with statusLog: String)
}

/// 默认实现
extension FeedbackAccessibility {

    /// 初始化 BDFBInjectedInfo 单例
    /// - Parameter feedbackAppID: 从内测平台申请的 feedbackAppID
    /// - Returns: BDFBInjectedInfo 单例
    private func setupBDFBInjectedInfo(_ feedbackAppID: String) -> BDFBInjectedInfo {
        let info = BDFBInjectedInfo.shared()
        info.appID = Int(ReleaseConfig.appId) ?? 462_391
        info.isLark = false
        info.feishuOrLarkAppId = feedbackAppID
        info.channel = ReleaseConfig.channelName
        info.userID = AccountServiceAdapter.shared.currentChatterId
        info.deviceID = AccountServiceAdapter.shared.deviceService.deviceId

        #if DEBUG
        info.appID = 462_391
        info.channel = "Enterprise"
        BDFBLarkSSOManager.shared().overrideBundleId = "com.larksuite.feishu.bytedance.inhouse"
        #endif

        return info
    }

    /// 获取授权码成功
    private func getAuthorizationCodeSuccess() {
        DispatchQueue.main.async {
            if #available(iOS 13.0, *) {
                if let activeScene = UIApplication.shared.windowApplicationScenes.first(where: {
                    $0.activationState == .foregroundActive && $0.isKind(of: UIWindowScene.self)
                }), let windowScene = activeScene as? UIWindowScene {
                    BDFBFloatingWindowManager.shared().setWindowScene(windowScene)
                }
            }

            // 鉴权代码
            BDFBLarkSSOManager.shared().startVerification {
                Self.logger.info("BDFeedback verification success")
            }
        }

        InnerOnce.once {
            // 添加 Feedback 页面显示和隐藏的监听
            self.addFeedbackControllerEnventObserver()

            // 注册DebugTools
            DebugRegistry.registerDebugItem(BOEEnableDebugItem(), to: .debugTool)
        }
    }

    func verifyFeedbackAccessibility() {
        let feedbackAppID = "lkd91mya3l2ogfe5be"

        #if DEBUG
        let bundleID = "com.larksuite.feishu.bytedance.inhouse"
        #else
        let bundleID = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? ""
        #endif

        let info = setupBDFBInjectedInfo(feedbackAppID)

        AccountServiceAdapter.shared.getAuthorizationCode(
            req: .init(appId: feedbackAppID, packageId: bundleID)
        ) { [weak self] result in
            switch result {
            case .success(let code):
                info.larkCode = code.code
                self?.getAuthorizationCodeSuccess()

            case .failure(let error):
                Self.logger.error("BDFeedback get code failed.", error: error)
            }
        }
    }

    func clearFeedbackState(with statusLog: String) {
        // Call some method to clear injected info?
        BDFBLarkSSOManager.shared().resetAuthInfo()
        BDFBFloatingWindowManager.shared().hideFloatingWindow()

        Self.logger.info("BDFeedback clear feedback state.", additionalData: ["status": statusLog])
    }
}

private extension FeedbackAccessibility {

    func addFeedbackControllerEnventObserver() {
        /// 添加 Feedback 页面显示和隐藏的方法
        /// - Parameters:
        ///   - name: 通知名字
        ///   - isHidden: 针对当前通知是显示还是隐藏多任务浮窗
        func addNotificationObserver(for name: NSNotification.Name, setSuspendWindowHidden isHidden: Bool) {
            NotificationCenter.default.rx.notification(name)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { _ in
                    SuspendManager.shared.setSuspendWindowHidden(isHidden)
                    Self.logger.info("BDFeedback set suspend window.", additionalData: ["isHidden": "\(isHidden)"])
                })
        }

        addNotificationObserver(for: .BDFBProblemReportViewControllerViewDidAppear, setSuspendWindowHidden: true)
        addNotificationObserver(for: .BDFBProblemReportViewControllerDidDismiss, setSuspendWindowHidden: false)
    }
}
