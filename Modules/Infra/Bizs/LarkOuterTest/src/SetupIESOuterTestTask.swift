//
//  SetupIESOuterTestTask.swift
//  SetupIESOuterTestTask
//
//  Created by luyz on 2021/9/23.
//

import Foundation
import LarkUIKit
import BootManager
import IESOuterTest
import EENavigator
import UIKit
import StoreKit
import LarkAccountInterface
import LarkAppConfig
import RxSwift
import LarkContainer
import UniverseDesignDialog
import LarkFeatureGating
import LarkReleaseConfig
import LKCommonsTracker
import Homeric
import LarkSetting

class SetupIESOuterTestTask: FlowBootTask, Identifiable {
    static var identify = "SetupIESOuterTestTask"

    override var runOnlyOnce: Bool { return true }

    deinit { }

    override func execute(_ context: BootContext) {
        LarkOuterTestTask.shared.setupTask()
    }
}

public class LarkOuterTestTask {
    public static let shared = LarkOuterTestTask()

    private let disposeBag = DisposeBag()

    @Provider  var accountManager: AccountService
    @InjectedLazy private var deviceService: DeviceService

    func setupTask() {
        let outerTestOpen = LarkFeatureGating.shared.getFeatureBoolValue(for: "messenger.outer.open")

        if outerTestOpen {
            isUsingInternalNetwork()
                .subscribe(onNext: {  [weak self] (usingInternalNetwork) in

                    if usingInternalNetwork && self!.isBytedanceCheck() {
                        self?.registOuterTestTask()
                        self?.handleCustomPopup()
                    }
                }, onError: { (_) in

                }).disposed(by: disposeBag)
        }

    }
    func registOuterTestTask() {
        IESOuterTest.setup { (config: IESOuterTestConfig) in
            config.appDisplayFullName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? ""
            config.appDisplayShortName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? ""
            config.appVersionCode = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
            config.appVersionCodeNumber = 4110
            config.deviceID = self.deviceService.deviceId// "2771199113571663"
            config.appID = ReleaseConfig.appId
            config.baseURL = "https://\(DomainSettingManager.shared.currentSetting[.appbeta]?.first ?? "")" //https://appbeta-bd.feishu.cn/
            config.enableWebviewSwipeGoBack = true
            let adapterImp = LarkOuterTestAdapterImp()
            config.applogAdapter = adapterImp
        }
    }
    let larkInsCtro = IESLarkTFOuterTestInstructionViewController()

    func handleCustomPopup() {
        IESOuterTest.popupOuterTestNewVersionIfNeeded(traceParams: {(params: NSMutableDictionary) in
            params["action_type"] = "check"
            params["event_page"] = "sdk_test"
        }, frequencyControl: nil, popupBlock: { (viewModel: IESOuterTestPopupViewModel?) -> Void in
            if viewModel != nil {
                let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
                let dialog = UDDialog()
                let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? ""
                dialog.setTitle(text: viewModel == nil ? "" : viewModel!.titleString.replacingOccurrences(of: "{APP_DISPLAY_NAME}", with: bundleName))
                dialog.setContent(text: viewModel == nil ? "" : viewModel!.contentString.replacingOccurrences(of: "{APP_DISPLAY_NAME}", with: bundleName))

                let url = NSURL.init(string: "itms-beta://")
                let type = UIApplication.shared.canOpenURL(url! as URL)
                var num = "1."

                if !type {
                    dialog.addDestructiveButton(text: "1." + BundleI18n.LarkOuterTest.Lark_IOSTestFlight_BetaTestingStepOne_Title,
                                                dismissCompletion: { [weak self] in
                        self?.larkInsCtro.delegate = self
                        self?.larkInsCtro.push()
                        IESOuterTestTracker.testflightInstallConfirm(withCustomParams: nil)
                    })
                    num = "2."
                }

                dialog.addDestructiveButton(text: (num == "1." ? "" : num) + BundleI18n.LarkOuterTest.Lark_IOSTestFlight_BetaTestingStepTwo_Title,
                                            dismissCompletion: { [weak self] in
                    self?.larkInsCtro.push()
                })

                dialog.addDestructiveButton(text: BundleI18n.LarkOuterTest.Lark_IOSTestFlight_AppJoinBetaTesting_CancelPopupButton,
                                            dismissCompletion: {
                    viewModel?.clickCloseButton()
                    IESOuterTestTracker.invitePopupCancel(withTargetVersion: version, duration: 0, isInstallTF: type, customParams: nil)
                })
                viewModel?.didActive()
                UIApplication.shared.keyWindow?.rootViewController?.present(dialog, animated: true, completion: nil)
                IESOuterTestTracker.invitePopupShow(withTargetVersion: version, isInstallTF: type, customParams: nil)
            }
        })

    }

    // MARK: private -> BoolCheck
    /// 启动灰度内测包检查（仅针对使用AppStore包的字节内部用户）
    private func isBytedanceCheck() -> Bool {
        let bundleID = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? ""
        let isOnAllowedList = (bundleID == "com.bytedance.ee.lark") // 飞书

        let isBytedancer = accountManager.currentAccountInfo.tenantInfo.isByteDancer == true

        // 字节用户、在包白名单中的条件同时满足则启动检查内测版本的任务
        return isBytedancer && isOnAllowedList
    }

    /// 检查是否连接内网
    private func isUsingInternalNetwork() -> Observable<Bool> {

        let internalURL = "http://app-alpha.bytedance.net/ping"
        guard let url = URL(string: internalURL) else {
            return Observable.just(false)
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0

        return Observable.create { observer in
            URLSession.shared.rx.response(request: request)
                .subscribe(onNext: { r, _ in
                    guard r.statusCode == 200 else {
                        return observer.onNext(false)
                    }
                    return observer.onNext(true)
                }, onError: { _ in
                    return observer.onNext(false)
                })
        }
    }

    private func showNativeAlert() {
        let alertController = UIAlertController.init(title: "title",
                                                            message: "message",
                                                            preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction.init(title: "ac1",
                                                     style: UIAlertAction.Style.cancel,
                                                     handler: { (_: UIAlertAction) in
            self.larkInsCtro.delegate = self
            self.larkInsCtro.push()
        }))
        alertController.addAction(UIAlertAction.init(title: "ac2", style: UIAlertAction.Style.default, handler: { (_: UIAlertAction) in
        }))
        alertController.addAction(UIAlertAction.init(title: "ac3", style: UIAlertAction.Style.default, handler: { (_: UIAlertAction) in

        }))
        UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
    }

}

extension LarkOuterTestTask: TFOuterTestDelegate {
    public func larkSKStoreProductViewControllerDidDisappear() {
        self.handleCustomPopup()
    }
}

class IESLarkTFOuterTestInstructionViewController: UIViewController, SKStoreProductViewControllerDelegate {

    public weak var delegate: TFOuterTestDelegate?

    func push() {
        let url = NSURL.init(string: "itms-beta://")
        let type = UIApplication.shared.canOpenURL(url! as URL)

        var openUrl = "https://itunes.apple.com/cn/app/testflight/id899247664?mt=8"

        if type {
            openUrl = "itms-beta://testflight.apple.com/join/7NyKlA0i"
            UIApplication.shared.open(NSURL.init(string: openUrl)! as URL, options: [:], completionHandler: nil)
            IESOuterTestTracker.hostInstallConfirm(withIsAuto: false, customParams: nil)
        } else {
            let storeProductVC = SKStoreProductViewController()
            storeProductVC.delegate = self
            UIApplication.shared.keyWindow?.rootViewController?.present(storeProductVC, animated: true, completion: nil)

            let testflightId = "899247664"
            let param = [SKStoreProductParameterITunesItemIdentifier: testflightId]
            storeProductVC.loadProduct(withParameters: param, completionBlock: { (loaded, _) -> Void in
                if loaded {
                    // success
                }
            })

            IESOuterTestTracker.testflightInstallConfirm(withCustomParams: nil)
        }
    }

    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true, completion: nil)
        self.delegate?.larkSKStoreProductViewControllerDidDisappear()
    }
}

public protocol TFOuterTestDelegate: AnyObject {
    func larkSKStoreProductViewControllerDidDisappear()
}

class LarkOuterTestAdapterImp: NSObject, IESOuterTestApplogAdapter {
    func outerTestTrackEvent(_ event: String, params: [AnyHashable: Any]?) {
        Tracker.post(TeaEvent(event, params: params ?? [:]))
    }
}
