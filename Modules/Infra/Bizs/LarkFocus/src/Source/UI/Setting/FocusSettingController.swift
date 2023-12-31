//
//  FocusSettingController.swift
//  ExpandableTable
//
//  Created by Hayden Wang on 2021/8/25.
//

import Foundation
import UIKit
import RxSwift
import FigmaKit
import LarkUIKit
import LarkEmotion
import EENavigator
import LarkContainer
import UniverseDesignIcon
import UniverseDesignToast
import LarkNavigator

public final class FocusSettingController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate, UserResolverWrapper {

    private let disposeBag = DisposeBag()

    @ScopedInjectedLazy private var focusManager: FocusManager?
    private var dataService: FocusDataService {
        focusManager?.dataService ?? .init(userResolver: userResolver)
    }

    lazy var allFocusStatus: [UserFocusStatus] = dataService.dataSource {
        didSet {
            specialStatus = getSpecialStatus()
            generalStatus = getGeneralStatus()
            tableView.reloadData()
        }
    }

    private lazy var specialStatus: [UserFocusStatus] = getSpecialStatus()

    private lazy var generalStatus: [UserFocusStatus] = getGeneralStatus()

    private func getSpecialStatus() -> [UserFocusStatus] {
        return allFocusStatus.filter { $0.isSystemStatus }
    }

    private func getGeneralStatus() -> [UserFocusStatus] {
        return allFocusStatus.filter { !$0.isSystemStatus }
    }

    /// 控制是否折叠超过限制数量的状态
    private var foldCell: Bool = true

    /// 最大展示 Cell 数（包含折叠按钮）
    private let maxUnfoldCell: Int = Int.max

    /// 是否显示 “展开 / 收起” 按钮
    private var haveExpandButton: Bool {
        generalStatus.count > maxUnfoldCell
    }

    /// 当前展示的状态数量（不包含折叠按钮）
    private var realDisplayStatusCount: Int {
        if foldCell {
            if haveExpandButton {
                return maxUnfoldCell - 1
            } else {
                return generalStatus.count
            }
        } else {
            return generalStatus.count
        }
    }

    private var canCreateNewFocus: Bool {
        dataService.canCreateNewStatus
    }

    private lazy var tableView: UITableView = {
        let table = InsetTableView()
        table.delegate = self
        table.dataSource = self
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = UITableView.automaticDimension
        table.estimatedSectionHeaderHeight = UITableView.automaticDimension
        table.estimatedSectionFooterHeight = UITableView.automaticDimension
        table.separatorStyle = .none
        table.backgroundColor = .clear
        table.register(cellWithClass: NormalSettingTableCell.self)
        table.register(cellWithClass: ButtonSettingTableCell.self)
        table.register(headerFooterViewClassWith: NormalSettingTableHeaderView.self)
        table.register(headerFooterViewClassWith: NormalSettingTableFooterView.self)
        return table
    }()

    public override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    public let userResolver: UserResolver
    public init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    deinit {
        // 侧划关闭手势无法捕捉，所以将关闭页面的埋点放在 deinit 里
        FocusTracker.didTapBackButtonInSettingPage(syncSetting: [:])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        FocusManager.logger.debug("\(#function), line: \(#line): user did open focus setting page.")
        view.backgroundColor = UIColor.ud.bgFloatBase
        title = BundleI18n.LarkFocus.Lark_Profile_PersonalStatus
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        // Reload data
        dataService.reloadData()
        // Observe data change
        dataService.dataSourceObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] statusList in
                guard let self = self else { return }
                self.allFocusStatus = statusList
                FocusManager.logger.debug("\(#function), line: \(#line): receive status list update: \(statusList).")
            }).disposed(by: disposeBag)
        dataService.canCreateNewStatusObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            }).disposed(by: disposeBag)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        if Display.pad {
            self.preferredContentSize = CGSize(width: 540, height: 620)
            self.modalPresentationControl.dismissEnable = true
        }
        FocusTracker.didShowFocusSettingPage()
    }

    // MARK: - DataSource

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // 隐藏最后一行的分割线
        guard let cell = cell as? NormalSettingTableCell else { return }
        let numberOfRow = tableView.numberOfRows(inSection: indexPath.section)
        let isLastRowInSection = indexPath.row == numberOfRow - 1
        cell.setDividingLineHidden(isLastRowInSection)
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return allSectionNumber
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case sectionIndexOfSpecialStatus:
            // 特殊状态列表
            return specialStatus.count
        case sectionIndexOfGeneralStatus:
            // 通用状态列表
            return realDisplayStatusCount + (haveExpandButton ? 1 : 0)
        case sectionIndexOfAddStatusButton:
            // 新建状态按钮
            return 1
        default:
            return 0
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case sectionIndexOfSpecialStatus:
            // 特殊状态列表
            let cell = tableView.dequeueReusableCell(withClass: NormalSettingTableCell.self)
            cell.controlType = .arrow
            cell.textLayout = .horizontal
            let focusStatus = specialStatus[indexPath.row]
            cell.title = focusStatus.title
            cell.icon = FocusManager.getFocusIcon(byKey: focusStatus.iconKey) ?? EmotionResouce.placeholder
            return cell
        case sectionIndexOfGeneralStatus:
            // 通用状态列表
            if indexPath.row == realDisplayStatusCount {
                let cell = tableView.dequeueReusableCell(withClass: ButtonSettingTableCell.self)
                if foldCell {
                    cell.title = BundleI18n.LarkFocus.Lark_Profile_ShowAll
                    cell.rightIcon = UDIcon.downOutlined.ud.withTintColor(UIColor.ud.primaryContentDefault)
                } else {
                    cell.title = BundleI18n.LarkFocus.Lark_Profile_Hide
                    cell.rightIcon = UDIcon.upOutlined.ud.withTintColor(UIColor.ud.primaryContentDefault)
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withClass: NormalSettingTableCell.self)
                cell.controlType = .arrow
                cell.textLayout = .horizontal
                let focusStatus = generalStatus[indexPath.row]
                cell.title = focusStatus.title
                cell.icon = FocusManager.getFocusIcon(byKey: focusStatus.iconKey) ?? EmotionResouce.placeholder
                return cell
            }
        case sectionIndexOfAddStatusButton:
            // 新建状态按钮
            let cell = tableView.dequeueReusableCell(withClass: NormalSettingTableCell.self)
            cell.controlType = .arrow
            cell.textLayout = .horizontal
            cell.title = BundleI18n.LarkFocus.Lark_Profile_AddNewStatus
            if canCreateNewFocus {
                cell.titleLabel.textColor = UIColor.ud.textTitle
                cell.icon = UDIcon.addOutlined.ud.withTintColor(UIColor.ud.iconN1)
            } else {
                cell.titleLabel.textColor = UIColor.ud.textDisabled
                cell.icon = UDIcon.addOutlined.ud.withTintColor(UIColor.ud.iconDisabled)
            }
            return cell
        default:
            return UITableViewCell()
        }
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withClass: NormalSettingTableHeaderView.self)
        switch section {
        case sectionIndexOfSpecialStatus:
            header.title = BundleI18n.LarkFocus.Lark_Status_SystemStatus_SubTitle
        case sectionIndexOfGeneralStatus:
            header.title = BundleI18n.LarkFocus.Lark_Status_GeneralStatus_SubTitle
        default:
            header.title = nil
        }
        return header
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch section {
        case sectionIndexOfSpecialStatus:
            let footer = tableView.dequeueReusableHeaderFooterView(withClass: NormalSettingTableFooterView.self)
            footer.title = BundleI18n.LarkFocus.Lark_Status_SystemStatus_AboveDescription
            return footer
        default:
            return UIView()
        }
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch section {
        case sectionIndexOfSpecialStatus:
            return UITableView.automaticDimension
        default:
            return CGFloat.leastNonzeroMagnitude
        }
    }

    // MARK: - Delegate

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case sectionIndexOfSpecialStatus:
            let status = specialStatus[indexPath.row]
            editStatus(status)
            FocusTracker.didTapStatusRowInSettingPage(status: status)
        case sectionIndexOfGeneralStatus:
            if indexPath.row == realDisplayStatusCount {
                // 展开/收起
                foldCell.toggle()
                FocusTracker.didToggleShowAllStatusInSettingPage(isExpanded: !foldCell)
                tableView.reloadData()
            } else {
                // 编辑个人状态
                let status = generalStatus[indexPath.row]
                editStatus(status)
                FocusTracker.didTapStatusRowInSettingPage(status: status)
            }
        case sectionIndexOfAddStatusButton:
            // 创建新状态
            createNewStatus()
            FocusTracker.didTapCreateNewStatusInSettingPage()
        default:
            break
        }
    }
}

extension FocusSettingController {

    private var hasSpecialStatus: Bool {
        return !specialStatus.isEmpty
    }

    private var allSectionNumber: Int {
        return hasSpecialStatus ? 3 : 2
    }

    private var sectionIndexOfSpecialStatus: Int {
        // -1 代表不存在 SpecialStatus section
        return hasSpecialStatus ? 0 : -1
    }

    private var sectionIndexOfGeneralStatus: Int {
        return hasSpecialStatus ? 1 : 0
    }

    private var sectionIndexOfAddStatusButton: Int {
        return hasSpecialStatus ? 2 : 1
    }
}

extension FocusSettingController {

    // MARK: Create status

    private func createNewStatus() {
        if canCreateNewFocus {
            let focusManager = try? userResolver.resolve(assert: FocusManager.self)

            let createVC = (focusManager?.isStatusNoteEnabled ?? false) ? getNewCreationViewController() : getOldCreationViewController()
            userResolver.navigator.present(createVC, wrap: LkNavigationController.self, from: self) { vc in
                vc.modalPresentationStyle = .formSheet
            }
        } else {
            UDToast.autoDismissWarning(BundleI18n.LarkFocus.Lark_Profile_CustomStatusLimit, on: view)
        }
    }

    // MARK: Update status

    private func editStatus(_ status: UserFocusStatus) {
        let editVC = EditViewControllerGenerator.generateEditViewController(userResolver: userResolver, focusStatus: status) { [weak self] (_, _) in
            self?.dataService.reloadData()
        } onUpdatingSuccess: { [weak self] updatedStaus in
            self?.dataService.updateDataSource(with: updatedStaus)
        }

        userResolver.navigator.present(editVC, wrap: LkNavigationController.self, from: self) { vc in
            vc.modalPresentationStyle = .formSheet
        }
    }
}

extension FocusSettingController {
    func getOldCreationViewController() -> UIViewController {
        let createVC = FocusCreationNoStatusDescController(userResolver: userResolver)
        createVC.onCreatingSuccess = { [weak self] newStatus in
            self?.dataService.addDataSource(newStatus)
        }
        return createVC
    }

    func getNewCreationViewController() -> UIViewController {
        let createVC = FocusCreationController(userResolver: userResolver)
        createVC.onCreatingSuccess = { [weak self] newStatus in
            self?.dataService.addDataSource(newStatus)
        }
        return createVC
    }
}
