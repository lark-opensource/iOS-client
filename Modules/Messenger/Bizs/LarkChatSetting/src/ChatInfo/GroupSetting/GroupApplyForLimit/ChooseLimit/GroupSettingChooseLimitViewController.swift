//
//  ChooseLimitViewController.swift
//  LarkChatSetting
//
//  Created by bytedance on 2021/10/18.
//

import Foundation
import UIKit
import FigmaKit
import RxSwift
import LarkNavigator
import LarkUIKit

final class GroupSettingChooseLimitViewController: BaseSettingController, UITableViewDelegate, UITableViewDataSource {
    private var disposeBag = DisposeBag()
    private lazy var tableView: InsetTableView = {
        let tableView = InsetTableView(frame: .zero)
        tableView.separatorStyle = .none
        return tableView
    }()
    private var viewModel: GroupSettingChooseLimitViewModel
    override func addCancelItem() -> UIBarButtonItem {
        let item = LKBarButtonItem(image: Resources.leftArrow, title: nil, fontStyle: .medium)
        item.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        navigationItem.leftBarButtonItem = item
        return item
    }
    init(viewModel: GroupSettingChooseLimitViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgFloatBase
        self.title = BundleI18n.LarkChatSetting.Lark_GroupLimit_SelectUpperLimitGroupSize_Subtitle
        self.view.addSubview(tableView)
        tableView.frame = self.view.bounds
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.lu.register(cellSelf: GroupSettingSingleCheckCell.self)
        tableView.register(
            GroupSettingSectionEmptyView.self,
            forHeaderFooterViewReuseIdentifier: String(describing: GroupSettingSectionEmptyView.self)
        )
        tableView.register(
            UITableViewHeaderFooterView.self,
            forHeaderFooterViewReuseIdentifier: "UITableViewHeaderFooterView")
        viewModel.reloadData.drive(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)
    }

    @objc
    private func makeSure() {
        viewModel.confirmOption()
        /// 延时一下 展示一下选中态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.navigationController?.dismiss(animated: true)
        }
    }
    @objc
    private func goBack() {
        navigationController?.dismiss(animated: true)
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: GroupSettingSingleCheckCell.lu.reuseIdentifier) as? GroupSettingSingleCheckCell {
            if viewModel.options.count - 1 == indexPath.row {
                cell.layoutSeparater(.none)
            } else {
                cell.layoutSeparater(.half)
            }
            cell.titleLabel.text = viewModel.indexText(indexPath: indexPath)
            cell.checkImage.isHidden = !viewModel.isIndexSelected(indexPath: indexPath)
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.options.count
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "UITableViewHeaderFooterView")
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(
            withIdentifier: String(describing: GroupSettingSectionEmptyView.self))
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        viewModel.setIndex(indexPath: indexPath)
        makeSure()
    }
}
