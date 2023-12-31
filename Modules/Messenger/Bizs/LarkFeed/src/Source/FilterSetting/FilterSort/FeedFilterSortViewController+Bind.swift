//
//  FeedFilterSortViewController+Bind.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/7/13.
//

import Foundation
import LarkUIKit
import EENavigator
import LarkMessengerInterface
import UniverseDesignToast

extension FeedFilterSortViewController {
    func bind() {
        viewModel.dataSourceDriver.drive(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.navigationItem.rightBarButtonItem = self.saveButtonItem
            self.tableView.reloadData()
            self.jumpToTargetIndexIfNeed()
        }).disposed(by: disposeBag)

        viewModel.hudShowDriver.drive(onNext: { [weak self] switchIsOn in
            self?.showHUD(switchIsOn: switchIsOn)
        }).disposed(by: disposeBag)

        viewModel.toastDriver.drive(onNext: { [weak self] text in
            guard !text.isEmpty else { return }
            guard let window = self?.view.window else {
                assertionFailure("cannot find window")
                return
            }
            UDToast.showTips(with: text, on: window)
        }).disposed(by: disposeBag)

        viewModel.pushVCDriver.drive(onNext: { [weak self] body in
            guard let self = self, let body = body else { return }
            self.navigator.present(body: body,
                                     wrap: LkNavigationController.self,
                                     from: self,
                                     prepare: { $0.modalPresentationStyle = .formSheet },
                                     animated: true)
        }).disposed(by: disposeBag)

        viewModel.refreshSectionDriver.drive(onNext: { [weak self] sectionType in
            guard let self = self, let sectionVM = self.viewModel.itemsMap[sectionType],
                  sectionVM.section < self.viewModel.items.count else { return }
            self.tableView.reloadSections([sectionVM.section], animationStyle: .none)
        }).disposed(by: disposeBag)

        viewModel.reloadSwitchDriver.drive(onNext: { [weak self] in
            guard let self = self, let sectionVM = self.viewModel.itemsMap[.filterSwitch],
                  sectionVM.section < self.viewModel.items.count else { return }
            self.tableView.reloadSections([sectionVM.section], animationStyle: .none)
        }).disposed(by: disposeBag)

        viewModel.pushSelectVCDriver.drive(onNext: { [weak self] dataSource in
            let vc = FeedFilterSelectViewController(dataSource: dataSource)
            vc.tapHandler = { [weak self] selectedType in
                self?.viewModel.addCommonlyUsedFilter(selectedType)
            }
            let nav = LkNavigationController(rootViewController: vc)
            self?.navigationController?.present(nav, animated: true, completion: nil)
        }).disposed(by: disposeBag)
    }
}
