//
//  AboutLarkModule.swift
//  LarkMine
//
//  Created by panbinghua on 2022/6/20.
//

import Foundation
import UIKit
import EENavigator
import UniverseDesignTag
import UniverseDesignBadge
import LarkTag
import LarkContainer
import LarkSDKInterface
import LarkAppConfig
import LarkReleaseConfig
import LarkKAFeatureSwitch
import RustPB
import LarkSetting
import LarkVersion
import LarkMessengerInterface
import LarkOpenSetting
import LarkUIKit
import LarkAccountInterface
import LarkSettingUI

final class AboutLarkEntryModule: BaseModule {

    private var badgeDependency: MineSettingBadgeDependency?

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)
        self.badgeDependency = try? userResolver.resolve(type: MineSettingBadgeDependency.self)
    }

    override func createCellProps(_ key: String) -> [CellProp]? {
        let badgeId = MineUGBadgeID.about.rawValue
        var accessories: [NormalCellAccessory] = []
        if let badgeDependency = self.badgeDependency {
            accessories = getAccessory(badgeId: badgeId, dependency: badgeDependency)
        }
        let item = NormalCellProp(title: BundleI18n.LarkMine.Lark_NewSettings_AboutFeishuMobile(),
                                     accessories: accessories,
                                     onClick: { [weak self] _ in
            guard let vc = self?.context?.vc else { return }
            self?.userResolver.navigator.push(body: MineAboutLarkBody(), from: vc)
        })
        return [item]
    }
}

final class AboutLarkModule: BaseModule {

    private var badgeDependency: MineSettingBadgeDependency?
    private var userAppConfig: UserAppConfig?
    private var versionUpdateService: VersionUpdateService?
    private var passportService: PassportService?
    private var featureGatingService: FeatureGatingService?

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)

        self.badgeDependency = try? self.userResolver.resolve(assert: MineSettingBadgeDependency.self)
        self.userAppConfig = try? self.userResolver.resolve(assert: UserAppConfig.self)
        self.versionUpdateService = try? self.userResolver.resolve(assert: VersionUpdateService.self)
        self.passportService = try? self.userResolver.resolve(assert: PassportService.self)
        self.featureGatingService = try? self.userResolver.resolve(assert: FeatureGatingService.self)

        self.onRegisterDequeueViews = { tableview in
            tableview.register(AboutLarkModule.WhitePaperFooter.self, forHeaderFooterViewReuseIdentifier: AboutLarkModule.WhitePaperFooter.identifier)
            tableview.register(AboutLarkModule.PowerByFooter.self, forHeaderFooterViewReuseIdentifier: AboutLarkModule.PowerByFooter.identifier)
        }
        self.addStateListener(.viewWillAppear) { [weak self] in
            self?.passportService?.subscribeStatusBarInteraction()
        }
        self.addStateListener(.viewWillDisappear) { [weak self] in
            self?.passportService?.unsubscribeStatusBarInteraction()
        }
        self.versionUpdateService?.isShouldUpdate
            .subscribe(onNext: { [weak self] _ in
                self?.context?.reload()
            }).disposed(by: self.disposeBag)
        NotificationCenter.default.rx.notification(
            MineNotification.DidShowSettingUpdateGuide)
            .subscribe(onNext: { [weak self] _ in
                self?.context?.reload()
            }).disposed(by: disposeBag)
    }

    override func createSectionProp(_ key: String) -> SectionProp? {
        if key == ModulePair.AboutLark.featureIntro.createKey {
            return createFeatureIntroSection()
        } else if key == ModulePair.AboutLark.whitePaper.createKey {
            return createWhitePaper()
        } else if key == ModulePair.AboutLark.privacy.createKey {
            return createPrivacySection()
        }
        return nil
    }

    func fsURL(for key: FeatureSwitch.ConfigKey, defaultKey: String) -> URL? {
        if let string = FeatureSwitch.share.config(for: key).first, let url = URL(string: string) {
            return url
        }
        return getUrl(key: defaultKey)
    }

    func getUrl(key: String) -> URL? {
        guard let str = userAppConfig?.resourceAddrWithLanguage(key: key) else { return nil }
        return URL(string: str)
    }

    func createLinkCell(key: String, title: String, onClick: (() -> Void)? = nil) -> CellProp? {
        guard let url = getUrl(key: key) else { return nil }
        return NormalCellProp(title: title, accessories: [.arrow()], onClick: { [weak self] _ in
            guard let vc = self?.context?.vc else { return }
            onClick?()
            self?.userResolver.navigator.push(url, context: ["from": "about_lark"], from: vc)
        })
    }

    // 获取白皮书地址
    private func getWhitePaperaUrl() -> URL? {
        let key = RustPB.Basic_V1_AppConfig.ResourceKey.securityWhitePaper
        guard var str = userAppConfig?.resourceAddrWithLanguage(key: key) else { return nil }
        str.append("&show_right_button=false")
        return URL(string: str)
    }

    func createWhitePaper() -> SectionProp? {
        guard let featureGatingService = self.featureGatingService else { return nil }
        guard featureGatingService.staticFeatureGatingValue(with: .suiteAboutWhitepaper) else { return nil }
        guard let url = getWhitePaperaUrl() else { return nil }
        let item = NormalCellProp(title: BundleI18n.LarkMine.Lark_Core_FeishuSecurityWhitePaper, accessories: [.arrow()], onClick: { [weak self] _ in
            guard let vc = self?.context?.vc else { return }
            MineTracker.trackSettingAboutWhitePaper()
            self?.userResolver.navigator.push(url, context: ["from": "about_lark"], from: vc)
        })
        let section = SectionProp(items: [item], header: .normal, footer: .prop(WhitePaperFooter.Prop()))
        return section
    }

    func createFeatureIntroSection() -> SectionProp? {
        let newVersion = createNewVersion()
        let changeLog: CellProp? = {
            guard let featureGatingService = self.featureGatingService else { return nil }
            guard featureGatingService.staticFeatureGatingValue(with: .suiteAboutReleasenote) else { return nil }
            return createLinkCell(key: RustPB.Basic_V1_AppConfig.ResourceKey.helpReleaseLog,
                                 title: BundleI18n.LarkMine.Lark_NewSettings_AboutFeishuChangeLog) {
                MineTracker.trackSettingAboutUpdatelog()
            }
        }()
        let features: CellProp? = {
            guard let featureGatingService = self.featureGatingService else { return nil }
            guard featureGatingService.staticFeatureGatingValue(with: .suiteSpecialFunction) else { return nil }
            return createLinkCell(key: RustPB.Basic_V1_AppConfig.ResourceKey.helpKeyFeature,
                                  title: BundleI18n.LarkMine.Lark_NewSettings_AboutFeishuFeatures) {
                MineTracker.trackSettingAboutFetures()
            }
        }()
        let bestPractice: CellProp? = {
            guard let featureGatingService = self.featureGatingService else { return nil }
            guard featureGatingService.staticFeatureGatingValue(with: .suiteBestPractice) else { return nil }
            return createLinkCell(key: RustPB.Basic_V1_AppConfig.ResourceKey.helpBestPractice,
                                  title: BundleI18n.LarkMine.Lark_NewSettings_AboutFeishuBestPractice) {
                MineTracker.trackSettingAboutBestpract()
            }
        }()
        let items = [newVersion, changeLog, features, bestPractice].compactMap { $0 }
        return SectionProp(items: items, header: .custom({ self.aboutLarkHeaderView }))
    }

    lazy var aboutLarkHeaderView: UITableViewHeaderFooterView = {
        let res = UITableViewHeaderFooterView()
        let view = MineAboutLarkHeaderView(frame: CGRect(x: 0, y: 0, width: Display.width, height: 142))
        res.contentView.addSubview(view)
        view.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.equalTo(142)
        }
        return res
    }()

    func createPrivacySection() -> SectionProp? {
        let privacy = createPrivacyItem()
        let userAggrement = createUserAggrement()
        let appPermissions: CellProp? = {
            guard let featureGatingService = self.featureGatingService else { return nil }
            guard featureGatingService.staticFeatureGatingValue(with: .suiteAboutAppPermission) else { return nil }
            return createLinkCell(key: RustPB.Basic_V1_AppConfig.ResourceKey.applicationPermissionDescription,
                              title: BundleI18n.LarkMine.Lark_Core_ApplicationPermissionDesc, onClick: {
                MineTracker.trackSettingAboutAppPermission()
            })
        }()
        let sysPermissions: CellProp? = {
            guard let featureGatingService = self.featureGatingService else { return nil }
            guard featureGatingService.staticFeatureGatingValue(with: .capabilityPermissionGate) else { return nil }
            return NormalCellProp(title: BundleI18n.LarkMine.Lark_CoreAccess_SystemAccessManagement_Option,
                                  accessories: [.arrow()], onClick: { [weak self] _ in
                guard let vc = self?.context?.vc else { return }
                self?.userResolver.navigator.push(body: MineCapabilityPermissionBody(), from: vc)
            })
        }()
        let openSourceNotice: CellProp? = {
            guard let featureGatingService = self.featureGatingService else { return nil }
            guard featureGatingService.staticFeatureGatingValue(with: .openSourceNotice) else { return nil }
            return createLinkCell(key: RustPB.Basic_V1_AppConfig.ResourceKey.openSourceNotice,
                                              title: BundleI18n.LarkMine.Lark_Core_AboutLark_OpenSourceSoftwareNotice_Title)
        }()
        let items = [userAggrement, privacy, appPermissions, sysPermissions, openSourceNotice].compactMap { $0 }
        let footer: HeaderFooterType = .custom { [weak self] in
            guard let `self` = self else { return UITableViewHeaderFooterView() }
            let footerView = PowerByFooter(reuseIdentifier: PowerByFooter.identifier, userResolver: self.userResolver)
            footerView.fromVC = self.context?.vc
            return footerView
        }
        return SectionProp(items: items, footer: footer)
    }

    func createNewVersion() -> CellProp? {
        let showUpdate = self.featureGatingService?.staticFeatureGatingValue(with: .suiteAboutSoftwareupdate) ?? false
        guard versionUpdateService?.shouldUpdate ?? false && showUpdate else { return nil }
        let badgeId = MineUGBadgeID.upgrade.rawValue
        var accessories: [NormalCellAccessory] = []
        if let badgeDependency = self.badgeDependency {
            accessories = getAccessory(badgeId: badgeId, dependency: badgeDependency)
        }
        let item = NormalCellProp(title: BundleI18n.LarkMine.Lark_Legacy_FindNewVersion,
                                         accessories: accessories,
                                         onClick: { [weak self] _ in
            guard let self = self else { return }
            MineTracker.trackSettingAboutLatestversion()
            self.versionUpdateService?.updateLark()
        })
        return item
    }

    func createPrivacyItem() -> CellProp? {
        guard let featureGatingService = self.featureGatingService else { return nil }
        guard featureGatingService.staticFeatureGatingValue(with: .suiteSoftwarePrivacyAgreement) else { return nil }
        guard let url = fsURL(for: .suiteSoftwarePrivacyAgreementLink,
                              defaultKey: RustPB.Basic_V1_AppConfig.ResourceKey.helpPrivatePolicy) else { return nil }
        let badgeId = MineUGBadgeID.privacy.rawValue
        var accessories: [NormalCellAccessory] = []
        if let badgeDependency = self.badgeDependency {
            accessories = getAccessory(badgeId: badgeId, dependency: badgeDependency)
        }
        let item = NormalCellProp(title: BundleI18n.LarkMine.Lark_NewSettings_AboutFeishuPrivacyPolicy,
                                         accessories: accessories,
                                         onClick: { [weak self] _ in
            guard let self = self else { return }
            self.badgeDependency?.consumeBadges(badgeIds: [MineUGBadgeID.privacy.rawValue])
            MineTracker.trackSettingAboutPrivacypolicy()
            if let vc = self.context?.vc {
                self.userResolver.navigator.push(url, context: ["from": "about_lark"], from: vc)
            }
        })
        return item
    }

    func createUserAggrement() -> CellProp? {
        guard let featureGatingService = self.featureGatingService else { return nil }
        guard featureGatingService.staticFeatureGatingValue(with: .suiteSoftwareUserAgreement) else { return nil }
        guard let url = fsURL(for: .suiteSoftwareUserAgreementLink,
                              defaultKey: RustPB.Basic_V1_AppConfig.ResourceKey.helpUserAgreement) else { return nil }
        let badgeId = MineUGBadgeID.agreement.rawValue
        var accessories: [NormalCellAccessory] = []
        if let badgeDependency = self.badgeDependency {
            accessories = getAccessory(badgeId: badgeId, dependency: badgeDependency)
        }
        let item = NormalCellProp(title: BundleI18n.LarkMine.Lark_NewSettings_AboutFeishuUserAgreement,
                                         accessories: accessories,
                                         onClick: { [weak self] _ in
            guard let self = self else { return }
            self.badgeDependency?.consumeBadges(badgeIds: [MineUGBadgeID.agreement.rawValue])
            MineTracker.trackSettingAboutUseragree()
            if let vc = self.context?.vc {
                self.userResolver.navigator.push(url, context: ["from": "about_lark"], from: vc)
            }
        })
        return item
    }

    deinit {
        SettingLoggerService.logger(.module(key)).info("life/deinit")
        badgeDependency?.consumeBadges(badgeIds: [MineUGBadgeID.privacy.rawValue, MineUGBadgeID.agreement.rawValue])
    }

    final class WhitePaperFooter: BaseHeaderFooterView {
        static let identifier = "AboutLarkModule.WhitePaperFooter"
        final class Prop: HeaderFooterProp {
            init() {
                super.init(identifier: WhitePaperFooter.identifier)
            }
        }
        override init(reuseIdentifier: String?) {
            super.init(reuseIdentifier: reuseIdentifier)
            let icon: UIImageView = UIImageView(image: Resources.security_white_paper_icon)
            contentView.addSubview(icon)
            icon.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(16)
                make.top.equalToSuperview().offset(6)
                make.size.equalTo(CGSize(width: 14, height: 14)).priority(.required)
            }
            let label: UILabel = UILabel()
            label.font = UIFont.systemFont(ofSize: 12)
            label.textColor = UIColor.ud.textPlaceholder
            label.numberOfLines = 0
            let str = BundleI18n.LarkMine.Lark_Core_PassedInformationSecurityCertification
            label.setFigmaText(str)
            contentView.addSubview(label)
            label.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(4)
                make.bottom.lessThanOrEqualTo(-4)
                make.left.equalTo(icon.snp.right).offset(2)
                make.right.equalToSuperview().offset(-16)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    final class PowerByFooter: UITableViewHeaderFooterView, UITextViewDelegate {
        weak var fromVC: UIViewController?
        private let userResolver: UserResolver

        private let LKSettingFieldName = UserSettingKey.make(userKeyLiteral: "app_record_info")
        private let ICPRecordName = "icp_record_name"
        private let ICPRecordLink = "icp_record_link"

        static let identifier = "AboutLarkModule.PowerByFooter"
        init(reuseIdentifier: String?, userResolver: UserResolver) {
            self.userResolver = userResolver
            super.init(reuseIdentifier: reuseIdentifier)
            contentView.addSubview(self.stackView)
            self.stackView.snp.makeConstraints { make in
                make.left.right.bottom.equalToSuperview()
                make.top.equalToSuperview().offset(Layout.topPadding)
            }
            let featureGatingService = try? self.userResolver.resolve(type: FeatureGatingService.self)
            /// 注意，这个fg是反着配的，全量为true，也就是不展示powerby，只有个别租户会改成false，需要展示powerby
            let noShowPowerBy = featureGatingService?.staticFeatureGatingValue(with: .suitePoweredBy) ?? false
            if !noShowPowerBy {
                self.stackView.addArrangedSubview(self.powerByLabel)
            }
            self.stackView.addArrangedSubview(self.icpTextView)
            self.icpTextView.delegate = self
            self.setUpDataSource()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private lazy var stackView: UIStackView = {
           let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.spacing = 0
            stackView.alignment = .center
            return stackView
        }()

        private lazy var powerByLabel: UILabel = {
            let label = UILabel()
            label.text = ReleaseConfig.isLark ?
                BundleI18n.LarkMine.Lark_Core_LarkCopyright :
                BundleI18n.LarkMine.Lark_Core_FeishuCopyright
            label.font = .systemFont(ofSize: Layout.fontSize)
            label.numberOfLines = 0
            label.textColor = UIColor.ud.textPlaceholder
            label.textAlignment = .center
            label.lineBreakMode = .byWordWrapping
            return label
        }()

        private lazy var icpTextView: UITextView = {
            let textView = UITextView()
            textView.textColor = UIColor.ud.textPlaceholder
            textView.font = UIFont.systemFont(ofSize: Layout.fontSize)
            textView.isScrollEnabled = false
            textView.linkTextAttributes = [
                .foregroundColor: UIColor.ud.textLinkNormal
            ]
            textView.backgroundColor = .clear
            textView.isEditable = false
            textView.isHidden = true
            textView.textAlignment = .center
            return textView
        }()

        func setUpDataSource() {
            if let settingService = try? self.userResolver.resolve(type: SettingService.self),
                   let config = try? settingService.setting(with: LKSettingFieldName) as? [String: String],
                   let recordName = config[ICPRecordName],
               let recordLink = config[ICPRecordLink] {
                self.icpTextView.isHidden = false
                let textString = BundleI18n.LarkMine.Lark_Core_ICPnumber_Text(code: recordName)
                let attributedString = NSMutableAttributedString(string: textString, attributes: [.foregroundColor: UIColor.ud.textPlaceholder])
                let range: NSRange = (attributedString.string as NSString).range(of: recordName)
                attributedString.addAttribute(.link, value: recordLink, range: range)
                attributedString.addAttribute(.foregroundColor, value: UIColor.ud.textLinkNormal, range: range)
                self.icpTextView.attributedText = attributedString
            } else {
                self.icpTextView.isHidden = true
            }
        }

        public func textView(_ textView: UITextView,
                             shouldInteractWith URL: URL,
                             in characterRange: NSRange,
                             interaction: UITextItemInteraction) -> Bool {
            guard let vc = self.fromVC else { return false }
            self.userResolver.navigator.push(URL, from: vc)
            return false
        }

        enum Layout {
            static let fontSize: CGFloat = 12
            static let topPadding: CGFloat = 16
        }
    }
}

private func getAccessory(badgeId: String, dependency: MineSettingBadgeDependency) -> [NormalCellAccessory] {
    let style = dependency.getBadgeStyle(badgeId: badgeId)
    switch style {
    case .upgrade:
        return [.custom({ TagWrapperView.iconTagView(for: .newVersion) }), .arrow()]
    case .dot:
        return [.custom({ UDBadge(config: UDBadgeConfig()) }, spacing: 10), .arrow()]
    case .label(let content):
        return [.custom({
            let tag = TagWrapperView.iconTagView(for: .newVersion)
            tag.text = content
            return tag
            }), .arrow()]
    case .none:
        return [.arrow()]
    }
}
