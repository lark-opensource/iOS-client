//
//  CustomerSelectViewController.swift
//  LarkContact
//
//  Created by zc09v on 2020/12/21.
//

import Foundation
import UIKit
import LarkUIKit
import LarkModel
import LarkContainer
import RxSwift
import RxCocoa
import LKCommonsLogging
import LarkSDKInterface
import LarkMessengerInterface
import LarkSearchCore
import AppReciableSDK
import LarkAccountInterface
import LarkAlertController
import LarkFeatureGating
import UniverseDesignToast
import UniverseDesignColor

class CustomerSelectViewController: NewLKContactViewController, PickerDelegate,
                                       CheckSearchChatterDeniedReason, GetSelectedUnFriendNum, UserResolverWrapper {
    private let disposeBag = DisposeBag()

    private var tableVC: CustomerVC!
    private let tracker: PickerAppReciable?
    private let confirmCallBack: ((UINavigationController, ContactPickerResult) -> Void)?
    private let navTitle: String
    private let limitInfo: SelectChatterLimitInfo?
    @ScopedInjectedLazy private var externalContactsAPI: ExternalContactsAPI?
    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?
    // 最大可选中的未授权人数
    private lazy var maxUnauthExternalContactsSelectNumber: Int = {
        return userGeneralSettings?.contactsConfig.maxUnauthExternalContactsSelectNumber ?? 50
    }()
    var userResolver: LarkContainer.UserResolver

    init(navTitle: String,
         picker: ChatterPicker,
         isShowGroup: Bool,
         allowSelectNone: Bool,
         limitInfo: SelectChatterLimitInfo?,
         pushDriver: Driver<PushExternalContacts>,
         router: CustomerSelectRouter,
         resolver: UserResolver,
         tracker: PickerAppReciable? = nil,
         confirmCallBack: ((UINavigationController, ContactPickerResult) -> Void)?) {
        self.navTitle = navTitle
        self.tracker = tracker
        self.limitInfo = limitInfo
        self.userResolver = resolver
        self.confirmCallBack = confirmCallBack
        super.init(chatterPicker: picker, style: .multi, allowSelectNone: allowSelectNone, allowDisplaySureNumber: true)
        guard let externalContactsAPI = self.externalContactsAPI else { return }
        let vm = CustomerSelectViewModel(isShowGroup: isShowGroup,
                                         externalContactsAPI: externalContactsAPI,
                                         pushDriver: pushDriver)
        tableVC = CustomerVC(viewModel: vm, config: CustomerVC.Config(openMyGroups: { [weak self](_) in
            guard let self = self else { return }
            guard let nav = self.navigationController else {
                assertionFailure("CustomerSelectController should have navigation")
                return
            }
            router.openMyGroups(navigationController: nav)
        }), selectionSource: picker)
        self.picker.defaultView = tableVC.view
        self.picker.delegate = self
        tracker?.initViewEnd()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = self.navTitle
        self.view.backgroundColor = UIColor.ud.bgBase
        self.view.addSubview(picker)
        picker.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.tracker?.firstRenderEnd()
    }

    override func sureDidClick() {
        let extra = (self.navigationController?.toolbar as? SyncMessageToolbar)?.syncRecord
        self.finishSelect(extra: extra)
    }

    func finishSelect(extra: Any? = nil) {
        guard let nav = self.navigationController else {
            return
        }
        // 点击完成，收起键盘
        UIApplication.shared.sendAction(#selector(resignFirstResponder), to: nil, from: nil, for: nil)
        confirmCallBack?(nav, convert(selected: picker.selected, extra: extra))
    }

    func convert(selected: [Option], extra: Any?) -> ContactPickerResult {
        ContactPickerResult.FromOptionBuilder(resolver: userResolver).build(options: selected, extra: extra)
    }

    func picker(_ picker: Picker, disabled option: Option, from: Any?) -> Bool {
        if let chatterMeta = option.getSearchChatterMetaInContact() {
            return self.checkSearchChatterDeniedReasonForDisabledPick(chatterMeta)
        }
        return false
    }

    func picker(_ picker: Picker, willSelected option: Option, from: Any?) -> Bool {
        if self.style == .multi || singleMultiChangeableStatus == .multi {
            if let limitInfo = self.limitInfo, picker.selected.count >= limitInfo.max {
                let alert = LarkAlertController()
                alert.setContent(text: limitInfo.warningTip)
                alert.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Legacy_ConfirmOk)
                present(alert, animated: true, completion: nil)
                return false
            } else if self.getSelectedUnFriendNum(self.picker.selected) >= maxUnauthExternalContactsSelectNumber {
                let alert = LarkAlertController()
                alert.setContent(text: BundleI18n.LarkContact.Lark_NewContacts_PermissionRequestSelectUserMax)
                alert.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Legacy_ConfirmOk)
                present(alert, animated: true, completion: nil)
                return false
            }
        }

        if picker.selected.contains(where: { $0.optionIdentifier == option.optionIdentifier }) {
            return true
        }

        if let chatterMeta = option.getSearchChatterMetaInContact() {
            return self.checkSearchChatterDeniedReasonForWillSelected(chatterMeta, on: self.view.window)
        }
        return true
    }

    func picker(_ picker: Picker, didSelected option: Option, from: Any?) {
        switch self.style {
        case .multi:
            break
        case .single(let style):
            switch style {
            case .callback, .callbackWithReset:
                self.finishSelect()
            case .defaultRoute:
                break
            }
        case .singleMultiChangeable:
            switch singleMultiChangeableStatus {
            case .multi:
                break
            case .single:
                self.finishSelect()
            }
        }
    }

    func unfold(_ picker: Picker) {
        return
    }
}

final class CalendarCustomerSelectViewController: CustomerSelectViewController {
    override func picker(_ picker: Picker, didSelected option: Option, from: Any?) {
        if isMeeting(option: option), let window = self.view.window {
            UDToast.showTips(with: BundleI18n.Calendar.Calendar_Meeting_AddToastMobile, on: window)
        }

        super.picker(picker, didSelected: option, from: from)
    }

    func isMeeting(option: Option) -> Bool {
        return (picker as? CalendarChatterPicker)?.includeMeetingGroup == true && option.isMeeting
    }

    override func convert(selected: [Option], extra: Any?) -> ContactPickerResult {
        let builder = ContactPickerResult.FromOptionBuilder(resolver: userResolver)
        builder.includeMeetingGroup = (picker as? CalendarChatterPicker)?.includeMeetingGroup == true
        return builder.build(options: selected, extra: extra)
    }

}

extension CustomerSelectViewController {
    /// 通过 option 获取 tenant info
    /// - Parameter option: Option
    /// - Returns: tenantID & isCrossTenant
    func tenantInfo(option: Option) -> (String?, Bool?) {
        switch option {
        case let v as SearchResultType:
            if case let .chatter(meta) = v.meta { return (meta.tenantID, nil) }
            if case let .chat(meta) = v.meta { return (nil, meta.isCrossTenant) }
        case let v as Chatter:
            return (v.tenantId, nil)
        case let v as NewSelectExternalContact:
            return (nil, true)
        default: break
        }
        return (nil, nil)
    }
}
