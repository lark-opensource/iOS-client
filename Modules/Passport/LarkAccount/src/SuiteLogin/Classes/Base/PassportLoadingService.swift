//
//  PassportLoadingService.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/10/3.
//

import Foundation
import RoundedHUD
import Lottie
import UIKit
import UniverseDesignToast

class PassportLoadingService {
    public static let shared = PassportLoadingService()

    private var useHUDLoading: Bool = false

    private var loadingHUD: RoundedHUD?

    private var timer: DispatchSourceTimer?
    private let showHudTimeInterval = 0.2

    lazy private var loadingMaskView: UIView = {
        return self.createLoadingMaskView(loadingView)
    }()

    lazy private var loadingView: LOTAnimationView = {
        return self.createLoading()
    }()

    //passport统一显示loading方法
    static func showLoading(with text: String = BundleI18n.LarkAccount.Lark_Legacy_BaseUiLoading) -> UDToast? {
        guard let topMostVC = PassportNavigator.topMostVC else {
            return nil
        }

        return UDToast.showLoading(with: text,
                                   on: topMostVC.view,
                                   disableUserInteraction: true)
    }

    static func showLoadingOnWindow(with text: String = BundleI18n.LarkAccount.Lark_Legacy_BaseUiLoading) -> UDToast? {
        guard let window = PassportNavigator.keyWindow else {
            return nil
        }

        return UDToast.showLoading(with: text,
                                   on: window,
                                   disableUserInteraction: true)
    }

    func showLoading(on view: UIView) {
        SuiteLoginUtil.runOnMain {
            self.setupLoading(on: view)
            view.endEditing(true)
            if self.useHUDLoading {
                self.loadingHUD = RoundedHUD.showLoading(on: view)
            } else {
                self.loadingMaskView.isHidden = false
                view.bringSubviewToFront(self.loadingMaskView)
                self.loadingView.play()
            }
        }
    }

    func stopLoading() {
        SuiteLoginUtil.runOnMain {
            if self.useHUDLoading {
                self.loadingHUD?.remove()
                self.loadingHUD = nil
            } else {
                self.loadingView.stop()
                self.loadingMaskView.isHidden = true
            }
        }
    }

    func setupLoading(on view: UIView) {
        view.addSubview(loadingMaskView)
        loadingMaskView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func createLoadingMaskView(_ loading: LOTAnimationView) -> UIView {
        let mask = UIView()
        mask.isHidden = true
        mask.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        let loadingView = UIView()
        loadingView.backgroundColor = .black
        let loadingBgColor: CGFloat = 199.0 / 255.0
        loadingView.layer.shadowColor = UIColor(red: loadingBgColor,
                                                green: loadingBgColor,
                                                blue: loadingBgColor, alpha: 0.5).cgColor
        loadingView.layer.opacity = 0.5
        loadingView.layer.cornerRadius = Common.Layer.commonAlertViewRadius
        mask.addSubview(loadingView)
        loadingView.addSubview(loading)
        loadingView.snp.makeConstraints({ (make) in
            make.size.equalTo(CGSize(width: BaseLayout.loadingMaskWidth,
                                     height: BaseLayout.loadingMaskWidth))
            make.center.equalToSuperview()
        })
        loading.snp.makeConstraints({ (make) in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: BaseLayout.loadingWidth,
                                     height: BaseLayout.loadingWidth))
        })
        return mask
    }

    func createLoading() -> LOTAnimationView {
        // swiftlint:disable ForceUnwrapping
        let loading = LOTAnimationView(filePath: BundleConfig.LarkAccountBundle.path(forResource: "data", ofType: "json", inDirectory: "Lottie/button_loading")!)
        // swiftlint:enable ForceUnwrapping

        loading.backgroundColor = .clear
        loading.isUserInteractionEnabled = false
        loading.loopAnimation = true
        return loading
    }

    func showHud(tip: String, view: UIView) {

        loadingHUD = RoundedHUD()
        timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global())
        timer?.schedule(deadline: .now() + showHudTimeInterval, leeway: DispatchTimeInterval.milliseconds(0))
        timer?.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.loadingHUD?.showLoading(
                    with: tip,
                    on: view,
                    disableUserInteraction: true
                )
            }
        }
        timer?.resume()
    }

    func removeHud() {
        timer?.cancel()
        timer = nil
        loadingHUD?.remove()
        loadingHUD = nil
    }

    struct BaseLayout {
        static let loadingWidth: CGFloat = 30
        static let loadingMaskWidth: CGFloat = 75
    }
}
