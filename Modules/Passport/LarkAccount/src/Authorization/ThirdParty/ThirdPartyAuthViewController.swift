//
//  ThirdPartyAuthViewController.swift
//  LarkWeb
//
//  Created by Miaoqi Wang on 2020/3/15.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import LarkUIKit
import LKCommonsLogging
import LarkFoundation
import LarkAccountInterface
import LarkContainer
import Homeric
import LarkButton
import ECOProbeMeta
import LarkLocalizations

class ThirdPartyAuthViewController: AuthorizationBaseViewController, UITableViewDataSource, UITableViewDelegate {

    private let authInfo: LoginAuthInfo
    private let thirdInfo: ThirdPartyAuthInfo

    private lazy var permissions: [DisplayScope] = {
        return thirdInfo.permissionScopes.map { (scope) -> DisplayScope in
            DisplayScope(
                key: scope.key,
                text: scope.text,
                required: scope.required,
                selected: true  // 默认都选中
            )
        }
    }()

    private lazy var isAllRequired: Bool = {
        for scope in thirdInfo.permissionScopes where !scope.required {
            return false
        }
        return true
    }()

    private var agreementLabel: AgreementView?

    @Provider var userManager: UserManager

    private var trackParasm: [String: String] {
        if case .sdk = vm.info {
            return [AuthTrack.pageTypeKey: AuthTrack.sdkAuthValue]
        } else {
            return [AuthTrack.pageTypeKey: AuthTrack.authValue]
        }
    }
    override func needBackImage() -> Bool { true }
    private lazy var backgroundImageView = UIImageView()

    init?(vm: SSOBaseViewModel, authInfo: LoginAuthInfo, resolver: UserResolver?) {
        guard let thirdInfo = authInfo.thirdPartyAuthInfo else {
            return nil
        }
        
        self.authInfo = authInfo
        self.thirdInfo = thirdInfo
        super.init(vm: vm, resolver: resolver)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMainUI()
        // need set after main ui
        setupNavigation(hasTitle: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Self.logger.info("n_page_authz_start")
        PassportMonitor.flush(EPMClientPassportMonitorAuthorizationCode.page_authz_enter, context: vm.context)
        SuiteLoginTracker.track(Homeric.PASSPORT_THIRD_PARTY_AUTH_VIEW, params: trackParasm)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Self.logger.info("n_page_authz_end")
        SuiteLoginTracker.track(Homeric.SSO_PAGE_DISMISS, params: trackParasm)
    }

    @objc
    func confirmButtonClick(_ sender: UIButton) {
        SuiteLoginTracker.track(Homeric.PASSPORT_THIRD_PARTY_AUTH_CLICK, params: [
            "click" : "auth"
        ])

        let sender = sender
        sender.isEnabled = false
        ThirdPartyAuthViewController.logger.info("sso auth start")
        let scope = permissions.filter { (scope) -> Bool in
            scope.required || scope.selected
        }.reduce("") { (result, scope) -> String in
            return "\(result) \(scope.key)"
        }.dropFirst()
        confirmToken(scope: String(scope), isMultiLogin: false, success: {}) {
            sender.isEnabled = true
        }
    }

    override func closeBtnClick() {
        Self.logger.info("n_page_authz_back")
        SuiteLoginTracker.track(Homeric.SSO_CLOSE_BTN_CLICK, params: trackParasm)
        super.closeBtnClick()
    }

    // MARK: - TableViewDataSource

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < permissions.count else {
            return UITableViewCell()
        }
        if let cell = tableView.dequeueReusableCell(withIdentifier: PermissionTableViewCell.lu.reuseIdentifier, for: indexPath) as? PermissionTableViewCell {
            cell.setCell(scope: permissions[indexPath.row], needCheck: !isAllRequired)
            return cell
        } else {
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return permissions.count
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !isAllRequired {
            permissions[indexPath.row].selected = !permissions[indexPath.row].selected
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
}

extension ThirdPartyAuthViewController {

    private var agreementPlainString: String {
        return I18N.Lark_Passport_ThirdPartyAppAuthorization_AuthRequestPage_TermsAndPolicyCheckbox_Text(I18N.Lark_Passport_ThirdPartyAppAuthorization_AuthRequestPage_TermsAndPolicyCheckbox_UsePolicy, I18N.Lark_Passport_ThirdPartyAppAuthorization_AuthRequestPage_TermsAndPolicyCheckbox_PrivacyPolicy)
    }

    func getAgreementLinks() -> [(String, URL)]? {

        let languageMapping: [LarkLocalizations.Lang : () -> I18nAgreementInfo?] = [
            .zh_CN: { self.thirdInfo.i18nAgreement?.zhCN },
            .ja_JP: { self.thirdInfo.i18nAgreement?.jaJP },
            .en_US: { self.thirdInfo.i18nAgreement?.enUS }
        ]

        //在非中英日的语言环境下，默认显示英文的协议链接
        if let agreementInfo = languageMapping[LanguageManager.currentLanguage]?() ?? thirdInfo.i18nAgreement?.enUS,
           let clauseUrl = URL(string: agreementInfo.clauseUrl),
           let privacyPolicyUrl = URL(string: agreementInfo.privacyPolicyUrl) {
            return [
                (I18N.Lark_Passport_ThirdPartyAppAuthorization_AuthRequestPage_TermsAndPolicyCheckbox_UsePolicy, clauseUrl),
                (I18N.Lark_Passport_ThirdPartyAppAuthorization_AuthRequestPage_TermsAndPolicyCheckbox_PrivacyPolicy, privacyPolicyUrl)
            ]
        }
        Self.logger.error("i18nAgreement not valid: \(String(describing: thirdInfo.i18nAgreement))")
        return nil
    }

    func setupMainUI() {

        // part 1: header view

        let headerView = makeHeaderView()
        view.addSubview(headerView)
        headerView.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.width.equalTo(headerView.snp.height).multipliedBy(Layout.Header.radio)
        }

        let tenantView = AuthTenantView()
        view.addSubview(tenantView)

        tenantView.snp.makeConstraints { (make) in
            make.top.equalTo(headerView.snp.bottom).offset(Layout.tenantViewTop)
            make.left.right.equalToSuperview().inset(CL.itemSpace)
        }

        // part 2: permission view

        let permissionLabel = UILabel()
        permissionLabel.text = thirdInfo.scopeTitle
        permissionLabel.font = Layout.PermissionLabel.font
        permissionLabel.numberOfLines = 3
        permissionLabel.textColor = Layout.PermissionLabel.titleColor
        view.addSubview(permissionLabel)

        let permissionTable = UITableView()
        permissionTable.separatorStyle = .none
        permissionTable.rowHeight = Layout.tableRowHeight
        permissionTable.backgroundColor = .clear
        permissionTable.dataSource = self
        permissionTable.delegate = self
        permissionTable.lu.register(cellSelf: PermissionTableViewCell.self)
        view.addSubview(permissionTable)

        permissionLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(permissionTable)
            make.top.equalTo(tenantView.snp.bottom).offset(Layout.PermissionLabel.top)
            make.height.lessThanOrEqualTo(40)
        }

        permissionTable.snp.makeConstraints { (make) in
            make.top.equalTo(permissionLabel.snp.bottom).offset(Layout.PermissionLabel.bottom)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview().inset(CL.itemSpace)
            let requiredHeight = CGFloat(permissionTable.numberOfRows(inSection: 0)) * Layout.tableRowHeight
            make.height.equalTo(requiredHeight > 200 ? 200 : requiredHeight)
        }

        // part 3: Agreement view
        if let alertAgreementLinks = getAgreementLinks() {
            let agreementLabel: AgreementView = AgreementView(
                needCheckBox: false,
                plainString: agreementPlainString,
                links: alertAgreementLinks,
                checkAction: { (_) in
                }) { [weak self](url, _, _) in
                    guard let self = self else {return}
                    vm.clickLink(vc: self, url: url)
            }
            agreementLabel.updateContent(plainString: agreementPlainString, links: alertAgreementLinks, color: UIColor.ud.textTitle)
            view.addSubview(agreementLabel)
            agreementLabel.snp.makeConstraints { (make) in
                make.left.right.equalTo(permissionTable)
                make.top.equalTo(permissionTable.snp.bottom).offset(BaseLayout.itemSpace)
            }
            self.agreementLabel = agreementLabel
        }

        // part 4: confirm button
        // 三方登录使用外层的 button 数据，SSO 登录只有 thirdPartyAuthInfo，从里面拿 buttonTitle
        var buttonTitle = authInfo.buttonList?.first { $0.actionType == .qrAuthz }?.text
        if buttonTitle == nil {
            buttonTitle = authInfo.thirdPartyAuthInfo?.buttonTitle
        }
        let confirmBtn = TypeButton(style: .largeA)
        confirmBtn.setTitle(buttonTitle, for: .normal)
        confirmBtn.addTarget(self, action: #selector(confirmButtonClick(_:)), for: .touchUpInside)
        confirmBtn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        view.addSubview(confirmBtn)

        if let agreementLabel  = agreementLabel {
            confirmBtn.snp.makeConstraints { (make) in
                make.right.left.equalTo(agreementLabel)
                make.height.equalTo(Layout.btnHeight)
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(Layout.confirmBtnBottom)
            }
        } else {
            confirmBtn.snp.makeConstraints { (make) in
                make.right.left.equalTo(permissionTable)
                make.height.equalTo(Layout.btnHeight)
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(Layout.confirmBtnBottom)
            }
        }

        let user = userManager.getUser(userID: userResolver.userID) ?? UserManager.placeholderUser
        tenantView.set(
            title: thirdInfo.identityTitle,
            imageUrl: user.user.tenant.iconURL,
            tenant: user.user.tenant.getCurrentLocalName(),
            name: user.user.getCurrentLocalDisplayName()
        )
    }

    func makeHeaderView() -> UIView {
        let headerView = UIView()

        let appIconView = UIImageView()
        appIconView.layer.cornerRadius = Common.Layer.commonAppIconRadius
        appIconView.clipsToBounds = true

        if !thirdInfo.appIconUrl.isEmpty, let url = URL(string: thirdInfo.appIconUrl) {
            appIconView.kf.setImage(with: url, placeholder: DynamicResource.default_avatar)
        } else {
            appIconView.image = DynamicResource.default_avatar
        }
        headerView.addSubview(appIconView)
        let connectorView = UIImageView(image: SSOVerifyResources.app_connector.ud.withTintColor(UIColor.ud.iconN3))
        headerView.addSubview(connectorView)

        let larkIconView = UIImageView(image: BundleResources.AppResourceLogo.logo)
        larkIconView.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        larkIconView.layer.cornerRadius = Common.Layer.commonAppIconRadius
        larkIconView.clipsToBounds = true
        headerView.addSubview(larkIconView)

        let titleLabel = UILabel()
        titleLabel.text = "\(thirdInfo.appName) \(thirdInfo.subtitle)"
        titleLabel.font = Layout.Header.titleFont
        titleLabel.numberOfLines = 3
        titleLabel.textColor = Layout.Header.titleColor
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        headerView.addSubview(titleLabel)

        appIconView.snp.makeConstraints { (make) in
            make.top.greaterThanOrEqualToSuperview()
                .offset(UIApplication.shared.statusBarFrame.height) // 避免文字太长 视图越界
            make.left.greaterThanOrEqualToSuperview()
            make.centerY.equalTo(connectorView)
            make.size.equalTo(Layout.Header.iconSize)
        }

        connectorView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.left.equalTo(appIconView.snp.right).offset(Layout.Header.connectorSpace)
            make.size.equalTo(Layout.Header.connectorSize)
        }

        larkIconView.snp.makeConstraints { (make) in
            make.left.equalTo(connectorView.snp.right).offset(Layout.Header.connectorSpace)
            make.centerY.equalTo(connectorView)
            make.right.lessThanOrEqualToSuperview()
            make.size.equalTo(Layout.Header.iconSize)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.left.greaterThanOrEqualToSuperview().offset(CL.itemSpace)
            make.right.lessThanOrEqualToSuperview().inset(CL.itemSpace)
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.top.equalTo(appIconView.snp.bottom).offset(Layout.Header.titleTop)
        }

        return headerView
    }
}

private enum Layout {
    static let confirmBtnBottom: CGFloat = 20.0
    static let tableRowHeight: CGFloat = 34.0
    static let tenantViewTop: CGFloat = 40
    static let btnHeight: CGFloat = 48
    static let visualNaviBarHeight: CGFloat = 44

    enum Header {
        static let titleFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
        static let titleColor = UIColor.ud.textTitle
        static let radio: CGFloat = Display.pad ? 375 / 130 : 375 / 212
        static let iconSize = CGSize(width: 48, height: 48)
        static let connectorSpace: CGFloat = 26
        static let connectorSize = CGSize(width: 14, height: 14)
        static let titleTop: CGFloat = 24
    }

    enum SpaceView {
        static let leftRightRatio: CGFloat = Display.pad ? 1 : 34 / 26
        static let height: CGFloat = 1.0
    }

    enum PermissionLabel {
        static let font = UIFont.systemFont(ofSize: 14.0)
        static let titleColor = UIColor.ud.textCaption
        static let top: CGFloat = 40.0
        static let bottom: CGFloat = 12.0
    }
}
