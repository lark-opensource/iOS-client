//
//  MailSettingSigWebCell.swift
//  MailSDK
//
//  Created by tanghaojin on 2021/10/11.
//

import Foundation
import LarkTag
import WebKit
import UniverseDesignIcon
import LarkFoundation
import LarkStorage

struct MailSettingSigWebModel {
    var title: String?
    var html: String = ""
    var htmlJson: String = ""
    var sigId: String = ""
    var cellHeight: CGFloat = 0.0
    var sigType: Int = 0 // 0: personal, 1: company
    var sigDevice: Int = 0 // 0: pc, 1:mobile
    var canUse: Bool = true
    var forceUse: Bool = false

    init() {}

    init(_ signature: MailSignature, _ canUse: Bool, _ forceUse: Bool, cacheService: MailCacheService) {
        self.title = signature.name
        self.cellHeight = 80
        self.sigId = signature.id
        self.sigType = signature.signatureType.rawValue
        self.sigDevice = signature.signatureDevice.rawValue
        self.html = signature.templateHtml
        self.htmlJson = signature.templateValueJson

        signature.images.forEach { (image) in
            if !image.cid.isEmpty && !image.fileToken.isEmpty {
                let value = ["imageName": image.imageName, "fileToken": image.fileToken]
                cacheService.set(object: value as NSCoding, for: image.cid)
            }
        }
        self.canUse = canUse
        self.forceUse = forceUse
    }
}

protocol MailSettingSigWebCellDelegate: AnyObject {
    func updateCellHeight(model: MailSettingSigWebModel)
    func clickWebView(model: MailSettingSigWebModel)
    func deleteSign(model: MailSettingSigWebModel)
}

class MailSettingSigWebCell: UITableViewCell {
    static let identifier = "MailSettingSigWebCell"
    private var model: MailSettingSigWebModel
    private var accountId: String
    private var accountContext: MailAccountContext
    weak var delegate: MailSettingSigWebCellDelegate?
    private lazy var weakSelf: WeakWKScriptMessageHandler = {
        return WeakWKScriptMessageHandler(self)
    }()
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(model: MailSettingSigWebModel, vcWidth: CGFloat, accountId: String, accountContext: MailAccountContext) {
        self.model = model
        self.accountId = accountId
        self.accountContext = accountContext
        super.init(style: .default, reuseIdentifier: MailSettingSigWebCell.identifier + model.sigId)
        self.selectionStyle = .none
        setupViews()
        configModel(model: model, forceLoad: true, vcWidth: vcWidth)
    }

    func mailClient() -> Bool {
        if let account = Store.settingData.getCachedAccountList()?.first(where: { $0.mailAccountID == accountId }) {
            return account.mailSetting.userType == .tripartiteClient
        }
        return false
    }

    func setupViews() {
        let mailClient = mailClient()
        self.layer.cornerRadius = 12
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
        self.clipsToBounds = true
        contentView.addSubview(titleView)
        contentView.addSubview(webViewContainer)
        webViewContainer.addSubview(webView)
        titleView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(6)
            make.right.equalToSuperview().offset(mailClient ? -88 : -16)
            make.height.equalTo(35)
        }
        webViewContainer.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(titleView.snp.bottom).offset(2)
            make.bottom.equalToSuperview().offset(-16)
        }
        webView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
            make.right.equalToSuperview().offset(-12)
        }
        if mailClient {
            contentView.addSubview(editButton)
            contentView.addSubview(deleteButton)
            deleteButton.snp.makeConstraints { (make) in
                make.centerY.equalTo(titleView)
                make.right.equalToSuperview().offset(-4)
                make.size.equalTo(CGSize(width: 42, height: 42))
            }
            editButton.snp.makeConstraints { (make) in
                make.centerY.equalTo(titleView)
                make.right.equalTo(deleteButton.snp.left)
                make.size.equalTo(CGSize(width: 30, height: 30))
            }
        }
        contentView.backgroundColor = UIColor.ud.bgFloat
    }

    @objc
    func editButtonClicked() {
        delegate?.clickWebView(model: model)
    }

    @objc
    func deleteButtonClicked() {
        delegate?.deleteSign(model: model)
    }

    func configModel(model: MailSettingSigWebModel, forceLoad: Bool, vcWidth: CGFloat) {
        var tag: String? = nil
        if model.sigType != 0 {
            tag = BundleI18n.MailSDK.Mail_BusinessSignature_Business
        }
//        self.titleView.configView(title: model.title ?? "", tagTitle: tag, needLock: model.forceUse, totalWidth: vcWidth - safeAreaInsets.left - safeAreaInsets.right - 104) // 42 + 30 + 16 + 16
        self.titleView.configView(title: model.title ?? "", tagTitle: tag, needLock: model.forceUse,
                                  totalWidth: vcWidth - 32)// vcWidth - safeAreaInsets.left - safeAreaInsets.right)
        self.titleLabel.text = model.title ?? ""
        if model.canUse {
            self.contentView.alpha = 1
        } else {
            self.contentView.alpha = 0.4
        }
        if forceLoad || self.model.sigId != model.sigId {
            self.webView.loadHTMLString(model.html, baseURL: nil)
        }
        titleView.snp.updateConstraints { make in
            make.height.equalTo(self.titleView.getSigTitleHeight())
        }
        self.model = model

    }

    func getSigId() -> String {
        return model.sigId
    }

    lazy var titleView: MailSigTitleView = {
        let titleView = MailSigTitleView()
        titleView.backgroundColor = UIColor.ud.bgFloat
        return titleView
    }()

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        return titleLabel
    }()

    lazy var editButton: UIButton = {
        let editButton = UIButton()
        editButton.setImage(UDIcon.editOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        editButton.tintColor = UIColor.ud.iconN2
        editButton.addTarget(self, action: #selector(editButtonClicked), for: .touchUpInside)
        editButton.imageEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        return editButton
    }()

    lazy var deleteButton: UIButton = {
        let deleteButton = UIButton()
        deleteButton.setImage(UDIcon.deleteTrashOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        deleteButton.tintColor = UIColor.ud.iconN2
        deleteButton.addTarget(self, action: #selector(deleteButtonClicked), for: .touchUpInside)
        deleteButton.imageEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return deleteButton
    }()

    lazy var webViewContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        if FeatureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)) {
            view.backgroundColor = UIColor.ud.bgFloat
        } else {
            view.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        }
        view.layer.borderColor = UIColor.ud.lineBorderCard.cgColor
        view.layer.borderWidth = 1.0
        return view
    }()
    
    func setDarkModeIfNeeded() {
        guard FeatureManager.open(FeatureKey(fgKey: .darkMode, openInMailClient: true)) else { return }
        if #available(iOS 13.0, *) {
            let isDarkMode = self.traitCollection.userInterfaceStyle == .dark
            if isDarkMode {
                self.webView.evaluateJavaScript("makeDarkMode()")
            } else {
                self.webView.evaluateJavaScript("makeLightMode()")
            }
            webViewContainer.layer.borderColor = UIColor.ud.lineBorderCard.cgColor
        }
    }
    
    func getDarkSDKScript() -> String? {
        let darkSDKScriptName = "dark_mode_sdk.min.js"
        var filePath = I18n.resourceBundle.bundlePath + "/\(darkSDKScriptName)"
        #if DEBUG
        let kvStore = MailKVStore(space: .global, mSpace: .global)
        let loadLocalTemplate = kvStore.value(forKey: MailDebugViewController.kMailLoadLocalTemplate) ?? false
        if LarkFoundation.Utils.isSimulator && loadLocalTemplate {
            // 需要手动填写rootPath
            let prjRootPath = String(cString:"")
            let templateRelativeDir = prjRootPath.contains("mail-ios-client/MailDemo")
                ? "../Modules/Mail/MailSDK/Resources/mail-native-template/template" :
                "../Modules/Mail/MailSDK/Resources/mail-native-template/template"
            filePath = prjRootPath + templateRelativeDir + "/\(darkSDKScriptName)"
            print("darkSDKScriptName filePath \(filePath ?? "")")
        }
        #endif
        do {
            return try String.read(from: AbsPath(filePath))
        } catch {
            return nil
        }
    }
    
    lazy var webView: MailNewBaseWebView = {
        let wkUController = WKUserContentController()
        let script = MailSignaturePreviewScript.mobileScalable
        + MailSignaturePreviewScript.newSigCloseEditableAndAddClick
        + MailSignaturePreviewScript.interpolateSignatureTemplate
        + MailSignaturePreviewScript.darkModeJS
        + MailSignaturePreviewScript.interpolateLarkCircularFont

        let wkUScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        wkUController.addUserScript(wkUScript)
        
        if let DMSource = getDarkSDKScript() {
            let DMScript = WKUserScript(source: DMSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            wkUController.addUserScript(DMScript)
        }
        
        let wkWebConfig = WKWebViewConfiguration()
        wkWebConfig.userContentController = wkUController
        wkWebConfig.userContentController.add(weakSelf, name: "invoke")
        let webView = MailWebViewSchemeManager.makeDefaultNewWebView(config: wkWebConfig, provider: accountContext)
        webView.loadHTMLString("", baseURL: nil)
        webView.scrollView.showsHorizontalScrollIndicator = true
        webView.scrollView.bounces = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.navigationDelegate = self
        webView.scrollView.isDirectionalLockEnabled = true
        webView.isSaasSig = !self.mailClient()
        return webView
    }()
}

extension MailSettingSigWebCell: WKNavigationDelegate, WKScriptMessageHandler {
    // MARK: - WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let script = MailSignaturePreviewScript.getContentHeight
        let replaceScript = "replaceJsonDic(`\(self.model.htmlJson)`)"
        initFontStyle()
        webView.evaluateJavaScript(replaceScript) { [weak self] (_, _) in
            guard let `self` = self else { return }
            webView.evaluateJavaScript(script) { [weak self](value, error) in
                guard let `self` = self else { return }
                var webContentHeight: CGFloat = 0.0
                if let strValue = value as? String,
                    let floatValue = NumberFormatter().number(from: strValue)?.floatValue {
                    webContentHeight = CGFloat(floatValue)
                } else if let floatValue = value as? CGFloat {
                    webContentHeight = floatValue
                }
                let totalHeight = webContentHeight + 6 +
                    self.titleView.getSigTitleHeight() + 6 + 16 + 24
                if abs(self.model.cellHeight - totalHeight) > 1 {
                    self.model.cellHeight = ceil(totalHeight)
                    self.delegate?.updateCellHeight(model: self.model)
                }
            }
        }
        webView.evaluateJavaScript("initDarkSDK()")
        setDarkModeIfNeeded()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        if url.absoluteString.hasPrefix("http://") || url.absoluteString.hasPrefix("https://") {
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }

    // MARK: - WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
                                      didReceive message: WKScriptMessage) {
        guard let params = message.body as? [String: Any] else { return }
        guard let method = params["method"] as? String,
            params["args"] as? [String: Any] != nil else {
                return
        }
        if method == "clickSignature" {
            delegate?.clickWebView(model: model)
        }
    }

    private func initFontStyle() {
        let (fontNormalBase64, fontBoldBase64) = getLarkCircularFontBase64String()
        if !fontNormalBase64.isEmpty && !fontBoldBase64.isEmpty {
            self.webView.evaluateJavaScript("initFontStyle(`\(fontNormalBase64)`,`\(fontBoldBase64)`)")
        } else {
            self.webView.evaluateJavaScript("document.body.style.fontFamily = \"-apple-system\"")
        }
    }
}
