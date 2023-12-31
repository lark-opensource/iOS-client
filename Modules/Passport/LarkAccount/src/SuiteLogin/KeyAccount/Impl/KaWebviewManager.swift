//
//  KaWebviewManager.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/10/24.
//

import Foundation
import RxSwift
import LarkUIKit
import LarkContainer

protocol KaLoginWebViewManager {
    var disposeBag: DisposeBag { get }
    var refreshSub: PublishSubject<Void> { get }
    func webViewController() -> UIViewController
    func showFailView()
    func open(_ url: URL)
}

class KaLoginWebViewManagerImpl: KaLoginWebViewManager {

    var disposeBag: DisposeBag = DisposeBag()

    var refreshSub: PublishSubject<Void> = PublishSubject()

    func webViewController() -> UIViewController {
        return navigation
    }

    func open(_ url: URL) {
        func internalOpen(_ url: URL) {
            controller = self.dependency.createWebViewController(url, customUserAgent: nil)
            self.navigation.viewControllers = [controller]
        }
        if Thread.current == .main {
            internalOpen(url)
        } else {
            DispatchQueue.main.async {
                internalOpen(url)
            }
        }
    }

    func showFailView() {
        let vc = UIViewController()
        let failView = dependency.createFailView()
        vc.view.backgroundColor = UIColor.white
        let tap = UITapGestureRecognizer(target: self, action: #selector(refresh))
        vc.view.addGestureRecognizer(tap)
        vc.view.addSubview(failView)
        failView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.navigation.viewControllers = [vc]
    }

    private var dependency: PassportDependency

    private var controller: UIViewController

    private let navigation: LkNavigationController

    init(url: URL, dependency: PassportDependency) {
        self.dependency = dependency
        let controller = dependency.createWebViewController(url, customUserAgent: nil)
        self.controller = controller
        self.navigation = PassportKANavigationController(rootViewController: controller)
    }

    @objc
    private func refresh() {
        refreshSub.onNext(())
    }

}
