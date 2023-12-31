//
//  LongPicViewController.swift
//  SpaceKit
//
//  Created by bytedance on 2018/10/18.
//swiftlint:disable file_length

import UIKit
import WebKit
import SnapKit
import Photos
import UniverseDesignToast
import SKCommon
import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import SpaceInterface
import SKInfra
import LarkSensitivityControl
import LarkContainer

public final class LongPicViewController: BaseViewController {
    private let docsInfo: DocsInfo
    private var exportedImage: UIImage
    private let titleString: String
    private var imagePath: SKFilePath?
    private var longPicPreView: LongPicPreview?
    private var bottomViewHeight: CGFloat {
        if type != nil {
            return 64
        }
        if UIApplication.shared.statusBarOrientation.isLandscape {
            return 114 - 16
        } else {
            return 114
        }
    }
    private var contentSize = CGSize.zero
    
    private var shareActionManager: ShareActionManager?
    var type: ShareAssistType?
    
    var sharedImage: UIImage? {
        if let path = self.imagePath {
            return try? UIImage.read(from: path)
        }
        return exportedImage
    }
    
    lazy private var toolBar: ShareImagePanel = {
        return ShareImagePanel().construct { (it) in
            it.delegate = self as ShareImagePanelDelegate
            var items: [ShareAssistItem]  = []
            if let shareActionManager = shareActionManager {
                items.append(shareActionManager.item(.saveImage))
                items.append(shareActionManager.item(.feishu))
                items.append(contentsOf: shareActionManager.availableOtherAppItems())
            }
            it.dataSource = items
        }
    }()
    
    lazy private var bottomViewSafeView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()
    
    lazy private var saveAndSharePanel: SaveAndSharePanel = {
        return SaveAndSharePanel().construct { (it) in
            if let type = type {
                it.setType(type)
                it.setButtonClickCallback { [weak self] in
                    self?.saveImage(type: type, sourceView: nil)
                }
            }
        }
    }()
    
    private lazy var dismissView: UIView = {
        let view = UIView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTapDimissView))
        view.addGestureRecognizer(tap)
        return view
    }()
    
    private lazy  var contentView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N200
        return view
    }()
    
    var bottomView: UIView {
        if type != nil {
            return saveAndSharePanel
        }
        return toolBar
    }
    
    public var supportOrientations: UIInterfaceOrientationMask = .portrait
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }
    
    public convenience init(docsInfo: DocsInfo, navigator: BrowserNavigator?, titleString: String? = nil, imagePath: SKFilePath) {
        self.init(BundleResources.SKResource.Common.Pop.pop_feishu_im, docsInfo: docsInfo, navigator: navigator, titleString: titleString, imagePath: imagePath)
    }

    public convenience init(_ image: UIImage, docsInfo: DocsInfo, navigator: BrowserNavigator?, titleString: String? = nil) {
        self.init(image, docsInfo: docsInfo, navigator: navigator, titleString: titleString, imagePath: nil)
    }
    
    private init(_ image: UIImage, docsInfo: DocsInfo, navigator: BrowserNavigator?, titleString: String? = nil, imagePath: SKFilePath?) {
        self.exportedImage = image
        self.imagePath = imagePath
        self.docsInfo = docsInfo
        self.titleString = (titleString ?? docsInfo.title) ?? ""
        super.init(nibName: nil, bundle: nil)
        let shareEntity = SKShareEntity.transformFrom(info: docsInfo)
        self.shareActionManager = ShareActionManager(shareEntity, fromVC: self)
        self.modalPresentationStyle = .formSheet
    }
    

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    func onTapDimissView() {
        dismiss(animated: true, completion: nil)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupNav()
        setupUI()
    }

    private func reportDocumentActivity() {
        if let userID = User.current.basicInfo?.userID,
           let reporter = DocsContainer.shared.resolve(DocumentActivityReporter.self) {
            let activity = DocumentActivity(objToken: docsInfo.token, objType: docsInfo.type, operatorID: userID,
                                            scene: .download, operationType: .download)
            reporter.report(activity: activity)
        } else {
            spaceAssertionFailure()
        }
    }

    override public var canShowBackItem: Bool {
        return false
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if SKDisplay.phone, supportedInterfaceOrientations != .portrait { return }
        self.dismiss(animated: true, completion: nil)
    }

    private func setupNav() {
        title = titleString
        view.backgroundColor = .clear
        let cancelButtonItem = SKBarButtonItem(image: UDIcon.closeSmallOutlined.ud.withTintColor(UDColor.iconN1),
                                               style: .plain,
                                               target: self,
                                               action: #selector(backBarButtonItemAction))
        cancelButtonItem.id = .close
        navigationBar.leadingBarButtonItem = cancelButtonItem
        if SKDisplay.phone {
            navigationBar.layer.cornerRadius = 12
            navigationBar.layer.maskedCorners = .top
        }
    }

    private func setupUI() {
        view.addSubview(dismissView)
        dismissView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        view.addSubview(contentView)
        updateContentSize(UIApplication.shared.statusBarOrientation)
        if type != nil {
            contentView.addSubview(saveAndSharePanel)
            saveAndSharePanel.snp.makeConstraints { (make) in
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
                make.left.right.equalToSuperview()
                make.height.equalTo(bottomViewHeight)
            }

            //清空
            HostAppBridge.shared.register(service: ShareImageEntity.self) {_ in
                return nil
            }
        } else {
            contentView.addSubview(toolBar)
            toolBar.snp.makeConstraints { (make) in
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
                make.left.right.equalToSuperview()
                make.height.equalTo(bottomViewHeight)
            }
        }
        contentView.addSubview(bottomViewSafeView)
        bottomViewSafeView.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        
        if let path = self.imagePath {
            previewWithLongPicPreview(path)
        } else {
            if case Result.success(let path) = _compress(image: exportedImage, mode: .png) {
                previewImageV2(path)
            } else {
                previewImageV1()
            }
        }
        
    }

    
    func didChangeStatusBarOrientation(to newOrentation: UIInterfaceOrientation) {
        view.layoutIfNeeded()
        updateContentSize(newOrentation)
    }
    
    private func updateContentSize(_ newOrentation: UIInterfaceOrientation) {
        if SKDisplay.phone, newOrentation.isLandscape {
            navigationBar.snp.remakeConstraints { (make) in
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).inset(14)
                make.centerX.equalToSuperview()
                make.width.equalToSuperview().multipliedBy(0.7)
            }
            contentView.snp.remakeConstraints { (make) in
                make.bottom.centerX.equalToSuperview()
                make.top.equalTo(navigationBar.snp.bottom)
                make.width.equalToSuperview().multipliedBy(0.7)
            }
        } else {
            navigationBar.snp.remakeConstraints { (make) in
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
                make.leading.trailing.equalToSuperview()
            }
            contentView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }
    
    private func previewWithLongPicPreview(_ path: SKFilePath) {
        let longPicPreView = LongPicPreview(path, delegate: self)
        let margin: CGFloat = 8
        contentView.addSubview(longPicPreView)
        longPicPreView.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom).offset(margin)
            make.left.equalToSuperview().offset(margin)
            make.right.equalToSuperview().offset(-margin)
            make.bottom.equalTo(bottomView.snp.top).offset(-margin)
        }
    }
    

    private func previewImageV2(_ path: SKFilePath) {
        //TODO:refactor:DriveImagePreviewStrategy移到common
        let previewImageStrategy: SKImagePreviewStrategy
        let ur = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        if let windowSize = view.window?.frame.size,
           let previewStrategy = ur.docs.browserDependency?.defaultDriveImagePreviewStrategy(for: windowSize) {
            previewImageStrategy = previewStrategy
        } else {
            previewImageStrategy = SKImagePreviewDefaultStrategy()
        }
        let previewView = SKImagePreviewView(frame: .zero, previewStratery: previewImageStrategy)
        let margin: CGFloat = 8
        let width = self.view.bounds.size.width - margin * 2
        // FIXME: VC重构了dbvc的topcontainer逻辑，后续会修改
        let height = self.view.bounds.size.height - margin * 2 - navigationBar.frame.height - bottomViewHeight
        previewView.loadImageScaleToFill(path: path, tileSize: CGSize(width: width, height: height))

        contentView.addSubview(previewView)

        previewView.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom).offset(margin)
            make.left.equalToSuperview().offset(margin)
            make.right.equalToSuperview().offset(-margin)
            make.bottom.equalTo(bottomView.snp.top).offset(-margin)

        }
    }

    private func previewImageV1() {
        let scrollViewWidth = view.frame.width
        let scrollView = UIScrollView(frame: CGRect.zero)
        scrollView.backgroundColor = UIColor.ud.N200
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        contentView.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom)
            make.bottom.equalTo(bottomView.snp.top)
        }

        let imageViewWidth = scrollViewWidth - 20
        let imageViewHeight = imageViewWidth * exportedImage.size.height / exportedImage.size.width
        let imageView = UIImageView(image: exportedImage)
        imageView.contentMode = .scaleAspectFit
        imageView.layer.shadowOffset = CGSize(width: 2, height: 0)
        imageView.layer.shadowColor = UIColor.ud.N1000.withAlphaComponent(0.16).cgColor
        imageView.layer.shadowOpacity = 1
        imageView.layer.shadowRadius = 8
        scrollView.addSubview(imageView)

        imageView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(8)
            make.left.equalToSuperview().offset(8)
            make.width.equalTo(imageViewWidth)
            make.height.equalTo(imageViewHeight)
        }

        scrollView.contentSize = CGSize(width: imageViewWidth, height: imageViewHeight + 20)
    }

    private func generateParas() -> [AnyHashable: Any] {
        var paras: [AnyHashable: Any] = [:]
        paras["file_type"] = docsInfo.type.name
        paras["file_id"] = DocsTracker.encrypt(id: docsInfo.objToken)
        return paras
    }

    @objc
    private func saveImage(showDidSaveTip: Bool, callback: @escaping (Bool) -> Void) { // 保存图片到本地
        DocsTracker.log(enumEvent: .clickLongImageDownload, parameters: generateParas())
        let window = view.window ?? UIView()
        if let path = self.imagePath {
            var isSuccessSave = true
            UDToast.showTipsOnScreenCenter(with: BundleI18n.SKResource.Doc_Share_ExportImageLoading, on: window, delay: 500)
            PHPhotoLibrary.shared().performChanges({
                do {
                    let creationRequest = try AlbumEntry.forAsset(forToken: Token(PSDATokens.DocX.docx_imageShare_do_download))
                    creationRequest.addResource(with: .photo, fileURL: path.pathURL, options: nil)
                } catch {
                    isSuccessSave = false
                    DocsLogger.error("AlbumEntry.forAsset", extraInfo: nil, error: error, component: nil)
                }
            }, completionHandler: { (success, error) in
                DispatchQueue.main.async {
                    UDToast.removeToast(on: window)
                    if success && isSuccessSave {
                        if showDidSaveTip {
                            UDToast.showSuccess(with: BundleI18n.SKResource.Doc_Doc_ShotSaveSuccessfully, on: window)
                        }
                        callback(true)
                    } else {
                        DocsLogger.error("save long pic to album", extraInfo: nil, error: error, component: nil)
                        if showDidSaveTip {
                            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_SaveFailed, on: window)
                        }
                        callback(false)
                    }
                }
            })
            
            return
        }
        
        if let data = exportedImage.pngData() {
            let window = view.window ?? UIView()
            var isSuccessSave = true
            UDToast.showTipsOnScreenCenter(with: BundleI18n.SKResource.Doc_Share_ExportImageLoading, on: window, delay: 500)
            PHPhotoLibrary.shared().performChanges({
                do {
                    let creationRequest = try AlbumEntry.forAsset(forToken: Token(PSDATokens.DocX.docx_imageShare_do_download))
                    creationRequest.addResource(with: .photo, data: data, options: nil)
                } catch {
                        isSuccessSave = false
                        DocsLogger.error("AlbumEntry.forAsset", extraInfo: nil, error: error, component: nil)
                }
            }, completionHandler: { (success, error) in
                DispatchQueue.main.async {
                    UDToast.removeToast(on: window)
                    if success && isSuccessSave {
                        if showDidSaveTip {
                            UDToast.showSuccess(with: BundleI18n.SKResource.Doc_Doc_ShotSaveSuccessfully, on: window)
                        }
                        callback(true)
                    } else {
                        DocsLogger.error("save long pic to album", extraInfo: nil, error: error, component: nil)
                        if showDidSaveTip {
                            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_SaveFailed, on: window)
                        }
                        callback(false)
                    }
                }
            })
        }
    }

    @objc
    private func showSystemPreviewPage(_ sourceView: UIView?) { // 展示更多页面
        DocsTracker.log(enumEvent: .clickLongImageShare, parameters: generateParas())

        if let path = self.imagePath {
            _showSystemPreviewPage(path, sourceView)
            return
        }
        
        let result = _compress(image: exportedImage, mode: .png)
        
        switch result {
        case .success(let path):
            _showSystemPreviewPage(path, sourceView)
        case .failure(let fail):
            DocsLogger.error("压缩图片失败", extraInfo: ["error": fail.localizedDescription])
        }
    }

    private func _showSystemPreviewPage(_ path: SKFilePath, _ sourceView: UIView?) {
        let systemActivityController = UIActivityViewController(activityItems: [path.pathURL as Any], applicationActivities: nil)

        // 注册分享回调
        let completionHandler: UIActivityViewController.CompletionWithItemsHandler = { _, _, _, error in
            if error != nil {
                DocsLogger.error("分享长图失败")
            }
        }

        systemActivityController.completionWithItemsHandler = completionHandler
        if SKDisplay.pad {
            systemActivityController.modalPresentationStyle = .popover
            systemActivityController.popoverPresentationController?.backgroundColor = UDColor.bgFloat
            systemActivityController.popoverPresentationController?.sourceView = toolBar
            systemActivityController.popoverPresentationController?.permittedArrowDirections = .down
            if let sourceView = sourceView {
                systemActivityController.popoverPresentationController?.sourceRect = toolBar.convert(sourceView.frame, from: toolBar)
            } else {
                systemActivityController.popoverPresentationController?.sourceRect = CGRect(origin: toolBar.bounds.center, size: .zero)
            }
        }

        present(systemActivityController, animated: true, completion: nil)
    }
}

extension LongPicViewController {
    private enum CompressError: Error {
        case imageToJPEGDataFailure
        case imageToPNGDataFailure
        case saveToTmpDirFailure
    }

    private enum CompressMode {
        case jpeg(CGFloat)
        case png

        var suffix: String {
            switch self {
            case .jpeg:
                return "jpg"
            case .png:
                return "png"
            }
        }
    }

    private func _compress(image: UIImage, mode: CompressMode) -> Swift.Result<SKFilePath, CompressError> {
        // 因为很多 App 都会对 UIImage 的分享进行限制大小，但是对文件分享限制较为宽松
        // 所以会对 UIImage 保存到沙盒里面再分享

        var compressData: Data!

        switch mode {
        case .jpeg(let quality):
            guard let cd = image.jpegData(compressionQuality: quality) else {
                return .failure(.imageToJPEGDataFailure)
            }
            compressData = cd
        case .png:
            guard let cd = image.pngData() else {
                return .failure(.imageToPNGDataFailure)
            }
            compressData = cd
        }

        // 2. 存储到沙盒 tmp 目录
        var imageName = "Share"
        if var title = docsInfo.title {
//            title.replacingOccurrences(of: " ", with: "")
            title = title.replacingOccurrences(of: "/", with: " ")
            imageName = title
        }
        let imagePath = SKFilePath.globalSandboxWithTemporary.appendingRelativePath("\(imageName).\(mode.suffix)")
        
        guard imagePath.writeFile(with: compressData, mode: .append) else {
            DocsLogger.info("Error saving picture")
            return .failure(.saveToTmpDirFailure)
        }
        // 3. 分享沙盒 URL
        return .success(imagePath)
    }
}

extension LongPicViewController: ShareImagePanelDelegate {
    func shareImagePanel(_ shareImagePanel: ShareImagePanel, type: ShareAssistType, sourceView: UIView?) {
        makeTrack(type: type)
        
        saveImage(type: type, sourceView: sourceView)
    }
    
    func checkDownloadPermission() -> Bool {
        //导出图片使用文档导出权限点位
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            return DocPermissionHelper.validate(objToken: docsInfo.token,
                                                objType: docsInfo.inherentType,
                                                operation: .export).allow
        } else {
            return DocPermissionHelper.checkPermission(.ccmExport,
                                                       docsInfo: docsInfo,
                                                       showTips: false)
        }
    }
    
    func saveImage(type: ShareAssistType, sourceView: UIView?) {
        let hudView = self.view.window ?? self.view
        // 分享SDK权限判断
        if shareActionManager?.checkShareAdminAuthority(type: type, showTips: true) == false {
            DocsLogger.warning("share to \(type) has no Admin Authority")
            return
        }
        if let isAvaliable = self.shareActionManager?.isAvailable(type: type), !isAvaliable {
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Share_AppNotInstalled, on: view.window ?? UIView())
            return
        }
        // 权限管控
        // 导出长图使用文档权限
        if type == .saveImage || type == .more {
            if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                let response = DocPermissionHelper.validate(objToken: docsInfo.token,
                                                            objType: docsInfo.inherentType,
                                                            operation: .export)
                response.didTriggerOperation(controller: self)
                guard response.allow else { return }
            } else {
                guard DocPermissionHelper.checkPermission(.ccmExport,
                                                          docsInfo: docsInfo,
                                                          showTips: true,
                                                          securityAuditTips: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, hostView: hudView) else {
                    return
                }
            }
        }

        // 通过鉴权，上报事件
        reportDocumentActivity()

        if type == .more {
            self.showSystemPreviewPage(sourceView)
            return
        }
        let showDidSaveTip = type == .saveImage
        saveImage(showDidSaveTip: showDidSaveTip) { [weak self] (_) -> Void in
            guard let self = self else {
                return
            }
            
            if type != .saveImage {
                if let image = self.sharedImage {
                    if type == .feishu {
                        self.shareActionManager?.shareImageToLark(image: image)
                    } else {
                        self.shareActionManager?.shareImageToSocialApp(type: type, image: image)
                    }
                } else {
                    DocsLogger.info("longpic 图片过大无法分享")
                    UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_Docx_ExportFailed, on: self.view.window ?? UIView())
                }
            }
        }
    }
    
    func makeTrack(type: ShareAssistType) {
        //埋点
        var params: [String: Any] = [:]
        var action = "share_button_click"
        var toPlatform = ""
        switch type {
        case .more:
            toPlatform = "more"
        case .wechat:
            toPlatform = "wechat"
        case .wechatMoment:
            toPlatform = "weixin_article"
        case .weibo:
            toPlatform = "weibo"
        case .qq:
            toPlatform = "qq"
        case .saveImage:
            action = "download"
        default: ()
            
        }
        params["action"] = action
        params["to_platform"] = toPlatform
        
        DocsTracker.log(enumEvent: .clickLongImageShare, parameters: params)
    }
}

extension LongPicViewController: LongPicPreviewDelegate {
    func animationView(_ preview: LongPicPreview) -> LongPicAnimationViewProtocol {
        return LongPicIndicatorView(frame: .zero)
    }
    
    func loadImageFailed(_ preview: LongPicPreview) {
        DocsLogger.error("图像加载失败，请重试")
        UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_OperateFailed, on: view.window ?? UIView())
        
        if let backItem = navigationBar.leadingBarButtonItem {
            perform(#selector(backBarButtonItemAction), with: backItem)
        }
    }
    
    func didLoadFirstFrame(_ preview: LongPicPreview) {
        
    }
}

class LongPicIndicatorView: UIView, LongPicAnimationViewProtocol {
    
    var loadingView = DocsContainer.shared.resolve(DocsLoadingViewProtocol.self)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody
        if let loadingView = loadingView {
            addSubview(loadingView.displayContent)
            loadingView.displayContent.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startAnimating() {
        loadingView?.startAnimation()
    }
    
    func stopAnimating() {
        loadingView?.stopAnimation()
    }
}
