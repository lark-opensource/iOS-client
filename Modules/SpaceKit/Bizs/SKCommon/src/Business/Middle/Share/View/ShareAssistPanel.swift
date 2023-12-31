//
//  ShareAssistPanel.swift
//  SpaceKit
//
//  Created by Webster on 2019/3/8.
//  swiftlint:disable file_length

import Foundation
import EENavigator
import SwiftyJSON
import UniverseDesignActionPanel
import SKFoundation
import SKUIKit
import SKResource
import RxSwift
import UniverseDesignToast
import UniverseDesignColor
import UniverseDesignBadge
import UniverseDesignDialog
import LarkReleaseConfig
import FigmaKit
import LarkEMM
import LarkSecurityComplianceInterface
import SpaceInterface
import SKInfra

public enum CopyLinkAction: Int {
    case linkAndPassWord = 0 //链接和密码
    case link  //链接
    case cancel
}

protocol ShareAssistPanelDelegate: AnyObject {
    func didClicked(type: ShareAssistType, sharePanel: ShareAssistPanel)
    func didRequestExportSnapShot(sharePanel: ShareAssistPanel)
    func didRequestSlideExport(sharePanel: ShareAssistPanel)
    func didClickShareToOtherApp(sharePanel: ShareAssistPanel, activityViewController: UIViewController?)
    func shouldDisplaySnapShotItem() -> Bool
    func sharePanelConfigInfo() -> SharePanelConfigInfoProtocol?
    func shouldDisplaySlideExport() -> Bool
    func shouldDisplayCopyLinkAlertSheet(view: UIView, iphoneAlert: UIViewController, ipaAlert: UIViewController)
    func didClickShareLinkToExternal(view: UIView, completion: (() -> Void)?)
    func didClickShareToByteDanceMoments(_ url: URL)
    func requestHostViewController() -> UIViewController?
    func requestweakFollowAPIDelegate() -> BrowserVCFollowDelegate?
    func requestShareToLarkServiceFromViewController() -> UIViewController?
    func didClickCopyLink(sharePanel: ShareAssistPanel)
    func didClickCopyPasswordLink(enablePasswordShare: Bool)
}

/// collection view data model
enum ShareAppearance {
    case defaultMode
    case darkMode
}

public enum ShareItemIdentifier: String {
    case shareImage
}

public final class ShareAssistItem {
    public var type: ShareAssistType
    public var image: UIImage?
    public var title: String
    public var enable: Bool = true
    var redDot: Bool = false
    var callback: (() -> Void)?
    var apperance = ShareAppearance.defaultMode
    public init(type: ShareAssistType, title: String, image: UIImage?) {
        self.type = type
        self.title = title
        self.image = image
    }
}

private extension ShareAssistPanel {
    enum Layout {
        static let panelHeight: CGFloat = 84
        static let itemWidth: CGFloat = 64
        static let itemMSpacing: CGFloat = 4
        static let contentInset = UIEdgeInsets(horizontal: 12, vertical: 0)
    }
}

class ShareAssistPanel: UIView {
    /// delegate
    private weak var delegate: ShareAssistPanelDelegate?
    /// 统计支撑
    weak var reporter: ShareAssistReportAbility?

    var source: ShareSource = .list
    /// 支持导出长图的文档类型
    private var snapShotEnableTypes: Set<DocsType> = [.doc, .mindnote]
    ///cell idenfifier
    private let cellReuseIdentifier = "ShareAssistPanel.ShareAssistCell"
    let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
    /// 公共权限
    private var publicPermissionMeta: PublicPermissionMeta?
    private var userPermissions: UserPermissionAbility?
    /// 当前用户 roleType
    private var currentUserRoleType: Int?

    /// 复制链接弹框
    var moreActionSheet: UDActionSheet? = UDActionSheet.actionSheet()
    var moreUIActionSheet: UIAlertController? = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    /// 复制链接选项
    var copyLinkActions: [CopyLinkAction] = []
    /// ipad
    var padPopDirection: UIPopoverArrowDirection = .left
    /// 用户设置了获得链接也无法访问时，需要一个提醒
    private var needPermissionTips: Bool {
        guard let publicPermissionMeta = publicPermissionMeta else { return false }
        if UserScopeNoChangeFG.PLF.shareExternalSettingEnable && ![.folder, .minutes].contains(shareEntity.type) { return false }
        if shareEntity.onlyShowSocialShareComponent { return false }
        if shareEntity.isFormV1 || shareEntity.isBitableSubShare { return false } //表单不展示
        if shareEntity.spaceSingleContainer || shareEntity.wikiV2SingleContainer {
            if publicPermissionMeta.externalAccessEnable == false {
                return false
            }
        }
        // 如果用户没有勾选「互联网上获得链接的人可阅读」或者「互联网上获得链接的人可编辑」需要弹窗让用户开启
        return !publicPermissionMeta.linkShareEntity.canCrossTenant
    }
    //是否选择了不再显示
    private var donntShowAgain: Bool {
        self.makeTracksForShowLinkShareTips(.clickLinkShareTipsOperation, "turn_on")
        let userDefault = CCMKeyValue.globalUserDefault.dictionary(forKey: UserDefaultKeys.showPermissiontTipsEnabled)
        // 用户选择了不要再显示
        let donntShowAgain = (userDefault?["showTips"] as? Bool) ?? false
        return donntShowAgain
    }

    private let disposeBag: DisposeBag = DisposeBag()
    private var shareAssistType: ShareAssistType?

    private var hasShowPermissionTips = false
    
    private weak var permissionAlert: UDDialog?

    var panelEnabled = true {
        didSet {
            guard oldValue != panelEnabled else { return }
            collectionView.reloadData()
        }
    }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = isNewFormV2 ? .vertical : .horizontal
        layout.itemSize = CGSize(width: Layout.itemWidth, height: Layout.panelHeight)
        layout.minimumLineSpacing = isNewFormV2 ? 12 : Layout.itemMSpacing
        if isNewFormV2 {
            layout.minimumInteritemSpacing = 0
        }
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.register(ShareAssistCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
        view.contentInset = isNewFormV2 ? UIEdgeInsets(horizontal: 0, vertical: 0) :  Layout.contentInset
        view.dataSource = self
        view.delegate = self
        view.clipsToBounds = false
        view.showsHorizontalScrollIndicator = false
        view.alwaysBounceHorizontal = true
        view.backgroundColor = .clear
        if isNewFormV2 {
            view.isScrollEnabled = false
        }
        return view
    }()

    /// collection view data source
    private var defaultItems: [ShareAssistItem] {
        get {
            return self.shareActionManager?.shareItems ?? []
        }
        set {
            self.shareActionManager?.shareItems = newValue
        }
    }
    private var shareActionManager: ShareActionManager?
    private var shareEntity: SKShareEntity
    private var viewModel: SKShareViewModel?
    private var currentTopMost: UIViewController? {
        guard let currentVC = delegate?.requestHostViewController() else {
            spaceAssertionFailure("cannot get rootVC")
            return nil
        }
        return UIViewController.docs.topMost(of: currentVC)
    }

    private(set) lazy var toastTextView: UITextView = {
        let t = UITextView()
        t.backgroundColor = UDColor.bgFloat
        t.textColor = UDColor.textTitle
        t.textAlignment = .center
        t.isEditable = false
        t.isUserInteractionEnabled = true
        t.isSelectable = true
        t.isScrollEnabled = false
        t.showsHorizontalScrollIndicator = false
        t.showsVerticalScrollIndicator = false
        return t
    }()

    init(_ shareEntity: SKShareEntity,
         delegate: ShareAssistPanelDelegate?,
         source: ShareSource,
         viewModel: SKShareViewModel?) {
        self.shareEntity = shareEntity
        self.viewModel = viewModel
        super.init(frame: .zero)
        self.shareActionManager = ShareActionManager(shareEntity, fromVC: delegate?.requestHostViewController(), permStatistics: viewModel?.permStatistics, requestPermissions: false, followAPIDelegate: delegate?.requestweakFollowAPIDelegate())
        self.delegate = delegate
        self.source = source
        setUpUI()
        refreshItemStatus(update: false)
    }
    
    deinit {
        DocsLogger.info("ShareAssistPanel deinit")
    }
    
    func setUpUI() {
        self.shareActionManager?.delegate = self
        defaultItems = items(update: false)
        addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            if isNewFormV2 {
                make.top.bottom.equalToSuperview()
                make.left.equalToSuperview().offset(12)
                make.right.equalToSuperview().offset(-12)
                make.height.equalTo(168)
            } else {
                make.edges.equalToSuperview()
                make.height.equalTo(Layout.panelHeight)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let size = (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize,
            size.width != frame.width {
            relayoutForScreenTransition()
        }
    }

    func relayoutForScreenTransition() {
        collectionView.collectionViewLayout.invalidateLayout()
    }

    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        reporter?.reportShowSharePage()
    }
    
    public func updateUserAndPublicPermissions(userPermissions: UserPermissionAbility?, publicPermissions: PublicPermissionMeta?) {
        self.userPermissions = userPermissions
        self.publicPermissionMeta = publicPermissions
        refreshItemStatus(update: true)
    }
    
    private func items(update: Bool) -> [ShareAssistItem] {
        var allItems: [ShareAssistItem] = []
        guard let shareActionManager = shareActionManager else {
            return []
        }
        // 单品移除『发送到会话』
        if !DocsSDK.isInLarkDocsApp {
            allItems.append(shareActionManager.item(.feishu))
        }
        //添加复制链接
        if !UserScopeNoChangeFG.PLF.shareChannelDisable {
            allItems.append(shareActionManager.item(.fileLink))
        }
        
        if shouldShowQrItem() {
            allItems.append(shareActionManager.item(.qrcode))
        }

        guard update else { return allItems }

        let disabledType = [.minutes, .folder, .sync].contains(shareEntity.type)
        let blockType = publicPermissionMeta?.blockOptions?.linkShareEntity(with: .anyoneCanRead)
        let blockTypeEnabled = blockType == nil
        || blockType == BlockOptions.BlockType.none
        || blockType == .currentLimit
        || blockType == .secretControl
        if UserScopeNoChangeFG.PLF.shareExternalSettingEnable,
           SettingConfig.shareWithPasswordConfig?.docEnable == true,
           !disabledType,
           blockTypeEnabled,
           userPermissions?.isFA == true,
           !shareEntity.isVersion
        {
            // 添加加密链接
            allItems.append(shareActionManager.item(.passwordLink))
        }

        //图片分享
        if shouldDisplaySnapShot(),
           !UserScopeNoChangeFG.PLF.shareChannelDisable {
            let item = shareActionManager.item(.snapshot)
            if shareEntity.type == .sheet, let sharePanelConfig = self.delegate?.sharePanelConfigInfo() {
                let badges = sharePanelConfig.badges
                var badgesMapping = [String: Bool]()
                for badge in badges {
                    badgesMapping[badge] = true
                }
                
                if badgesMapping[ShareItemIdentifier.shareImage.rawValue] != nil {
                    item.redDot = true
                }
                
            }
            allItems.append(item)
        }
        
        allItems.append(contentsOf: shareActionManager.availableOtherAppItems())
        return allItems
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
// MARK: - 导出长图的相关逻辑
extension ShareAssistPanel {
    private func shouldDisplaySnapShot() -> Bool {
        // 这里的 delegate 实现有问题，文档场景下，会直接用宿主文档信息判断，而非当前分享的对象（同步块），导致判断不准确
        // 暂时直接判断是否是同步块，直接隐藏掉
        if shareEntity.isSyncedBlock { return false }
        let add = delegate?.shouldDisplaySnapShotItem() ?? false
        return add
    }

    private func shouldDisplaySlideExport() -> Bool {
        return delegate?.shouldDisplaySlideExport() ?? false
    }

    private func refreshItemStatus(update: Bool) {
        defaultItems = items(update: update)
        tryRefreshSnapShotStatus()
    }
    
    private func tryRefreshSnapShotStatus() {
        //文件夹
        let noNeedExportType: Set<ShareDocsType> = [.folder]
        if noNeedExportType.contains(shareEntity.type) {
            //旧共享文件夹根目录是特例
            guard shareEntity.isOldShareFolder,
                  let isRoot = shareEntity.shareFolderInfo?.shareRoot, isRoot else {
                DocsLogger.info("folder reload share panel")
                collectionView.reloadData()
                return
            }
        }
        self.tryDisableSnapShot()
    }

    private func tryDisableSnapShot() {
        for data in self.defaultItems where data.type == .snapshot {
            data.enable = canExportLongImage()
        }
        collectionView.reloadData()
    }

    private func policyResultFor(type: ShareAssistType) -> CCMSecurityPolicyService.ValidateResult {
        var operate: LarkSecurityComplianceInterface.EntityOperate = .ccmExport
        switch type {
        case .snapshot:
            operate = .ccmExport
        case .more:
            operate = .ccmFileDownload
        default:
            spaceAssertionFailure("invalid type")
            break
        }
        let docsType = DocsType(rawValue: shareEntity.type.rawValue) ?? .doc
        return CCMSecurityPolicyService.syncValidate(entityOperate: operate, fileBizDomain: .ccm, docType: docsType, token: shareEntity.objToken)
    }

    private func showInterceptDialogFor(type: ShareAssistType) {
        var operate: LarkSecurityComplianceInterface.EntityOperate = .ccmExport
        switch type {
        case .snapshot:
            operate = .ccmExport
        case .more:
            operate = .ccmFileDownload
        default:
            spaceAssertionFailure("invalid type")
            break
        }
        let docsType = DocsType(rawValue: shareEntity.type.rawValue) ?? .doc
        CCMSecurityPolicyService.showInterceptDialog(entityOperate: .ccmExport, fileBizDomain: .ccm,
                                                     docType: docsType, token: shareEntity.objToken)
    }

    private func canDownload() -> Bool {
        let policyAllow = policyResultFor(type: .more).allow
        let userPermissonAllow = userPermissions?.canDownload() == true
        return policyAllow && userPermissonAllow
    }

    private func canExport() -> Bool {
        let policyAllow = policyResultFor(type: .snapshot).allow
        let userPermissonAllow = userPermissions?.canExport() == true
        return policyAllow && userPermissonAllow
    }

    private func canExportLongImage() -> Bool {
        if userPermissions?.adminBlocked() == true {
            return false
        }
        if !policyResultFor(type: .snapshot).allow {
            return false
        }
        var canExportSnap = userPermissions?.canExport() ?? false

        if shareEntity.type == .sheet, let sharePanelConfig = self.delegate?.sharePanelConfigInfo() {
            let disables = sharePanelConfig.disables
            var disablesMapping = [String: Bool]()
            for disable in disables {
                disablesMapping[disable] = true
            }
            
            if disablesMapping[ShareItemIdentifier.shareImage.rawValue] != nil {
                canExportSnap = false
            }
            
        }
        return canExportSnap
    }

    private var canEdit: Bool {
        guard nil != User.current.info?.tenantID, nil != User.current.info?.userID else {
            return false
        }
        guard shareEntity.type.isBizDoc else { return false }
        /// 这里可以信任缓存，在 UpdateUserPermissionService 设置 UserDefaults 的时候，permissionManager 的缓存也设置过了
        return permissionManager.isUserEditable(for: shareEntity.objToken, type: shareEntity.type.rawValue).editable
    }
    
    private func showExternAppView(_ item: ShareAssistItem) {
        guard let shareAssistType = self.shareAssistType,
              let shareActionManager = shareActionManager else {
            return
        }
        guard shareActionManager.checkShareAdminAuthority(type: shareAssistType, showTips: true) else {
            DocsLogger.warning("share to \(shareAssistType) has no Admin Authority")
            return
        }
        guard shareActionManager.isAvailable(type: shareAssistType) else {
            let alert = UIAlertController(title: BundleI18n.SKResource.Doc_Share_AppNotInstalled, message: nil, preferredStyle: .alert)
            let action = UIAlertAction(title: BundleI18n.SKResource.Doc_Facade_Ok, style: .default, handler: nil)
            alert.addAction(action)
            present(alert)
            return
        }
        
        if let callback = item.callback {
            callback()//用于处理sheet导出图像
        }
        
        handleShareType(type: shareAssistType)
        reportDidShare(type: shareAssistType)
        delegate?.didClicked(type: shareAssistType, sharePanel: self)
    }
    
    private func present(_ viewController: UIViewController) {
        if let vc = delegate?.requestHostViewController(),
           let fromVC = UIViewController.docs.topMost(of: vc) {
            Navigator.shared.present(viewController, from: fromVC)
        } else {
            DocsLogger.error("fromVC is nil")
        }
    }
}

extension ShareAssistPanel: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return defaultItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell1 = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath)
        guard let cell = cell1 as? ShareAssistCell else {
            return cell1
        }
        cell.configure(by: defaultItems[indexPath.row])
        if !panelEnabled {
            cell.forceRenderDisable()
        }
        return cell
    }
}

extension ShareAssistPanel: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = defaultItems[indexPath.row]

        collectionView.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) {
            collectionView.isUserInteractionEnabled = true
        }
        
        self.shareAssistType = item.type
        showExternAppView(item)
    }
}

///点击处理
extension ShareAssistPanel {
    // swiftlint:disable cyclomatic_complexity
    private func handleShareType(type: ShareAssistType) {
        guard let shareActionManager = shareActionManager else { return }
        shareActionManager.handler.onShareToFeishu = { [weak self] (title, content) in
            guard let self = self, let currentTopMost = self.currentTopMost else { return }
            currentTopMost.dismiss(animated: false, completion: {
                var fromVC: UIViewController?
                if let injectionVC = self.delegate?.requestShareToLarkServiceFromViewController() {
                    fromVC = injectionVC
                } else if let currentTopMost = self.currentTopMost {
                    fromVC = currentTopMost
                } else {
                    spaceAssertionFailure("from vc is nil")
                }
                self.viewModel?.permStatistics?.reportPermissionShareLarkView()
                self.viewModel?.permStatistics?.reportPermissionShareClick(shareType: self.shareEntity.type, click: .shareLark, target: .permissionShareLarkView)
                let shareHandler = self.shareEntity.shareHandlerProvider?.shareToLarkHandler
                let completion: (() -> Void) = {
                    LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait, delay: 0.05) {
                        let service = ShareToLarkService(
                            contentType: .text(content: content, callback: shareHandler),
                            fromVC: fromVC,
                            type: .feishu
                        )
                        HostAppBridge.shared.call(service)
                    }
                }
                if #available(iOS 16.0, *), UIApplication.shared.statusBarOrientation.isLandscape {
                    DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) {
                        completion()
                    }
                } else {
                    completion()
                }
            })
        }
        shareActionManager.handler.onShareToQRCode = { [weak self] in
            guard let self = self, let currentTopMost = self.currentTopMost else { return }
            guard let config = self.fetchQrCodeConfig() else {
                DocsLogger.error("share qrConfig is nil")
                return
            }
            currentTopMost.dismiss(animated: false) {
                self.navigtorToQrCodeController(config: config)
            }
        }
        shareActionManager.handler.onShareToByteDanceMoments = { [weak self] (url) in
            guard let self = self, let currentTopMost = self.currentTopMost else { return }
            guard let url = url else { return }
            self.viewModel?.permStatistics?.reportPermissionShareClick(shareType: self.shareEntity.type, click: .shareBytedanceMoments, target: .noneTargetView)
            currentTopMost.dismiss(animated: false, completion: { [weak self] in
                self?.delegate?.didClickShareToByteDanceMoments(url)
            })
        }
        shareActionManager.handler.onShareToOtherApp = { [weak self] activityController in
            guard let self = self else { return }
            self.delegate?.didClickShareToOtherApp(sharePanel: self, activityViewController: activityController)
        }
        shareActionManager.handler.onDidHandle = { [weak self] (_, type) in
            guard let self = self else { return }
            switch type {
            case .snapshot:
                self.viewModel?.permStatistics?.reportPermissionShareClick(shareType: self.shareEntity.type, click: .imageShare, target: .noneTargetView)
                self.handleSnapshot()
            default: ()
            }
        }
        shareActionManager.handler.onWillHandle = { [weak self] (_, type) in
            guard let self = self else { return true }
            if self.shareEntity.isFormV1 || self.shareEntity.isBitableSubShare { return true }
            switch type {
            case .feishu, .fileLink, .passwordLink: return !self.shareUrlEmptyLogic()
            case .wechat, .weibo, .qq, .wechatMoment: return !self.needPermissionTips(type)
            case .more: return self.canHandleMore()
            default: return true
            }
        }
        
        shareActionManager.handler.onShareImageToOtherApp = { [weak self] (_, type) in
            self?.handleSnapshot()
        }
        
        shareActionManager.fire(type)
    }
    
    var isNewFormV2: Bool {
        shareEntity.formsShareModel != nil
    }
    
    private func shouldShowQrItem() -> Bool {
        if isNewFormV2 || shareEntity.isOldForm {
            return true
        }
        let cxtEnable = shareEntity.bitableSubType == .record || shareEntity.bitableSubType == .addRecord
        let cxtFgEnable = UserScopeNoChangeFG.PXR.btSingleCardShowQrcodeWhenShareEnable
        return cxtEnable && cxtFgEnable
    }
        
    private func fetchQrCodeConfig() -> SKShareQRConfig? {
        let shareUrl = shareEntity.shareUrl
        if isNewFormV2, let formsShareModel = shareEntity.formsShareModel {
            var formsShareUrl = shareUrl
                if let url = URL(string: formsShareUrl) {
                    let urlWithQuery = url
                        .docs
                        .addOrChangeEncodeQuery(
                            parameters: [
                                "ccm_open_type" : "form_qrcode"
                            ]
                        )
                        .absoluteString
                    formsShareUrl = urlWithQuery
                    DocsLogger.info("forms share url append ccm_open_type success")
                } else {
                    let msg = "URL(string: formsShareUrl) is nil, and formsShareUrl is: \(formsShareUrl)"
                    DocsLogger.error(msg)
                    assertionFailure(msg)
                }
            let formsStyle = SKShareQrCodeViewStyle.forms(info: SKShareQrCodeFormsStyleInfo(bannerUrl: formsShareModel.bannerURL))
            return SKShareQRConfig(
                tilte: formsShareModel
                    .formName,
                qrStr: formsShareUrl,
                style: formsStyle
            )
        } else if shareEntity.bitableSubType == .record {
            var qrStr = shareUrl
            if let url = URL.init(string: shareUrl) {
                let params = ["ccm_open_type": "record_qrcode",
                             "from": "record_qrcode"]
                qrStr = url.docs.addOrChangeEncodeQuery(parameters: params).absoluteString
            }
            return SKShareQRConfig.init(tilte: self.shareEntity.title, qrStr: qrStr, style: .singleCardRecord)
        } else if shareEntity.bitableSubType == .addRecord {
            var qrStr = shareUrl
            if let url = URL.init(string: shareUrl) {
                let params = ["ccm_open_type": "quickadd_qrcode"]
                qrStr = url.docs.addOrChangeEncodeQuery(parameters: params).absoluteString
            }
            return SKShareQRConfig.init(tilte: self.shareEntity.title, qrStr: qrStr, style: .singleCardRecord)
        } else if shareEntity.isOldForm {
            var formsShareUrl = shareUrl
            if let url = URL(string: formsShareUrl) {
                let urlWithQuery = url
                    .docs
                    .addOrChangeEncodeQuery(
                        parameters: [
                            "ccm_open_type" : "form_v1_qrcode_share"
                        ]
                    )
                    .absoluteString
                formsShareUrl = urlWithQuery
                DocsLogger.info("old form share url append ccm_open_type success")
            } else {
                let msg = "URL(string: formsShareUrl) is nil, and old form shareUrl is: \(formsShareUrl)"
                DocsLogger.error(msg)
                assertionFailure(msg)
            }
            let formsStyle = SKShareQrCodeViewStyle.oldForm
            return SKShareQRConfig(
                tilte: shareEntity.title,
                qrStr: formsShareUrl,
                style: formsStyle
            )
        }
        return nil
    }
    
    private func navigtorToQrCodeController(config: SKShareQRConfig) {
        var fromVC: UIViewController?
        if let injectionVC = self.delegate?.requestShareToLarkServiceFromViewController() {
            fromVC = injectionVC
        } else if let currentTopMost = self.currentTopMost {
            fromVC = currentTopMost
        } else {
            DocsLogger.warning("navigtorToQrCodeController failed, from vc is nil")
            spaceAssertionFailure("from vc is nil")
        }
        let individual = self.viewModel?.shareEntity.bitableShareEntity?.param.preShareToken != nil
        if let fromVC = fromVC {
            let formsQRCodeViewController = SKShareQrCodeViewController(qrConfig: config, saveClick: {
                if self.shareEntity.type == .bitableSub(.addRecord) {
                    self.viewModel?.permStatistics?.reportPermissionShareQrcodeClick(shareType: self.shareEntity.type, click: "download", individual: individual)
                    return
                }
                switch config.style {
                case .forms, .oldForm:
                        self.viewModel?.permStatistics?.reportPermissionShareClick(shareType: self.shareEntity.type, click: .download_qrcode, target: .noneTargetView)
                    case .singleCardRecord:
                        self.viewModel?.permStatistics?.reportPermissionShareClickInBitableSingleCardContext(shareType: self.shareEntity.type, click: .download_qrcode, target: .noneTargetView)
                }
            })
            formsQRCodeViewController.backClick = { [weak self] in
                guard let self = self else {
                    return
                }
                self.viewModel?.permStatistics?.reportPermissionShareQrcodeClick(shareType: self.shareEntity.type, click: "close", individual: individual)
            }
            let nav = UINavigationController(rootViewController: formsQRCodeViewController)
            if SKDisplay.phone {
                nav.modalPresentationStyle = .overFullScreen
            }
            Navigator.shared.present(nav, from: fromVC)
        }
        self.viewModel?.permStatistics?.reportPermissionShareQrcodeView(shareType: self.shareEntity.type, individual: individual)
    }

    private func canHandleMore() -> Bool {
        return !(self.needPermissionTips(.more))
    }
    
    private func needPermissionTips(_ type: ShareAssistType) -> Bool {
        if UserScopeNoChangeFG.PLF.wikiShareChannelEnable && publicPermissionMeta?.linkShareEntityV2?.canShareAnyone != true && userPermissions?.isFA != true {
            UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_CM_Mobile_ExSharing_TurnOnSwitchToViewOrEdit_Toast, on: self.window ?? self)
            return true
        }
        if needPermissionTips {     // 用户没有打开链接可共享
            _showPermissionTips(for: type)
            return true
        }
        return false
    }

    private func shareUrlEmptyLogic() -> Bool {
        let shareUrl = shareEntity.shareUrl
        if shareUrl.isEmpty {
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Doc_NetException, on: self.window ?? self)
            return true
        }
        return false
    }

    fileprivate func makeTracksForShowLinkShareTips(_ event: DocsTracker.EventType, _ operation: String? = nil) {
        let fileType = shareEntity.type.name
        let linkPermission = getLinkPermissionType()
        let ownerString = shareEntity.isOwner ? "true" : "flase"
        var params = [
            "file_type": fileType,
            "link_permission": linkPermission,
            "is_owner": ownerString
        ]
        
        if let operation = operation {
            params["operation"] = operation
        }
        
        DocsTracker.log(enumEvent: event, parameters: params)
    }
    
    private func _showPermissionTips(for type: ShareAssistType) {
        if shareEntity.isOwner {
            viewModel?.permStatistics?.reportPermissionSharePublicAccessView()
        } else {
            viewModel?.permStatistics?.reportPermissionOwnerTurnedOffPromptView()
        }
        makeTracksForShowLinkShareTips(.showLinkShareTips)
        let dialog = UDDialog()
        let tipString = shareEntity.isOwner ? BundleI18n.SKResource.Doc_Facade_NotNow: BundleI18n.SKResource.Doc_Facade_GotIt
        let typeString: String
        if shareEntity.type == .minutes {
            typeString = BundleI18n.SKResource.CreationMobile_Minutes_name
        } else if shareEntity.type == .wikiCatalog {
            typeString = BundleI18n.SKResource.CreationMobile_Common_Page
        } else {
            typeString = BundleI18n.SKResource.CreationMobile_Common_Document
        }
        var content = shareEntity.isOwner
            ? BundleI18n.SKResource.Doc_Share_ExternalShareOwnerTips_AddVariable(typeString)
            : BundleI18n.SKResource.Doc_Share_ExternalShareCollTips_AddVariable(typeString)
        if shareEntity.isFolder {
            content = shareEntity.isOwner
                ? BundleI18n.SKResource.CreationMobile_Docs_Share_ExternalShareOwnerTips_folder
                : BundleI18n.SKResource.CreationMobile_Docs_Share_ExternalShareCollTips_folder
        }
        if shareEntity.isOwner {
            dialog.setTitle(text: BundleI18n.SKResource.Doc_Share_ExternalShareOwnerTitle)
        }
        dialog.setContent(text: content)
        dialog.addSecondaryButton(text: tipString, dismissCompletion:  { [weak self] in
            guard let self = self else {
                return
            }
            if self.shareEntity.isOwner {
                self.viewModel?.permStatistics?.reportPermissionSharePublicAccessClick(click: .maybeLater, target: .noneTargetView)
            } else {
                self.viewModel?.permStatistics?.reportPermissionOwnerTurnedOffPromptClick(click: .gotIt, target: .noneTargetView)
            }
            let operation = self.shareEntity.isOwner ? "not_now" : "ok"
            self.makeTracksForShowLinkShareTips(.clickLinkShareTipsOperation, operation)
            self.shareActionManager?.directlyFire(type)
        })

        if shareEntity.isOwner {
            dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_TurnOn,
                            dismissCheck: { [weak self] () -> Bool in
                                guard let self = self else {
                                    return true
                                }
                                self.viewModel?.permStatistics?.reportPermissionSharePublicAccessClick(click: .turnOn, target: .noneTargetView)
                                if !self.donntShowAgain {
                                    self._showPermissionConfirm(for: type)
                                    return false
                                } else {
                                    self._updatePermissionSetting({ [weak self] in
                                        self?.shareActionManager?.directlyFire(type)
                                    })
                                    return true
                                }
                            },
                            dismissCompletion: {})
        }
        hasShowPermissionTips = true
        var userDefault = CCMKeyValue.globalUserDefault.dictionary(forKey: UserDefaultKeys.showPermissiontTipsEnabled) ?? [:]
        userDefault[shareEntity.encryptedObjToken] = true
        CCMKeyValue.globalUserDefault.setDictionary(userDefault, forKey: UserDefaultKeys.showPermissiontTipsEnabled)
        present(dialog)
        permissionAlert = dialog
    }

    private func _showPermissionConfirm(for type: ShareAssistType) {
        viewModel?.permStatistics?.reportPermissionPromptView(fromScene: .share)
        let config = UDDialogUIConfig()
        config.contentMargin = .zero
        let dialog = UDDialog(config: config)
        // 标题
        dialog.setTitle(text: BundleI18n.SKResource.Doc_Share_Confirm)
        dialog.setContent(view: makeToastMessage(), checkButton: false)
        dialog.setCheckButton(text: "")
        // 按键
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel,
                        dismissCheck: { () -> Bool in return true },
                        dismissCompletion: { [weak self] in
                            self?.viewModel?.permStatistics?.reportPermissionPromptClick(click: .cancel,
                                                                                         target: .noneTargetView,
                                                                                         fromScene: .share)
                            self?.updateDonntShowAgainStatus(status: false)
        })
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_Confirm,
                        dismissCheck: { return true },
                        dismissCompletion: { [weak self] in
                            self?.viewModel?.permStatistics?.reportPermissionPromptClick(click: .confirm,
                                                                                         target: .noneTargetView,
                                                                                         fromScene: .share)
                            self?.permissionAlert?.dismiss(animated: false, completion: { [weak self] in
                                self?._updatePermissionSetting({ [weak self] in
                                    self?.shareActionManager?.directlyFire(type)
                                })
                            })
        })
        permissionAlert?.present(dialog, animated: true, completion: nil)
    }

    // 根据用户是小B/C还是B端以及海内海外版本判断应该显示的文案
    private func makeToastMessage() -> UITextView {
        var msg: String = ""
        let typeString: String
        if shareEntity.type == .minutes {
            typeString = BundleI18n.SKResource.CreationMobile_Minutes_name
        } else if shareEntity.type == .wikiCatalog {
            typeString = BundleI18n.SKResource.CreationMobile_Common_Page
        } else {
            typeString = BundleI18n.SKResource.CreationMobile_Common_Document
        }
        //海外
        guard DomainConfig.envInfo.isChinaMainland == true && !ReleaseConfig.isPrivateKA else {
            msg = BundleI18n.SKResource.Doc_Permission_AnonymousVisitTips_AddVariable(typeString)
            let attritedMsg: NSMutableAttributedString = NSMutableAttributedString(string: msg)
            let paraph = NSMutableParagraphStyle()
            attritedMsg.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], range: NSRange(location: 0, length: msg.count))
            attritedMsg.addAttributes([NSAttributedString.Key.paragraphStyle: paraph], range: NSRange(location: 0, length: msg.count))
            let range = NSRange(location: 0, length: attritedMsg.length)
            attritedMsg.addAttributes([NSAttributedString.Key.foregroundColor: UDColor.textTitle], range: range)
            toastTextView.attributedText = attritedMsg
            return toastTextView
        }
        //国内
        let isToC = (User.current.info?.isToNewC == true)
        if isToC == false {
            msg = BundleI18n.SKResource.Doc_Permission_AnonymousVisitWithPrivacyTips_AddVariable(typeString,
                                                                                                         BundleI18n.SKResource.Doc_Share_ServiceTerm(),
                                                                                                         BundleI18n.SKResource.Doc_Share_Privacy)
        }
        // 向文本中插入超链接
        let attritedMsg: NSMutableAttributedString = NSMutableAttributedString(string: msg)
        let paraph = NSMutableParagraphStyle()
        attritedMsg.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], range: NSRange(location: 0, length: msg.count))
        attritedMsg.addAttributes([NSAttributedString.Key.paragraphStyle: paraph], range: NSRange(location: 0, length: msg.count))
        let range = NSRange(location: 0, length: attritedMsg.length)
        attritedMsg.addAttributes([NSAttributedString.Key.foregroundColor: UDColor.textTitle], range: range)
        guard let serviceRange = msg.range(of: BundleI18n.SKResource.Doc_Share_ServiceTerm()), let privacyRange = msg.range(of: BundleI18n.SKResource.Doc_Share_Privacy) else {
            toastTextView.attributedText = attritedMsg
            return toastTextView
        }
        attritedMsg.addAttributes([NSAttributedString.Key.link: Self.links.0], range: msg.nsrange(fromRange: serviceRange))
        attritedMsg.addAttributes([NSAttributedString.Key.link: Self.links.1], range: msg.nsrange(fromRange: privacyRange))
        toastTextView.attributedText = attritedMsg
        return toastTextView
    }

    /// mina 动态下发 service & privacy URL 解析
    private static let links: (String, String) = {
        if DocsSDK.isInLarkDocsApp {
            guard let docsManagerDelegate = HostAppBridge.shared.call(GetDocsManagerDelegateService()) as? DocsManagerDelegate else {
                DocsLogger.info("no share link toast URL")
                return ("", "")
            }
            let serviceSite = docsManagerDelegate.serviceTermURL
            let privacySite = docsManagerDelegate.privacyURL
            return (serviceSite, privacySite)
        } else {
            guard let config = CCMKeyValue.globalUserDefault.dictionary(forKey: UserDefaultKeys.shareLinkToastURL) else {
                DocsLogger.info("no share link toast URL")
                return ("", "")
            }
            var serviceSite = ""
            var privacySite = ""
            if var serviceURL = config["service_term_url"] as? String {
                serviceSite = "https://" + serviceURL.replacingOccurrences(of: "{lan}", with: DocsSDK.convertedLanguage)
            } else {
                serviceSite = ""
            }
            if var privacyURL = config["privacy_url"] as? String {
                privacySite = "https://" + privacyURL.replacingOccurrences(of: "{lan}", with: DocsSDK.convertedLanguage)
            } else {
                privacySite = ""
            }
            return (serviceSite, privacySite)
        }
     }()

    private func updateDonntShowAgainStatus(status: Bool) {
        var userDefault = CCMKeyValue.globalUserDefault.dictionary(forKey: UserDefaultKeys.showPermissiontTipsEnabled) ?? [:]
        userDefault["showTips"] = status
        CCMKeyValue.globalUserDefault.setDictionary(userDefault, forKey: UserDefaultKeys.showPermissiontTipsEnabled)
    }
    
    private func _updatePermissionSetting(_ completion: (() -> Void)?) {
        self.delegate?.didClickShareLinkToExternal(view: self, completion: completion)
    }

    private func handleSnapshot() {
        if canExportLongImage() {
            delegate?.didRequestExportSnapShot(sharePanel: self)
            return
        }
        let exportPolicyResult = policyResultFor(type: .snapshot)
        if !exportPolicyResult.allow, exportPolicyResult.validateSource == .fileStrategy {
            showInterceptDialogFor(type: .snapshot)
            return
        }
        if !exportPolicyResult.allow, exportPolicyResult.validateSource == .securityAudit {
            UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, on: self.window ?? self)
            return
        }
        if userPermissions?.adminBlocked() == true {
            UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, on: self.window ?? self)
            return
        }
        UDToast.showFailure(with: BundleI18n.SKResource.Doc_Share_DisableExportImageToast, on: self.window ?? self)
    }

    private func reportDidShare(type: ShareAssistType) {
        guard let shareActionManager = shareActionManager else { return }
        var params = getTenantParams()
        params["relegated_flag"] = "\((shareActionManager.shareStatus(type)).rawValue)"
        params["source"] = "\(source.rawValue)"
        params["permission_type"] = getPermissionType()
        params["module"] = shareEntity.type == .folder ? "folder" : "docs"
    
        reporter?.reportDidShare(to: type, params: params)
    }
    
    func getPermissionType() -> String {
        guard let publicPermissionMeta = self.publicPermissionMeta else { return "" }
        switch publicPermissionMeta.linkShareEntity {
        case .close:
            return "turn_off_link_sharing"
        case .tenantCanRead:
            return "colleagues_with_link_can_view"
        case .tenantCanEdit:
            return "colleagues_with_link_can_edit"
        case .anyoneCanRead:
            return "anyone_with_link_can_view"
        case .anyoneCanEdit:
            return "anyone_with_link_can_edit"
        }
    }

    func getLinkPermissionType() -> String {
        guard let publicPermissionMeta = self.publicPermissionMeta else { return "" }
        switch publicPermissionMeta.linkShareEntity {
        case .tenantCanRead:
            return "inner_readable"
        case .tenantCanEdit:
            return "inner_editable"
        default:
            return "private"
        }
    }

    private func getTenantParams() -> [String: String] {
        var params = [String: String]()
        let ownerID = self.shareEntity.ownerID
        let fileTenantID = shareEntity.tenantID
        if !ownerID.isEmpty, !fileTenantID.isEmpty {
            params["file_tenant_id"] = DocsTracker.encrypt(id: fileTenantID)
            let isCrossTenant = (fileTenantID == User.current.info?.tenantID) ? "false" : "true"
            params["file_is_cross_tenant"] = isCrossTenant
        }
        return params
    }
}


extension ShareAssistPanel {

    private func showCopyLinkActionSheet() {
        viewModel?.permStatistics?.reportPermissionShareClick(shareType: shareEntity.type, click: .copyLink, target: .permissionCopyLinkView)
        viewModel?.permStatistics?.reportPermissionCopyLinkView()
        moreActionSheet = UDActionSheet.actionSheet(title: BundleI18n.SKResource.Doc_Facade_CopyLinkHasPasswordDialogTips)
        moreUIActionSheet = UIAlertController(title: BundleI18n.SKResource.Doc_Facade_CopyLinkHasPasswordDialogTips, message: nil, preferredStyle: .actionSheet)
        copyLinkActions = [.linkAndPassWord, .link, .cancel]
        _updateAlertSheetController()
        guard let iphoneAlert = moreActionSheet, let ipaAlert = moreUIActionSheet else {
            return
        }
        delegate?.shouldDisplayCopyLinkAlertSheet(view: self, iphoneAlert: iphoneAlert, ipaAlert: ipaAlert)
    }

    private func _updateAlertSheetController() {
        if SKDisplay.pad {
            addActionsForUIAlert()
        } else {
            addActionsForAlertSheet()
        }
    }

    private func addActionsForUIAlert() {
        copyLinkActions.forEach { (action) in
            var model = convertToAlertAction(action)
            guard !model.isDefault else { return }
            model.style = (action == .cancel ? .cancel : model.style)
            let uiAction = model.convert2UIAlertACtion()
            moreUIActionSheet?.addAction(uiAction)
        }
    }

    private func addActionsForAlertSheet() {
        copyLinkActions.forEach { (action) in
            let model = convertToAlertAction(action)
            guard !model.isDefault else { return }
            if action == .cancel {
                moreActionSheet?.addItem(text: model.title, style: .cancel, action: model.handler)
            } else {
                moreActionSheet?.addItem(text: model.title, action: model.handler)
            }
        }
    }

    private func convertToAlertAction(_ action: CopyLinkAction) -> AlertActionModel {
        switch action {
        case .linkAndPassWord:
            return AlertActionModel(title: BundleI18n.SKResource.Doc_Facade_CopyLinkAndPassword) { [weak self] in
                self?.viewModel?.permStatistics?.reportPermissionCopyLinkClick(click: .copyLinkAndPassword, target: .noneTargetView)
                self?.copyLinkAndPassword()
            }
        case .link:
            return AlertActionModel(title: BundleI18n.SKResource.Doc_Facade_CopyLinkOnly) { [weak self] in
                self?.viewModel?.permStatistics?.reportPermissionCopyLinkClick(click: .copyLink, target: .noneTargetView)
                self?.copyLink()
            }
        case .cancel:
            return AlertActionModel(title: BundleI18n.SKResource.Doc_Facade_Cancel) { [weak self] in
                self?.viewModel?.permStatistics?.reportPermissionCopyLinkClick(click: .cancel, target: .noneTargetView)
            }
        }
    }

    private func copyLink() {
        var shareUrl = shareEntity.shareUrl
        if let idx = shareUrl.firstIndex(of: "?") {
            if (shareEntity.type != .bitable || !UserScopeNoChangeFG.ZJ.btShareAddExtraParam) {
                shareUrl = String(shareUrl[..<idx])
            }
        }
        if shareEntity.isVersion, let vurl = URL(string: shareUrl) {
            shareUrl = vurl.docs.addQuery(parameters: ["edition_id": shareEntity.versionInfo!.version]).absoluteString
        }
        let isSuccess = SKPasteboard.setString(shareUrl,
                               psdaToken: PSDATokens.Pasteboard.docs_share_link_do_copy,
                          shouldImmunity: shareEntity.scPasteImmunity)
        let title = shareEntity.isVersion ?
        BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_Share_Copied_Toast : BundleI18n.SKResource.Doc_Share_LinkCopied
        if isSuccess {
            UDToast.showSuccess(with: title, on: self.window ?? self).observeKeyboard = false
        }
    }
    private func copyLinkAndPassword() {
        guard let perm = publicPermissionMeta,
            perm.hasLinkPassword == true,
            perm.linkPassword.isEmpty == false else {
            copyLink()
            return
        }
        var shareUrl = shareEntity.shareUrl
        if let idx = shareUrl.firstIndex(of: "?") {
            shareUrl = String(shareUrl[..<idx])
        }
        if shareEntity.isVersion, let vurl = URL(string: shareUrl) {
            shareUrl = vurl.docs.addQuery(parameters: ["edition_id": shareEntity.versionInfo!.version]).absoluteString
        }
        let isSuccess = SKPasteboard.setString(BundleI18n.SKResource.Doc_Facade_LinkAndPasswordText(shareUrl, perm.linkPassword),
                               psdaToken: PSDATokens.Pasteboard.docs_share_link_do_copy,
                          shouldImmunity: shareEntity.scPasteImmunity)
        if isSuccess {
            UDToast.showSuccess(with: BundleI18n.SKResource.Doc_Facade_CopyLinkAndPassword + BundleI18n.SKResource.Doc_Normal_Success, on: self.window ?? self)
        }
    }
}

extension ShareAssistPanel: ShareActionManagerDelegate {
    func shareActionManagerWillHandle(manager: ShareActionManager,
                                      type: ShareAssistType,
                                      needFinish: inout Bool) {

    }
    func shareActionManagerDidHandle(manager: ShareActionManager,
                                     type: ShareAssistType) {

    }

    func handleCopyLink() {
        guard let perm = publicPermissionMeta,
            perm.hasLinkPassword == true,
            perm.linkPassword.isEmpty == false else {
            copyLink()
            viewModel?.permStatistics?.reportPermissionShareClick(shareType: shareEntity.type, click: .copyLink, target: .noneTargetView, hasCover: shareEntity.formShareFormMeta?.hasCover)
            delegate?.didClickCopyLink(sharePanel: self)
            return
        }
        showCopyLinkActionSheet()
    }

    func handleCopyPasswordLink(enablePasswordShare: Bool) {
        delegate?.didClickCopyPasswordLink(enablePasswordShare: enablePasswordShare)
    }
}

public final class ShareAssistCell: UICollectionViewCell {

//    enum Const {
//        static let redDotViewWidthHeight: CGFloat = 7
//        static let imageViewWidthHeight: CGFloat = 52
//    }
    
    public private(set) lazy var containerView: SquircleView = {
        let view = SquircleView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.cornerRadius = 12
        view.cornerSmoothness = .natural
        return view
    }()
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.layer.allowsEdgeAntialiasing = true
        view.backgroundColor = .clear
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 10)
        label.numberOfLines = 2
        return label
    }()
    
    private lazy var redDotView: UDBadge = {
        let view = imageView.addBadge(.dot, anchor: .topRight, anchorType: .circle,
                                      offset: .init(width: 0, height: 0))
        view.config.dotSize = .middle
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(imageView)
        contentView.addSubview(titleLabel)

        containerView.snp.makeConstraints { make in
            make.width.height.equalTo(52)
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }

        imageView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(containerView.snp.bottom).offset(8)
        }
        containerView.docs.addStandardLift()
    }

    public func configure(by item: ShareAssistItem) {
        imageView.image = item.image
        titleLabel.text = item.title
        redDotView.isHidden = !item.redDot
        update(isEnabled: item.enable)
    }

    // 整个 panel 被 disabled 时，每个 cell 需要强制 disable
    func forceRenderDisable() {
        update(isEnabled: false)
    }

    private func update(isEnabled: Bool) {
        imageView.alpha = isEnabled ? 1 : 0.3
        titleLabel.textColor = isEnabled ? UDColor.textTitle : UDColor.textDisabled
        redDotView.alpha = isEnabled ? 1 : 0.3
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
