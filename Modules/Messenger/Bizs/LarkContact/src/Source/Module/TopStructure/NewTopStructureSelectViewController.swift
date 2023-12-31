//
//  TopStructureSelectViewController.swift
//  LarkContact
//
//  Created by zc09v on 2020/12/11.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import EENavigator
import RxSwift
import RxRelay
import LarkSDKInterface
import LarkFeatureGating
import LarkContainer
import LarkSearchCore
import LarkAccountInterface
import SuiteAppConfig
import LarkMessengerInterface
import LarkAlertController
import AppReciableSDK
import LKCommonsTracker
import Homeric
import UniverseDesignToast
import UniverseDesignIcon
import UniverseDesignColor

class TopStructureSelectViewController: NewLKContactViewController, PickerDelegate,
                                           CheckSearchChatterDeniedReason, GetSelectedUnFriendNum, UserResolverWrapper {
    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy private var appConfigService: AppConfigService?
    @ScopedInjectedLazy private var userGeneralSettings: UserGeneralSettings?
    private let limitInfo: SelectChatterLimitInfo?
    private var selectedCallback: ((UINavigationController, ContactPickerResult) -> Void)?
    private var switchToolTitle: ((Bool) -> Void)?
    private let navTitle: String
    private var navTitleView: UIView?
    private var tracker: PickerAppReciable?
    // 最大可选中的未授权人数
    private lazy var maxUnauthExternalContactsSelectNumber: Int = {
        return userGeneralSettings?.contactsConfig.maxUnauthExternalContactsSelectNumber ?? 50
    }()

    // 调起 chatterPicker 的来源
    var source: ChatterPickerSource?
    // 仅在 来源是 Todo 时该字段有效，用于区分 Todo 选人组件的调起场景，有值为IM，否则为Todo中心
    var chatIdFromTodo: String?

    // 仅在 from filter section 中使用
    var selectedRecommendList: [SearchResultType] {
        guard let structureView = picker.defaultView as? StructureView else { return [] }
        return structureView.selectedRecommendList
    }

    var hasSearchFromFilterRecommend: Bool {
        guard let structureView = picker.defaultView as? StructureView else { return false }
        return structureView.dependency.hasSearchFromFilterRecommend
    }
    let passportUserService: PassportUserService
    var userResolver: LarkContainer.UserResolver
    init(navTitle: String,
         navTitleView: UIView? = nil,
         chatterPicker: ChatterPicker,
         style: NewDepartmentViewControllerStyle,
         allowSelectNone: Bool,
         allowDisplaySureNumber: Bool,
         limitInfo: SelectChatterLimitInfo?,
         tracker: PickerAppReciable?,
         selectedCallback: ((UINavigationController, ContactPickerResult) -> Void)?,
         resolver: UserResolver
         ) throws {
        self.navTitle = navTitle
        self.navTitleView = navTitleView
        self.selectedCallback = selectedCallback
        self.limitInfo = limitInfo
        self.tracker = tracker
        self.userResolver = resolver
        self.passportUserService = try resolver.resolve(assert: PassportUserService.self)
        super.init(chatterPicker: chatterPicker,
                   style: style,
                   allowSelectNone: allowSelectNone,
                   allowDisplaySureNumber: allowDisplaySureNumber)
        super.picker.delegate = self
        tracker?.initViewEnd()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func addCancelItem() -> UIBarButtonItem {
        let barItem = UIBarButtonItem(image: UDIcon.closeSmallOutlined, style: .plain, target: self, action: #selector(closeBtnTapped))
        self.navigationItem.leftBarButtonItem = barItem
        return barItem
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let navTitleView = self.navTitleView {
            self.navigationItem.titleView = navTitleView
        } else {
            title = navTitle
        }
        view.addSubview(picker)
        picker.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        view.backgroundColor = UIColor.ud.bgBase
        tracker?.firstRenderEnd()
        picker.searchTextFieldAutoFocus = false
    }

    override func closeBtnTapped() {
        Tracer.imGroupMemberAddClickCancel()
        super.closeBtnTapped()
    }

    override func sureDidClick() {
        //(添加群成员)页面，发生动作事件(73)
        Tracker.post(TeaEvent(Homeric.IM_GROUP_MEMBER_ADD_CLICK, params: [ "click": "confirm",
                                                                           "target": "im_chat_setting_view" ]))
        let extra = (self.navigationController?.toolbar as? SyncMessageToolbar)?.syncRecord
        self.finishSelect(extra: extra)
    }
    private var comfirmDate: TimeInterval = 0
    private func comfirmRepeated() -> Bool {
        let currentDate = Date().timeIntervalSince1970 * 1000
        if (currentDate - comfirmDate) > 500 {
            comfirmDate = currentDate
            return false
        }
        return true
    }
    func finishSelect(extra: Any? = nil) {
        guard let nav = self.navigationController else {
            return
        }
        if comfirmRepeated() { return } // 避免短时间多次触发
        // 点击完成，收起键盘
        UIApplication.shared.sendAction(#selector(resignFirstResponder), to: nil, from: nil, for: nil)
        selectedCallback?(nav, convert(selected: picker.selected, extra: extra))
    }

    func convert(selected: [Option], extra: Any?) -> ContactPickerResult {
        return ContactPickerResult.FromOptionBuilder(resolver: userResolver).build(options: selected, extra: extra, isRecommendSelected: !selectedRecommendList.isEmpty)
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

        if self.picker.selected.contains(where: { $0.optionIdentifier == option.optionIdentifier }) {
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
            case .callback:
                self.finishSelect()
            case .defaultRoute:
                break
            case .callbackWithReset:
                self.finishSelect(extra: (from as? HasSelectChannel)?.selectChannel.rawValue)
            }
        case .singleMultiChangeable:
            switch singleMultiChangeableStatus {
            case .multi:
                break
            case .single:
                self.finishSelect()
            }
        }
        if option is SearchResultType,
           case .todo = source {
            Tracker.post(TeaEvent(Homeric.TODO_ADD_PERFORMER, params: [
                "type": "search",
                "source": chatIdFromTodo == nil ? "center" : "im"
            ]))
        }
    }

    func picker(_ picker: Picker, didDeselected option: Option, from: Any?) { }

    func unfold(_ picker: Picker) {
        let body = PickerSelectedBody(
            picker: self.picker,
            confirmTitle: BundleI18n.LarkContact.Lark_Legacy_ConfirmInfo,
            allowSelectNone: false,
            targetPreview: self.picker.targetPreview,
            completion: { [weak self] _ in
                self?.sureDidClick()
            })
        navigator.push(body: body, from: self)
    }
}

final class CalendarTopStructureSelectViewController: TopStructureSelectViewController {
    var enableSearchingOuterTenant: Bool = true
    @ScopedInjectedLazy private var chatterManager: ChatterManagerProtocol?
    override func picker(_ picker: Picker, willSelected option: Option, from: Any?) -> Bool {
        // 外租户可搜不可选
        if !enableSearchingOuterTenant && isCrossTenant(option: option) {
            let alertVC = LarkAlertController()
            alertVC.setTitle(text: BundleI18n.Calendar.Calendar_Event_UnableToAdd)
            alertVC.setContent(text: BundleI18n.Calendar.Calendar_Event_CantInviteExternalContactsDesc, alignment: .left)
            alertVC.addPrimaryButton(text: BundleI18n.Calendar.Calendar_Event_GotIt)

            self.present(alertVC, animated: true, completion: nil)
            return false
        }

        return super.picker(picker, willSelected: option, from: from)
    }

    override func picker(_ picker: Picker, didSelected option: Option, from: Any?) {
        if isMeeting(option: option), let window = self.view.window {
            UDToast.showTips(with: BundleI18n.Calendar.Calendar_Meeting_AddToastMobile, on: window)
        }

        if isDepartment(option: option), let window = self.view.window {
            UDToast.showTips(with: BundleI18n.Calendar.Calendar_Edit_DepartmentMemberWillJoinEvent, on: window)
        }

        super.picker(picker, didSelected: option, from: from)
    }

    override func picker(_ picker: Picker, disabled option: Option, from: Any?) -> Bool {
        // 外租户可搜不可选
        if !enableSearchingOuterTenant && isCrossTenant(option: option) {
            return true
        }

        return super.picker(picker, disabled: option, from: from)
    }

    private func isCrossTenant(option: Option) -> Bool {
        guard let chatterManager = self.chatterManager else { return false }
        let currentTenantID = chatterManager.currentChatter.tenantId
        switch option {
        case let v as SearchResultType:
            if case let .chatter(meta) = v.meta { return meta.tenantID != currentTenantID }
            if case let .chat(meta) = v.meta { return meta.isCrossTenant }
        case let v as Chatter:
            return v.tenantId != currentTenantID
        case let v as NewSelectExternalContact:
            return true
        case let v as OptionIdentifier:
            // 邮件参与人认为是外租户
            if v.type == OptionIdentifier.Types.mailContact.rawValue { return true }
        default: break
        }
        return false
    }

    func isMeeting(option: Option) -> Bool {
        return (picker as? CalendarChatterPicker)?.includeMeetingGroup == true && option.isMeeting
    }

    func isDepartment(option: Option) -> Bool {
        return option.optionIdentifier.type == OptionIdentifier.Types.department.rawValue
    }

    override func convert(selected: [Option], extra: Any?) -> ContactPickerResult {
        let builder = ContactPickerResult.FromOptionBuilder(resolver: userResolver)
        builder.includeMeetingGroup = (picker as? CalendarChatterPicker)?.includeMeetingGroup == true
        return builder.build(options: selected, extra: extra)
    }
}

final class TopStructureSelectNavigationTitleView: UIView {
    private lazy var contentStatckView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.textAlignment = .center
        return titleLabel
    }()

    private lazy var subTitleLabel: UILabel = {
        let subTitleLabel = UILabel()
        subTitleLabel.font = UIFont.systemFont(ofSize: 11)
        subTitleLabel.textColor = UIColor.ud.textCaption
        subTitleLabel.adjustsFontSizeToFitWidth = true
        subTitleLabel.minimumScaleFactor = 0.8
        return subTitleLabel
    }()

    private let disposeBag = DisposeBag()

    init(title: String, subTitle: String) {
        super.init(frame: .zero)

        self.titleLabel.text = title
        self.subTitleLabel.text = subTitle
        self.addSubview(contentStatckView)
        contentStatckView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentStatckView.addArrangedSubview(titleLabel)
        contentStatckView.addArrangedSubview(subTitleLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class WaterChannelView: UIView {

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.textPlaceholder
        return titleLabel
    }()

    init(title: String) {
        super.init(frame: .zero)

        self.lu.addTopBorder()
        self.lu.addBottomBorder()
        self.titleLabel.text = title
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(4)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
