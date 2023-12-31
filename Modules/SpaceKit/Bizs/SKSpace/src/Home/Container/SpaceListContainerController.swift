//
//  SpaceListContainerController.swift
//  SKECM
//
//  Created by Weston Wu on 2021/2/4.
//

import Foundation
import SKUIKit
import SKFoundation
import SKCommon
import UniverseDesignColor
import SnapKit
import RxSwift
import RxRelay
import RxCocoa

// 自带导航栏的容器VC，专门提供给space的二级页面
public final class SpaceListContainerController: BaseViewController {
    private let bag = DisposeBag()

    private let contentViewController: SpaceHomeViewController

    public override var commonTrackParams: [String: String] {
        let bizParams = contentViewController.homeViewModel.commonTrackParams
        return [
            "module": bizParams["module"] ?? "null",
            "sub_module": bizParams["sub_module"] ?? "none"
        ]
    }

    public var needLogNavBarEvent: Bool = true

    public init(contentViewController: SpaceHomeViewController, title: String) {
        self.contentViewController = contentViewController
        super.init(nibName: nil, bundle: nil)
        navigationBar.title = title
        contentViewController.naviBarCoordinator.update(naviBarProvider: self)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentViewController.reloadHomeLayout()
    }

    private func setupUI() {
        view.backgroundColor = UDColor.bgBody
        navigationController?.isNavigationBarHidden = true

        addChild(contentViewController)
        view.addSubview(contentViewController.view)
        contentViewController.didMove(toParent: self)
        contentViewController.view.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    public override func logNavBarEvent(_ event: DocsTracker.EventType, click: String? = nil, target: String? = "none", extraParam: [String: String]? = nil) {
        //bitableHome不上报相关埋点
        guard needLogNavBarEvent else { return }
        super.logNavBarEvent(event, click: click, target: target, extraParam: extraParam)
    }
}
