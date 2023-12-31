//
//  SetInformationViewModel.swift
//  LarkContact
//
//  Created by 强淑婷 on 2020/7/15.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LarkUIKit
import LarkMessengerInterface
import LarkSDKInterface
import LarkAccountInterface
import EENavigator
import LarkContainer
import LarkSetting
import LKCommonsLogging
import LarkAlertController
import LarkFeatureGating
import LarkModel
import LarkProfile
import UniverseDesignToast
import RustPB
import CryptoSwift

protocol SetInformationViewModelDelegate: AnyObject {
    func pushSetQueryNumber(userID: String, chatterAPI: ChatterAPI)
    func pushReport(userID: String, reportURL: String)
    func pushTnsReport(userID: String, tnsUrl: String, params: String)
    func blockContact(userID: String, isOn: Bool)
    func deleteContact(userID: String)
    func onClickShare(userID: String, shareInfo: SetInformationViewControllerBody.ShareInfo)
    func onChangeSpecialFocus(chatterID: String, follow: Bool)
    func onClickSpecialFocusSetting()
    func onClickAlias(userID: String,
                      aliasAndMemoInfo: SetInformationViewControllerBody.AliasAndMemoInfo,
                      updateAliasCallback: ((String, String, UIImage?) -> Void)?)
}

struct SetInformationCondition {
    /// 是否被屏蔽
    var isBlocked: Bool

    /// 是否组织内
    let isSameTenant: Bool

    /// 是否为leader
    let setNumebrEnable: Bool

    /// 是否可以举报
    let isCanReport: Bool

    let isMe: Bool

    /// 是不是好友
    var isFriend: Bool

    /// 分享信息
    let shareInfo: SetInformationViewControllerBody.ShareInfo

    /// 是否是星标联系人
    var isSpecialFocus: Bool

    /// 是否来自隐私状态Profile
    var isFromPrivacy: Bool = false

    /// 是否离职
    var isResigned: Bool = false
    /// 是否展示屏蔽入口
    var isShowBlockMenu: Bool = false
}

final class SetInformationViewModel: NSObject, UserResolverWrapper {

    struct TnsReportConfig: SettingDecodable {
        static let settingKey = UserSettingKey.make(userKeyLiteral: "tns_report_config")
        let reportPath: String
        let token: String
    }

    private lazy var config: TnsReportConfig? = try? self.userResolver.settings.setting(with: TnsReportConfig.self)

    weak var delegate: SetInformationViewModelDelegate?
    /// 对方的userId
    private(set) var userId: String
    /// 二维码、分享链接进来此界面有token
    private(set) var contactToken: String

    private var userAuthDisposeBag = DisposeBag()

    private var blockedDisposeBag = DisposeBag()

    private let disposeBag = DisposeBag()

    private var condition: SetInformationCondition

    var dismissForDeleContact: (() -> Void)?
    var userResolver: LarkContainer.UserResolver
    @ScopedInjectedLazy var monitor: SetContactInfomationMonitorService?

    weak var targetVc: UIViewController?

    /// 分组头部视图
    var headerViews: [() -> UIView] = []
    /// 分组底部视图
    var footerViews: [() -> UIView] = []
    /// 数据源
    var items: [[SetInformationItemProtocol]] = []

    var contactType: String {
        if self.condition.isMe {
            return "self"
        } else if self.condition.isSameTenant {
            return "internal"
        } else if self.condition.isFriend {
            return "external_friend"
        } else {
            return "external_nonfriend"
        }
    }

    @ScopedInjectedLazy var chatterAPI: ChatterAPI?
    @ScopedInjectedLazy var contactAPI: ContactAPI?

    static let logger = Logger.log(SetInformationViewModel.self, category: "Module.IM.PersonCard")

    /// 刷新表格视图
    private let refreshPublish: PublishSubject<Void> = PublishSubject<Void>()
    var refreshDriver: Driver<()> {
        return refreshPublish.asDriver(onErrorJustReturn: ())
    }
    var canShowBlockMenu: Bool {
        return !self.condition.isSameTenant || self.condition.isShowBlockMenu
    }

    private let reloadDataSpaceValueOnError = 0.8
    private var oldTempBlocked: Bool = false
    private var aliasAndMemoInfo: SetInformationViewControllerBody.AliasAndMemoInfo
    public var showAddBtn: Bool = false
    public var pushToAddContactHandler: (() -> Void)?

    init(userId: String,
         contactToken: String,
         condition: SetInformationCondition,
         aliasAndMemoInfo: SetInformationViewControllerBody.AliasAndMemoInfo,
         resolver: UserResolver,
         dismissForDeleContact: (() -> Void)? = nil) {
        self.userId = userId
        self.contactToken = contactToken
        self.condition = condition
        self.aliasAndMemoInfo = aliasAndMemoInfo
        self.dismissForDeleContact = dismissForDeleContact
        self.userResolver = resolver
        // 只有不是同一个Tenant的才会有屏蔽状态 不需要所有情况进行拉取
        super.init()
        if self.canShowBlockMenu {
            self.getUserAuthority()
        }
        self.items = self.createDataSourceItems()
        self.headerViews = self.createHeaderViews()
        self.footerViews = self.createFooterViews()
        oldTempBlocked = condition.isBlocked

        chatterAPI?.pushFocusChatter
            .subscribe(onNext: { [weak self] msg in
                guard let self = self else { return }
                let isSpecialFocus = self.condition.isSpecialFocus
                if (msg.addChatters.contains { $0.id == userId } && !isSpecialFocus)
                    || (msg.deleteChatterIds.contains(userId) && isSpecialFocus) {
                    self.condition.isSpecialFocus.toggle()
                    self.items = self.createDataSourceItems()
                    self.refreshPublish.onNext(())
                }
            }).disposed(by: disposeBag)
        let notificationName = Notification.Name(rawValue: LKFriendStatusChangeNotification)
        NotificationCenter.default.addObserver(self, selector: #selector(onFriendApplyed), name: notificationName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onApplyStatusChanged(noti:)), name: Notification.Name(LKProfileUserInfoUpdateNotification), object: nil)
    }

    @objc
    private func onFriendApplyed() {
        self.showAddBtn = false
        self.items = self.createDataSourceItems()
        self.refreshPublish.onNext(())
    }

    @objc
    private func onApplyStatusChanged(noti: Notification) {
        let isHideAddOnProfile = noti.userInfo?[LKProfileHideAddOnProfileKey] as? Bool ?? false
        let isDoubleFriend = noti.userInfo?[LKProfileIsDoubleFriend] as? Bool ?? condition.isFriend
        Self.logger.info("set info status changed: hideAddConnectButton: \(isHideAddOnProfile), \(isDoubleFriend)")
        // 更新好友状态, 避免发生添加按钮和删除按钮同时存在的情况
        condition.isFriend = isDoubleFriend
        self.showAddBtn = isHideAddOnProfile
        self.items = self.createDataSourceItems()
        self.refreshPublish.onNext(())
    }

    // MARK: - 数据源
    /// 获取tableview sections的header 依赖items，所以必须在createDataSourceItems()之后调用
    /// - Returns: header views的函数数组
    private func createHeaderViews() -> [() -> UIView] {

        var tempHeaderViews: [() -> UIView] = []

        for _ in self.items {
            let view = createHeaderFooterView()
            tempHeaderViews.append { view }
        }

        return tempHeaderViews
    }

    /// 获取tableview sections的footer，依赖items，所以必须在createDataSourceItems()之后调用
    /// - Returns: [() -> UIView]
    private func createFooterViews() -> [() -> UIView] {
        var tempFooterViews: [() -> UIView] = []
        var i = 0
        // 备注与描述
        if !condition.isMe && !condition.isFromPrivacy {
            let view = createHeaderFooterView()
            tempFooterViews.append { view }
            i += 1
        }
        // 分享
        switch condition.shareInfo {
        case .no: break
        case .yes(_):
            let view = createHeaderFooterView()
            tempFooterViews.append { view }
            i += 1
        @unknown default:
            assertionFailure("unknown enum")
        }
        // 星标联系人
        if !condition.isMe && !condition.isResigned {
            let view = createSpecialFocusFooter()
            tempFooterViews.append { view }
            i += 1
        }
        for _ in i ..< items.count {
            let view = createHeaderFooterView()
            tempFooterViews.append { view }
        }
        return tempFooterViews
    }

    private func createHeaderFooterView(_ height: CGFloat = 8.0) -> UIView {
        let view: UIView = UIView()
        view.snp.makeConstraints { (make) in
            make.height.equalTo(height)
        }
        return view
    }

    /// 配置tableView的【【cells】【cells】 【cells】】信息
    /// - Returns: 返回数据源
    private func createDataSourceItems() -> [[SetInformationItemProtocol]] {
        var tempItems: [[SetInformationItemProtocol]] = []
        // 描述与备注
        do {
            var sectionItems: [SetInformationItemProtocol] = []
            if !condition.isMe && !condition.isFromPrivacy {
                sectionItems.append(createAliasItem())
            }
            if !sectionItems.isEmpty {
                tempItems.append(sectionItems)
            }
        }
        // 分享 section
        do {
            var sectionItems: [SetInformationItemProtocol] = []
            switch condition.shareInfo {
            case .no: break
            case .yes(_):
                sectionItems.append(createShareItem())
            @unknown default:
                assertionFailure("unknown enum")
            }
            if !sectionItems.isEmpty {
                tempItems.append(sectionItems)
            }
        }
        // 星标联系人 section
        do {
            var sectionItems: [SetInformationItemProtocol] = []
            if !condition.isMe && !condition.isResigned {
                sectionItems.append(createSpecialFocusItem())
            }
            if !sectionItems.isEmpty {
                tempItems.append(sectionItems)
            }
        }
        /// 员工电话号码查询次数设置
        do {
            var sectionItems: [SetInformationItemProtocol] = []
            /// row1 上级对下级才会有
            if condition.setNumebrEnable {
                sectionItems.append(SetInformationArrowItem(
                    cellIdentifier: SetInformationArrowCell.lu.reuseIdentifier,
                    title: BundleI18n.LarkContact.Lark_Legacy_ApplicationPhoneCallTimeSetPageTitle,
                    tapHandler: { [weak self] in
                        guard let self = self, let chatterAPI = self.chatterAPI else {
                            return
                        }
                        self.delegate?.pushSetQueryNumber(userID: self.userId, chatterAPI: chatterAPI)
                    }
                ))
            }
            if !sectionItems.isEmpty {
                tempItems.append(sectionItems)
            }
        }

        /// section 屏蔽该用户 & 举报该用户
        do {
            var sectionItems: [SetInformationItemProtocol] = []
            /// row0 组织外展示
            if self.canShowBlockMenu {
                sectionItems.append(SetInformationSwitchItem(
                    cellIdentifier: SetInformationSwitchCell.lu.reuseIdentifier,
                    title: BundleI18n.LarkContact.Lark_NewContacts_SettingsFromProfileBlockUserMobile,
                    switchHandler: { [weak self] isOn in
                        guard let self = self else {
                            return
                        }
                        self.delegate?.blockContact(userID: self.userId, isOn: isOn)
                    },
                    status: condition.isBlocked
                ))
            }
            /// row1 all
            if condition.isCanReport {
                sectionItems.append(SetInformationArrowItem(
                    cellIdentifier: SetInformationArrowCell.lu.reuseIdentifier,
                    title: BundleI18n.LarkContact.Lark_NewContacts_SettingsFromProfileReportUser,
                    tapHandler: { [weak self] in
                        guard let self = self else { return }
                        self.pushTnsReport()
                    }
                ))
            }
            if !sectionItems.isEmpty {
                tempItems.append(sectionItems)
            }
        }

        do {
            if self.showAddBtn {
                let item = SetInformationArrowItem(
                    cellIdentifier: SetInformationArrowCell.lu.reuseIdentifier,
                    title: BundleI18n.LarkContact.Lark_Legacy_AddContactNow,
                    tapHandler: { [weak self] in
                        self?.pushToAddContactHandler?()
                    }
                )
                tempItems.append([item])
            }
        }
        /// section4 组织外展示  --- 删除联系人
        do {
            var sectionItems: [SetInformationItemProtocol] = []
            if !condition.isSameTenant && condition.isFriend && !condition.isResigned {
                sectionItems.append(SetInformationTextItem(
                    cellIdentifier: SetInformationTextCell.lu.reuseIdentifier,
                    title: BundleI18n.LarkContact.Lark_NewContacts_DeleteContact,
                    tapHandler: { [weak self] in
                        guard let self = self else {
                            return
                        }
                        self.delegate?.deleteContact(userID: self.userId)
                    }
                ))
                tempItems.append(sectionItems)
            }
        }
        return tempItems
    }

    func aesEncryptWith(_ string: String) -> String {
        guard let key = config?.token else {
            Self.logger.error("SetInformationViewModel: token is nil")
            return ""
        }
        var result: String?
        do {
            // iv默认为token的前16个字符,AES,CBC,Pkcs7
            let aes = try AES(key: key, iv: key.substring(to: 16), padding: .pkcs7)
            result = try aes.encrypt(Array(string.utf8)).toBase64()
        } catch {
            Self.logger.error("SetInformationViewModel: aes encrypt failed, \(error)")
        }
        return base64UrlSafeEncode(result ?? "")
    }

    func base64UrlSafeEncode(_ string: String) -> String {
        var result = string
        result = result.replacingOccurrences(of: "+", with: "-")
        result = result.replacingOccurrences(of: "/", with: "_")
        result = result.replacingOccurrences(of: "=", with: "")
        return result
    }

    private func pushReport() {
        self.delegate?.pushReport(userID: self.userId,
                                  reportURL: "https://\(DomainSettingManager.shared.currentSetting[.suiteReport]?.first ?? "")/report/")
    }

    private func pushTnsReport() {
        if config?.reportPath == nil {
            Self.logger.error("SetInformationViewModel: settings reportPath is nil")
        }
        if DomainSettingManager.shared.currentSetting[.tnsReport]?.first == nil {
            Self.logger.error("SetInformationViewModel: settings domian is nil")
        }
        guard let paramsJSONData = try? JSONSerialization.data(withJSONObject: ["report_type": 10, "report_params": ["profile_params": ["uid": self.userId]]]),
              let paramsJSONString = String(data: paramsJSONData, encoding: .utf8)
        else {
            Self.logger.error("SetInformationViewModel: failed to get params json string")
            return
        }
        self.delegate?.pushTnsReport(userID: self.userId,
                                     tnsUrl: "https://\(DomainSettingManager.shared.currentSetting[.tnsReport]?.first ?? "")\(config?.reportPath ?? "")",
                                     params: aesEncryptWith(paramsJSONString))
    }

    private func createAliasItem() -> SetInformationItemProtocol {
        let detail = self.aliasAndMemoInfo.alias
        return SetInformationAliasItem(
            cellIdentifier: SetInformationAliasCell.lu.reuseIdentifier,
            title: BundleI18n.LarkContact.Lark_IM_StarredContactAliasAndNotes_SettingsTitle,
            detailTitle: detail,
            tapHandler: { [weak self] in
                guard let self = self else { return }
                self.onClickAlias()
            }
        )
    }

    private func onClickAlias() {
        self.delegate?.onClickAlias(userID: self.userId, aliasAndMemoInfo: self.aliasAndMemoInfo) { [weak self] (alias, memoText, memoImage) in
            guard let self = self else { return }
            self.updateAliasInfo(alias: alias, memoText: memoText, memoImage: memoImage)
        }
    }

    private func updateAliasInfo(alias: String, memoText: String, memoImage: UIImage?) {
        self.aliasAndMemoInfo.alias = alias
        self.aliasAndMemoInfo.memoText = memoText
        self.aliasAndMemoInfo.memoImage = memoImage
        if self.aliasAndMemoInfo.memoDescription != nil {
            /// 更新信息后使用最新的本地数据
            self.aliasAndMemoInfo.memoDescription = nil
        }
        // 刷新数据
        self.items = self.createDataSourceItems()
        self.refreshPublish.onNext(())
        self.aliasAndMemoInfo.updateAliasCallback?()
    }

    private func createShareItem() -> SetInformationItemProtocol {
        let shareInfo = condition.shareInfo
        let userID = userId
        return SetInformationArrowItem(
            cellIdentifier: SetInformationArrowCell.lu.reuseIdentifier,
            title: BundleI18n.LarkContact.Lark_Legacy_Share,
            tapHandler: { [weak self] in
                self?.delegate?.onClickShare(userID: userID, shareInfo: shareInfo)
            }
        )
    }

    private func createSpecialFocusItem() -> SetInformationItemProtocol {
        let userID = userId
        return SetInformationSwitchItem(
            cellIdentifier: SetInformationSwitchCell.lu.reuseIdentifier,
            title: BundleI18n.LarkContact.Lark_IM_ProfileSettings_AddToVIPContacts,
            switchHandler: { [weak self] follow in
                self?.delegate?.onChangeSpecialFocus(chatterID: userID, follow: follow)
            },
            status: condition.isSpecialFocus
        )
    }

    private func createSpecialFocusFooter() -> UIView {
        let textview = UITextView()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.maximumLineHeight = 20
        paragraphStyle.minimumLineHeight = 20
        paragraphStyle.lineSpacing = 0
        let attrStr = NSMutableAttributedString(string: BundleI18n.LarkContact.Lark_IM_ProfileSettings_VIPContactsNotifications,
                                                attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                             .paragraphStyle: paragraphStyle,
                                                             .foregroundColor: UIColor.ud.textPlaceholder])
        attrStr.append(NSAttributedString(string: BundleI18n.LarkContact.Lark_IM_ProfileSettings_VIPContactsNotifications_GoToSettings,
                                          attributes: [.link: "", .font: UIFont.systemFont(ofSize: 14)]))
        textview.linkTextAttributes = [.font: UIFont.systemFont(ofSize: 14),
                                       .paragraphStyle: paragraphStyle,
                                       .foregroundColor: UIColor.ud.textLinkNormal]
        textview.attributedText = attrStr
        textview.backgroundColor = .clear
        textview.isEditable = false
        textview.isSelectable = true
        textview.textDragInteraction?.isEnabled = false
        textview.isScrollEnabled = false
        textview.showsVerticalScrollIndicator = false
        textview.showsHorizontalScrollIndicator = false
        textview.delegate = self
        textview.textContainerInset = .zero
        textview.textContainer.lineFragmentPadding = 0
        let containerView = UIView()
        let textViewWidth = UIScreen.main.bounds.size.width - 16 * 4
        let contentHeight = attrStr.string.boundingRect(with: CGSize(width: textViewWidth, height: CGFloat.greatestFiniteMagnitude),
                                    options: .usesLineFragmentOrigin,
                                    attributes: [.font: UIFont.systemFont(ofSize: 14),
                                                 .paragraphStyle: paragraphStyle], context: nil).height
        containerView.addSubview(textview)
        textview.snp.makeConstraints {
            $0.top.equalToSuperview().offset(4)
            $0.bottom.equalToSuperview().offset(-8)
            $0.right.equalToSuperview().offset(-16)
            $0.left.equalToSuperview().offset(16)
            $0.height.equalTo(contentHeight)
        }
        return containerView
    }

    // MARK: - 业务逻辑
    func setSpecialFocus(chatterID: Int64, follow: Bool) -> Observable<Bool> {
        guard let chatterAPI = self.chatterAPI else { return .just(false) }
        let originIsSpecialFocus = condition.isSpecialFocus
        condition.isSpecialFocus = follow
        self.items = self.createDataSourceItems()
        let ob = chatterAPI
            .updateSpecialFocusStatus(to: [chatterID], operate: follow ? .add : .delete)
            .map { response in response.isShowGuidance }
            .do(onError: { [weak self] _ in
                guard let self = self else { return }
                self.condition.isSpecialFocus = originIsSpecialFocus
                self.items = self.createDataSourceItems()
                 // 因为刷新太快，没有弹回去的效果，延迟刷新
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.refreshPublish.onNext(())
                }
            })
        return ob
    }

    // 因为屏蔽权限需要同步设置完成，所以单写一个方法
    func setUserBlockAuth(enable: Bool, _ setBlockSuccessBlock: (() -> Void)? = nil) {

        self.condition.isBlocked = enable
        self.items = self.createDataSourceItems()
        self.refreshPublish.onNext(())

        let viewForShowingHUD = targetVc?.viewIfLoaded
        self.blockedDisposeBag = DisposeBag()
        monitor?.setUserBlockAuthWith(blockUserID: userId, isBlock: enable)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else {
                    return
                }
                self.oldTempBlocked = self.condition.isBlocked
                setBlockSuccessBlock?()
                SetInformationViewModel.logger.info("用户\(String(describing: self.userId))设置屏蔽权限成功")
            }, onError: { [weak self] (error) in
                guard let self = self else {
                    return
                }
                if let view = viewForShowingHUD {
                    UDToast.showFailure(with: BundleI18n.LarkContact.Lark_Legacy_ErrorMessageTip, on: view, error: error)
                }
                self.condition.isBlocked = self.oldTempBlocked
                self.items = self.createDataSourceItems()
                 // 因为刷新太快，没有弹回去的效果，延迟刷新
                DispatchQueue.main.asyncAfter(deadline: .now() + self.reloadDataSpaceValueOnError) { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.refreshPublish.onNext(())
                }
                SetInformationViewModel.logger.error("用户设置屏蔽权限失败\(String(describing: self.userId))", error: error)
            }).disposed(by: blockedDisposeBag)

    }

    func getUserAuthority() {
        // 用户ID不存在 直接返回
        if userId.isEmpty {
            return
        }
        monitor?.getUserBlockAuthority(userId: userId, strategy: nil)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                guard let self = self else {
                    return
                }
                self.condition.isBlocked = response.blockStatus
                self.oldTempBlocked = self.condition.isBlocked
                self.items = self.createDataSourceItems()
                self.headerViews = self.createHeaderViews()
                self.footerViews = self.createFooterViews()
                self.refreshPublish.onNext(())
                }, onError: { [weak self] (error) in
                    SetInformationViewModel.logger.error("用户屏蔽, 协作权限配置未拉取到\(String(describing: self?.userId))", error: error)
            }).disposed(by: disposeBag)
    }

    func deleContactWithFinishBlock(_ finishBlock: @escaping (Bool) -> Void) {
        monitor?.deleContact(userId: self.userId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                finishBlock(true)
            }, onError: { (error) in
                finishBlock(false)
                SetInformationViewModel.logger.error("删除好友失败", error: error)
            }).disposed(by: self.disposeBag)
    }

    // MARK: 获取是否有配置项需要展示
    static func needToShowSetInfoViewWithConfig(_ config: SetInformationCondition) -> Bool {
        let showSpecialFocus = !config.isMe
        let shareEnable: Bool = {
            switch config.shareInfo {
            case .no:
                return false
            default:
                return true
            }
        }()
        let showShare = shareEnable
        let showAliasAndMemo = !config.isMe
        let canDelete = !config.isSameTenant && config.isFriend // 删除联系人
        let canBlock = !config.isSameTenant // 屏蔽
         // 举报| 设置号码查询次数| 屏蔽(不是同一Tenant) | 删除联系人(不是同一Tenant&好友)
        let needToShow = config.isCanReport
            || config.setNumebrEnable
            || canBlock
            || canDelete
            || showAliasAndMemo
            || showShare
            || showSpecialFocus
        return needToShow
    }
}

extension SetInformationViewModel: UITextViewDelegate {
    // MARK: - UITextViewDelegate
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if interaction == .invokeDefaultAction {
            // 去到星标联系人设置页
            self.delegate?.onClickSpecialFocusSetting()
        }
        return false
    }
}
