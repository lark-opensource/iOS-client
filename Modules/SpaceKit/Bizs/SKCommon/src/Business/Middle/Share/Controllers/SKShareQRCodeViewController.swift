import ByteWebImage
import LarkCompatible
import LarkContainer
import LarkExtensions
import LarkSensitivityControl
import LarkUIKit
import QRCode
import SKFoundation
import SKResource
import SKUIKit
import SnapKit
import UIKit
import UniverseDesignButton
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignToast

/// 收集表二维码数据
public struct SKShareQrCodeFormsStyleInfo {
    
    /// 封面 URL
    public let bannerUrl: String
}

/// 二维码风格
public enum SKShareQrCodeViewStyle {
    ///收集表样式
    case forms(info: SKShareQrCodeFormsStyleInfo)
    ///单一卡片样式
    case singleCardRecord
    /// 老表单
    case oldForm
    
    func scanLabelTitle() -> String {
        switch self {
        case .forms, .oldForm:
                return BundleI18n.SKResource.Bitable_NewSurvey_Settings_ScanViaMobile_Desc
            case .singleCardRecord:
                return BundleI18n.SKResource.Bitable_ShareSingleRecord_Sharing_ScanCode_Desc()
        }
    }
    
    func saveButtonTitle() -> String {
        switch self {
        case .forms, .oldForm:
                return BundleI18n.SKResource.Bitable_NewSurvey_Mobile_SaveToAlbums_Button
            case .singleCardRecord:
                return BundleI18n.SKResource.Bitable_ShareSingleRecord_Sharing_SaveToAlbums_Button
        }
    }
}

public protocol SKShareQrCodeConfigProtocol {
    ///标题
    var shareTtile: String { get set }
    ///二维码分享链接
    var shareQrStr: String {get set}
    ///二维码样式
    var style: SKShareQrCodeViewStyle {get set}
}

//MARK: 二维码展示Controller,只支持Light模式
class SKShareQrCodeViewController: UIViewController {
    ///数据
    private var qrConfig: SKShareQrCodeConfigProtocol
    let saveClick: () -> Void
    var backClick: (() -> Void)?
    
    ///子View
    lazy var screenshotView: UIView = UIView()
    var screenShotViewTopOffset: CGFloat {
        var defaultValue = 75.0
        if Display.pad {
            defaultValue = UIApplication.shared.statusBarOrientation.isLandscape ? 100.0 : 150.0
        }
        return defaultValue
    }
    
    lazy var qrCodeView = SKShareQrCodeView(qrConfig: self.qrConfig)
    lazy var supportView = SKShareQrCodeSupportView.init()
    lazy var saveButton: UDButton = {
        var config = UDButtonUIConifg.primaryBlue
        config.type = .big
        var button = UDButton(config)
        button.setTitle(qrConfig.style.saveButtonTitle(), for: .normal)
        var icon = UDIcon.getIconByKey(
            .downloadOutlined,
            iconColor: .white,
            size: CGSize(width: 20, height: 20)
        )
        button.setImage(icon, for: .normal)
        button.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return button
    }()
    
    weak var gradientLayer: CAGradientLayer?
    
    init(qrConfig: SKShareQrCodeConfigProtocol, saveClick: @escaping () -> Void) {
        self.qrConfig = qrConfig
        self.saveClick = saveClick
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            view.overrideUserInterfaceStyle = .light
        }
        gradientLayer = view.setChangedColor(
            startColor: UIColor(red: 0.976, green: 0.984, blue: 0.996, alpha: 1),
            endColor: UIColor(red: 0.878, green: 0.961, blue: 0.996, alpha: 1)
        )
        setupNavigationBar()
        setupChildViews()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        remakeScreenshotViewConstraints()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer?.frame = view.bounds
    }
    
    private func setupNavigationBar() {
        let icon = UDIcon.getIconByKey(
            .leftOutlined,
            iconColor: UDColor.N800.alwaysLight,
            size: CGSize(width: 24, height: 24)
        )
        let item = UIBarButtonItem(
            image: icon,
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        item.tintColor = UDColor.N800.alwaysLight
        navigationItem.leftBarButtonItem = item
    }
    
    private func remakeScreenshotViewConstraints() {
        if UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable, case .singleCardRecord = qrConfig.style {
            screenshotView.snp.remakeConstraints { make in
                make.centerY.equalToSuperview().offset(-100)
                make.centerX.equalToSuperview()
            }
        } else {
            screenshotView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(screenShotViewTopOffset)
                make.centerX.equalToSuperview()
            }
        }
    }
    
    private func setupChildViews() {
        view.addSubview(screenshotView)
        view.addSubview(saveButton)
        
        screenshotView.addSubview(qrCodeView)
        screenshotView.addSubview(supportView)
        
        remakeScreenshotViewConstraints()
        
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(self.screenshotView.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
            make.width.equalTo(Display.width <= 375 ? 320 : 342)
            make.height.equalTo(48)
        }
        qrCodeView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(30)
            make.width.equalTo(Display.width <= 375 ? 320 : 342)
            make.left.equalToSuperview().offset(24)
            make.right.equalToSuperview().offset(-24)
        }
        supportView.snp.makeConstraints { make in
            make.top.equalTo(self.qrCodeView.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.height.equalTo(16)
            make.bottom.equalToSuperview().offset(-30)
        }
    }
    
    @objc func backButtonTapped() {
        backClick?()
        DocsLogger.info("back button tapped and will dismiss")
        navigationController?.dismiss(animated: true)
    }
    
    @objc func saveTapped() {
        saveClick()
        if let image = screenshotView.lu.screenshotWithUIVisualEffectView() {
            SKAssetBrowserActionHandler.savePhoto(img: image) { [weak self] (success, granted) in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    switch (granted, success) {
                    case (false, _):
                        DocsLogger.error("SKAssetBrowserActionHandler.savePhoto error, success is false")
                        UDToast.showFailure(
                            with: BundleI18n.SKResource.Lark_Legacy_PhotoPermissionRequired,
                            on: self.view)
                    case (true, true):
                        DocsLogger.info("SKAssetBrowserActionHandler.savePhoto success, success and granted is true")
                        UDToast.showSuccess(
                            with: BundleI18n.SKResource.Lark_Legacy_QrCodeSaveToAlbum,
                            on: self.view)
                    case (true, false):
                        DocsLogger.error("SKAssetBrowserActionHandler.savePhoto error, success is true and  granted is false")
                        UDToast.showFailure(
                            with: BundleI18n.SKResource.Lark_Legacy_ChatGroupInfoQrCodeSaveFail,
                            on: self.view)
                    }
                }
            }
        } else {
            DocsLogger.error("save qr error, formsQRCodeScreenshotView.lu.screenshotWithUIVisualEffectView() is nil")
            UDToast.showFailure(
                with: BundleI18n.SKResource.Lark_Legacy_ChatGroupInfoQrCodeSaveFail,
                on: self.view)
        }
    }
}

//MARK: 带圆角的QRCodeView
class SKShareQrCodeView: UIView {
    
    private let qrConfig: SKShareQrCodeConfigProtocol
    
    private lazy var nameAndQrAndScanView = NameAndQRImageAndScanView(qrConfig: qrConfig)
    
    init(qrConfig: SKShareQrCodeConfigProtocol) {
        self.qrConfig = qrConfig
        super.init(frame: .zero)
        self.setupShadowAndCorner()
        self.setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupShadowAndCorner() {
        layer.masksToBounds = true
        layer.shadowColor = UIColor(red: 31/255.0, green: 35/255.0, blue: 41/255.0, alpha: 1)
            .cgColor
        layer.shadowRadius = 16
        layer.shadowOffset = CGSize(width: 0, height: 6)
        layer.shadowOpacity = 0.1
        layer.borderWidth = 1
        layer.borderColor = UIColor.black.withAlphaComponent(0.05)
            .cgColor
        layer.cornerRadius = 16
        clipsToBounds = false
    }
    
    private func setupViews() {
        var bannerView: UIView?
        switch qrConfig.style {
        case let .forms(info: styleInfo):
            bannerView = SKShareQrCodeBannerView(bannerUrlStr: styleInfo.bannerUrl)
        case .singleCardRecord:
            break
        case .oldForm:
            bannerView = SKShareQrCodeBannerView(bannerUrlStr: nil)
        }
        if let bannerView = bannerView {
            addSubview(bannerView)
            addSubview(nameAndQrAndScanView)
            bannerView.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.height.equalTo(200)
            }
            nameAndQrAndScanView.snp.makeConstraints { make in
                make.top.equalTo(bannerView.snp.bottom).offset(-90)
                make.left.right.bottom.equalToSuperview()
            }
        } else {
            addSubview(nameAndQrAndScanView)
            nameAndQrAndScanView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
    
}

//MARK: 头部Banner区域
class SKShareQrCodeBannerView: ByteImageView {
    private var bannerUrlStr: String?
    init(bannerUrlStr: String?) {
        self.bannerUrlStr = bannerUrlStr
        super.init(frame: .zero)
        contentMode = .scaleAspectFill
        layer.cornerRadius = 16
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        backgroundColor = UDColor.bgBody
        clipsToBounds = true
        
        if let imgUrlStr = bannerUrlStr {
            DocsLogger.info("start request qrcodeBanner by setLarkImage with url: \(imgUrlStr)")
            bt.setLarkImage(
                .default(key: imgUrlStr ),
                completion: { result in
                    switch result {
                    case .success:
                        DocsLogger.info("success request qrcodeBanner by setLarkImage with url: \(imgUrlStr)")
                    case .failure(let error):
                        DocsLogger.error("fail request qrcodeBanner by setLarkImage with url: \(imgUrlStr) code: \(error.code) userinfo: \(error.userInfo) localizedDescription: \(error.localizedDescription)", error: error)
                    }
                }
            )
        } else {
            // oldForm
            image = BundleResources.SKResource.Bitable.bitable_form_bg
            backgroundColor = UDColor.primaryContentDefault
            DocsLogger.info("no qrcode banner info")
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: 标题 Image 扫一扫 Label 组合 view
class NameAndQRImageAndScanView: UIView {
    
    private let qrConfig: SKShareQrCodeConfigProtocol
    
    lazy var nameLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 20, weight: .medium)
        view.textColor = UDColor.textTitle
        view.text = qrConfig.shareTtile
        view.textAlignment = .center
        view.numberOfLines = 2
        return view
    }()
    
    lazy var qrImageView: ByteImageView = {
        let view = ByteImageView()
        view.image = QRCodeTool.createQRImg(str: qrConfig.shareQrStr, size: 140)
        return view
    }()
    
    lazy var scanLabel: UILabel = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 12)
        view.textColor = UDColor.textPlaceholder
        view.text = qrConfig.style.scanLabelTitle()
        return view
    }()
    
    weak var gradientLayer: CAGradientLayer?
    
    init(qrConfig: SKShareQrCodeConfigProtocol) {
        
        self.qrConfig = qrConfig
        super.init(frame: .zero)
        
        self.gradientLayer = setChangedColor(
            startColor: UIColor.white.withAlphaComponent(0.3),
            endColor: UIColor.white
        )
        
        let blurEffect = UIBlurEffect(style: .extraLight)
        let blurView = UIVisualEffectView(effect: blurEffect)
        addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        layer.cornerRadius = 16
        clipsToBounds = true
        
        blurView.contentView.addSubview(nameLabel)
        blurView.contentView.addSubview(qrImageView)
        blurView.contentView.addSubview(scanLabel)
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        qrImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.nameLabel.snp.bottom).offset(24)
            make.size.equalTo(CGSize(width: 140, height: 140))
        }
        scanLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.qrImageView.snp.bottom).offset(12)
            make.height.equalTo(16)
            make.bottom.equalToSuperview().offset(-30)
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

//MARK: 支持标签
class SKShareQrCodeSupportView: UIView {
    lazy var icon: UIImageView = {
        let view = ByteImageView()
        view.image = UDIcon.fileBitableColorful
        return view
    }()
    
    lazy var supportLabel: UIView = {
        let view = UILabel()
        view.font = .systemFont(ofSize: 12)
        view.textColor = UDColor.textPlaceholder
        view.text = BundleI18n.SKResource.Bitable_NewSurvey_PoweredByBase_Text()
        view.textAlignment = .center
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(icon)
        addSubview(supportLabel)
        
        icon.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 16, height: 16))
        }
        supportLabel.snp.makeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(4)
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: 截图拓展
public extension LarkUIKitExtension where BaseType: UIView {
    
    func screenshotWithUIVisualEffectView() -> UIImage? {
        let transform = self.base.transform
        self.base.transform = .identity
        var screenshot: UIImage?
        var renderSize = self.base.frame.size
        if renderSize.width == 0 { renderSize.width = 1 }
        if renderSize.height == 0 { renderSize.height = 1 }
        UIGraphicsBeginImageContextWithOptions(renderSize, false, UIScreen.main.scale)
        if let _ = UIGraphicsGetCurrentContext() {
            let tokenString = "LARK-PSDA-forms_qrcode_save_request_permission"
            let token = Token(tokenString)
            do {
                let success = try DeviceInfoEntry.drawHierarchy(
                    forToken: token,
                    view: self.base,
                    rect: self.base.bounds,
                    afterScreenUpdates: true
                )
                DocsLogger.info("DeviceInfoEntry.drawHierarchy, value: \(success)")
            } catch {
                DocsLogger.error("DeviceInfoEntry.drawHierarchy error", error: error)
            }
            screenshot = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()
        self.base.transform = transform
        return screenshot
    }
}

extension UIView {
    
    fileprivate func setChangedColor(startColor: UIColor, endColor: UIColor) -> CAGradientLayer {
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        
        gradientLayer.colors = [
            startColor.cgColor,
            endColor.cgColor
        ]
        
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        
        layer.addSublayer(gradientLayer)
        
        return gradientLayer
    }
    
}
