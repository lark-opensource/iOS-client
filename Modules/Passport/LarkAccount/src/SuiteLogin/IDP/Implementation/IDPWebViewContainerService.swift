//
//  IDPWebViewContainerService.swift
//  SuiteLogin
//
//  Created by tangyunfei.tyf on 2020/1/13.
//

import Foundation
import RxSwift
import LarkUIKit

protocol IDPWebViewContainerServiceProtocol {
    var disposeBag: DisposeBag { get }
    var refreshSub: PublishSubject<Void> { get }
    func currentController() -> UIViewController
    func showFailView(_ error: Error)
    func open(_ url: URL)
    func addPendingView()
    func removePendingView()
}

class IDPWebViewContainerService: IDPWebViewContainerServiceProtocol {

    var disposeBag: DisposeBag = DisposeBag()

    var refreshSub: PublishSubject<Void> = PublishSubject()

    func open(_ url: URL) {
        func internalOpen(_ url: URL) {
            let newVC = self.dependency.createWebViewController(url, customUserAgent: customUserAgent)
            let navVC = self.controller.navigationController

            replace(navVC: navVC, newVC: newVC)
        }
        if Thread.current == .main {
            internalOpen(url)
        } else {
            DispatchQueue.main.async {
                internalOpen(url)
            }
        }
    }

    func currentController() -> UIViewController {
        return self.controller
    }

    func showFailView(_ error: Error) {
        switch error {
        case let loginError as V3LoginError:
            if case .networkNotReachable = loginError {
                let vc = IDPNetworkLossInteractiveViewController {
                    if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.openURL(url)
                    }
                } refreshBlock: {
                    self.refresh()
                }
                replace(navVC: self.controller.navigationController, newVC: vc)
            } else {
                fallthrough
            }
        default:
            let vc = UIViewController()
            let failView = dependency.createFailView()
            vc.view.backgroundColor = UIColor.ud.bgBase
            let tap = UITapGestureRecognizer(target: self, action: #selector(refresh))
            vc.view.addGestureRecognizer(tap)
            vc.view.addSubview(failView)
            failView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            replace(navVC: self.controller.navigationController, newVC: vc)
        }
    }

    func addPendingView() {
        replace(navVC: controller.navigationController, newVC: IDPPendingViewController())
    }

    func removePendingView() {
        let viewController = dependency.createWebViewController(URL(string: CommonConst.aboutBlank)!, customUserAgent: customUserAgent)
        replace(navVC: controller.navigationController, newVC: viewController)
    }

    private var controller: UIViewController

    private let dependency: PassportDependency

    private let customUserAgent: String?

    init(
        url: URL,
        dependency: PassportDependency,
        customUserAgent: String? = nil
    ) {
        self.dependency = dependency
        let controller = dependency.createWebViewController(url, customUserAgent: customUserAgent)
        self.controller = controller
        self.customUserAgent = customUserAgent
    }

    @objc
    private func refresh() {
        refreshSub.onNext(())
    }

    private func replace(navVC: UINavigationController?, newVC: UIViewController) {
        var viewControllers: [UIViewController] = []
        navVC?.viewControllers.forEach({ (vc) in
            if vc != self.controller {
                viewControllers.append(vc)
            }
        })
        viewControllers.append(newVC)
        navVC?.viewControllers = viewControllers
        self.controller = newVC
    }

}

fileprivate class IDPPendingViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBase
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}
