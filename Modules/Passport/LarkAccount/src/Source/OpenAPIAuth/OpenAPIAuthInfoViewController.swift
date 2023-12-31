//
//  OpenAPIAuthInfoViewController.swift
//  LarkAccount
//
//  Created by au on 2023/6/7.
//

import UIKit
import LarkUIKit
import LKCommonsLogging
import UniverseDesignColor
import UniverseDesignDialog
import UniverseDesignFont
import LarkContainer

final class OpenAPIAuthInfoViewController: UIViewController {

    private static let logger = Logger.log(OpenAPIAuthInfoViewController.self, category: "LarkAccount")

    private let authInfo: OpenAPIAuthGetAuthInfo
    private let allowAction: (() -> Void)
    private let denyAction: (() -> Void)
    private let userResolver: UserResolver

    init(userResolver: UserResolver, authInfo: OpenAPIAuthGetAuthInfo, allowAction: @escaping (() -> Void), denyAction: @escaping (() -> Void)) {
        self.authInfo = authInfo
        self.allowAction = allowAction
        self.denyAction = denyAction
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.ud.bgLogin
        setupNavigation()
        setupContents()

        showCompleteScope = (authInfo.currentUser?.scopeList.count ?? 0) <= 3

        Self.logger.info("n_action_open_api_service", body: "info page view did load")
    }

    private func setupContents() {
        view.addSubview(denyButton)
        denyButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-Layout.bottomPadding)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }
        
        view.addSubview(allowButton)
        allowButton.snp.makeConstraints { make in
            make.bottom.equalTo(denyButton.snp.top).offset(-12)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(64) // 48 + 16
            make.left.right.equalToSuperview()
            make.bottom.equalTo(allowButton.snp.top).offset(-24)
        }
    }

    private func setupNavigation() {
        let closeButton = UIButton(type: .custom)
        closeButton.setImage(BundleResources.UDIconResources.closeOutlined, for: .normal)
        closeButton.addTarget(self, action: #selector(onCloseButtonTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        closeButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(8)
            make.left.equalToSuperview().offset(12)
            make.width.height.equalTo(32)
        }

        let titleLabel = UILabel()
        titleLabel.text = I18N.Lark_Login_SSO_AuthorizationTitle()
        titleLabel.textColor = UDColor.textTitle
        titleLabel.textAlignment = .center
        titleLabel.font = UDFont.title3
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.height.equalTo(24)
            make.top.equalToSuperview().offset(12)
            make.left.right.equalToSuperview().inset(64)
        }

        let separator = UIView()
        separator.backgroundColor = UDColor.lineDividerDefault
        view.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(47)
            make.height.equalTo(0.5)
        }
    }

    @objc
    private func onCloseButtonTapped() {
        Self.logger.info("n_action_open_api_service", body: "info page tap close button")
        dismiss(animated: true) { [self] in
            denyAction()
        }
    }

    @objc
    private func onAllowButtonTapped() {
        Self.logger.info("n_action_open_api_service", body: "info page tap allow button")
        dismiss(animated: true) { [self] in
            allowAction()
        }
    }

    @objc
    private func onDenyButtonTapped() {
        Self.logger.info("n_action_open_api_service", body: "info page tap deny button")
        dismiss(animated: true) { [self] in
            denyAction()
        }
    }

    private func reloadIfNeeded() {
        Self.logger.info("n_action_open_api_service", body: "info page tap reload button")
        guard (authInfo.currentUser?.scopeList.count ?? 0) > 3 else {
            Self.logger.warn("n_action_open_api_service", body: "info page reload failed, scope list count issue")
            return
        }
        guard !showCompleteScope else {
            Self.logger.warn("n_action_open_api_service", body: "info page reload failed, flag issue")
            return
        }
        showCompleteScope = true
        tableView.reloadData()
        Self.logger.info("n_action_open_api_service", body: "info page reloaded")
    }


    func clickLink(url: URL) {
        func postWeb(url: URL) {
            self.userResolver.passportEventBus.post(
                event: V3NativeStep.simpleWeb.rawValue,
                context: V3LoginContext(serverInfo: nil, additionalInfo: V3SimpleWebInfo(url: url), context: nil),
                success: {},
                error: {error in
                    V3ErrorHandler(vc: self, context: UniContextCreator.create(.authorization)).handle(error)
                }
            )
        }
        if let presentedViewController = self.presentedViewController {
            Self.logger.warn("Current VC already has presented \(presentedViewController). \(presentedViewController) will be dismissed before web post.")
            presentedViewController.dismiss(animated: true, completion: {
                postWeb(url: url)
            })
        } else {
            postWeb(url: url)
        }
    }


    // MARK: - Property

    // scope 超过 3 条，首次进入展示前 3 条和展开按钮，点击显示全部
    private var showCompleteScope = false

    lazy var tableView: UITableView = {
        let tb = UITableView(frame: .zero)
        tb.lu.register(cellSelf: OpenAPIAuthAppInfoTableViewCell.self)
        tb.lu.register(cellSelf: OpenAPIAuthUserInfoTableViewCell.self)
        tb.lu.register(cellSelf: OpenAPIAuthScopeListTableViewCell.self)
        tb.lu.register(cellSelf: OpenAPIAuthAgreementTableViewCell.self)
        tb.backgroundColor = .clear
        tb.separatorStyle = .none
        tb.dataSource = self
        tb.delegate = self
        tb.showsVerticalScrollIndicator = false
        return tb
    }()

    lazy var allowButton: NextButton = {
        let confirmButton = NextButton(title: I18N.Lark_Passport_ThirdPartyAppAuthorization_Button_Authorize, style: .roundedRectBlue)
        confirmButton.addTarget(self, action: #selector(onAllowButtonTapped), for: .touchUpInside)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        return confirmButton
    }()

    lazy var denyButton: NextButton = {
        let button = NextButton(title: I18N.Lark_Passport_ThirdPartyAppAuthorization_Button_Reject, style: .roundedRectWhiteWithGrayOutline)
        button.addTarget(self, action: #selector(onDenyButtonTapped), for: .touchUpInside)
        return button
    }()

}

extension OpenAPIAuthInfoViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OpenAPIAuthAppInfoTableViewCell.lu.reuseIdentifier, for: indexPath) as? OpenAPIAuthAppInfoTableViewCell else {
                return UITableViewCell()
            }
            cell.configCell(authInfo: authInfo)
            return cell
        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OpenAPIAuthUserInfoTableViewCell.lu.reuseIdentifier, for: indexPath) as? OpenAPIAuthUserInfoTableViewCell else {
                return UITableViewCell()
            }
            cell.configCell(authInfo: authInfo)
            return cell
        case 2:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OpenAPIAuthScopeListTableViewCell.lu.reuseIdentifier, for: indexPath) as? OpenAPIAuthScopeListTableViewCell else {
                return UITableViewCell()
            }
            cell.configCell(authInfo: authInfo, showCompleteScope: showCompleteScope) { [weak self] in
                guard let self = self else { return }
                SuiteLoginUtil.runOnMain {
                    let dialog = UDDialog()
                    dialog.setTitle(text: I18N.Lark_Legacy_Hint)
                    dialog.setContent(text: I18N.Lark_Passport_ThirdPartyAppAuthorization_AuthRequestPage_PermissionListInfoTooltip)
                    dialog.addPrimaryButton(text: BundleI18n.LarkAccount.Lark_Legacy_IKnow)
                    self.present(dialog, animated: true)
                }
            } showMoreButtonAction: { [weak self] in
                SuiteLoginUtil.runOnMain {
                    guard let self = self else { return }
                    self.reloadIfNeeded()
                }
            }
            return cell
        case 3:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OpenAPIAuthAgreementTableViewCell.lu.reuseIdentifier, for: indexPath) as? OpenAPIAuthAgreementTableViewCell else {
                return UITableViewCell()
            }
            cell.configCell(authInfo: authInfo, vc: self)
            return cell
        default:
            assertionFailure("incorrect row")
            return UITableViewCell()
        }
    }

    struct Layout {
        static let userInfoHeight: CGFloat = 144
        static var bottomPadding: CGFloat { Display.pad ? 16 : 8 }
        static var homeIndicatorHeight: CGFloat { Display.pad ? 0 : 32 }
    }
}

extension OpenAPIAuthInfoViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return Self.calculateAppInfoCellHeight(authInfo: authInfo)
        case 1:
            return Layout.userInfoHeight
        case 2:
            return Self.calculateScopeListCellHeight(authInfo: authInfo, showCompleteScope: showCompleteScope)
        case 3:
            return (authInfo.i18nAgreement != nil) ? 85 : 0
        default:
            assertionFailure("incorrect row")
            return 0
        }
    }
}

extension OpenAPIAuthInfoViewController {
    static func calculateScopeListCellHeight(authInfo: OpenAPIAuthGetAuthInfo, showCompleteScope: Bool) -> CGFloat {
        let scopeCount = authInfo.currentUser?.scopeList.count ?? 0
        let height: CGFloat
        let width = UIScreen.main.bounds.width - 32
        // "授权后应用将获得以下权限 + icon"文本高度
        let title = I18N.Lark_Passport_AuthorizedAppDesc + String(repeating: " ", count: 4)
        let titleHeight = max(20, title.height(withConstrainedWidth: width, font: UDFont.systemFont(ofSize: 14)))
        if (scopeCount > 3 && showCompleteScope) || (scopeCount <= 3) {
            // 大于 3 并全部展开，或小于等于 3 条，以数量计算
            height = 24 + titleHeight + (27 + 12) * CGFloat(scopeCount) + 8
        } else {
            // 折叠时，显示 3 条和按钮高度
            height = 24 + titleHeight + (27 + 12) * 4 + 8
        }
        return height
    }

    static func calculateAppInfoCellHeight(authInfo: OpenAPIAuthGetAuthInfo) -> CGFloat {
        // 顶部 app icon: 88
        let width = UIScreen.main.bounds.width - 32
        let title = I18N.Lark_Passport_ThirdPartyAppAuthorization_AuthRequestPage_Title(authInfo.appInfo?.appName ?? "")
        let titleHeight = title.height(withConstrainedWidth: width, attributes: [.font: UDFont.title3])
        return titleHeight + 88
    }

    static func calculateAuthSheetHeight(authInfo: OpenAPIAuthGetAuthInfo) -> CGFloat {
        // navigation bar: 48
        // 16 + scope list(table view) + 16
        // buttons: 124
        let appInfoHeight = Self.calculateAppInfoCellHeight(authInfo: authInfo)
        let scopeListHeight = Self.calculateScopeListCellHeight(authInfo: authInfo, showCompleteScope: false)
        let height = 53 + 16 + appInfoHeight + Layout.userInfoHeight + scopeListHeight + ((authInfo.i18nAgreement != nil) ? 100 : 0) + 124 + Layout.bottomPadding + Layout.homeIndicatorHeight
        return height
    }

}
