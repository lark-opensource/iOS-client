//
//  MailSettingSignatureViewController.swift
//  MailSDK
//
//  Created by tanghaojin on 2021/10/8.
//

import Foundation
import UIKit
import EENavigator
import LarkUIKit
import UniverseDesignTabs
import RxSwift

class MailSettingSignatureViewController: MailBaseViewController, UDTabsViewDelegate, MailSettingSigSettingDelegate {

    enum Scene {
        case signatureList
        case signatureSetting
    }

    var scene: Scene = .signatureList
    private var signatureBag: DisposeBag = DisposeBag()
    private lazy var titleTabsView: UDTabsTitleView = {
        let tabsView = UDTabsTitleView()
        let mySigText = BundleI18n.MailSDK.Mail_Signature_MySignature_TabButton
        let defaultText = BundleI18n.MailSDK.Mail_Mobile_DefaultSignature_Tab
        tabsView.titles = [mySigText, defaultText]
        let config = tabsView.getConfig()
        config.layoutStyle = .average
        config.itemSpacing = 0
        config.titleNumberOfLines = 5
        tabsView.setConfig(config: config)
        /// 配置指示器
        let indicator = UDTabsIndicatorLineView()
        indicator.indicatorHeight = 2
        indicator.indicatorCornerRadius = 0
        tabsView.indicators = [indicator]
        tabsView.delegate = self
        return tabsView
    }()
    private lazy var tabViewBottomLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault.withAlphaComponent(0.15)
        return view
    }()
    private lazy var tabsContainer: UDTabsListContainerView = {
        return UDTabsListContainerView(dataSource: self)
    }()

    var items = [MailBaseViewController & UDTabsListContainerViewDelegate]()
    var firstLoad = true
    enum middleViewType {
        case none
        case emptyView
        case netErrorView
        case createSignView
        case dbErrorView
    }
    var viewType: middleViewType = .none
    var accountId: String = ""
    var email: String = ""
    var name: String = ""
    private var signs = [MailSignature]()
    private var listData: SigListData?

    private let accountContext: MailAccountContext

    init(accountContext: MailAccountContext) {
        self.accountContext = accountContext
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    override var navigationBarTintColor: UIColor {
        return UIColor.ud.bgFloat
    }

    func mailClient() -> Bool {
        if let account = Store.settingData.getCachedAccountList()?.first(where: { $0.mailAccountID == accountId }) {
            return account.mailSetting.userType == .tripartiteClient
        }
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.shouldRecordMailState = false
        title = mailClient() ? BundleI18n.MailSDK.Mail_ThirdClient_MobileSignature :
        BundleI18n.MailSDK.Mail_BusinessSignature_EmailSignature
        loadSigData()
        updateNavAppearanceIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateNavAppearanceIfNeeded()
    }

    func shouldRefreshListData() {
        MailDataServiceFactory.commonDataService?.getSignaturesRequest(fromSetting: true,
                                                                      accountId: self.accountId ).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (listData) in
            guard let `self` = self else { return }
            self.listData = Store.settingData.processSigData(resp: listData,
                                                             email: self.email,
                                                             name: self.name)
            if self.accountId == Store.settingData.getCachedCurrentAccount()?.mailAccountID {
                if let data = self.listData {
                    Store.settingData.updateCurrentSigData(data)
                }
                self.accountContext.editorLoader.changeNewEditor(type: .settingChange)
            }
        }, onError: { (err) in
            MailLogger.error("[mail_client_sign] loadSigData err \(err)")
        }).disposed(by: signatureBag)
    }

    func loadSigData() {
        self.showLoading()
        MailDataServiceFactory.commonDataService?.getSignaturesRequest(fromSetting: true,
                                                                      accountId: self.accountId ).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (listData) in
            guard let `self` = self else { return }
            let resData = Store.settingData.processSigData(resp: listData,
                                                           email: self.email,
                                                           name: self.name)
            if resData.signatures.isEmpty {
                self.viewType = self.mailClient() ? .createSignView : .emptyView
                self.setupViews()
                return
            }
            self.viewType = .none
            self.setupViews()
            self.signs = resData.signatures
            self.showTipsView = self.showTips(sigData: resData)
            self.configSigList(origin: resData)
            self.configSigSetting(origin: resData)
            self.listData = resData
        }, onError: { [weak self] (err) in
            guard let `self` = self else { return }
            self.hideLoading()
            MailLogger.info("loadSigData err \(err)")
            self.viewType = self.mailClient() ? .dbErrorView : .netErrorView
            self.setupViews()
        }).disposed(by: signatureBag)
    }

    func showTips(sigData: SigListData) -> Bool {
        return sigData.optionalSignatureMap["current_account"]?.isForceApply ?? false
    }

    func configSigList(origin: SigListData) {
        var sigList: [MailSettingSigWebModel] = []
        let forceMode = origin.optionalSignatureMap["current_account"]?.isForceApply ?? false
        var newSigCnt = 0
        var replySigCnt = 0
        for usage in origin.signatureUsages {
            if usage.hasNewMailSignatureID {
                newSigCnt = newSigCnt + 1
            }
            if usage.hasReplyMailSignatureID {
                replySigCnt = replySigCnt + 1
            }
        }
        for data in origin.signatures {
            var canUse = false
            if let ids = origin.optionalSignatureMap["current_account"]?.signatureIds,
               ids.contains(data.id) {
                canUse = true
            }
            let forceUse = forceMode && canUse
            let model = MailSettingSigWebModel(data, canUse, forceUse, cacheService: accountContext.cacheService)
            sigList.append(model)
        }
        for item in items {
            if let vc = item as? MailSettingSigListViewController {
                vc.delegate = self
                vc.configSigList(sigs: sigList,
                                 newSigCnt: newSigCnt,
                                 replySigCnt: replySigCnt)
                vc.refreshList()
            }
        }
    }

    func configSigSetting(origin: SigListData) {
        let usages = origin.signatureUsages
        // gen canUseIds
        var ids: [String] = []

        if let sigIds = origin.optionalSignatureMap["current_account"]?.signatureIds {
            ids = sigIds
        }
        let forceApply = origin.optionalSignatureMap["current_account"]?.isForceApply ?? false
        for item in items {
            if let vc = item as? MailSettingSigSettingViewController {
                vc.configSigSettings(usages: origin.signatureUsages,
                                     signatures: origin.signatures,
                                     canUseIds: ids,
                                     forceApply: forceApply)
            }
        }
    }

    func setupViews() {
        view.subviews.forEach({ $0.removeFromSuperview() })
        view.backgroundColor = UIColor.ud.bgFloat
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.tintColor = UIColor.ud.iconN1

        if viewType != .none {
            view.backgroundColor = UIColor.ud.bgFloatBase
            self.view.addSubview(emptyView)
            self.view.addSubview(emptyTitle)
            emptyView.snp.makeConstraints { (make) in
                make.size.equalTo(CGSize(width: 120, height: 120))
                make.centerY.equalToSuperview().offset(-100)
                make.centerX.equalToSuperview()
            }
            emptyTitle.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(76)
                make.right.equalToSuperview().offset(-76)
                make.centerX.equalToSuperview()
                make.top.equalTo(emptyView.snp.bottom).offset(15)
            }
            if viewType == .netErrorView {
                emptyTitle.text = BundleI18n.MailSDK.Mail_Settings_NetworkErrorRetry
                emptyView.image = Resources.mail_setting_net_err
            } else if viewType == .dbErrorView {
                emptyTitle.text = BundleI18n.MailSDK.Mail_ThirdClient_UnableToLoadTryAgain
                emptyView.image = Resources.mail_setting_net_err
            }
            if viewType == .createSignView {
                emptyTitle.text = BundleI18n.MailSDK.Mail_ThirdClient_NoSignaturesYet
                view.addSubview(emptyAddButton)
                emptyAddButton.snp.makeConstraints { (make) in
                    make.top.equalTo(emptyTitle.snp.bottom).offset(16)
                    var width: CGFloat = 96
                    if let calWidth = emptyAddButton.titleLabel?.text?.getTextWidth(font: UIFont.systemFont(ofSize: 16.0), height: 36) {
                        width = calWidth + 32.0
                    }
                    make.size.equalTo(CGSize(width: width, height: 36))
                    make.centerX.equalToSuperview()
                }
            }
            self.hideLoading()
            return
        }

        // tabs
        titleTabsView.listContainer = tabsContainer
        titleTabsView.isHidden = false

        let listVC = MailSettingSigListViewController(accountContext: accountContext)
        listVC.accountId = accountId
        items.append(listVC)

        let settingVC = MailSettingSigSettingViewController(accountContext: accountContext)
        settingVC.accountId = accountId
        settingVC.delegate = self
        items.append(settingVC)
        layoutFilp()
    }

    lazy private var tipsView: MailSharedAccountHeaderView = {
        let txt = BundleI18n.MailSDK.Mail_Mailbox_PublicMailboxSettingSync
        let txtWidth = txt.getTextWidth(fontSize: 14)
        var iconTop = false
        if txtWidth > self.view.bounds.size.width - 56 {
            iconTop = true
        }
        let view = MailSharedAccountHeaderView(frame: .zero, iconTop: iconTop)
        view.updateTitleColor(color: UIColor.ud.textTitle)
        return view
    }()
    var showTipsView: Bool = false {
        didSet {
            tipsView.isHidden = !showTipsView
            let topMargin = showTipsView ? 46 : 0
            self.tabsContainer.snp.updateConstraints { (make) in
                make.top.equalTo(titleTabsView.snp.bottom).offset(topMargin)
            }
        }
    }

    func layoutFilp() {
        let naviHeight = navigationController?.navigationBar.frame.height ?? 0 + UIApplication.shared.statusBarFrame.height
        let safeAreaMargin = Display.bottomSafeAreaHeight + Display.topSafeAreaHeight
        let offset = Display.pad ? 0 : safeAreaMargin + naviHeight
        view.addSubview(tipsView)
        view.addSubview(titleTabsView)
        view.addSubview(tabsContainer)
        titleTabsView.addSubview(tabViewBottomLine)

        tipsView.isHidden = !showTipsView
        tipsView.setTitle(text: BundleI18n.MailSDK.Mail_Signature_UseMandatoryOrganizationSignature_Text)
        titleTabsView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.width.equalToSuperview()
            $0.height.equalTo(40)
            $0.top.equalToSuperview().offset(0)
        }

        tipsView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(titleTabsView.snp.bottom)
            make.height.equalTo(46)
        }

        let topMargin = showTipsView ? 46 : 0
        tabsContainer.snp.makeConstraints {
            $0.top.equalTo(titleTabsView.snp.bottom).offset(topMargin)
            $0.left.right.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        tabViewBottomLine.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        for view in titleTabsView.indicators {
            titleTabsView.bringSubviewToFront(view)
        }
        self.showLoading()
    }

    func scrollChangeToIndex(_ index: Int) {

    }

    func selectChangeToIndex(_ index: Int) {

    }

    func selectChangeToIndexProgress(_ progress: CGFloat) {

    }

    lazy var emptyView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Resources.mail_setting_empty
        imageView.contentMode = .scaleAspectFill
        //(120,120)
        return imageView
    }()

    lazy var emptyTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.ud.textCaption
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = BundleI18n.MailSDK.Mail_Settings_GoToDesktopToAddSignature()
        return label
    }()

    lazy var emptyAddButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(BundleI18n.MailSDK.Mail_ThirdClient_AddSignature, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0)
        button.tintColor = UIColor.ud.iconN1
        button.backgroundColor = UIColor.ud.primaryContentDefault
        button.layer.cornerRadius = 6
        button.layer.masksToBounds = true
        button.rx.tap
            .subscribe(onNext: { [weak self] _ in self?.addSign() })
            .disposed(by: signatureBag)
        return button
    }()

    func addSign() {
        if signs.count >= 20 {
            MailRoundedHUD.showTips(with: BundleI18n.MailSDK.Mail_ThirdClient_MaximumSignatures, on: view)
            return
        }
        let editVC = MailClientSignEditViewController(accountID: accountId, accountContext: accountContext)
        editVC.existSignNames = signs.map({ $0.name })
        editVC.delegate = self
        navigator?.push(editVC, from: self)
    }
}

extension MailSettingSignatureViewController: MailClientSignEditViewControllerDelegate {
    func needShowToastAndRefreshSignList(_ toast: String, inNewScene: Bool, sign: MailSignature) {
        MailRoundedHUD.showSuccess(with: toast, on: self.view)
        loadSigData()
        hideLoading()
    }
}

extension MailSettingSignatureViewController: UDTabsListContainerViewDataSource {
    func numberOfLists(in listContainerView: UDTabsListContainerView) -> Int {
        return items.count
    }

    func listContainerView(_ listContainerView: UDTabsListContainerView, initListAt index: Int) -> UDTabsListContainerViewDelegate {
        return items[index]
    }
}

extension MailSettingSignatureViewController: MailSettingSigListDelegate {
    func loadingFinish() {
        self.hideLoading()
    }

    func reloadSigData() {
        loadSigData()
    }

    func deleteSign(_ sigID: String) {
        if let index = signs.firstIndex(where: { $0.id == sigID }) {
            signs.remove(at: index)
            updateConfigSigDatasource(signs)
        }
    }

    func updateSign(_ sign: MailSignature) {
        if let index = signs.firstIndex(where: { $0.id == sign.id }) {
            signs[index] = sign
        } else {
            signs.append(sign)
        }
        updateConfigSigDatasource(signs)
    }

    private func updateConfigSigDatasource(_ signs: [MailSignature]) {
        if var listData = self.listData {
            listData.signatures = signs
            listData.optionalSignatureMap["current_account"]?.signatureIds = signs.map({ $0.id }) // 佛了 为啥还要这个
            configSigSetting(origin: listData)
            Store.settingData.updateCurrentSigData(listData)
            accountContext.editorLoader.clearEditor(type: .settingChange)
        }
    }
}
