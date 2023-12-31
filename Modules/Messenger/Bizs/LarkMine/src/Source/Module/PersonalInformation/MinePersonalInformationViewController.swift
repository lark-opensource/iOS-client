//
//  MinePersonalInformationViewController.swift
//  LarkMine
//
//  Created by 姚启灏 on 2018/12/26.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import RxSwift
import LarkExtensions
import EENavigator
import LarkMessengerInterface
import FigmaKit
import LarkSetting
import UniverseDesignIcon
import UniverseDesignToast
import UniverseDesignDialog

// 自定义类型字段
class MinePersonalInformationCustomField {
    var key: String
    var name: String
    var text: String = ""
    var link: String = ""
    var type: MinePersonalInformationCustomFieldType = .text
    var enableEdit: Bool = false

    init(key: String, name: String, text: String, link: String, type: MinePersonalInformationCustomFieldType, enableEdit: Bool) {
        self.key = key
        self.name = name
        self.text = text
        self.link = link
        self.type = type
        self.enableEdit = enableEdit
    }
}

enum MinePersonalInformationCustomFieldType {
    case text
    case link
}

final class MinePersonalInformationViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    enum CellType {
        /// 头像
        case avatar(String)
        /// 姓名
        case name(String)
        /// 别名
        case anotherName(String)
        /// 部门
        case department(String)
        /// 企业认证
        case company(String)
        /// 二维码
        case myQrcode(String)
        /// 勋章
        case myMedal(String)
        /// 个人签名
        case personalSignature(String)
        /// 自定义
        case custom(field: MinePersonalInformationCustomField)
    }

    /// 状态保存成功执行的回调
    var completion: ((String) -> Void)?

    private lazy var isMedalWallEntryShown: Bool = false
    private let disposeBag = DisposeBag()
    // 工位和自定义类型通过server请求判断是否展示
    private var customDataSource: [MinePersonalInformationCustomField] = []
    private var personalDataSource: [[CellType]] {
        let enableQrcodeEntry = self.viewModel.enableQrcodeEntry
        let enabelMedal = self.viewModel.enabelMedal
        var dataSource: [[CellType]] = [
            // section 0
            [
                .avatar(BundleI18n.LarkMine.Lark_Legacy_MineProfileDetailImage),
                .name(BundleI18n.LarkMine.Lark_Legacy_MineDataName)
            ],
            // section 1
            []
        ]
        if viewModel.isAnotherNameEnable {
            dataSource[0].append(
                .anotherName(self.viewModel.anotherNameTitle)
            )
        }
        if enableQrcodeEntry {
            dataSource[0].append(
                .myQrcode(BundleI18n.LarkMine.Lark_Legacy_MyQRCode)
            )
        }
        if enabelMedal {
            isMedalWallEntryShown = true
            dataSource[0].append(.myMedal(BundleI18n.LarkMine.Lark_Profile_MyBadges))
        }
        dataSource[0].append(.personalSignature(BundleI18n.LarkMine.Lark_Profile_PersonalSignature))
        if viewModel.isTenantNameEnabled {
            dataSource[1].append(.company(BundleI18n.LarkMine.Lark_Profile_Orgnization))
        }
        if viewModel.isDepartmentEnabled {
            dataSource[1].append(
                .department(BundleI18n.LarkMine.Lark_Legacy_MineDataDepartment)
            )
        }
        customDataSource.forEach({
            dataSource[1].append(.custom(field: $0))
        })
        return dataSource
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    private let viewModel: MinePersonalInformationViewModel

    private lazy var tableView: UITableView = {
        let tableView = InsetTableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 50
        tableView.tableHeaderView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 8)))
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.lu.register(cellSelf: MinePersonalInformationAvatarViewCell.self)
        tableView.lu.register(cellSelf: MinePersonalInformationDetailViewCell.self)
        tableView.lu.register(cellSelf: MinePersonalInformationAuthViewCell.self)
        return tableView
    }()
    var router: MinePersonalInformationRouter?

    init(viewModel: MinePersonalInformationViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.LarkMine.Lark_Legacy_Information
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.bottom.top.left.right.equalToSuperview()
        }
        /// 监听用户信息变化刷新界面
        self.viewModel.currentChatterObservable
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                /// 修改别名时候刷新UI
                self.viewModel.anotherName = self.viewModel.currentUser.anotherName
                self.tableView.reloadData()
            }).disposed(by: disposeBag)

        self.viewModel.currentUserStateObservable
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.tableView.reloadData()
            }).disposed(by: disposeBag)
        self.viewModel.requestProfileInformation {[weak self] (_, _) in
            guard let self = self else { return }
            let verifiedStatus = "\(self.viewModel.authInfo.certificateStatus.rawValue)"
            MineTracker.trackPersonalInfoViewShow(params: ["verified_status": verifiedStatus])
            self.tableView.reloadData()
        }
        /// 获取修改用户名权限
        self.viewModel.fetchUserUpdateNamePermission().observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.tableView.reloadData()
            }).disposed(by: disposeBag)
        /// 获取自定义字段和工位信息
        self.viewModel.requestStationAndCustomInfo().observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] fields in
                guard let self = self else { return }
                self.customDataSource = fields
                self.tableView.reloadData()
        }).disposed(by: disposeBag)
        MineTracker.trackIsMedalWallEntryShown(self.isMedalWallEntryShown)
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return personalDataSource.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < personalDataSource.count else {
            return 0
        }
        return personalDataSource[section].count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: "UITableViewHeaderFooterView")
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var tableViewCell = UITableViewCell()
        guard indexPath.section < personalDataSource.count, indexPath.row < personalDataSource[indexPath.section].count else {
            return tableViewCell
        }
        switch personalDataSource[indexPath.section][indexPath.row] {
        case .avatar(let title):
            let identifier = MinePersonalInformationAvatarViewCell.lu.reuseIdentifier
            if let cell = tableView.dequeueReusableCell( withIdentifier: identifier) as? MinePersonalInformationAvatarViewCell {
                cell.set(title: title, avatarKey: self.viewModel.currentUser.avatarKey, entityId: self.viewModel.currentUser.id)
                tableViewCell = cell
            }
        case .name(let title):
            let identifier = MinePersonalInformationDetailViewCell.lu.reuseIdentifier
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MinePersonalInformationDetailViewCell {
                let name = viewModel.canChangeUserName == nil ? "" : viewModel.currentUser.localizedName
                cell.set(title: title, detail: name, showArrow: (self.viewModel.canChangeUserName ?? false) )
                tableViewCell = cell
            }
        case .anotherName(let title):
            let identifier = MinePersonalInformationDetailViewCell.lu.reuseIdentifier
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MinePersonalInformationDetailViewCell {
                var name = self.viewModel.anotherName
                if self.viewModel.canChangeAnotherName && self.viewModel.anotherName.isEmpty {
                    name = BundleI18n.LarkMine.Lark_ProfileMyAlias_EnterAlias_Placeholder
                }
                cell.set(title: title, detail: name, showArrow: self.viewModel.canChangeAnotherName)
                tableViewCell = cell
            }
        case .department(let title):
            let identifier = MinePersonalInformationDetailViewCell.lu.reuseIdentifier
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MinePersonalInformationDetailViewCell {
                cell.set(title: title, detail: self.viewModel.department, showArrow: false)
                tableViewCell = cell
            }
        case .company(let title):
            let identifier = MinePersonalInformationAuthViewCell.lu.reuseIdentifier
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MinePersonalInformationAuthViewCell {
                cell.set(
                    title: title,
                    detail: viewModel.tenantName,
                    hasAuth: viewModel.authInfo.hasAuth,
                    isAuth: viewModel.authInfo.isAuth,
                    showArrow: !viewModel.authInfo.authURL.isEmpty
                )
                tableViewCell = cell
            }
        case .myQrcode(let title):
            let identifier = MinePersonalInformationDetailViewCell.lu.reuseIdentifier
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MinePersonalInformationDetailViewCell {
                cell.set(
                    title: title,
                    detail: "",
                    detailIcon: UDIcon.getIconByKey(.qrOutlined).ud.withTintColor(UIColor.ud.iconN3),
                    showArrow: true
                )

                tableViewCell = cell
            }
        case .myMedal(let title):
            let identifier = MinePersonalInformationDetailViewCell.lu.reuseIdentifier
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MinePersonalInformationDetailViewCell {
                cell.set(title: title, detail: "", detailIcon: nil, showArrow: true)
                tableViewCell = cell
            }
        case .personalSignature(let title):
            let identifier = MinePersonalInformationDetailViewCell.lu.reuseIdentifier
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MinePersonalInformationDetailViewCell {
                cell.set(
                    title: title,
                    detail: self.viewModel.personalStatus ?? "",
                    showArrow: true
                )
                tableViewCell = cell
            }
        case .custom(let field):
            let identifier = MinePersonalInformationDetailViewCell.lu.reuseIdentifier
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MinePersonalInformationDetailViewCell {
                let detail = !field.text.isEmpty ? field.text : BundleI18n.LarkMine.Lark_Core_PersonalInformationNull_Text
                let showLink = field.type == .link && !field.text.isEmpty
                cell.set(title: field.name, detail: detail, showArrow: field.enableEdit, showLink: showLink)
                tableViewCell = cell
            }
        default: break
        }
        return tableViewCell
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section < personalDataSource.count, indexPath.row < personalDataSource[indexPath.section].count else {
            return
        }
        let item = self.personalDataSource[indexPath.section][indexPath.row]
        switch item {
        case .avatar:
            let avatarKey = self.viewModel.currentUser.avatarKey
            let entityId = self.viewModel.currentUser.id
            self.router?.presentAssetBrowser(self, avatarKey: avatarKey, entityId: entityId, supportReset: !self.viewModel.isDefaultAvatar)
        case .name:
            // 有权限进入姓名修改界面，无权限不进行任何操作
            var changeNameEnable = false
            if let canChangeUserName = self.viewModel.canChangeUserName, canChangeUserName {
                let name = self.viewModel.currentUser.localizedName
                self.router?.pushSetUserName(self, oldName: name)
                changeNameEnable = canChangeUserName
            }
            // 无权限给一个弹窗提示
            else {
                UDToast.showTips(with: BundleI18n.LarkMine.Lark_Core_UnableEditPersonalInfo_Toast, on: self.view)
            }
            MineTracker.trackEditNameEntrance(isPermission: changeNameEnable)
        case .anotherName:
            // 有权限进入别名修改界面，无权限不进行任何操作
            if self.viewModel.canChangeAnotherName {
                let name = self.viewModel.anotherName
                self.router?.pushSetAnotherName(self, oldName: name)
            }
            // 无权限给一个弹窗提示
            else {
                UDToast.showTips(with: BundleI18n.LarkMine.Lark_Core_UnableEditPersonalInfo_Toast, on: self.view)
            }
            MineTracker.trackEditAnotherNameEntrance(isPermission: self.viewModel.canChangeAnotherName)
            break
        case .department:
            break
        case .company:
            self.router?.openLink(self, linkURL: URL(string: viewModel.authInfo.authURL), isShowDetail: true)
            let verifiedStatus = "\(self.viewModel.authInfo.certificateStatus.rawValue)"
            MineTracker.trackPersonalInfoViewClick(params: ["click": "enterprise",
                                                            "verified_status": verifiedStatus,
                                                            "target": "madmin_company_certificate_view"])
        case .myQrcode:
            /// 我的二维码
            self.router?.openMyQrcodeController(self)
        case .myMedal:
            self.router?.openMedalController(self, userID: self.viewModel.currentUser.id)
            MineTracker.trackIsMedalOptionClicked()
        case .personalSignature:
            router?.openWorkDescription(self, completion: {  [weak self] newSignature in
                guard let self = self else { return }
                self.viewModel.personalStatus = newSignature
                self.tableView.reloadData()
                self.completion?(newSignature)
            })
        case .custom(let field):
            guard field.enableEdit else {
                UDToast.showTips(with: BundleI18n.LarkMine.Lark_Core_UnableEditPersonalInfo_Toast, on: self.view)
                return
            }
            if field.type == .text {
                self.router?.pushSetTextViewController(self, key: field.key, pageTitle: field.name, text: field.text) { [weak self] newText in
                    guard let self = self, var item = self.customDataSource.first(where: { $0.key == field.key }) else { return }
                    DispatchQueue.main.async {
                        UDToast.showSuccess(with: BundleI18n.LarkMine.Lark_Legacy_SaveSuccess, on: self.view)
                        item.text = newText
                        self.tableView.reloadData()
                    }
                }
            } else {
                self.router?.pushSetLinkViewController(self, key: field.key, pageTitle: field.name, text: field.text, link: field.link) { [weak self] (newText, newLink) in
                    guard let self = self, var item = self.customDataSource.first(where: { $0.key == field.key }) else { return }
                    DispatchQueue.main.async {
                        UDToast.showSuccess(with: BundleI18n.LarkMine.Lark_Legacy_SaveSuccess, on: self.view)
                        item.text = newText
                        item.link = newLink
                        self.tableView.reloadData()
                    }
                }
            }
        default: break
        }
    }
}
