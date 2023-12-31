//
//  MailCacheSettingViewController.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/3/28.
//

import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import RxDataSources
import RustPB
import Homeric
import FigmaKit
import UniverseDesignCheckBox
import UniverseDesignFont
import Reachability
import UniverseDesignToast
import LarkAlertController

protocol MailCacheSettingDelegate: AnyObject {
    func updateCacheRangeSuccess(accountId: String, expandPreload: Bool, offline: Bool, allowMobileTraffic: Bool)
}

enum MailCacheScene {
    case setting
    case home
    case search
}

class MailCacheSettingViewController: MailBaseViewController, UITableViewDataSource, UITableViewDelegate {
    typealias PreloadConfig = DataService.PreloadConfig
    var scene: MailCacheScene = .setting
    private weak var viewModel: MailSettingViewModel?
    private let disposeBag = DisposeBag()
    private let timeOptions: [Email_Client_V1_MailPreloadTimeStamp] = [.preloadClosed, .within7Days,
                                                                       .within30Days, .within90Days,
                                                                       .within180Days, .within365Days]
    private var configSections = [[MailSettingItemProtocol]]()
    var accountId: String
    var accountSetting: MailAccountSetting?
    let accountContext: MailAccountContext
    weak var delegate: MailCacheSettingDelegate?
    private var originalTimeStamp: Email_Client_V1_MailPreloadTimeStamp = .preloadStUnspecified
    
    /// originConfig是用户进入设置界面后拉取到的配置信息， 即用户未修改前的配置。
    /// newConfig 是修改配置后的数据，其初始值是originConfig, 只有newConfig != originConfig 右上角的保存按钮才可点
    /// 在保存成功后，originConfig会变成修改后的值。
    private var originConfig: PreloadConfig
    private var newConfig: PreloadConfig?
    
    private let saveBtn = UIButton(type: .custom)
    
    init(viewModel: MailSettingViewModel?, accountContext: MailAccountContext) {
        self.viewModel = viewModel
        self.accountContext = accountContext
        self.accountId = accountContext.accountID
        self.originConfig = PreloadConfig(timeStamp: .preloadStUnspecified,
                                          needPreloadImage: false,
                                          needPreloadAttach: false,
                                          allowMobileTraffic: true)
        super.init(nibName: nil, bundle: nil)
        self.refreshOptions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        updateNavAppearanceIfNeeded()
        Store.fetcher?.mailGetPreloadTimeStamp(accountID: accountId)
            .subscribe(onNext: { [weak self] response in
                guard let `self` = self else { return }
                MailLogger.info("[mail_cache_preload] getPreloadTimeStamp success! accountId: \(self.accountId) selected: \(response.timeStamp)")
                self.originConfig = PreloadConfig(timeStamp: response.timeStamp,
                                                  needPreloadImage: response.needPreloadImage,
                                                  needPreloadAttach: response.needPreloadAttachment,
                                                  allowMobileTraffic: response.allowMobileTraffic)
                self.originalTimeStamp = response.timeStamp
                self.reloadData()
            }, onError: { [weak self] (error) in
                MailLogger.error("[mail_cache_preload] getPreloadTimeStamp fail accountId: \(self?.accountId)", error: error)
            }).disposed(by: self.disposeBag)
    }
    
    override var navigationBarTintColor: UIColor {
        return UIColor.ud.bgFloatBase
    }
    
    func setupViews() {
        self.title = BundleI18n.MailSDK.Mail_EmailCache_Title
        view.backgroundColor = UIColor.ud.bgFloatBase
        
        saveBtn.addTarget(self, action: #selector(saveCacheSetting), for: .touchUpInside)
        saveBtn.setTitle(BundleI18n.MailSDK.Mail_EmailCache_Save_Button, for: .normal)
        saveBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        saveBtn.setTitleColor(UIColor.ud.primaryPri500, for: .normal)
        saveBtn.setTitleColor(UIColor.ud.primaryPri600, for: .highlighted)
        saveBtn.setTitleColor(UIColor.ud.primaryPri200, for: .disabled)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: saveBtn)
        saveBtn.isEnabled = false
        
        let cancelBtn = UIBarButtonItem(title: BundleI18n.MailSDK.Mail_EmailCache_Cancel_Button,
                                        style: .plain, target: self, action: #selector(cancel))
        cancelBtn.setTitleTextAttributes([.foregroundColor: UIColor.ud.textTitle], for: .normal)
        cancelBtn.setTitleTextAttributes([.foregroundColor: UIColor.ud.textTitle.withAlphaComponent(0.7)], for: .highlighted)
        navigationItem.leftBarButtonItem = cancelBtn
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    @objc func saveCacheSetting() {
        guard var config = newConfig else { return }
        if config.timeStamp == .preloadClosed || config.timeStamp == .preloadStUnspecified {
            // 设置为默认值
            config.allowMobileTraffic = true
            config.needPreloadImage = false
            config.needPreloadAttach = false
        }
        MailLogger.info("[mail_cache_preload] image: \(config.needPreloadImage), attach: \(config.needPreloadImage), net: \(config.allowMobileTraffic)")
        Store.fetcher?.mailSetPreloadTimeStamp(accountID: accountId, config: config)
            .subscribe(onNext: { [weak self] response in
                guard let `self` = self else { return }
                guard response.hasAvailableSpace_p else {
                    let alert = LarkAlertController()
                    alert.setTitle(text: BundleI18n.MailSDK.Mail_EmailCache_NotEnoughSpace_UnableToCache_MobileTitle)
                    alert.setContent(text: BundleI18n.MailSDK.Mail_EmailCache_NotEnoughSpace_UnableToCache_MobileDesc, alignment: .center)
                    alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_EmailCache_NotEnoughSpace_GotItMobile_Button)
                    self.accountContext.navigator.present(alert, from: self)
                    return
                }
                MailLogger.info("[mail_cache_preload] mailSetPreloadTimeStamp success! selected range: \(config.timeStamp)")
                self.originConfig = config
                self.newConfig = nil
                if self.rootSizeClassIsRegular && self.scene == .setting {
                    self.accountContext.navigator.pop(from: self) {
                        self.completeSave()
                    }
                } else {
                    self.dismiss(animated: true) {
                        self.completeSave()
                    }
                }
        }, onError: { (error) in
            MailLogger.error("[mail_cache_preload] mailSetPreloadTimeStamp fail", error: error)
        }).disposed(by: self.disposeBag)
    }

    private func completeSave() {
        let event = NewCoreEvent(event: .email_lark_setting_click)
        event.params = ["target": "none",
                        "click": "save_cache_setting",
                        "last_cache_days": "\(self.originalTimeStamp.cacheCapacity())",
                        "cache_days": "\(self.originConfig.timeStamp.cacheCapacity())",
                        "user_mobile_network": self.originConfig.allowMobileTraffic ? "true" : "false",
                        "cache_attachment": self.originConfig.needPreloadAttach ? "true" : "false",
                        "cache_img": self.originConfig.needPreloadImage ? "true" : "false"]
        event.post()
        let offline = {
            if let reach = Reachability() {
                return reach.connection == .none
            } else {
                return false
            }
        }()
        if Store.settingData.getCachedCurrentAccount()?.mailAccountID == accountId {
            /// 强制关闭首页已经完成的缓存任务成功提示
            Store.settingData.$preloadRangeChanges.accept(())
        }
        self.delegate?.updateCacheRangeSuccess(accountId: self.accountId,
                                               expandPreload: self.originConfig.timeStamp.cacheCapacity() > self.originalTimeStamp.cacheCapacity(),
                                               offline: offline,
                                               allowMobileTraffic: self.originConfig.allowMobileTraffic)
        self.originalTimeStamp = self.originConfig.timeStamp
    }
    
    private func refreshOptions() {
        let currentTimeStamp = newConfig?.timeStamp ?? originConfig.timeStamp
        if currentTimeStamp == .preloadClosed || currentTimeStamp == .preloadStUnspecified {
            self.configSections = []
        } else {
            var originStatus = false
            self.configSections = []
            if enableCacheImageAndAttach() {
                var secondSection = [MailSettingItemProtocol]()
                originStatus = newConfig?.needPreloadImage ?? originConfig.needPreloadImage
                let imageCache = MailSettingSwitchModel(cellIdentifier: MailSettingSwitchCell.lu.reuseIdentifier,
                                                        accountId: accountId,
                                                        title: BundleI18n.MailSDK.Mail_EmailCache_SelectContentType_Images_Checkbox,
                                                        status: originStatus) { [weak self] status in
                    guard let self = self else { return }
                    MailLogger.info("[mail_cache_preload] did clicked imageCache switch \(status)")
                    if self.newConfig == nil {
                        self.newConfig = self.originConfig
                    }
                    self.newConfig?.needPreloadImage = status
                    self.updateSaveBtnStatus()
                }
                secondSection.append(imageCache)
                originStatus = newConfig?.needPreloadAttach ?? originConfig.needPreloadAttach
                let attachCache = MailSettingSwitchModel(cellIdentifier: MailSettingSwitchCell.lu.reuseIdentifier,
                                                         accountId: accountId,
                                                        title: BundleI18n.MailSDK.Mail_EmailCache_SelectContentType_Attachments_Checkbox,
                                                         status: originStatus) { [weak self] status in
                    guard let self = self else { return }
                    MailLogger.info("[mail_cache_preload] did clicked attachCache switch \(status)")
                    if self.newConfig == nil {
                        self.newConfig = self.originConfig
                    }
                    self.newConfig?.needPreloadAttach = status
                    self.updateSaveBtnStatus()
                }
                secondSection.append(attachCache)
                self.configSections.append(secondSection)
            }
            
            var thirdSection = [MailSettingItemProtocol]()
            originStatus = newConfig?.allowMobileTraffic ?? originConfig.allowMobileTraffic
            let cellulaOption = MailSettingSwitchModel(cellIdentifier: MailSettingSwitchCell.lu.reuseIdentifier,
                                                       accountId: accountId,
                                                       title: BundleI18n.MailSDK.Mail_EmailCache_UseCellularData_Toggle,
                                                       status: originStatus) { [weak self] status in
                guard let self = self else { return }
                MailLogger.info("[mail_cache_preload] did clicked cellula switch")
                if self.newConfig == nil {
                    self.newConfig = self.originConfig
                }
                self.newConfig?.allowMobileTraffic = status

                self.updateSaveBtnStatus()
            }
            
            thirdSection.append(cellulaOption)
            self.configSections.append(thirdSection)
        }
    }

    @objc func cancel() {
        if rootSizeClassIsRegular && scene == .setting {
            accountContext.navigator.pop(from: self)
        } else {
            dismiss(animated: true)
        }
    }

    // MARK: - UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return timeOptions.count
        } else {
            return configSections[section - 1].count
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return configSections.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MailBaseSettingOptionCell.lu.reuseIdentifier) as? MailBaseSettingOptionCell else {
                return UITableViewCell()
            }
            let time = timeOptions[indexPath.row]
            cell.titleLabel.text = time.title()
            if self.originConfig.timeStamp == .preloadStUnspecified {
                self.originConfig.timeStamp = .preloadClosed
            }
            let newTimestamp = self.newConfig?.timeStamp ?? self.originConfig.timeStamp
            cell.isSelected = (time == newTimestamp)
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MailSettingSwitchCell.lu.reuseIdentifier) as? MailSettingSwitchCell else {
                return UITableViewCell()
            }
            guard indexPath.section > 0, indexPath.section - 1 < configSections.count else { return UITableViewCell() }
            let section = configSections[indexPath.section - 1]
            cell.item = section[indexPath.row]
            return cell
        }
    }
    
    func updateSaveBtnStatus() {
        saveBtn.isEnabled = newConfig != originConfig && newConfig != nil
    }
    
    func reloadData() {
        self.refreshOptions()
        self.tableView.reloadData()
    }
    
    private func enableCacheImageAndAttach() -> Bool {
        return accountContext.featureManager.open(.offlineCache, openInMailClient: true)
        && accountContext.featureManager.open(.offlineCacheImageAttach, openInMailClient: true)
        && accountSetting?.setting.userType != .tripartiteClient
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil, indexPath.section == 0 else { return }
        let time = timeOptions[indexPath.row]
        if newConfig == nil {
            newConfig = originConfig
        }
        newConfig?.timeStamp = time
        updateSaveBtnStatus()
        reloadData()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 0 else {
            return createHeaderView(title: "")
        }
        return createHeaderView(title: BundleI18n.MailSDK.Mail_EmailCache_CacheEmailFrom_Title)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section == 0 else {
            return createFooterView(title: "")
        }
        return createFooterView(title: BundleI18n.MailSDK.Mail_EmailCache_TakeUpSpace_Text)
    }

    lazy var tableView: InsetTableView = {
        let t = InsetTableView(frame: .zero)
        t.dataSource = self
        t.delegate = self
        t.lu.register(cellSelf: MailBaseSettingOptionCell.self)
        t.lu.register(cellSelf: MailSettingSwitchCell.self)
        t.separatorColor = UIColor.ud.lineDividerDefault
        t.rowHeight = UITableView.automaticDimension
        t.sectionFooterHeight = UITableView.automaticDimension
        t.sectionHeaderHeight = UITableView.automaticDimension
        t.backgroundColor = UIColor.ud.bgFloatBase
        return t
    }()
    
    private func createFooterView(title: String) -> UITableViewHeaderFooterView {
        let view = UITableViewHeaderFooterView()
        let detailLabel = UILabel()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 1.4
        let attrString = NSMutableAttributedString(string: title)
        attrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attrString.length))
        detailLabel.attributedText = attrString
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        detailLabel.textColor = UIColor.ud.textPlaceholder
        detailLabel.numberOfLines = 0
        view.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.left.equalTo(32)
            make.right.equalTo(-32)
            if title.isEmpty {
                make.height.equalTo(0.1)
                make.top.equalToSuperview().offset(0.1)
            } else {
                make.top.equalToSuperview().offset(4)
            }
        }
        return view
    }
    
    private func createHeaderView(title: String) -> UITableViewHeaderFooterView {
        let view = UITableViewHeaderFooterView()
        let detailLabel = UILabel()
        detailLabel.text = BundleI18n.MailSDK.Mail_EmailCache_CacheEmailFrom_Title
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        detailLabel.textColor = UIColor.ud.textCaption
        detailLabel.numberOfLines = 0
        view.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-4)
            make.left.equalTo(20)
            make.right.equalTo(-20)
            if title.isEmpty {
                make.height.equalTo(0)
            }
        }
        return view
    }

}

extension MailCacheSettingViewController {
    /// 工具方法，展示修改范围后的提示
    static func changeCacheRangeSuccess(accountId: String, showProgrssBtn: Bool, expandPreload: Bool,
                                        offline: Bool, allowMobileTraffic: Bool, view: UIView, completion: (() -> Void)?) {
        if expandPreload {
            if !offline {
                let canStartPreload = Reachability()?.connection == .wifi || (Reachability()?.connection == .cellular && allowMobileTraffic)
                if showProgrssBtn && canStartPreload {
                    let opConfig = UDToastOperationConfig(text: BundleI18n.MailSDK.Mail_EmailCache_SettingsSavedStartCache_ViewProgress_Button, displayType: .auto)
                    let config = UDToastConfig(toastType: .success, text: BundleI18n.MailSDK.Mail_EmailCache_SettingsSavedStartCache_Toast, operation: opConfig)
                    UDToast.showToast(with: config, on: view, operationCallBack: { _ in
                        completion?()
                    })
                } else {
                    let toast = canStartPreload ? BundleI18n.MailSDK.Mail_EmailCache_SettingsSavedStartCache_Toast : BundleI18n.MailSDK.Mail_EmailCache_CachingWithWiFi_Toast
                    UDToast.showSuccess(with: toast, on: view)
                }
            } else {
                UDToast.showSuccess(with: BundleI18n.MailSDK.Mail_EmailCache_SettingsSavedEffectBackOnline_Toast, on: view)
            }
        } else {
            UDToast.showSuccess(with: BundleI18n.MailSDK.Mail_EmailCache_SettingsSaved_Toast, on: view)
        }
    }
}

extension Email_Client_V1_MailPreloadTimeStamp {
    func title() -> String {
        switch self {
        case .preloadClosed, .preloadStUnspecified:
            return BundleI18n.MailSDK.Mail_EmailCache_CacheEmailFrom_Dont_Option
        case .within7Days:
            return BundleI18n.MailSDK.Mail_EmailCache_CacheEmailFrom_LastNumDays_Option("7")
        case .within30Days:
            return BundleI18n.MailSDK.Mail_EmailCache_CacheEmailFrom_LastNumDays_Option("30")
        case .within90Days:
            return BundleI18n.MailSDK.Mail_EmailCache_CacheEmailFrom_LastNumDays_Option("90")
        case .within180Days:
            return BundleI18n.MailSDK.Mail_EmailCache_CacheEmailFrom_LastNumDays_Option("180")
        case .within365Days:
            return BundleI18n.MailSDK.Mail_EmailCache_CacheEmailFrom_LastNumDays_Option("365")
        @unknown default:
            fatalError()
        }
    }

    func detail() -> String {
        switch self {
        case .preloadClosed, .preloadStUnspecified:
            return BundleI18n.MailSDK.Mail_EmailCacheOff_Setting_Text
        case .within7Days:
            return BundleI18n.MailSDK.Mail_EmailCacheDays_Setting_Text("7")
        case .within30Days:
            return BundleI18n.MailSDK.Mail_EmailCacheDays_Setting_Text("30")
        case .within90Days:
            return BundleI18n.MailSDK.Mail_EmailCacheDays_Setting_Text("90")
        case .within180Days:
            return BundleI18n.MailSDK.Mail_EmailCacheDays_Setting_Text("180")
        case .within365Days:
            return BundleI18n.MailSDK.Mail_EmailCacheDays_Setting_Text("365")
        @unknown default:
            fatalError()
        }
    }

    func cacheCapacity() -> Int {
        switch self {
        case .preloadClosed, .preloadStUnspecified:
            return 0
        case .within7Days:
            return 7
        case .within30Days:
            return 30
        case .within90Days:
            return 90
        case .within180Days:
            return 180
        case .within365Days:
            return 365
        @unknown default:
            fatalError()
        }
    }
}

extension DataService.PreloadConfig: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.timeStamp == rhs.timeStamp &&
        lhs.allowMobileTraffic == rhs.allowMobileTraffic &&
        lhs.needPreloadImage == rhs.needPreloadImage &&
        lhs.needPreloadAttach == rhs.needPreloadAttach
    }
}
