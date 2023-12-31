//
//  NativeSwitchUserViewController.swift
//  LarkAccount
//
//  Created by bytedance on 2022/4/21.
//

import Foundation
import UIKit
import FigmaKit
import RxSwift
import LarkContainer
import LarkUIKit
import EENavigator
import LKCommonsLogging
import UniverseDesignButton

typealias BaseLayout = BaseViewController.BaseLayout

class NativeSwitchUserViewController: UIViewController {

    @Provider private var launcher: Launcher
    @Provider private var switchUserService: NewSwitchUserService

    private let disposeBag = DisposeBag()

    static let logger = Logger.plog(NativeSwitchUserViewController.self, category: "LarkAccount.NativeSwitchUserViewController")

    let vm: NativeSwitchUserViewModel

    // 根据页面层级 willAppear 阶段自动生成
    lazy var backButton = { UIButton(type: .custom) }()

    init(vm: NativeSwitchUserViewModel) {
        self.vm = vm
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        addBackOrCloseButton()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.ud.bgBase
        makeSubviewsAndLayout()
        subscribeDataSource()
    }

    func subscribeDataSource() {
        vm.dataSource
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            }).disposed(by: disposeBag)
    }

    func makeSubviewsAndLayout() {

        titleLabel.text = vm.title
        self.view.addSubview(titleLabel)

        titleLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(BaseViewController.BaseLayout.visualNaviBarHeight + CL.itemSpace)
            make.height.equalTo(BaseViewController.BaseLayout.titleLabelHeight)
        }

        self.view.addSubview(tableView)

        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.topSpace)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        //group 的 tableview 左右间距会在不同设备上有不同的表现。titleLabel 设置一个 autolayout。
        let titleLabelLeadingConstraint = titleLabel.leadingAnchor.constraint(equalTo: tableView.insetLayoutGuide.leadingAnchor)
        let titleLabelTrailingConstraint = titleLabel.trailingAnchor.constraint(equalTo: tableView.insetLayoutGuide.trailingAnchor)
        NSLayoutConstraint.activate([titleLabelLeadingConstraint, titleLabelTrailingConstraint])
    }

    func addBackOrCloseButton() {
        guard backButton.superview == nil else { return }

        if hasBackPage {
            backButton.setImage(BundleResources.UDIconResources.leftOutlined.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
            backButton.rx.controlEvent(.touchUpInside).observeOn(MainScheduler.instance).subscribe { [weak self] (_) in
                self?.clickBackOrClose(isBack: true)
            }.disposed(by: self.disposeBag)
            view.addSubview(backButton)
            backButton.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(CL.itemSpace)
                let navigationBarHeight = self.navigationController?.navigationBar.frame.size.height ?? 0
                var offset = (navigationBarHeight - BaseLayout.backHeight) / 2
                if offset < 0 {
                    offset = CL.backButtonTopSpace
                }
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(Display.pad && self.isInFormSheet ? CL.itemSpace : offset)
                make.size.equalTo(CGSize(width: BaseLayout.backHeight, height: BaseLayout.backHeight))
            }
        } else if presentingViewController != nil {
            backButton.setImage(BundleResources.UDIconResources.closeOutlined, for: .normal)
            backButton.rx.controlEvent(.touchUpInside).observeOn(MainScheduler.instance).subscribe { [weak self] (_) in
                self?.clickBackOrClose(isBack: false)
            }.disposed(by: self.disposeBag)
            view.addSubview(backButton)
            backButton.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(CL.itemSpace)
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(Display.pad && self.isInFormSheet ? CL.itemSpace : CL.backButtonTopSpace)
                make.size.equalTo(CGSize(width: BaseLayout.backHeight, height: BaseLayout.backHeight))
            }
        }
    }

    private func clickBack() {
        if let nc = navigationController,
           let index = nc.realViewControllers.firstIndex(of: self),
           index == 0 {
            clickClose()
            return
        }
        navigationController?.popViewController(animated: true)
    }

    private func clickClose() {
        self.dismiss(animated: true) {}
    }

    func clickBackOrClose(isBack: Bool) {
        if isBack {
            clickBack()
        } else {
            clickClose()
        }
    }

    var isInFormSheet: Bool {
        guard presentingViewController != nil else { return false }

        var inFormSheet = modalPresentationStyle == .formSheet
        if !inFormSheet, let navi = self.navigationController {
            // 自己不是 fromSheet 但导航是
            inFormSheet = navi.modalPresentationStyle == .formSheet
        }
        return inFormSheet
    }

    lazy internal var tableView: InsetTableView = {
        let tb = InsetTableView(frame: .zero)
        tb.lu.register(cellSelf: NativeSwitchUserTableViewCell.self)
        tb.backgroundColor = .clear
        tb.separatorStyle = .none
        tb.rowHeight = Layout.rowHeight
        tb.sectionHeaderHeight = UITableView.automaticDimension
        tb.dataSource = self
        tb.delegate = self
        tb.contentInsetAdjustmentBehavior = .scrollableAxes
        tb.showsVerticalScrollIndicator = false
        return tb
    }()

    lazy internal var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: Layout.titleLabelFontSize, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 0
        return titleLabel
    }()

    lazy internal var headerView: UIView = {
        let headerView = UIView(frame: .zero)
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        label.font = Layout.sectionHeaderFont
        label.textColor = UIColor.ud.textCaption
        label.attributedText = V3ViewModel.attributedString(for: vm.subTitle, UIColor.ud.textCaption)

        headerView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().inset(44)
        }
        return headerView
    }()

    lazy internal var footerView: UIView = {
        let footerView = UIView(frame: .zero)
        let addAccountBtn = UIButton.init(type: .custom)
        addAccountBtn.setTitle(BundleI18n.suiteLogin.Lark_Shared_Passport_SwitchAccount_AddAccountTab, for: .normal)
        addAccountBtn.titleLabel?.font = UIFont.systemFont(ofSize: Layout.addAccountBtnFontSize)
        addAccountBtn.imageView?.contentMode = .scaleAspectFit
        addAccountBtn.contentHorizontalAlignment = .fill
        addAccountBtn.contentVerticalAlignment = .fill
        addAccountBtn.imageEdgeInsets = UIEdgeInsets(top: Layout.addAccountPadding, left: 0, bottom: Layout.addAccountPadding, right: Layout.addAccountPadding)
        addAccountBtn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        addAccountBtn.setImage(BundleResources.LarkAccount.V3.create_tenant, for: .normal)
        addAccountBtn.addTarget(self, action: #selector(toLoginVC(sender:)), for: .touchUpInside)
        footerView.addSubview(addAccountBtn)

        addAccountBtn.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(Layout.addAccountHeight)
        }
        return footerView
    }()
}

extension NativeSwitchUserViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let tableViewHeight = tableView.frame.size.height
        let minFooterHeight = Layout.minTableFooterHeight
        let headerHeight = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        let height = tableViewHeight - CGFloat(vm.dataSource.value.count) * Layout.rowHeight  -  headerHeight - Layout.tableFooterBottomInset - view.safeAreaInsets.bottom

        if (height < minFooterHeight) {
            return minFooterHeight
        } else {
            return height
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return footerView
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return headerView
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? NativeSwitchUserTableViewCell
        cell?.updateSelection(false)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        guard let cell = cell as? NativeSwitchUserTableViewCell, let userID = cell.data?.userId, cell.data?.isValid == true else {
            Self.logger.error("n_action_native_switchUser", body: "no userID or inValid")
            return
        }

        //更新 UI
        cell.updateSelection(true)

        switchUserService.switchTo(userID: userID, complete: { [weak self] flag in
            guard let self = self else { return }
            self.tableView.deselectRow(at: indexPath, animated: true)
        }, context: vm.context)
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? NativeSwitchUserTableViewCell
        cell?.updateSelection(false)
    }

}

extension NativeSwitchUserViewController: UITableViewDataSource {

    func dataSource(section: Int) -> [SelectUserCellData] {
        return vm.dataSource.value
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource(section: section).count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let userInfo = vm.getData(of: indexPath)
        let cell: NativeSwitchUserTableViewCell
        if let dequeueCell = tableView.dequeueReusableCell(withIdentifier: NativeSwitchUserTableViewCell.lu.reuseIdentifier,
                                                           for: indexPath) as? NativeSwitchUserTableViewCell {
            cell = dequeueCell
        } else {
            cell = NativeSwitchUserTableViewCell()
        }
        cell.data = userInfo
        return cell
    }
}

extension NativeSwitchUserViewController {

    @objc
    private func toLoginVC(sender: UIButton) {
        guard let nav = self.navigationController else {
            Self.logger.error("n_action_switchUser", body: "viewController don't have navVC")
            return
        }
        launcher.pushToTeamConversion(fromNavigation: nav, trackPath: nil)
    }
}


extension NativeSwitchUserViewController {
    fileprivate struct Layout {
        static let minTableFooterHeight: CGFloat = 52
        static let tableFooterBottomInset: CGFloat = 22
        static let topSpace: CGFloat = 12
        static let rowHeight: CGFloat = 72
        static let titleLabelFontSize: CGFloat = 26
        static let addAccountBtnFontSize: CGFloat = 16
        static let addAccountPadding: CGFloat = 2
        static let addAccountHeight: CGFloat = 24
        static let sectionHeaderVertical: CGFloat = 12
        static let sectionHeaderHorizonal: CGFloat = 4
        static let firstSectionHeaderVertical: CGFloat = 24.0
        static let sectionHeaderFont: UIFont = UIFont.systemFont(ofSize: 14.0)
    }
}
