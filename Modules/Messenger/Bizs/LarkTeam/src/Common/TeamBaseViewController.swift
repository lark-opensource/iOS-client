//
//  TeamBaseViewController.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/7/5.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LarkModel
import LarkCore
import EENavigator
import LKCommonsLogging
import LarkAlertController
import LarkMessengerInterface
import LarkSplitViewController

protocol TeamBaseViewControllerAbility: UIViewController {
    func reloadWithAnimation(_ animated: Bool)
}

final class TeamBaseViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {

    // UI
    var tableView: UITableView?

    // Logic
    private let disposeBag = DisposeBag()
    private(set) var viewModel: TeamBaseViewModel
    private var maxWidth: CGFloat?
    private(set) var createButton: UIButton?
    private var isShowRightItem: Bool {
        viewModel.rightItemInfo.0
    }

    init(viewModel: TeamBaseViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        self.commInit()
        self.configViewModel()

        self.viewModel.targetVC = self
        self.viewModel.reloadData
            .drive(onNext: { [weak self] (_) in
                self?.tableView?.reloadData()
            }).disposed(by: self.disposeBag)
        self.viewModel.viewDidLoadTask()

        self.viewModel.rightItemEnableRelay.asObservable()
            .asDriver(onErrorJustReturn: true)
            .drive(onNext: { [weak self] enable in
                self?.createButton?.isEnabled = enable
            }).disposed(by: self.disposeBag)

        self.viewModel.rightItemColorStyleRelay.asObservable()
            .asDriver(onErrorJustReturn: true)
            .drive(onNext: { [weak self] enable in
                guard let self = self else { return }
                guard self.createButton?.isEnabled ?? false else { return }
                if enable {
                    self.createButton?.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
                } else {
                    self.createButton?.setTitleColor(UIColor.ud.N400, for: .normal)
                }
            }).disposed(by: self.disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.viewWillAppearTask()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.viewWillDisappearTask()
    }

    private func configViewModel() {
        viewModel.targetVC = self
    }

    @objc
    override func closeBtnTapped() {
        viewModel.closeItemClick()
    }

    override func backItemTapped() {
        super.backItemTapped()
        viewModel.backItemTapped()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if Display.pad && UIApplication.shared.applicationState == .background { return }
        self.maxWidth = size.width
        self.tableView?.reloadData()
    }

    private func commInit() {
        commInitNavigation()
        commTableView()
    }

    private func commInitNavigation() {
        self.title = viewModel.title
        if isShowRightItem {
            let button = UIButton(type: .custom)
            self.createButton = button
            button.setTitle(viewModel.rightItemInfo.1, for: .normal)
            button.setTitle(viewModel.rightItemInfo.1, for: .selected)
            button.setTitle(viewModel.rightItemInfo.1, for: .disabled)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            button.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
            button.isEnabled = false
            button.setTitleColor(UIColor.ud.N400, for: .disabled)
            button.addTarget(self, action: #selector(navigationBarRightItemTapped), for: .touchUpInside)
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
        }

        if let leftItemInfo = viewModel.leftItemInfo {
            let leftItem = LKBarButtonItem(title: leftItemInfo)
            leftItem.setProperty(alignment: .left)
            leftItem.button.setTitleColor(UIColor.ud.textTitle, for: .normal)
            leftItem.button.addTarget(self, action: #selector(closeBtnTapped), for: .touchUpInside)
            self.navigationItem.leftBarButtonItem = leftItem
        }
    }

    @objc
    func navigationBarRightItemTapped() {
        self.viewModel.rightItemClick()
    }

    private func commTableView() {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = UIColor.clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 66
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        tableView.contentInsetAdjustmentBehavior = .never

        tableView.lu.register(cellSelf: TeamTapCell.self)
        tableView.lu.register(cellSelf: TeamInfoCell.self)
        tableView.lu.register(cellSelf: TeamInputCell.self)
        tableView.lu.register(cellSelf: TeamMemberCell.self)
        tableView.lu.register(cellSelf: TeamConfigCell.self)
        tableView.lu.register(cellSelf: TeamAvatarCell.self)
        tableView.lu.register(cellSelf: TeamDescriptionCell.self)
        tableView.lu.register(cellSelf: TeamAvatarConfigCell.self)
        tableView.lu.register(cellSelf: TeamDescriptionInputCell.self)

        tableView.register(
            TeamSectionHeaderView.self,
            forHeaderFooterViewReuseIdentifier: String(describing: TeamSectionHeaderView.self)
        )
        tableView.register(
            TeamSectionFooterView.self,
            forHeaderFooterViewReuseIdentifier: String(describing: TeamSectionFooterView.self)
        )
        self.tableView = tableView
    }

    // MARK: - UITableViewDelegate
    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    // swiftlint:enable did_select_row_protection

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard viewModel.items.sectionHeader(at: section) != nil else {
            return 8
        }
        return 36
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard viewModel.items.sectionFooter(at: section) != nil else {
            return 0
        }
        return 36
    }

    // MARK: - UITableViewDataSource
    private func item<T>(for items: [T], at index: Int) -> T? {
        guard index > -1, index < items.count else { return nil }
        return items[index]
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.items.numberOfSections
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let header = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: String(describing: TeamSectionHeaderView.self)) as? TeamSectionHeaderView else {
            return UIView()
        }
        header.titleLabel.text = viewModel.items.sectionHeader(at: section) ?? ""
        return header
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footer = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: String(describing: TeamSectionFooterView.self)) as? TeamSectionFooterView else {
            return UIView()
        }
        footer.titleLabel.text = viewModel.items.sectionFooter(at: section) ?? ""
        return footer
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.items.numberOfRows(in: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let item = viewModel.items.item(at: indexPath),
            var cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier) as? TeamCellProtocol {
            cell.updateAvailableMaxWidth(self.maxWidth ?? self.view.bounds.width)
            cell.item = item
            cell.cellForRowTask()
            return (cell as? UITableViewCell) ?? UITableViewCell()
        }
        return UITableViewCell()
    }
}

extension TeamBaseViewController: TeamBaseViewControllerAbility {
    func reloadWithAnimation(_ animated: Bool) {
        func reload() {
            tableView?.beginUpdates()
            tableView?.endUpdates()
        }
        if animated {
            reload()
        } else {
            UIView.performWithoutAnimation {
                reload()
            }
        }
    }
}
