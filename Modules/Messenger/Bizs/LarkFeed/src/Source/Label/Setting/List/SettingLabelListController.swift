//
//  SettingLabelListController.swift
//  LarkFeed
//
//  Created by aslan on 2022/4/20.
//

import Foundation
import LarkUIKit
import RxSwift
import LKCommonsLogging
import UniverseDesignToast
import UIKit
import FigmaKit
import EENavigator
import LarkSDKInterface
import LarkOpenFeed
import SwiftUI
import LarkContainer

final class SettingLabelListController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UserResolverWrapper {
    var userResolver: UserResolver { vm.userResolver }

    private static let logger = Logger.log(
        SettingLabelListController.self,
        category: "LarkFeed.SettingLabelListController")

    private var vm: SettingLabelListViewModel
    private let disposeBag = DisposeBag()

    fileprivate let tableView: InsetTableView = InsetTableView(frame: .zero)

    private(set) var completeButton: UIButton?

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    init(vm: SettingLabelListViewModel) {
        self.vm = vm
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addCancelItem()
        self.addNavigationBarRightItem()
        self.title = self.vm.title
        view.backgroundColor = UIColor.ud.bgFloatBase

        initializeTableView()

        self.bindViewModel()
    }

    private func bindViewModel() {
        observeDataSource()
        observeSelectEvent()
        observeUpdateLabelResult()
        self.vm.fetchLabelList()
    }

    private func observeDataSource() {
        self.vm.datasourceObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            self.tableView.reloadData()
        }, onError: { [weak self] _ in
            guard let `self` = self else {
                return
            }
            self.tableView.reloadData()
        }).disposed(by: self.disposeBag)
    }

    private func observeSelectEvent() {
        /// update confirm button style
        self.vm.selectObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] hasChange in
                guard let `self` = self else {
                    return
                }
                self.completeButton?.isEnabled = hasChange
            }).disposed(by: self.disposeBag)
    }

    private func observeUpdateLabelResult() {
        /// update labels select result
        self.vm.resultObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (selectCount, error) in
                guard let `self` = self else {
                    return
                }
                if let error = error {
                    UDToast.showFailure(with: self.vm.errorTip, on: self.view, error: error.transformToAPIError())
                } else {
                    if selectCount > 0 {
                        var tip = BundleI18n.LarkFeed.Lark_Core_RemovedNumLabels_Toast(selectCount)
                        UDToast.showSuccess(with: tip, on: self.view.window ?? self.view)
                    } else if selectCount < 0 {
                        var tip = BundleI18n.LarkFeed.Lark_Core_AddedNumLabels_Toast(-selectCount)
                        UDToast.showSuccess(with: tip, on: self.view.window ?? self.view)
                    } else {
                        var tip = BundleI18n.LarkFeed.Lark_Feed_Label_AddedSuccessfully_Toast
                        UDToast.showSuccess(with: tip, on: self.view.window ?? self.view)
                    }
                    self.dismiss(animated: true)
                }
            }).disposed(by: self.disposeBag)
    }

    fileprivate func addNavigationBarRightItem() {
        let rightItem = LKBarButtonItem(title: self.vm.rightItemTitle, fontStyle: .medium)
        rightItem.setProperty(font: LKBarButtonItem.FontStyle.medium.font, alignment: .right)
        rightItem.button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        rightItem.button.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        rightItem.button.addTarget(self, action: #selector(navigationBarRightItemTapped), for: .touchUpInside)
        self.completeButton = rightItem.button
        self.navigationItem.rightBarButtonItem = rightItem
        self.completeButton?.isEnabled = false
    }

    @objc
    fileprivate func navigationBarRightItemTapped() {
        self.vm.rightItemClick()
    }

    private func initializeTableView() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.rowHeight = 46
        self.tableView.estimatedRowHeight = 46
        self.tableView.estimatedSectionHeaderHeight = 0
        self.tableView.estimatedSectionFooterHeight = 0
        self.tableView.separatorStyle = .none
        self.tableView.contentInsetAdjustmentBehavior = .never
        self.tableView.backgroundColor = UIColor.ud.bgFloatBase
        let name = String(describing: SettingLabelListCell.self)
        self.tableView.register(SettingLabelListCell.self, forCellReuseIdentifier: name)
        self.tableView.register(SettingLabelAddCell.self, forCellReuseIdentifier: String(describing: SettingLabelAddCell.self))
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview()
        }
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // swiftlint:disable all
        if indexPath.row < self.vm.datasource.count {
            let label = self.vm.datasource[indexPath.row].feedGroup
            let title = label.name ?? ""
            let isSelected = self.vm.checkIsSelected(labelId: label.id)
            if let cell = tableView.cellForRow(at: indexPath) as? SettingLabelListCell {
                cell.set(title: title, isSelected: !isSelected)
                self.vm.updateLabelSelect(labelId: label.id)
            }
        } else if (indexPath.row == self.vm.datasource.count) {
            let body = SettingLabelBody(mode: .create,
                                        entityId: nil,
                                        labelId: nil,
                                        labelName: nil,
                                        successCallback: { [weak self] labelId in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.vm.updateLabelSelect(labelId: labelId)
                    self.vm.fetchLabelList()
                }
            })
            navigator.present(body: body, wrap: LkNavigationController.self, from: self)
            FeedTeaTrack.selectLabelCreateClick()
        }
        // swiftlint:enable all
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.vm.datasource.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < self.vm.datasource.count {
            let name = String(describing: SettingLabelListCell.self)
            if let cell = tableView.dequeueReusableCell(withIdentifier: name) as? SettingLabelListCell {
                let label = self.vm.datasource[indexPath.row].feedGroup
                let title = label.name ?? ""
                let isSelected = self.vm.checkIsSelected(labelId: label.id)
                cell.set(title: title, isSelected: isSelected)
                return cell
            }
        } else if indexPath.row == self.vm.datasource.count {
            let name = String(describing: SettingLabelAddCell.self)
            if let cell = tableView.dequeueReusableCell(withIdentifier: name) as? SettingLabelAddCell {
                return cell
            }
        }
        return UITableViewCell(style: .default, reuseIdentifier: "emptyCell")
    }
}
