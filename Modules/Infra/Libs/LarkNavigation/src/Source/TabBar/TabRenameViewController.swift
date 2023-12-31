//
//  TabRenameViewController.swift
//  LarkNavigation
//
//  Created by phoenix on 2023/9/12.
//

import UIKit
import LarkUIKit
import RxSwift
import RxCocoa
import RustPB
import UniverseDesignDialog
import UniverseDesignInput
import UniverseDesignIcon
import UniverseDesignToast
import ByteWebImage
import AnimatedTabBar
import LarkTab
import LarkLocalizations
import LarkQuickLaunchInterface
import LarkInteraction
import LarkContainer
import LarkDocsIcon
import LarkRustClient
import LKCommonsLogging
import EENavigator
import LKCommonsTracker
import Homeric

private let kTabRenameTextFieldMaxLength = 300

public final class TabRenameViewController: BaseUIViewController, UDTextFieldDelegate, UserResolverWrapper {
    static let logger = Logger.log(TabRenameViewController.self, category: "LarkNavigation.TabRenameViewController")

    public var userResolver: LarkContainer.UserResolver

    @ScopedInjectedLazy var navigationAPI: NavigationAPI?

    private let disposeBag = DisposeBag()

    private var appInfo: RustPB.Basic_V1_NavigationAppInfo

    private var style: TabbarStyle

    private var confirmCallback: ((RustPB.Basic_V1_NavigationAppInfo, RustPB.Settings_V1_PinNavigationAppResponse) -> Void)

    private var originalName: String?

    private lazy var hud: UDToast = {
        return UDToast()
    }()

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloatBase
        return view
    }()
    
    /// 顶部导航栏容器
    private lazy var navigationBar: UIView = {
       return UIView()
    }()

    /// 标题
    private lazy var navTitleView: UIView = {
        let label = UILabel()
        label.text = BundleI18n.LarkNavigation.Lark_Core_AddToNavBar_Mobile_Title
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    /// 取消
    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTitle(BundleI18n.LarkNavigation.Lark_Legacy_Cancel, for: .normal)
        button.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        
        return button
    }()

    /// 添加
    private lazy var confirmButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(UIColor.ud.textLinkNormal, for: .normal)
        button.setTitleColor(UIColor.ud.textLinkDisabled, for: .disabled)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitle(BundleI18n.LarkNavigation.Lark_Core_More_AddApp_Button, for: .normal)
        button.addTarget(self, action: #selector(didTapConfirm), for: .touchUpInside)
        return button
    }()
    
    private let iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.layer.cornerRadius = 13.0
        view.clipsToBounds = true
        let placeHolder = UDIcon.getIconByKey(.globalLinkOutlined, iconColor: UIColor.ud.iconN3)
        view.image = placeHolder
        return view
    }()

    private lazy var titleTextField: UDTextField = {
        let config = UDTextFieldUIConfig(clearButtonMode: .always,
                                         backgroundColor:  UIColor.ud.bgFloat,
                                         textColor: UIColor.ud.textTitle,
                                         contentMargins: Cons.textFieldContentInsets)
        let textField = UDTextField(config: config)
        textField.placeholder = BundleI18n.LarkNavigation.Lark_Core_NavbarAppAction_Rename_Placeholder
        textField.delegate = self
        textField.cornerRadius = 0
        textField.backgroundColor = UIColor.ud.bgFloat
        textField.layer.cornerRadius = 8
        textField.clipsToBounds = true
        return textField
    }()

    /// 提示文字
    private lazy var hintView: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkNavigation.Lark_Core_AddToNavBar_Mobile_Desc
        label.numberOfLines = 2
        label.textColor = UIColor.ud.textPlaceholder
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .left
        return label
    }()

    public init(userResolver: UserResolver,
                appInfo: RustPB.Basic_V1_NavigationAppInfo,
                style: TabbarStyle,
                confirmCallback: @escaping ((RustPB.Basic_V1_NavigationAppInfo, RustPB.Settings_V1_PinNavigationAppResponse) -> Void)) {
        self.userResolver = userResolver
        self.appInfo = appInfo
        self.style = style
        self.confirmCallback = confirmCallback
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.ud.bgFloatBase
        setupSubViews()
        reloadData()
        let bizType = appInfo.extra[RecentRecordExtraKey.bizType] ?? ""
        let appId = appInfo.extra[RecentRecordExtraKey.appid] ?? ""
        Tracker.post(TeaEvent(Homeric.NAVIGATION_ADD_APP_DETAIL_VIEW, params: ["biz_type": bizType, "op_app_id": appId]))
    }

    private func setupSubViews() {
        view.addSubview(containerView)
        containerView.addSubview(navigationBar)
        containerView.addSubview(iconView)
        containerView.addSubview(titleTextField)
        containerView.addSubview(hintView)

        navigationBar.addSubview(cancelButton)
        navigationBar.addSubview(confirmButton)
        navigationBar.addSubview(navTitleView)

        containerView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }
        navigationBar.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(Cons.naviBarHeight)
        }
        navTitleView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(navigationBar.snp.width).multipliedBy(0.4)
        }
        cancelButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(Cons.hMargin)
            make.centerY.equalTo(navTitleView)
            make.height.equalTo(Cons.naviButtonHeight)
        }
        confirmButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-Cons.hMargin)
            make.centerY.equalTo(navTitleView)
            make.height.equalTo(Cons.naviButtonHeight)
        }
        iconView.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom).offset(Cons.vPadding)
            make.centerX.equalToSuperview()
            make.width.equalTo(Cons.iconSize.width)
            make.height.equalTo(Cons.iconSize.height)
            
        }
        titleTextField.snp.makeConstraints { (make) in
            make.top.equalTo(iconView.snp.bottom).offset(Cons.vPadding)
            make.leading.equalToSuperview().offset(Cons.hMargin)
            make.right.equalToSuperview().offset(-Cons.hMargin)
            make.height.equalTo(Cons.textFieldHeight)
        }
        hintView.snp.makeConstraints { (make) in
            make.top.equalTo(titleTextField.snp.bottom).offset(Cons.vPadding)
            make.leading.equalToSuperview().offset(Cons.hMargin)
            make.right.equalToSuperview().offset(-Cons.hMargin)
        }
        
        if #available(iOS 13.4, *) {
            cancelButton.addLKInteraction(PointerInteraction(style: PointerStyle(effect: .automatic)))
            confirmButton.addLKInteraction(PointerInteraction(style: PointerStyle(effect: .automatic)))
        }
    }
    
    private func reloadData() {
        // 应用的名字
        let lang = LanguageManager.currentLanguage.rawValue.lowercased()
        let name = appInfo.name[lang] ?? (appInfo.name["en_us"] ?? "")
        titleTextField.text = name
        originalName = name
        // 应用的图标
        let icon = appInfo.logo.customNavigationAppLogo.toCustomTabIcon()
        self.loadImage(tabIcon: icon) { [weak self] (img) in
            guard let self = self else { return }
            self.iconView.image = img
        }
    }
    
    private func dismiss() {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    @objc
    private func didTapCancel() {
        self.dismiss()
    }

    @objc
    private func didTapConfirm() {
        let currentText = titleTextField.text ?? ""
        let is_rename = currentText == originalName ? "0" : "1"
        let bizType = appInfo.extra[RecentRecordExtraKey.bizType] ?? ""
        let appId = appInfo.extra[RecentRecordExtraKey.appid] ?? ""
        Tracker.post(TeaEvent(Homeric.NAVIGATION_ADD_APP_DETAIL_CLICK, params: ["click": "add_to_navigation", "biz_type": bizType, "op_app_id": appId, "is_rename": is_rename]))
        let trimmedText = currentText.trimmingCharacters(in: .whitespaces)
        let lang = LanguageManager.currentLanguage.rawValue.lowercased()
        appInfo.name[lang] = trimmedText
        appInfo.extra[RecentRecordExtraKey.displayName] = trimmedText
        pinApp(appInfo, style: style)
    }

    // MARK: UDTextFieldDelegate
    @objc
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else {
            return false
        }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        let trimmedText = updatedText.trimmingCharacters(in: .whitespaces)
        self.confirmButton.isEnabled = !trimmedText.isEmpty
        let ok = updatedText.count <= kTabRenameTextFieldMaxLength
        if ok {
            self.titleTextField.setStatus(.normal)
        } else {
            self.titleTextField.setStatus(.error)
        }
        return ok
    }

    @objc
    public func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.confirmButton.isEnabled = false
        return true
    }
}

extension TabRenameViewController {
    enum Cons {
        static var naviBarHeight: CGFloat { 56 }
        static var naviButtonHeight: CGFloat { 32 }
        static var textFieldHeight: CGFloat { 48 }
        static var textFieldContentInsets: UIEdgeInsets { UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12) }
        static var iconSize: CGSize { CGSize(width: 56, height: 56) }
        static var hMargin: CGFloat { 16 }
        static var vMargin: CGFloat { 12 }
        static var vPadding: CGFloat { 36 }
    }

    // 根据图标类型加载图片
    func loadImage(tabIcon: TabCandidate.TabIcon, success: @escaping (UIImage) -> Void) {
        let placeHolder = UDIcon.getIconByKey(.globalLinkOutlined, iconColor: UIColor.ud.iconN3)
        switch tabIcon.type {
        case .iconInfo:
            // 如果是ccm iconInfo图标
            if let docsService = try? userResolver.resolve(assert: DocsIconManager.self) {
                let url = appInfo.extra[RecentRecordExtraKey.url] ?? ""
                docsService.getDocsIconImageAsync(iconInfo: tabIcon.content, url: url, shape: .SQUARE)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { (image) in
                        success(image)
                    }, onError: { error in
                        Self.logger.error("<NAVIGATION_BAR> get docs icon image error", error: error)
                    }).disposed(by: self.disposeBag)
            } else {
                Self.logger.error("<NAVIGATION_BAR> can't resolver DocsIconManager")
            }
        case .udToken:
            // 如果是UD图片
            let image = UDIcon.getIconByString(tabIcon.content) ?? placeHolder
            success(image)
        case .byteKey, .webURL:
            // 如果是ByteImage或者网络图片
            var resource: LarkImageResource
            if tabIcon.type == .byteKey {
                let (key, entityId) = tabIcon.parseKeyAndEntityID()
                resource = .avatar(key: key ?? "", entityID: entityId ?? "")
            } else {
                resource = .default(key: tabIcon.content)
            }
            // 获取图片资源
            LarkImageService.shared.setImage(with: resource, completion:  { (imageResult) in
                var image = placeHolder
                switch imageResult {
                case .success(let r):
                    if let img = r.image {
                        image = img
                    } else {
                        Self.logger.error("<NAVIGATION_BAR> LarkImageService get image result is nil!!! tabIcon content = \(tabIcon.content)")
                    }
                case .failure(let error):
                    Self.logger.error("<NAVIGATION_BAR> LarkImageService get image failed!!! tabIcon content = \(tabIcon.content), error = \(error)")
                    break
                }
                success(image)
            })
        @unknown default:
            break
        }
    }

    // 把应用pin到主导航
    func pinApp(_ appInfo: RustPB.Basic_V1_NavigationAppInfo, style: TabbarStyle) {
        guard let navigationAPI = self.navigationAPI, let id = appInfo.extra[RecentRecordExtraKey.appid] else {
            Self.logger.error("<NAVIGATION_BAR> pin app but appId == nil")
            return
        }
        if let topView = navigator.mainSceneWindow {
            self.hud.showLoading(with: BundleI18n.LarkNavigation.Lark_Legacy_BaseUiLoading, on: topView, disableUserInteraction: true)
        }
        // 向服务端发pin请求
        Self.logger.info("<NAVIGATION_BAR> begin to pin appId: \(id) to quick launch window")
        navigationAPI.pinAppToNavigation(appInfo: appInfo, style: style)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (resp) in
                Self.logger.info("<NAVIGATION_BAR> pin appId: \(id) to quick launch window success! name: \(appInfo.name) extra: \(appInfo.extra)")
                guard let self = self else { return }
                self.hud.remove()
                self.confirmCallback(appInfo, resp)
                self.dismiss()
            }, onError: { [weak self] (error) in
                Self.logger.error("<NAVIGATION_BAR> pin appId: \(id) to quick launch window failed! name: \(appInfo.name) extra: \(appInfo.extra) error: \(error)")
                guard let self = self, let topView = self.userResolver.navigator.mainSceneWindow else { return }
                self.hud.remove()
                let (_, errorMessage) = self.getNavigationErrorMessage(error: error)
                UDToast.showFailure(with: errorMessage, on: topView)
            }).disposed(by: self.disposeBag)
    }

    // 获取导航错误代码和信息
    func getNavigationErrorMessage(error: Error) -> (Int32, String) {
        var errorMessage = BundleI18n.LarkNavigation.Lark_Core_NavBarUpdateFail_Toast
        var errorCode: Int32 = 0
        if let err = error as? RCError {
            switch err {
            case .businessFailure(let errorInfo):
                errorCode = errorInfo.errorCode
                /* 导航栏[350100-350200] */
                if errorCode == 350100 {
                    // NAVIGATION_CUSTOM_APP_BEYOND_LIMIT = 350100：用户自定义应用超出了数量限制
                    errorMessage = BundleI18n.LarkNavigation.Lark_Core_NavbarUpdate_CantPinNumReached_Toast
                } else if errorCode == 350102 {
                    // NAVIGATION_UNIQUE_ID_DUPLICATE = 350102：应用ID不能重复
                    errorMessage = BundleI18n.LarkNavigation.Lark_Core_NavbarUpdate_AppExistsAlready_Toast
                } else if errorCode == 350107 {
                    // NNAVIGATION_REQ_VERSION_NOT_LATEST = 350107：传参数导航栏version不是最新的
                    errorMessage = BundleI18n.LarkNavigation.Lark_Core_NavBarUpdateFailRefresh_Toast
                }
            default:
                errorMessage = BundleI18n.LarkNavigation.Lark_Core_NavBarUpdateFail_Toast
            }
        }
        return (errorCode, errorMessage)
    }
}

