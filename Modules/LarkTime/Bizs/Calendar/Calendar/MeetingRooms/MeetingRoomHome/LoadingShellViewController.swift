//
//  LoadingShellViewController.swift
//  Calendar
//
//  Created by LiangHongbin on 2021/12/31.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkUIKit
import SnapKit

final class LoadingShellViewController<ChildVC: UIViewController>: UIViewController {

    var childVC: ChildVC?

    private lazy var loadingView = LoadingPlaceholderView()
    private lazy var failedView = LoadFaildRetryView()

    private let disposeBag = DisposeBag()
    private let status: BehaviorRelay<DataPrepareStatus> = .init(value: .loading)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlaceholder()
        status.bind { [weak self] status in
            guard let self = self else { return }
            switch status {
            case .loading:
                self.loadingView.isHidden = false
            case .finished:
                self.setupChildVC()
            case .faild:
                self.failedView.isHidden = false
            }
        }.disposed(by: disposeBag)
    }

    private func setupPlaceholder() {
        view.addSubview(loadingView)
        loadingView.isHidden = true
        loadingView.snp.makeConstraints { $0.edges.equalToSuperview() }

        view.addSubview(failedView)
        failedView.isHidden = true
        failedView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private func setupChildVC() {
        guard let childVC = childVC else { return }
        addChild(childVC)
        view.addSubview(childVC.view)
        childVC.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        childVC.didMove(toParent: self)
    }
}

extension LoadingShellViewController {
    convenience init(roomsChildVCProvider: ((_ multiLevel: Bool, _ multiSelect: Bool) -> ChildVC)?) {
        self.init()

        SettingService.rxTenantSetting().subscribeForUI { [weak self] setting in
            let roomVC = roomsChildVCProvider?(setting.resourceDisplayType == .hierarchical && FG.multiLevel,
                                               setting.enableMultiSelection)
            self?.childVC = roomVC
            self?.status.accept(.finished)
        } onError: { [weak self] _ in
            // 降级展示
            let setting = SettingService.defaultTenantSetting
            self?.childVC = roomsChildVCProvider?(setting.resourceDisplayType == .hierarchical && FG.multiLevel,
                                                  setting.enableMultiSelection)
            self?.status.accept(.finished)
        }
        .disposed(by: disposeBag)
    }
}

extension LoadingShellViewController {
    enum DataPrepareStatus {
    case loading
    case finished
    case faild
    }
}
