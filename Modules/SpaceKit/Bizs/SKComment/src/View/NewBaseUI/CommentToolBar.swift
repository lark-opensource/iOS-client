//
//  CommentInputToolBar.swift
//  SKCommon
//
//  Created by chenhuaguan on 2021/2/7.
//

import Foundation
import RxSwift
import RxCocoa
import SKFoundation
import AVFoundation
import Speech
import SKUIKit
import SKResource
import LarkUIKit
import LarkReleaseConfig
import UniverseDesignIcon
import SnapKit
import UIKit
import SKCommon
import SKInfra
import SpaceInterface

public final class CommentToolBar: UIView {

    public var forceVoiceButtonHidden: Bool = false {
        didSet {
            self.updateOtherViewLayout()
            //需要根据当前横竖屏状态刷新下布局
            self.updateConstraintsWhenOrientationChangeIfNeed(isChangeLandscape: self.isChangeLandscape)
        }
    }

    weak var delegate: CommentToolBarDelegate?

    private var disposeBag: DisposeBag = DisposeBag()

    /// 发送按钮
    private lazy var sendButton: UIButton = setupSendButton()

    /// @按钮
    private lazy var atButton: UIButton = setupAtButton()

    /// 选择图片按钮
    private lazy var selectImgBtn: UIButton = setupSelectImgBtn()

    /// 语音按钮
    private lazy var voiceButton: UIButton = setupVoiceButton()

    /// 选择框(for drive)
    private lazy var selectBoxButton: UIButton? = self.delegate?.selectBoxButton()
    
    /// 横屏时下掉键盘的按钮
    private lazy var resignKeyboardButton: UIButton = setupResignKeyboardBtn()
    
    /// 横屏时发送按钮左边的分隔线
    private lazy var separateLineWithSend: UIView = setupSeparateLineWithSendBtn()
    
    /// 横屏时收起键盘按钮左边的分隔线
    private lazy var separateLineWithResign: UIView = setupSeparateLineWithResignBtn()
    
    /// 竖屏下的约束
    private var portraitScreenConstraints: [SnapKit.Constraint] = []
    
    /// 横屏下的约束
    private var landscapeScreenConstraints: [SnapKit.Constraint] = []
    
    /// at，语音，图片等图标竖屏下的约束
    private var iconPortraitScreenConstraints: [SnapKit.Constraint] = []
    
    /// at，语音，图片等图标横屏下的约束
    private var iconLandscapeScreenConstraints: [SnapKit.Constraint] = []
    
    ///是否横屏
    private var isChangeLandscape: Bool = false

    private var isLarkDocsApp: Bool {
        return DocsSDK.isInLarkDocsApp
    }

    var requestingURLInfo = false

    struct Metric {
        // nolint-next-line: magic number
        static let btnSize = CGFloat(20)
    }

    init(delegate: CommentToolBarDelegate) {
        super.init(frame: .zero)
        self.delegate = delegate

        _setupUI()
        _setupBind()
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("@")
    }


    public func setSendBtnEnable(enable: Bool) {
        if UserScopeNoChangeFG.HYF.disableSendWhenParsingUrl, requestingURLInfo {
            DocsLogger.info("requesting url return", component: LogComponents.comment)
            return
        }
        sendButton.isEnabled = enable
    }

    public func setVoiceButton(select: Bool? = nil, enable: Bool? = nil) {
        if let enable = enable {
            voiceButton.isEnabled = enable
        }
        if let select = select {
            voiceButton.isSelected = select
        }
    }

    public func setImageButton(select: Bool? = nil, enable: Bool? = nil) {
        let allow = checkUploadPermission()
        if !allow {
            selectImgBtn.isSelected = false
            selectImgBtn.isEnabled = true
        } else {
            if let enable = enable {
                selectImgBtn.isEnabled = enable
            }
            if let select = select {
                selectImgBtn.isSelected = select
            }
        }
    }

    private func checkUploadPermission() -> Bool {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
            let request = PermissionRequest(entity: .ccm(token: "", type: .file),
                                            operation: .uploadAttachment,
                                            bizDomain: .ccm)
            return permissionSDK.validate(request: request).allow
        } else {
            return AdminPermissionManager.adminCanUpload()
        }
    }

    public func setAtButton(select: Bool? = nil, enable: Bool? = nil) {
        if let enable = enable {
            atButton.isEnabled = enable
        }
        if let select = select {
            atButton.isSelected = select
        }
    }
    
    public var isSelectingImage: Bool {
        return selectImgBtn.isSelected
    }

    public var isSelectingVoice: Bool {
        return voiceButton.isSelected
    }

    deinit {
    }
}


extension CommentToolBar {
    private func _setupBind() {
        sendButton.rx.tap
            .observeOn(MainScheduler.instance)
            .bind { [weak self] in
                self?.didClickSendBtn()
            }.disposed(by: disposeBag)

        atButton.rx.tap
            .bind { [weak self] in
                self?.didClickAtBtn()
            }.disposed(by: disposeBag)

        selectImgBtn.rx.tap
            .bind { [weak self] in
                self?.didClickImageBtn()
            }.disposed(by: disposeBag)
        
        resignKeyboardButton.rx.tap
            .bind { [weak self] in
                self?.didClickResignKeyboard()
            }.disposed(by: disposeBag)

        DocsNetStateMonitor.shared.addObserver(self) { [weak self] (_, isReachable) in
            self?.setVoiceButton(enable: isReachable)
            self?.setAtButton(enable: isReachable)
            self?.setImageButton(enable: isReachable)
        }
    }


    private var supportInsertPic: Bool {
        return delegate?.supportPic ?? false
    }

    private var supportShowPic: Bool {
        return delegate?.supportPic ?? false
    }

    private var supportAt: Bool {
        // 匿名用户屏蔽at按钮
        return (User.current.basicInfo?.isGuest ?? false) == false
    }

    private var supportVoice: Bool {
        var externalSupport = delegate?.supportVoice ?? true
        return (forceVoiceButtonHidden == false) &&
            (DocsSDK.isInLarkDocsApp == false) &&
            (ReleaseConfig.isPrivateKA == false) && externalSupport
    }
    
    private var supportSelectBox: Bool {
        return selectBoxButton != nil
    }

    private var showOnPadComment: Bool {
        return Display.pad
    }

    // nolint: magic number
    private func _setupUI() {
        addSubview(sendButton)
        addSubview(atButton)
        addSubview(selectImgBtn)
        addSubview(voiceButton)
        addSubview(resignKeyboardButton)
        addSubview(separateLineWithResign)
        addSubview(separateLineWithSend)
        if let selectBoxButton = selectBoxButton {
            addSubview(selectBoxButton)
        }
        //iPad Highlight
        sendButton.docs.addHighlight(with: UIEdgeInsets(top: -5, left: -5, bottom: -5, right: -5), radius: 4)
        resignKeyboardButton.docs.addHighlight(with: UIEdgeInsets(top: -5, left: -5, bottom: -5, right: -5), radius: 4)
        atButton.docs.addHighlight(with: UIEdgeInsets(top: -5, left: -5, bottom: -5, right: -5), radius: 4)
        selectImgBtn.docs.addHighlight(with: UIEdgeInsets(top: -5, left: -5, bottom: -5, right: -5), radius: 4)
        voiceButton.docs.addHighlight(with: UIEdgeInsets(top: -5, left: -5, bottom: -5, right: -5), radius: 4)
        selectBoxButton?.docs.addHighlight(with: UIEdgeInsets(top: -5, left: -5, bottom: -5, right: -5), radius: 4)

        // 收起键盘按钮（仅横屏）
        resignKeyboardButton.snp.makeConstraints { (make) in
            if delegate?.supportLandscapeConstraint == true {
                landscapeScreenConstraints.append(make.right.equalToSuperview().offset(-40).constraint)
                landscapeScreenConstraints.append(make.left.equalTo(separateLineWithResign.snp.right).offset(16).constraint)
                landscapeScreenConstraints.append(make.width.height.equalTo(24).constraint)
            }
            
            portraitScreenConstraints.append(make.width.height.equalTo(0).constraint)
            make.centerY.equalTo(sendButton)
        }
        
        // 收起键盘按钮左边的分隔线（仅横屏）
        separateLineWithResign.snp.makeConstraints { (make) in
            if delegate?.supportLandscapeConstraint == true {
                landscapeScreenConstraints.append(make.left.equalTo(sendButton.snp.right).offset(16).constraint)
                landscapeScreenConstraints.append(make.width.equalTo(2).constraint)
                landscapeScreenConstraints.append(make.top.bottom.equalToSuperview().constraint)
                landscapeScreenConstraints.append(make.centerY.equalToSuperview().constraint)
            }
            
            portraitScreenConstraints.append(make.width.height.equalTo(0).constraint)
        }
        
        // 右边发送按钮
        sendButton.snp.makeConstraints { (make) in
            portraitScreenConstraints.append(make.right.equalToSuperview().offset(-16).constraint)
            if delegate?.supportLandscapeConstraint == true {
                landscapeScreenConstraints.append(make.left.equalTo(separateLineWithSend.snp.right).offset(16).constraint)
            }
            let height: CGFloat = showOnPadComment ? 18 : 24
            make.height.equalTo(height)
            make.width.equalTo(height + 1)
            make.centerY.equalToSuperview()
        }

        // 发送按钮左边的分隔线（仅横屏）
        separateLineWithSend.snp.makeConstraints { (make) in
            if delegate?.supportLandscapeConstraint == true {
                landscapeScreenConstraints.append(make.left.equalTo(selectImgBtn.snp.right).offset(16).constraint)
                landscapeScreenConstraints.append(make.width.equalTo(1).constraint)
                landscapeScreenConstraints.append(make.top.bottom.equalTo(sendButton).constraint)
            }
            
            portraitScreenConstraints.append(make.width.height.equalTo(0).constraint)
        }
        
        sendButton.accessibilityIdentifier = "docs.comment.button.send"
        atButton.accessibilityIdentifier = "docs.comment.button.at"
        let canUpload: Bool
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            // FG 开，综合判断
            canUpload = checkUploadPermission()
        } else {
            // FG 关，分开判断 admin + CAC
            canUpload = checkUploadPermission() && (delegate?.enabledWhenPictureSupported == true)
        }
        if !canUpload {
            let image = BundleResources.SKResource.Common.Global.icon_global_image_nor.withColor(UIColor.ud.N600.withAlphaComponent(0.3))
            selectImgBtn.setImage(image, for: .normal)
            setImageButton(enable: true)
        }

        updateOtherViewLayout()
    }
    // enable-lint: magic number

    // nolint: magic number
    private func updateOtherViewLayout() {
        //这个方法会不同的地方调用更新UI，所以需要清除下横竖屏的记录的约束
        iconPortraitScreenConstraints.removeAll()
        iconLandscapeScreenConstraints.removeAll()
        
        // 在iPad上间距会小一点
        let itemMargin: CGFloat = showOnPadComment ? 20 : 40
        let iconLength: CGFloat = showOnPadComment ? 18 : 24
        
        // 横屏下的按钮间距
        let itemMarginLandscape: CGFloat = 10
            
        // at,匿名下at不展示
        atButton.snp.remakeConstraints { (make) in
            make.width.height.equalTo(supportAt ? iconLength : 0)
            make.centerY.equalTo(sendButton)
            iconPortraitScreenConstraints.append(make.left.equalTo(supportAt ? 16 : 0).constraint)
            if delegate?.supportLandscapeConstraint == true {
                iconLandscapeScreenConstraints.append(make.left.equalToSuperview().offset(supportAt ? 16 : 0).constraint)
            }
        }

        // 语音输入
        voiceButton.snp.remakeConstraints { (make) in
            let hadBtnOnLeft = supportAt
            make.centerY.equalTo(atButton)
            make.width.height.equalTo(supportVoice ? iconLength : 0)
            iconPortraitScreenConstraints.append(make.left.equalTo(atButton.snp.right).offset(supportVoice ? (hadBtnOnLeft ? itemMargin : 16) : 0).constraint)
            if delegate?.supportLandscapeConstraint == true {
                iconLandscapeScreenConstraints.append(make.left.equalTo(atButton.snp.right).offset(supportVoice ? (hadBtnOnLeft ? itemMarginLandscape : 16) : 0).constraint)
            }
        }

        // 插入图片，fg控制
        selectImgBtn.snp.remakeConstraints { (make) in
            let hadBtnOnLeft = supportAt || supportVoice
            make.centerY.equalTo(sendButton)
            make.width.height.equalTo(supportInsertPic ? iconLength : 0)
            iconPortraitScreenConstraints.append(make.left.equalTo(voiceButton.snp.right).offset(supportInsertPic ? (hadBtnOnLeft ? itemMargin : 16) : 0).constraint)
            if delegate?.supportLandscapeConstraint == true {
                iconLandscapeScreenConstraints.append(make.left.equalTo(voiceButton.snp.right).offset(supportInsertPic ? (hadBtnOnLeft ? itemMarginLandscape : 16) : 0).constraint)
            }
            
        }

        if let selectBoxButton = selectBoxButton {
            selectBoxButton.snp.remakeConstraints { (make) in
                let hadBtnOnLeft = supportAt || supportVoice || supportInsertPic
                make.centerY.equalTo(atButton)
                iconPortraitScreenConstraints.append(make.width.height.equalTo(iconLength).constraint)
                iconPortraitScreenConstraints.append(make.left.equalTo(selectImgBtn.snp.right).offset(hadBtnOnLeft ? itemMargin : 16).constraint)
                if delegate?.supportLandscapeConstraint == true {
                    iconLandscapeScreenConstraints.append(make.left.equalTo(selectImgBtn.snp.right).offset(hadBtnOnLeft ? itemMarginLandscape : 16).constraint)
                }
            }
        }
    }
    // enable-lint: magic number

}

extension CommentToolBar {

    @objc
    private func didClickSendBtn() {
        DocsLogger.info("button clickSendIcon", component: LogComponents.comment)
        delegate?.didClickSendIcon(select: sendButton.isSelected)
    }

    @objc
    private func didClickAtBtn() {
        delegate?.didClickAtIcon(select: atButton.isSelected)
    }

    @objc
    private func didClickImageBtn() {
        delegate?.didClickInsertImageIcon(select: selectImgBtn.isSelected)
    }
    
    @objc
    private func didClickResignKeyboard() {
        delegate?.didClickResignKeyboardBtn(select: true)
    }

    @objc
    private func voiceTap(_ gesture: UITapGestureRecognizer) {
        self.delegate?.didClickVoiceIcon(gesture)
    }

    @objc
    private func voiceLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
          case .began:
            self.setVoiceButton(select: true)
          case .ended:
            self.setVoiceButton(select: false)
          default:
              break
          }
        self.delegate?.didLongPressVoiceBtn(gesture)
    }
    
    @objc
    private func applicationWillResignActive(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.willResignActive()
        }
    }
}


class CommentToolButton: UIButton {
    
    /// 按钮点击范围扩大，宽高不满40按40的范围处理， 超过40按照按钮自身宽高处理
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard self.bounds.size != .zero else {
            return false
        }
        let min: CGFloat = 40
        let w = CGFloat.maximum(min - bounds.width, 0) / 2.0
        let h = CGFloat.maximum(min - bounds.height, 0) / 2.0
        let rect = bounds.insetBy(dx: -w, dy: -h)
        return rect.contains(point)
    }
}

extension CommentToolBar {
    private func setupSendButton() -> UIButton {
        let button = UIButton()
        let image = UDIcon.sendColorful.ud.withTintColor(UIColor.ud.primaryContentDefault)
        let disableImage = image.ud.withTintColor(UIColor.ud.primaryContentLoading)
        button.setImage(image, for: .normal)
        button.setImage(disableImage, for: .disabled)
        return button
    }

    private func setupAtButton() -> UIButton {
        let button = CommentToolButton()
        let size = CGSize(width: Metric.btnSize, height: Metric.btnSize)
        let udImage = UDIcon.getIconByKey(.atOutlined, renderingMode: .alwaysOriginal, size: size)
        let image = udImage.ud.withTintColor(UIColor.ud.iconN2)
        let selImage = udImage.ud.withTintColor(UIColor.ud.colorfulBlue)
        button.setImage(image, for: .normal)
        button.setImage(selImage, for: .selected)
        return button
    }

    private func setupSelectImgBtn() -> UIButton {
        let button = CommentToolButton()
        let size = CGSize(width: Metric.btnSize, height: Metric.btnSize)
        let udImage = UDIcon.getIconByKey(.imageOutlined, renderingMode: .alwaysOriginal, size: size)
        let image = udImage.ud.withTintColor(UIColor.ud.iconN2)
        let selImage = udImage.ud.withTintColor(UIColor.ud.colorfulBlue)
        button.setImage(image, for: .normal)
        button.setImage(selImage, for: .selected)
        return button
    }

    private func setupVoiceButton() -> UIButton {
        let button = CommentToolButton()
        let size = CGSize(width: Metric.btnSize, height: Metric.btnSize)
        let udImage = UDIcon.getIconByKey(.voiceOutlined, renderingMode: .alwaysOriginal, size: size)
        let image = udImage.ud.withTintColor(UIColor.ud.iconN2)
        let selImage = udImage.ud.withTintColor(UIColor.ud.colorfulBlue)
        button.setImage(image, for: .normal)
        button.setImage(selImage, for: .selected)

        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(voiceTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        button.addGestureRecognizer(tapGesture)
        // 长按手势
        let longPressGesture = UILongPressGestureRecognizer()
        longPressGesture.addTarget(self, action: #selector(voiceLongPress(_:)))
        button.addGestureRecognizer(longPressGesture)

        return button
    }
    
    private func setupResignKeyboardBtn() -> UIButton {
        let button = CommentToolButton()
        // nolint-next-line: magic number
        let size = CGSize(width: 25, height: 25)
        let udImage = UDIcon.getIconByKey(.keyboardDisplayOutlined, renderingMode: .alwaysOriginal, size: size)
        let image = udImage.ud.withTintColor(UIColor.ud.iconN2)
        button.setImage(image, for: .normal)
        return button
    }
    
    private func setupSeparateLineWithSendBtn() -> UIView {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }
    
    private func setupSeparateLineWithResignBtn() -> UIView {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = UIColor.ud.N50
        return view
    }
}

extension CommentToolBar {
    /// 根据是否支持横屏下评论和当前设备横竖屏状态更改
    public func updateConstraintsWhenOrientationChangeIfNeed(isChangeLandscape: Bool) {
        self.isChangeLandscape = isChangeLandscape
        
        if isChangeLandscape {
            portraitScreenConstraints.forEach { $0.deactivate() }
            landscapeScreenConstraints.forEach { $0.activate() }
            
            iconPortraitScreenConstraints.forEach { $0.deactivate() }
            iconLandscapeScreenConstraints.forEach { $0.activate() }
        } else {
            landscapeScreenConstraints.forEach { $0.deactivate() }
            portraitScreenConstraints.forEach { $0.activate() }
            
            iconLandscapeScreenConstraints.forEach { $0.deactivate() }
            iconPortraitScreenConstraints.forEach { $0.activate() }
        }
    }
}
