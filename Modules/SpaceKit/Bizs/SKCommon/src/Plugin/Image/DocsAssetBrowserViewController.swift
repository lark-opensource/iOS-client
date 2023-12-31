//
//  DocsAssetBrowserViewController.swift
//  SpaceKit
//
//  Created by nine on 2019/1/29.
//

import SKFoundation
import LarkUIKit
import EENavigator
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignDialog
import SpaceInterface

public protocol DocsAssetBrowserViewControllerDelegate: AnyObject {
    func updateViewToolStatus(vc: DocsAssetBrowserViewController, imageData: PhotoImageData, mainToolStatus: PhotoToolStatus?)
}

public final class DocsAssetBrowserViewController: SKAssetBrowserViewController {

    static let rightGapDefault: CGFloat = 15.0
    static let rightGapHadSaveBtn: CGFloat = 63.0
    static let buttonWidth: CGFloat = 32.0
    static let buttonCornerRadius = 8.0
    public weak var commentDelegate: PhotoCommentDelegate?
    public weak var deleteDelegate: PhotoDeleteActionDelegate?
    public weak var editDelegate: PhotoEditActionDelegate?
    public weak var orientationDelegate: PhotoBrowserOrientationDelegate?
    public weak var browserVCDelegate: DocsAssetBrowserViewControllerDelegate?
    public var toolStatus: PhotoToolStatus? //控件栏展示状态
    private var orientationObserver: OrientationObserver?
//    public weak var atInputTextView: AtInputTextView?
    private var pageIndex: Int {
        return currentPageIndex
    }
    public let watermarkConfig = WatermarkViewConfig()
    /// 组件不支持横屏，需要强制竖屏，具有最高优先级
    public var forcePortraitMask: UIInterfaceOrientationMask?
    public var openImagePermission: OpenImagePermission?

    private lazy var commentButton: UIButton = {
        let button = UIButton(type: .custom)
        button.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        button.backgroundColor = UDColor.N600.withAlphaComponent(0.6)
        button.isHidden = isSavePhotoButtonHidden
        button.layer.cornerRadius = Self.buttonCornerRadius
        button.layer.masksToBounds = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.addTarget(self, action: #selector(commentoButtonClicked), for: .touchUpInside)
        let icon = UDIcon.getIconByKey(.addCommentOutlined, renderingMode: .alwaysOriginal, size: CGSize(width: 20, height: 20))
        button.setImage(icon.ud.withTintColor(UDColor.primaryOnPrimaryFill), for: .normal)
        return button
    }()

    fileprivate lazy var deleteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        button.backgroundColor = UDColor.N600.withAlphaComponent(0.6)
        button.isHidden = isSavePhotoButtonHidden
        button.layer.cornerRadius = Self.buttonCornerRadius
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(deleteButtonClicked), for: .touchUpInside)
        let icon = UDIcon.getIconByKey(.deleteTrashOutlined, renderingMode: .alwaysOriginal, size: CGSize(width: 20, height: 20))
        button.setImage(icon.ud.withTintColor(UDColor.primaryOnPrimaryFill), for: .normal)
        return button
    }()

    fileprivate lazy var editButton: UIButton = {
        let button = UIButton(type: .custom)
        button.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        button.backgroundColor = UDColor.N600.withAlphaComponent(0.6)
        button.isHidden = isSavePhotoButtonHidden
        button.layer.cornerRadius = Self.buttonCornerRadius
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(editButtonClicked), for: .touchUpInside)
        button.setImage(BundleResources.SKResource.Common.Tool.icon_tool_edit_nor.ud.withTintColor(UDColor.N00), for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }()

    required public init(assets: [LKDisplayAsset],
                         pageIndex: Int,
                         actionHandler: SKAssetBrowserActionHandler = SKAssetBrowserActionHandler()) {
        super.init(assets: assets, pageIndex: pageIndex, actionHandler: actionHandler)
        //增加屏幕旋转监听
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(statusBarOrientationChange),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
        
        // 组件不支持，需要强制竖屏
        _ = NotificationCenter.default.addObserver(
              forName: Notification.Name.commentForcePotraint,
              object: nil,
              queue: nil) { [weak self] (_) in
                guard let self = self else { return }
                self.handleForcePortrait()
        }
        _ = NotificationCenter.default.addObserver(
            forName: Notification.Name.commentCancelForcePotraint,
            object: nil,
            queue: nil) { [weak self] (_) in
                guard let self = self else { return }
                self.handleCacelForcePortrait()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
      // 是否永久隐藏评论按钮，当被设置为 true 时，showCommentButton 会被理解设置为 false，且后续 showCommentButton 会失效。
    public var isAlwayHideCommentButton: Bool = false {
        didSet {
            if isAlwayHideCommentButton {
                showCommentButton = false
            }
        }
    }
    
    // 控制是否展示评论按钮
    public var showCommentButton: Bool = false {
        didSet {
            // 这里进行拦截，isAlwayHideComemntButton 为 true，且设置的值为 ture 时，将其重置为 false。
            if isAlwayHideCommentButton {
                if showCommentButton {
                    showCommentButton = false
                }
                commentButton.isHidden = true
            } else {
                commentButton.isHidden = !showCommentButton
            }
        }
    }

    // 控制是否展示删除按钮
    public var showDeleteButton: Bool = false {
        didSet {
            deleteButton.isHidden = !showDeleteButton
        }
    }

    public var showSavePhotoButton: Bool = false {
        didSet {
            isSavePhotoButtonHidden = !showSavePhotoButton
            longPressEnable = showSavePhotoButton
            self.savePhotoButton.isHidden = isSavePhotoButtonHidden
        }
    }
    
    /// 置灰（非禁用）
    public var savePhotoButtoGrayStyle: Bool = false {
        didSet {
            self.savePhotoButton.alpha = savePhotoButtoGrayStyle ? 0.5 : 1
        }
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        isAutoHideButton = false
        let rightGap = showSavePhotoButton ? Self.rightGapHadSaveBtn : Self.rightGapDefault
        view.addSubview(commentButton)
        commentButton.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: Self.buttonWidth, height: Self.buttonWidth))
            make.right.equalToSuperview().offset(-rightGap)
            make.centerY.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-22)
        }
        commentButton.isHidden = !showCommentButton
        view.addSubview(deleteButton)
        deleteButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-rightGap)
            make.size.equalTo(CGSize(width: Self.buttonWidth, height: Self.buttonWidth))
            make.centerY.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-22)
        }
        deleteButton.isHidden = !showDeleteButton
        view.addSubview(editButton)
        editButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-22)
            if showCommentButton {
                make.right.equalTo(commentButton.snp.left).offset(-20)
            } else {
                make.right.equalToSuperview().offset(-rightGap)
            }
            make.size.equalTo(CGSize(width: Self.buttonWidth, height: Self.buttonWidth))
        }
        editButton.isHidden = true
        if currentPageIndex < photoImageDatas.count {
            editButton.isHidden = photoImageDatas[currentPageIndex].token?.isEmpty ?? true
        }
        reloadCommentButton()
        watermarkConfig.add(to: view)
        // 屏幕旋转需要埋点
        prepareForOrientationDidChange()
    }

    public override var prefersStatusBarHidden: Bool {
        return true
    }

    public func updateBottomLayout() {
        guard commentButton.superview != nil,
        deleteButton.superview != nil else {
            return
        }
        let rightGap = showSavePhotoButton ? Self.rightGapHadSaveBtn : Self.rightGapDefault
        commentButton.snp.updateConstraints { make in
            make.right.equalToSuperview().offset(-rightGap)
        }
        deleteButton.snp.updateConstraints { make in
            make.right.equalToSuperview().offset(-rightGap)
        }
        if !editButton.isHidden, editButton.superview != nil {
            editButton.snp.remakeConstraints { (make) in
                make.centerY.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-22)
                if showCommentButton {
                    make.right.equalTo(commentButton.snp.left).offset(-20)
                } else {
                    make.right.equalToSuperview().offset(-rightGap)
                }
                make.size.equalTo(CGSize(width: Self.buttonWidth, height: Self.buttonWidth))
            }
        }
    }

    override public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let forceMask = forcePortraitMask {
            return forceMask
        }
        //是否支持手机横屏评论
        if DocsType.commentSupportLandscapaeFg && !SKDisplay.pad && self.supportCommentWhenLandscape {
            return .allButUpsideDown
        }
        return super.supportedInterfaceOrientations
    }

    override public func currentPageIndexWillChange(_ newValue: Int) {
        super.currentPageIndexWillChange(newValue)

        if newValue != currentPageIndex {
            commentDelegate?.docsAssetBrowser(self, statisticsAction: "switch")
        }
        reloadEditButtonStatus(index: newValue)
        reloadCommentButtonStatus(index: newValue)
        updateToolStatus(newValue)
    }

    public func reloadCommentButton() {
        reloadCommentButtonStatus(index: pageIndex)
    }

    private func prepareForOrientationDidChange() {
        guard let info = orientationDelegate?.docsAssetBrowserTrackForOrientationDidChange(self) else { return }
        orientationObserver = OrientationObserver(docsInfo: info, source: .image)
    }

    @objc
    func commentoButtonClicked() {
        guard let d = commentDelegate else { DocsLogger.error("没有实现图片评论所需要的事件协议", component: LogComponents.comment) ; return }
        guard pageIndex < photoImageDatas.count else {
            DocsLogger.error("pageIndex: \(pageIndex) is out of range count:\(photoImageDatas.count)", component: LogComponents.comment)
            return
        }
        guard let uuid = photoImageDatas[pageIndex].uuid else { DocsLogger.error("没有找到这张图片的udid", component: LogComponents.comment) ; return }
        // DocX下评论&回复支持横屏
        if supportCommentWhenLandscape {
            d.showComment(with: uuid)
            d.docsAssetBrowser(self, statisticsAction: "send_comment")
        } else { // 其他：评论&回复评论不支持横屏
            LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) { [weak self] in
                guard let self = self else { return }
                d.showComment(with: uuid)
                d.docsAssetBrowser(self, statisticsAction: "send_comment")
            }
        }
    }

    @objc
    func deleteButtonClicked() {
        let dialog = UDDialog()
        dialog.isAutorotatable = true
        // 内容
        dialog.setContent(text: BundleI18n.SKResource.Doc_Doc_DeleteImageConfirm, style: .defaultContentStyle)
        // 取消按钮
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel)
        // 移除按钮
        dialog.addDestructiveButton(text: BundleI18n.SKResource.Doc_Facade_Confirm, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            let currentPageIndex = self.pageIndex
            self.deleteDelegate?.deleteImg(with: self.photoImageDatas[currentPageIndex].uuid ?? "")
            self.commentDelegate?.docsAssetBrowser(self, statisticsAction: "delete_image_confirm")
        })
        present(dialog, animated: false)
        commentDelegate?.docsAssetBrowser(self, statisticsAction: "delete_image")
    }

    @objc
    func editButtonClicked() {
        //通知前端点击了图片查看器页面的编辑按钮
        self.dismiss(animated: true, completion: { [weak self] in
            guard let self = self else { return }
            self.editDelegate?.clickEdit(photoToken: self.photoImageDatas[self.currentPageIndex].token ?? "", uuid: self.photoImageDatas[self.currentPageIndex].uuid ?? "")
        })
    }
    
    deinit {
        let name = PowerConsumptionStatisticEventName.assetBrowseLeave
        PowerConsumptionExtendedStatistic.addEvent(name: name, params: nil)
    }
    
    @objc
    func statusBarOrientationChange() {
        self.updateConstraintsWhenOrientationChangeIfNeed()
    }
    
    public override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        DocsLogger.info("dismiss + \(ObjectIdentifier(self))", component: LogComponents.commentPic)
    }
    
    //弹出dialog确定当前正在展示图片已被删除按钮事件
    public func confirmDeleted(with info: DeleteAlertInfo?) {
        guard let imgList = info?.tempImgList,
              let assects = info?.tempAssects else { return }
        let lastCurrentPageIndex = currentPageIndex
        let lastCurrentImgID = currentPhotoUdid()
        var newCurrentPageIndex = lastCurrentPageIndex
        for (index, img) in imgList.enumerated() where img.uuid == lastCurrentImgID {
            newCurrentPageIndex = index
        }
        if imgList.count == 0 {
            // 退出查看器
            self.dismissViewController(completion: nil)
        } else if lastCurrentPageIndex >= imgList.count {
            // 没有下一张 则跳转到上一张
            if lastCurrentPageIndex - 1 < imgList.count {
                newCurrentPageIndex = lastCurrentPageIndex - 1
            } else if lastCurrentPageIndex < imgList.count {
                newCurrentPageIndex = lastCurrentPageIndex
            } else {
                newCurrentPageIndex = 0
            }
        } else {
            // 跳转到下一张
            newCurrentPageIndex = (lastCurrentPageIndex < imgList.count) ? lastCurrentPageIndex : 0
        }
        self.reloadAssets(assects, newCurrentPageIndex: newCurrentPageIndex)
        self.photoImageDatas = imgList
        self.reloadCommentButton()
    }
    
    /// 设置`保存`按钮是否隐藏
    public func setSaveButtonHidden(_ isHidden: Bool) {
        self.showSavePhotoButton = !isHidden
        self.savePhotoButton.isHidden = isHidden // 组件内未立即刷新,这里手动调用一下
        self.updateBottomLayout()
    }
}

private extension DocsAssetBrowserViewController {
    func setCommentButtonNum(_ num: Int) {
        if isSavePhotoButtonHidden {
            if commentButton.superview != nil {
                commentButton.snp.updateConstraints { (make) in
                    make.right.equalToSuperview().offset(-Self.rightGapDefault)
                }
            }
        }
        if num == 0 {
            commentButton.imageEdgeInsets = .zero
            commentButton.titleEdgeInsets = .zero
            commentButton.setTitle("", for: .normal)
            commentButton.snp.updateConstraints { (make) in
                make.size.equalTo(CGSize(width: Self.buttonWidth, height: Self.buttonWidth))
            }
        } else {
            let numberWidth = CGFloat(num.digit * 8)
            commentButton.snp.updateConstraints { (make) in
                make.size.equalTo(CGSize(width: 43 + numberWidth, height: Self.buttonWidth))
            }
            commentButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 7, bottom: 0, right: 11 + numberWidth / 2)
            commentButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 13, bottom: 0, right: 5)
            commentButton.setTitle("\(num)", for: .normal)
        }
        DocsLogger.info("commentButton title set:\(commentButton.title(for: .normal) ?? ""), num:\(num)", component: LogComponents.commentPic)
    }

    func reloadCommentButtonStatus(index: Int) {
        guard let d = commentDelegate else { DocsLogger.error("没有实现图片评论所需要的事件协议") ; return }
        guard photoImageDatas.count > index, let uuid = photoImageDatas[index].uuid else { DocsLogger.error("没有找到这张图片的udid") ; return }
        setCommentButtonNum(d.commentCount(with: uuid))
        commentButton.isEnabled = d.commentable(with: uuid)
    }

    func reloadEditButtonStatus(index: Int) {
        guard photoImageDatas.count > index,
              photoImageDatas[index].uuid != nil else {
            DocsLogger.error("没有找到这张图片的udid")
            return
        }
        editButton.isHidden = (photoImageDatas[index].token == nil ||
                                (photoImageDatas[index].token?.isEmpty ?? true))
    }
    
    private func updateToolStatus(_ index: Int) {
        guard index >= 0, index < photoImageDatas.count else {
            return
        }
        
        if UserScopeNoChangeFG.LJY.enableSyncBlock {
            // 回调到service统一更新图片查看器的权限，避免维护下面的相似逻辑
            if let delegate = self.browserVCDelegate {
                delegate.updateViewToolStatus(vc: self, imageData: photoImageDatas[index], mainToolStatus: self.toolStatus)
                return
            }
            spaceAssertionFailure()
        }
        
        let openImagePermission = self.openImagePermission ?? OpenImagePermission(canCopy: true,
                                                                                  canShowDownload: true,
                                                                                  canDownloadDoc: true,
                                                                                  canDownloadAttachment: true)
        let isDiagramSVG = photoImageDatas[index].uuid?.isDiagramSVG ?? false
        let canAdminDownload = isDiagramSVG ? openImagePermission.canDownloadDoc : openImagePermission.canDownloadAttachment
        
        if let toolStatus = self.toolStatus {
            if let curShouldShowComment = toolStatus.comment, curShouldShowComment != self.showCommentButton {
                self.showCommentButton = curShouldShowComment
            }
            if let curShouldShowDelete = toolStatus.delete, curShouldShowDelete != self.showDeleteButton {
                self.showDeleteButton = curShouldShowDelete
            }
            if let curShouldShowSavePhoto = toolStatus.export, curShouldShowSavePhoto != self.showSavePhotoButton {
                self.showSavePhotoButton = curShouldShowSavePhoto && openImagePermission.canShowDownload
            }
            self.savePhotoButtoGrayStyle = !canAdminDownload
            if let canCopy = toolStatus.copy {
                setAllowCapture(canCopy)
            }
        }
        // 加入前端设置了single_tool_status，需要对这种情况单独配置
        if let subToolStatus = photoImageDatas[index].subToolStatus {
            if let curShouldShowComment = subToolStatus.comment, curShouldShowComment != self.showCommentButton {
                self.showCommentButton = curShouldShowComment
            }
            if let curShouldShowDelete = subToolStatus.delete, curShouldShowDelete != self.showDeleteButton {
                self.showDeleteButton = curShouldShowDelete
            }
            if let curShouldShowSavePhoto = subToolStatus.export, curShouldShowSavePhoto != self.showSavePhotoButton {
                self.showSavePhotoButton = curShouldShowSavePhoto && openImagePermission.canShowDownload
            }
            self.savePhotoButtoGrayStyle = !canAdminDownload
            if let canCopy = subToolStatus.copy {
                setAllowCapture(canCopy)
            }
        }
        self.updateBottomLayout()
    }
}

private extension Int {
    /// 得到当前数字是几位数
    var digit: Int {
        var digit = 0
        var temp = self
        while temp != 0 { digit += 1; temp /= 10 }
        return digit
    }
}

extension DocsAssetBrowserViewController {
    func updateConstraintsWhenOrientationChangeIfNeed() {
        // atInputTextView?.updateConstraintsWhenOrientationChangeIfNeed()
    }
}

extension DocsAssetBrowserViewController {
    func handleForcePortrait() {
        if !SKDisplay.pad, DocsType.commentSupportLandscapaeFg {
            self.forcePortraitMask = .portrait
        }
    }
    
    func handleCacelForcePortrait() {
        if !SKDisplay.pad, DocsType.commentSupportLandscapaeFg {
            self.forcePortraitMask = nil
        }
    }
}
