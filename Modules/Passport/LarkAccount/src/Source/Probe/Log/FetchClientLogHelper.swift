//
//  FetchClientLogHelper.swift
//  LarkAccount
//
//  Created by au on 2021/9/22.
//

import EENavigator
import Foundation
import LarkAccountInterface
import LarkContainer
import LarkUIKit
import RxCocoa
import RxSwift
import UniverseDesignToast
import LKCommonsLogging
import LarkFoundation
import LarkSetting

final class FetchClientLogHelper {

    private static let _progress = BehaviorRelay<UInt32>(value: 0)
    static var progress: Observable<UInt32> { _progress.asObservable() }

    static func subscribeStatusBarInteraction() {

        // 有调试面板的时候，从调试面板获取设备日志
        if Self.appCanDebug() { return }

        // 整体功能开关，关闭时屏蔽此功能
        guard PassportStore.shared.configInfo?.config().getEnableExportClientLogFile() ?? true else { return }

        // 如果订阅过，则不重复订阅
        guard Self.disposable == nil else { return }

        // hook状态栏点击事件
        UIStatusBarHookManager.hookTapEvent()

        // 实现参考 LarkDebug/SetupDebugTask
        Self.disposable = NotificationCenter.default
            .rx
            .notification(Notification.statusBarTapped.name)
            .subscribe(onNext: { notification in
                let kw = UIApplication.shared.windows.first { $0.isKeyWindow }
                guard let tapCount = notification.userInfo?[Notification.statusBarTappedCount] as? NSNumber,
                      tapCount.intValue == 5,
                      var window = kw ?? PassportNavigator.keyWindow else {
                          return
                      }
                
                if #available(iOS 13.0, *),
                   let tappedScene = notification.userInfo?[Notification.statusBarTappedInScene] as? UIWindowScene,
                   let delegate = tappedScene.delegate as? UIWindowSceneDelegate,
                   let tappedWindow = delegate.window?.map({ $0 }) {
                    window = tappedWindow
                }
                
                DispatchQueue.main.async {
                    let enableUpload = GlobalFeatureGatingManager.shared.globalFeatureValue(of: .init(.make(golbalKeyLiteral: "passport_no_user_log_upload")))
                    if enableUpload {
                        Self.uploadClientLog()
                    } else {
                        Self.shareClientLog()
                    }
                }
            })
    }
    
    //取消订阅的方法，建议在disappear中调用
    static func unsubscribeStatusBarInteraction() {
        Self.disposable?.dispose()
        Self.disposable = nil
    }
    
    static func fetchClientLog(completion: @escaping (ClientLogShareViewController?) -> Void) {
        let request = FetchClientLogPathAPI()
        request.fetchClientLogPath(completion: { path in
            DispatchQueue.main.async {
                guard let path = path else {
                    completion(nil)
                    return
                }
                let controller = ClientLogShareViewController(url: URL(fileURLWithPath: path))
                completion(controller)
            }
        })
    }
    private static var disposable: Disposable? = nil
    
    static func appCanDebug() -> Bool {
        #if DEBUG || ALPHA
        return true
        #else
        let suffix = Utils.appVersion.lf.matchingStrings(regex: "[a-zA-Z]+(\\d+)?").first?.first
        return suffix != nil
        #endif
    }

    /// 使用系统分享页面获取日志文件
    static func shareClientLog() {
        var toast: UDToast?
        if let view = PassportNavigator.topMostVC?.view {
            toast = UDToast.showDefaultLoading(on: view)
        }
        let request = FetchClientLogPathAPI()
        request.fetchClientLogPath(completion: { path in
            DispatchQueue.main.async {
                toast?.remove()
                guard let path = path else { return }
                let url = URL(fileURLWithPath: path)
                let controller = ClientLogShareViewController(url: url)

                guard let from = PassportNavigator.topMostVC else { return }
                if Display.pad {
                    controller.modalPresentationStyle = .formSheet
                }
                from.present(controller, animated: true, completion: nil)
            }
        })
    }

    /// 使用自定义页面上传日志文件
    static func uploadClientLog(prefilledToken: String? = nil) {
        let controller = ClientLogUploadViewController()
        guard let from = PassportNavigator.topMostVC else { return }
        if Display.pad {
            controller.modalPresentationStyle = .formSheet
            if #available(iOS 13.0, *) {
                controller.isModalInPresentation = true
            }
        } else {
            controller.modalPresentationStyle = .fullScreen
        }
        from.present(controller, animated: true) {
            guard let token = prefilledToken else { return }
            controller.prefillToken(token)
        }
    }

    static func updateUploadProgress(_ value: UInt32) {
        _progress.accept(value)
    }

}
