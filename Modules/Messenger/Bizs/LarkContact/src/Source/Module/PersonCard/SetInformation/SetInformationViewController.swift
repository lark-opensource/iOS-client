//
//  SetInformationViewController.swift
//  LarkContact
//
//  Created by 强淑婷 on 2020/7/15.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift
import LarkMessengerInterface
import LarkSDKInterface
import EENavigator
import UniverseDesignToast
import UniverseDesignColor
import LKCommonsLogging
import LarkAlertController
import AnimatedTabBar
import LarkCore
import LKCommonsTracker
import Homeric
import LarkRustClient
import FigmaKit
import RustPB
import LarkProfile
import LarkEnv
import LarkContainer
import LarkStorage
import UniverseDesignDialog

final class SetInformationViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    private let viewModel: SetInformationViewModel
    private static let tableDidSelectSpaceValue = 0.04

    static let logger = Logger.log(SetInformationViewController.self, category: "Module.IM.PersonCard")

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloatBase)
    }

    /// 表格视图
    private lazy var tableView = self.createTableView()

    private let disposeBag = DisposeBag()

    init(viewModel: SetInformationViewModel, resolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        var params: [AnyHashable: Any] = [:]
        params["contact_type"] = viewModel.contactType
        params["to_user_id"] = viewModel.userId
        LKCommonsTracker.Tracker.post(TeaEvent(Homeric.PROFILE_MORE_ACTION_VIEW, params: params, md5AllowList: ["to_user_id"]))

        self.title = BundleI18n.LarkContact.Lark_NewContacts_SettingsFromProfileMobile
        self.viewModel.delegate = self
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }

        self.viewModel.refreshDriver.drive(onNext: { [weak self] () in
            guard let `self` = self else { return }
            self.tableView.reloadData()
        }).disposed(by: self.disposeBag)

        self.backCallback = {
            Tracer.tarckProfileMoreButtonTap(type: "back")
        }
        viewModel.targetVc = self
    }

    private func createTableView() -> UITableView {
        let tableView = InsetTableView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 0.1)))
        tableView.tableHeaderView = UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 0.1, height: 8)))
        tableView.estimatedRowHeight = 68
        tableView.estimatedSectionFooterHeight = 10
        tableView.estimatedSectionHeaderHeight = 10
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        registerTableViewCells(tableView)
        tableView.contentInsetAdjustmentBehavior = .never
        return tableView
    }

    private func registerTableViewCells(_ tableView: UITableView) {
        tableView.lu.register(cellSelf: SetInformationSwitchCell.self)
        tableView.lu.register(cellSelf: SetInformationArrowCell.self)
        tableView.lu.register(cellSelf: SetInformationCheckCell.self)
        tableView.lu.register(cellSelf: SetInformationTextCell.self)
        tableView.lu.register(cellSelf: SetInformationAliasCell.self)
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section >= self.viewModel.footerViews.count {
            return nil
        }
        return self.viewModel.footerViews[section]()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section >= self.viewModel.headerViews.count {
            return nil
        }
        return self.viewModel.headerViews[section]()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.items.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section >= self.viewModel.items.count {
            return 0
        }
        return self.viewModel.items[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section >= self.viewModel.items.count {
            return UITableViewCell()
        }
        if indexPath.row >= self.viewModel.items[indexPath.section].count {
            return UITableViewCell()
        }

        let item: SetInformationItemProtocol = viewModel.items[indexPath.section][indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier) as? SetInformationBaseCell {
            if let checkCell = cell as? SetInformationCheckCell,
                let checkItem = item as? SetInformationCheckItem {
                checkCell.set(isSelected: checkItem.isSelected)
            }
            cell.item = item
            return cell
        }

        return UITableViewCell()
    }

    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let checkItems: [SetInformationItemProtocol] = self.viewModel.items[indexPath.section]
        checkItems.enumerated().forEach { (index, item) in
            if let item = item as? SetInformationCheckItem {
                item.isSelected = (index == indexPath.row)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + SetInformationViewController.tableDidSelectSpaceValue) {
            tableView.reloadData()
        }
    }
    // swiftlint:enable did_select_row_protection
}

extension SetInformationViewController: SetInformationViewModelDelegate {
    func blockContact(userID: String, isOn: Bool) {
        // 屏蔽成功后需要在Profile页底部展示字段
        if isOn {
            self.showAlert(title: BundleI18n.LarkContact.Lark_Profile_BlockWindow_Title,
                           message: BundleI18n.LarkContact.Lark_Profile_BlockWindow_Desc,
                           rightButtonTitle: BundleI18n.LarkContact.Lark_Profile_BlockWindow_Block_Button) { [weak self] in
                guard let self = self else {
                    return
                }

                var params: [AnyHashable: Any] = [:]
                params["click"] = "block"
                params["target"] = "none"
                params["contact_type"] = self.viewModel.contactType
                params["to_user_id"] = self.viewModel.userId
                LKCommonsTracker.Tracker.post(TeaEvent(Homeric.PROFILE_MORE_ACTION_CLICK, params: params, md5AllowList: ["to_user_id"]))

                Tracer.tarckProfileMoreButtonTap(type: "block")
                self.viewModel.setUserBlockAuth(enable: isOn, { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                })
                Tracer.trackContactBlock(blockSource: .profile, userID: self.viewModel.userId)
            }
        } else {
            self.showAlert(title: BundleI18n.LarkContact.Lark_Profile_UnBlockWindow_Title,
                           message: BundleI18n.LarkContact.Lark_Profile_UnBlockWindow_Desc,
                           rightButtonTitle: BundleI18n.LarkContact.Lark_Profile_UnBlockWindow_Unblock_Button) { [weak self] in
                guard let self = self else {
                    return
                }
                Tracer.tarckProfileMoreButtonTap(type: "unblock")
                Tracer.trackContactUnBlock(unblockSource: .profile, userID: self.viewModel.userId)
                self.viewModel.setUserBlockAuth(enable: isOn, { [weak self] in
                    if let window = self?.view.window {
                        // 取消屏蔽成功
                        UDToast.showTips(with: BundleI18n.LarkContact.Lark_NewContacts_UnblockedSuccessfully, on: window)
                    }
                    NotificationCenter.default.post(name: .cancelBlockedSetting, object: nil)

                    var params: [AnyHashable: Any] = [:]
                    params["click"] = "unblock"
                    params["target"] = "none"
                    params["contact_type"] = self?.viewModel.contactType ?? ""
                    params["to_user_id"] = self?.viewModel.userId ?? ""
                    LKCommonsTracker.Tracker.post(TeaEvent(Homeric.PROFILE_MORE_ACTION_CLICK, params: params, md5AllowList: ["to_user_id"]))
                })
            }
        }
    }

    func deleteContact(userID: String) {
        self.showAlert(title: BundleI18n.LarkContact.Lark_NewContacts_DeleteContactDialogTitle,
                       message: BundleI18n.LarkContact.Lark_NewContacts_SettingsFromProfileDeletetContactToastMobile,
                       rightButtonTitle: BundleI18n.LarkContact.Lark_NewContacts_SettingsFromProfileDeletetContactDeleteButtonMobile) { [weak self] in
            self?.requestForDeleteContact()
            Tracer.tarckProfileMoreButtonTap(type: "delete")

            var params: [AnyHashable: Any] = [:]
            params["click"] = "delete"
            params["target"] = "none"
            params["contact_type"] = self?.viewModel.contactType ?? ""
            params["to_user_id"] = self?.viewModel.userId ?? ""
            LKCommonsTracker.Tracker.post(TeaEvent(Homeric.PROFILE_MORE_ACTION_CLICK, params: params, md5AllowList: ["to_user_id"]))
        }
    }

    func onChangeSpecialFocus(chatterID: String, follow: Bool) {
        guard let id = Int64(chatterID) else {
            SetInformationViewController.logger.error("userID convert failed", additionalData: ["userID": chatterID])
            return
        }
        trackChangeSpecialFocus(follow: follow)

        viewModel.setSpecialFocus(chatterID: id, follow: follow)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] showGuidance in
                guard let self = self else { return }
                SetInformationViewController.logger.info("setSpecialFocus success follow: \(follow) showGuidance: \(showGuidance)")
                self.setupSpecialFocusPrompt(isFollow: follow, isShowGuidance: showGuidance)
            }, onError: { [weak self] error in
                guard let self = self else { return }
                UDToast.showFailure(with: BundleI18n.LarkContact.Lark_Legacy_ErrorMessageTip, on: self.view, error: error)
                SetInformationViewController.logger.warn("setSpecialFocus failed", error: error)
            }).disposed(by: self.disposeBag)
    }

    func setupSpecialFocusPrompt(isFollow follow: Bool, isShowGuidance showGuidance: Bool) {
        if showGuidance {
            self.firstsetSpecialFocusAlert()
        } else {
            let str = follow ? BundleI18n.LarkContact.Lark_IM_AddToStarredConact_SuccessToast : BundleI18n.LarkContact.Lark_IM_RemoveFromStarredContact_SuccessToast
            UDToast.showSuccess(with: str, on: self.view)
        }
    }

    //首次设置星标联系人成功提示
    func firstsetSpecialFocusAlert() {
        let alert = UDDialog()
        alert.setTitle(text: BundleI18n.LarkContact.Lark_IM_ProfileSettings_AddedToStarredContacts_Title)
        alert.setContent(text: BundleI18n.LarkContact.Lark_IM_ProfileSettings_AddedToStarredContacts_Desc)
        alert.addPrimaryButton(
            text: BundleI18n.LarkContact.Lark_IM_ProfileSettings_AddedToStarredContactsGotIt_Button,
            dismissCompletion: nil)
        self.present(alert, animated: true)
    }

    func onClickShare(userID: String, shareInfo: SetInformationViewControllerBody.ShareInfo) {
        switch shareInfo {
        case .no: break
        case .yes(let enable):
            switch enable {
            case .enable:
                let body = ShareUserCardBody(shareChatterId: userID)
                navigator.present(body: body, from: self,
                                         prepare: { $0.modalPresentationStyle = .formSheet })
            case .denied(let desc):
                UDToast.showFailure(with: desc, on: self.view)
            }
            trackClickShare()
        }
    }

    private func requestForDeleteContact() {
        self.viewModel.deleContactWithFinishBlock({ [weak self] (success) in
            if success {
                Tracer.trackDeleteContactInProfileSetting()
                Tracer.tarckProfileMoreButtonTap(type: "delete")
                self?.popCurrentVC()
            }
        })
    }

    private func popCurrentVC() {
        // 删除完成之后需要跳转到profile页的上一层页面
        navigator.pop(from: self, animated: true) {
            self.viewModel.dismissForDeleContact?()
        }
    }

    private func showAlert(title: String, message: String, rightButtonTitle: String = "", handler: @escaping (() -> Void)) {
        var rightTitle = BundleI18n.LarkContact.Lark_Legacy_Sure
        if !rightButtonTitle.isEmpty {
            rightTitle = rightButtonTitle
        }
        let alertController = LarkAlertController()
        alertController.setTitle(text: title)
        alertController.setContent(text: message)
        alertController.addCancelButton(dismissCompletion: { [weak self] in
            self?.tableView.reloadData()
        })

        alertController.addPrimaryButton(text: rightTitle, dismissCompletion: {
            handler()
        })
        navigator.present(alertController, from: self)
    }

    func pushSetQueryNumber(userID: String, chatterAPI: ChatterAPI) {
        let viewModel: SetQueryNumberViewModel = SetQueryNumberViewModel(chatterId: userID, chatterAPI: chatterAPI)
        let vc: SetQueryNumberController = SetQueryNumberController(viewModel: viewModel)
        navigator.present(vc, wrap: LkNavigationController.self, from: self) { vc in
            vc.modalPresentationStyle = .fullScreen
        }
        Tracer.tarckProfileMoreButtonTap(type: "phone_query")
    }

    private func trackReportInProfileSetting() {
        var params: [AnyHashable: Any] = [:]
        params["click"] = "report"
        params["target"] = "none"
        params["contact_type"] = viewModel.contactType
        params["to_user_id"] = viewModel.userId
        LKCommonsTracker.Tracker.post(TeaEvent(Homeric.PROFILE_MORE_ACTION_CLICK, params: params, md5AllowList: ["to_user_id"]))
        Tracer.trackReportInProfileSetting()
        Tracer.tarckProfileMoreButtonTap(type: "report")
    }

    func pushReport(userID: String, reportURL: String) {
        guard let paramsJSONData = try? JSONSerialization.data(
            withJSONObject: ["chatter_id": userID],
            options: .prettyPrinted) else { return }
        guard let paramsJSONString = String(data: paramsJSONData, encoding: .utf8) else { return }
        /// push url
        guard var url = URL(string: reportURL) else { return }
        url = url.lf.appendPercentEncodedQuery(["type": "chatter", "params": paramsJSONString])
        navigator.push(url, from: self)
        trackReportInProfileSetting()
    }

    func pushTnsReport(userID: String, tnsUrl: String, params: String) {
        guard var url = URL(string: tnsUrl) else { return }
        let featureEnvKey = KVPublic.Common.ttenv.value() ?? ""
        url = url.lf.appendPercentEncodedQuery(["params": params, "v": 2, "lang": BundleI18n.currentLanguage.identifier, "x-tt-env": featureEnvKey])
        navigator.push(url, from: self)
        trackReportInProfileSetting()
    }

    func onClickSpecialFocusSetting() {
        let body = SpecialFocusSettingBody(from: .profile)
        navigator.push(body: body, from: self)
        trackGoToSpecialFocusSetting()
    }

    func onClickAlias(userID: String,
                      aliasAndMemoInfo: SetInformationViewControllerBody.AliasAndMemoInfo,
                      updateAliasCallback: ((String, String, UIImage?) -> Void)? ) {
        let vc = LarkProfileAliasViewController(resolver: userResolver,
                                                userID: userID,
                                                name: aliasAndMemoInfo.name,
                                                alias: aliasAndMemoInfo.alias,
                                                memoDescription: aliasAndMemoInfo.memoDescription,
                                                memoText: aliasAndMemoInfo.memoText,
                                                memoImage: aliasAndMemoInfo.memoImage) { (alias, memoText, image) in
            updateAliasCallback?(alias, memoText, image)
        }
        navigator.present(vc, wrap: LkNavigationController.self, from: self)
    }

    private func showAlert() {
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkContact.Lark_Legacy_Hint)
        alertController.setContent(text: BundleI18n.LarkContact.Lark_Legacy_ContentEmpty)
        alertController.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Legacy_ConfirmOk)
        navigator.present(alertController, from: self)
    }

    // MARK: - 埋点
    private func trackClickShare() {
        track(with: ["click": "share", "target": "public_multi_select_share_view"])
    }

    private func trackChangeSpecialFocus(follow: Bool) {
        track(with: ["click": "starred_contact",
                     "target": "profile_more_action_view",
                     "status": follow ? "off_to_on" : "on_to_off"])
    }

    private func trackGoToSpecialFocusSetting() {
        track(with: ["click": "to_setting", "target": "setting_detail_click"])
    }

    private func track(with extra: [AnyHashable: Any] = [:]) {
        var params: [AnyHashable: Any] = [:]
        params["contact_type"] = viewModel.contactType
        params["to_user_id"] = viewModel.userId
        params += extra
        Tracker.post(TeaEvent(Homeric.PROFILE_MORE_ACTION_CLICK, params: params, md5AllowList: ["to_user_id"]))
    }
}
