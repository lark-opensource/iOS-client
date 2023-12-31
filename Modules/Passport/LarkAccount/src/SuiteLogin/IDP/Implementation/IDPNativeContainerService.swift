//
//  IDPAppLinkContainerService.swift
//  LarkAccount
//
//  Created by bytedance on 2022/9/15.
//

import Foundation
import RxSwift
import LarkAppLinkSDK
import LarkContainer
import UIKit
import SnapKit
import LarkUIKit
import UniverseDesignTheme
import EENavigator
import LKCommonsLogging

class IDPNativeContainerService: IDPWebViewContainerServiceProtocol {

    var disposeBag: DisposeBag = DisposeBag()

    var refreshSub: PublishSubject<Void> = PublishSubject()

    @Provider var applinkService: LarkAppLinkSDK.AppLinkService // user:checked (global-resolve)

    @Provider var dependency: PassportDependency // user:checked (global-resolve)

    lazy var viewController = IDPNativeLoadingViewController()

    static let logger = Logger.plog(IDPWebViewService.self, category: "SuiteLogin.IDP.IDPNativeContainerService")

}

extension IDPNativeContainerService {

    func currentController() -> UIViewController {
        return viewController
    }

    func showFailView(_ error: Error) {
        let vc = UIViewController()
        vc.modalPresentationStyle = .fullScreen
        let failView = dependency.createFailView()
        vc.view.backgroundColor = UIColor.ud.bgBase
        let tap = UITapGestureRecognizer(target: self, action: #selector(refresh))
        vc.view.addGestureRecognizer(tap)
        vc.view.addSubview(failView)
        failView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        clearPageStackAndPresentNew(newVC: vc)
    }

    func open(_ url: URL) {
        Self.logger.info("n_action_idp_native_open_url")
        //先清理页面堆栈，避免错误页面没有dismiss
        clearPageStack()
        //打开idp登录页
        applinkService.open(url: url, from: .unknown, fromControler: self.viewController) { flag in
            Self.logger.info("n_action_idp_native_open_url", body: "result \(flag)")
        }
    }

    private func clearPageStack() {
        if let presentVC = self.viewController.presentedViewController {
            presentVC.dismiss(animated: false)
        }
    }

    private func clearPageStackAndPresentNew(newVC: UIViewController) {
        clearPageStack()
        viewController.present(newVC, animated: false)
    }

    @objc
    private func refresh() {
        refreshSub.onNext(())
    }

    func addPendingView() { }

    func removePendingView() { }

}

class IDPNativeLoadingViewController: UIViewController {

    private let loadingView = LoadingPlaceholderView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.ud.bgLogin
        view.addSubview(loadingView)
        loadingView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        loadingView.text = BundleI18n.suiteLogin.Lark_Passport_InitializeDataLoading
        loadingView.isHidden = false
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        loadingView.animationView.stop()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadingView.animationView.play()
    }
}
