// 
// Created by duanxiaochen.7 on 2020/3/16.
// Affiliated with DocsSDK.
// 
// Description:

import Foundation
import SKCommon
import SKResource
import UniverseDesignEmpty
import UniverseDesignIcon
import UniverseDesignColor
import SKUIKit
import SKFoundation
import UniverseDesignNotice
import Lottie

enum BTRecordHeaderViewMode {
    case normal // 正常模式
    case transparent // 透明模式
}

enum BTRecordHeaderNoticeType {
    case none // 普通无notice
    case proAdd // 高级权限，添加的Notice
    case archived // 记录被归档的notice
    case filtered // 记录被视图过滤
}

final class BTRecordHeaderView: UIView {
    
    // 简单的view不想设计的太复杂，就用结构体代替protocol了
    struct DataSource {
        var mode: BTRecord.Mode = .normal
        var topColor: UIColor = UDColor.primaryContentDefault
        var title: NSAttributedString = NSAttributedString(string: "")
        var canDelete = false
        var canAddRecord = false
        var shouldShowSubmitTopTip = false
        var canShare = false
        var btViewMode: BTViewMode
        var viewMode: BTRecordHeaderViewMode = .normal
        var closeIconType: CloseIconType = .leftOutlined
        var coverChangeAble = false
        var subscribeStatue: BTRecordSubscribeStatus = .unknown
        var isArchived: Bool = false // 是否被归档
        var shouldShowFilteredTips = false  // 是否显示被过滤的提示
        var noticeType: BTRecordHeaderNoticeType {
            if isArchived && (mode == .indRecord || mode == .stage) {
                return .archived
            } else if shouldShowSubmitTopTip && mode == .submit {
                return .proAdd
            } else if shouldShowFilteredTips && UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable {
                return .filtered
            }
            return .none
        }
    }
    
    private lazy var topBar = UIView().construct { it in
        it.backgroundColor = UDColor.primaryContentDefault
    }

    private lazy var topMaskView = UIView().construct { it in
        it.backgroundColor = .clear
    }
    
    private lazy var contentView = UIView().construct { it in
        it.backgroundColor = .clear
    }
    

    // Common Mode Subviews
    private lazy var titleTextView = BTReadOnlyTextView().construct { it in
        it.textContainer.maximumNumberOfLines = 1
        it.textContainer.lineBreakMode = .byTruncatingTail
        it.btDelegate = self
    }
    
    private lazy var closeButton = BitableRecordHeaderButtonWrapper().construct { it in
        it.button.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: UDColor.iconN1, size: CGSize(width: 24, height: 24)), for: .normal)
        it.button.addTarget(self, action: #selector(closeButtonClick), for: .touchUpInside)
        it.button.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
    }
    
    lazy var moreButton = BitableRecordHeaderButtonWrapper().construct { it in
        it.button.setImage(UDIcon.getIconByKey(.moreOutlined, iconColor: UDColor.iconN1, size: CGSize(width: 24, height: 24)), for: .normal)
        it.button.addTarget(self, action: #selector(moreButtonClick), for: .touchUpInside)
        it.button.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
    }
    
    lazy var rightIconStackView = UIStackView().construct { it in
        it.axis = .horizontal
        it.spacing = 12
        it.alignment = .center
    }
    
    lazy var shareButton = BitableRecordHeaderButtonWrapper().construct { it in
        it.button.setImage(UDIcon.getIconByKey(.forwardOutlined, iconColor: UDColor.iconN1, size: CGSize(width: 24, height: 24)), for: .normal)
        it.button.addTarget(self, action: #selector(shareButtonClick), for: .touchUpInside)
        it.button.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        it.isHidden = true
    }

    private lazy var operateCoverButton = BitableRecordHeaderButtonWrapper().construct { it in
        let image = UDIcon.getIconByKey(.imageOutlined, iconColor: UDColor.iconN1, size: CGSize(width: 24, height: 24))
        it.button.setImage(image, for: .normal)
        it.button.addTarget(self, action: #selector(didOperateCoverButtonPressed(sender:)), for: .touchUpInside)
        it.button.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        it.isHidden = true
    }
    
    lazy var subscribeButton = BitableRecordHeaderButtonWrapper().construct { it in
        let subscribeImg = UDIcon.getIconByKey(.subscribeAddOutlined, iconColor: UDColor.iconN1, size: CGSize(width: 24, height: 24))
        it.button.setImage(subscribeImg, for: .normal)
        it.button.addTarget(self, action: #selector(didSubscribeButtonPressed(sender:)), for: .touchUpInside)
        it.button.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        it.button.adjustsImageWhenHighlighted = false
        it.isHidden = true
    }
    
    private var subscribeAnimationView: LOTAnimationView = {
        return BTRecordHeaderView.fetchAnimationView()
    }()
    
    static private func fetchAnimationView () -> LOTAnimationView {
        let animation = AnimationViews.bitableRecordSubscribeAnimation
        animation.backgroundColor = UIColor.clear
        animation.loopAnimation = false
        animation.autoReverseAnimation = false
        animation.contentMode = .scaleAspectFill
        return animation
    }
    
    private var isSubscribing: Bool = false
    /*
    // 0 是否显示topTips 1 显示的是归档的
    private var hasTopTips: (Bool, Bool) {
        let showSubmitToolTips = dataSource?.mode == .submit && dataSource?.shouldShowSubmitTopTip == true
        let showArchivedTips = (dataSource?.mode == .indRecord || dataSource?.mode == .stage) && dataSource?.isArchived == true
        return (showSubmitToolTips || showArchivedTips, showArchivedTips)
    }
    */
    @objc
    func moreButtonClick() {
        guard let dele = delegate else {
            DocsLogger.error("click card more button failed, BTRecordHeaderView.delegate is nil")
            return
        }
        if LKFeatureGating.ccmios16Orientation, LKDeviceOrientation.isLandscape() {
            DocsLogger.info("system bug and isLandscape, not show button")
            return
        }
        dele.didClickMoreButton(sourceView: moreButton)
    }
    
    @objc
    func shareButtonClick() {
        guard let dele = delegate else {
            DocsLogger.warning("click card share button failed, BTRecordHeaderView.delegate is nil")
            return
        }
        dele.didClickShareButton(sourceView: shareButton)
    }

    @objc
    private func didOperateCoverButtonPressed(sender: UIButton) {
        guard let delegate = delegate else {
            DocsLogger.warning("click cover button failed, BTRecordHeaderView.delegate is nil")
            return
        }
        delegate.recordHeaderViewDidClickAddCover(view: self, sourceView: sender)
    }
    
    // Add Mode Subviews
    
    private lazy var cancelButton = UIButton().construct { it in
        it.setTitle(BundleI18n.SKResource.Bitable_AdvancedPermission_AddRecordButtonCancel,
                    withFontSize: 16,
                    fontWeight: .regular,
                    singleColor: UDColor.textTitle,
                    forAllStates: [.normal, .highlighted, .selected, [.highlighted, .selected]])
        it.titleLabel?.textAlignment = .left
        it.addTarget(self, action: #selector(cancelButtonClick), for: .touchUpInside)
        it.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
    }
    
    private lazy var newLabel = UILabel().construct { it in
        it.numberOfLines = 1
        it.textColor = UDColor.textTitle
        it.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        it.text = BundleI18n.SKResource.Bitable_AdvancedPermission_AddRecordTitle
        it.textAlignment = .center
    }
    
    private lazy var confirmButton = UIButton().construct { it in
        it.setTitle(BundleI18n.SKResource.Bitable_AdvancedPermission_AddRecordButtonAdd,
                    withFontSize: 16,
                    fontWeight: .regular,
                    singleColor: UDColor.primaryContentDefault,
                    forAllStates: [.normal, .highlighted, .selected, [.highlighted, .selected]])
        it.titleLabel?.textAlignment = .right
        it.addTarget(self, action: #selector(confirmButtonClick), for: .touchUpInside)
        it.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
    }
    
    private lazy var proAddNoticeConfig: UDNoticeUIConfig = {
        let text = BundleI18n.SKResource.Bitable_AdvancedPermission_NeedToFillRecordFirst_Notice
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2
        var att = NSMutableAttributedString(string: text)
        att.setAttributes([NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle,
                           NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
                           NSAttributedString.Key.paragraphStyle: paragraphStyle],
                          range: NSRangeFromString(text))
        var config = UDNoticeUIConfig(type: .info, attributedText: att)
        config.trailingButtonIcon = UDIcon.closeOutlined
        return config
    }()
    
    private lazy var archivedNoticeConfig: UDNoticeUIConfig = {
        let text = BundleI18n.SKResource.Bitable_Record_Archived_Desc
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2
        var att = NSMutableAttributedString(string: text)
        att.setAttributes([NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle,
                           NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
                           NSAttributedString.Key.paragraphStyle: paragraphStyle],
                          range: NSRangeFromString(text))
        var config = UDNoticeUIConfig(type: .info, attributedText: att)
        return config
    }()
    
    private lazy var filteredNoticeConfig: UDNoticeUIConfig = {
        let text = BundleI18n.SKResource.Doc_Block_RecordFilteredTip
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.2
        var att = NSMutableAttributedString(string: text)
        att.setAttributes([NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle,
                           NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
                           NSAttributedString.Key.paragraphStyle: paragraphStyle],
                          range: NSRangeFromString(text))
        var config = UDNoticeUIConfig(type: .warning, attributedText: att)
        config.trailingButtonIcon = UDIcon.closeOutlined
        return config
    }()
    
    private lazy var notice: UDNotice = {
        var config = UDNoticeUIConfig(type: .info, attributedText: NSAttributedString(string: ""))
        let notice = UDNotice(config: config)
        notice.delegate = self
        return notice
    }()
    
    private lazy var bottomLine = UIView().construct { it in
        it.backgroundColor = UDColor.lineDividerDefault
    }
    
    var dataSource: DataSource? {
        didSet { loadData() }
    }
    
    var iconSize: CGSize {
        if dataSource?.viewMode == .transparent {
            return CGSize(width: 34, height: 34)
        } else {
            return CGSize(width: 24, height: 24)
        }
    }
    
    weak var delegate: BTRecordHeaderViewDelegate?
    
    init() {
        super.init(frame: .zero)
        if UserScopeNoChangeFG.ZJ.btCardReform {
            setupLayoutV2()
        } else {
            setupLayout()
        }
        if LKFeatureGating.ccmios16Orientation {
            NotificationCenter.default.addObserver(self, selector: #selector(changeMoreButtonHidden), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        }
    }
    @objc
    private func changeMoreButtonHidden() {
        loadData()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addPanGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panAction))
        addGestureRecognizer(panGesture)
    }
    
    private func setupLayoutV2() {
        // Add Mode
        addSubview(topMaskView)
        topMaskView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(0)
        }
        
        addSubview(contentView)
        addSubview(notice)
        
        contentView.addSubview(newLabel)
        newLabel.snp.makeConstraints { it in
            it.centerX.equalToSuperview()
            it.height.equalTo(22)
        }
        
        contentView.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { it in
            it.centerY.equalTo(newLabel)
            it.left.equalToSuperview().offset(12)
            it.right.lessThanOrEqualTo(newLabel.snp.left).offset(-10)
        }
        
        contentView.addSubview(confirmButton)
        confirmButton.snp.makeConstraints { it in
            it.centerY.equalTo(newLabel)
            it.right.equalToSuperview().offset(-12)
            it.left.greaterThanOrEqualTo(newLabel.snp.right).offset(-10)
        }

        // Common Mode
        contentView.addSubview(titleTextView)
        contentView.addSubview(closeButton)
        contentView.addSubview(rightIconStackView)
        contentView.addSubview(moreButton)
        titleTextView.snp.remakeConstraints { it in
            it.height.equalTo(24)
            if UserScopeNoChangeFG.ZJ.btCardReform {
                it.centerY.equalToSuperview()
            } else {
                it.bottom.equalToSuperview().offset(-9)
            }
            it.left.equalTo(closeButton.snp.right).offset(12)
            it.right.equalTo(rightIconStackView.snp.left).offset(-12)
        }
        
        rightIconStackView.addArrangedSubview(shareButton)
        
        if shouldOptimizeForSubscribe() {
            rightIconStackView.addArrangedSubview(subscribeButton)
        } else {
            rightIconStackView.addArrangedSubview(operateCoverButton)
        }
        
        rightIconStackView.addArrangedSubview(moreButton)
        moreButton.snp.makeConstraints { it in
            it.size.equalTo(iconSize)
        }
        shareButton.snp.makeConstraints { it in
            it.size.equalTo(iconSize)
        }
        operateCoverButton.snp.makeConstraints { make in
            make.size.equalTo(iconSize)
        }
        subscribeButton.snp.makeConstraints { make in
            make.size.equalTo(iconSize)
        }
        updateLayoutV2()

        self.backgroundColor = UDColor.bgBody.withAlphaComponent(0)
        self.titleTextView.alpha = 0
    }
    
    private func setupLayout() {
        addSubview(topBar)
        topBar.snp.makeConstraints { it in
            it.left.right.top.equalToSuperview()
            it.height.equalTo(8)
        }
        
        // Add Mode
        addSubview(newLabel)
        newLabel.snp.makeConstraints { it in
            it.centerX.equalToSuperview()
            it.height.equalTo(22)
            it.top.equalTo(topBar.snp.bottom).offset(9)
        }
        
        addSubview(cancelButton)
        cancelButton.snp.makeConstraints { it in
            it.centerY.equalTo(newLabel)
            it.left.equalToSuperview().offset(12)
            it.right.lessThanOrEqualTo(newLabel.snp.left).offset(-10)
        }
        
        addSubview(confirmButton)
        confirmButton.snp.makeConstraints { it in
            it.centerY.equalTo(newLabel)
            it.right.equalToSuperview().offset(-12)
            it.left.greaterThanOrEqualTo(newLabel.snp.right).offset(-10)
        }
        addSubview(notice)
        let noticeViewHeight = getNoticeViewHeight()
        notice.snp.makeConstraints { make in
            make.height.equalTo(noticeViewHeight)
            make.left.right.bottom.equalToSuperview()
        }
        
        // Common Mode
        
        addSubview(titleTextView)
        addSubview(closeButton)
        addSubview(bottomLine)
        addSubview(rightIconStackView)
        bottomLine.snp.makeConstraints { it in
            it.right.bottom.left.equalToSuperview()
            it.height.equalTo(0.5)
        }
        addSubview(moreButton)
        closeButton.snp.makeConstraints { it in
            it.width.height.equalTo(20).priority(.medium)
            it.centerY.equalTo(titleTextView)
            it.left.equalToSuperview().offset(12)
        }
        rightIconStackView.snp.makeConstraints { it in
            it.centerY.equalTo(titleTextView)
            it.right.equalToSuperview().offset(-12)
        }
        titleTextView.snp.remakeConstraints { it in
            it.height.equalTo(24)
            it.bottom.equalToSuperview().offset(-9)
            it.left.equalTo(closeButton.snp.right).offset(12)
            it.right.equalTo(rightIconStackView.snp.left).offset(-12)
        }
        
        rightIconStackView.addArrangedSubview(shareButton)
        rightIconStackView.addArrangedSubview(moreButton)
        moreButton.snp.makeConstraints { it in
            it.width.height.equalTo(20)
        }
        shareButton.snp.makeConstraints { it in
            it.width.height.equalTo(20)
        }
    }
    
    private func updateButton() {
        updateButton(button: closeButton, isCloseButton: true)
        updateButton(button: moreButton)
        updateButton(button: shareButton)
        if shouldOptimizeForSubscribe() {
            updateButton(button: subscribeButton)
        } else {
            updateButton(button: operateCoverButton)
        }
        updateButtonImage()
    }

    private func updateButtonImage() {
        let iconType: UniverseDesignIcon.UDIconType
        if !UserScopeNoChangeFG.QYK.btAttachmentUploadingCrashFixDisable {
            if dataSource?.closeIconType == .closeOutlined {
                iconType = .closeOutlined
            } else {
                iconType = .leftOutlined
            }
        } else {
            iconType = .leftOutlined
        }
        let imageSize = dataSource?.viewMode == .transparent ? CGSize(width: 22, height: 22) : CGSize(width: 24, height: 24)
        closeButton.button.setImage(UDIcon.getIconByKey(iconType, iconColor: UDColor.iconN1, size: imageSize), for: .normal)
        rightIconStackView.spacing = dataSource?.viewMode == .transparent ? 10 : 24
        moreButton.button.setImage(UDIcon.getIconByKey(.moreOutlined, iconColor: UDColor.iconN1, size: imageSize), for: .normal)
        shareButton.button.setImage(UDIcon.getIconByKey(.forwardOutlined, iconColor: UDColor.iconN1, size: imageSize), for: .normal)
        if shouldOptimizeForSubscribe() {
            let subscribeImg = UDIcon.getIconByKey(.subscribeAddOutlined, iconColor: UDColor.iconN1, size: imageSize)
            subscribeButton.button.setImage(subscribeImg, for: .normal)
            let subscribeSelectedImg = UDIcon.resolveColorful.ud.resized(to: imageSize)
            subscribeButton.button.setImage(subscribeSelectedImg, for: .selected)
        } else {
            let coverImage = UDIcon.getIconByKey(.imageOutlined, iconColor: UDColor.iconN1, size: imageSize)
            operateCoverButton.button.setImage(coverImage, for: .normal)
        }
    }

    private func updateButton(button: BitableRecordHeaderButtonWrapper, isCloseButton: Bool = false) {
        button.layer.cornerRadius = dataSource?.viewMode == .transparent ? iconSize.width / 2 : 0
        button.layer.masksToBounds = true
        // 使用 updateConstraints 偶现 crash
        if isCloseButton {
            closeButton.snp.remakeConstraints { make in
                make.size.equalTo(iconSize)
                make.centerY.equalTo(titleTextView)
                make.left.equalToSuperview().offset(dataSource?.viewMode == .transparent ? 14 : 12)
            }
        } else {
            button.snp.remakeConstraints { make in
                make.size.equalTo(iconSize)
            }
        }
        button.update(showBlur: buttonShowBlur())
    }

    private func buttonShowBlur() -> Bool {
        return UserScopeNoChangeFG.ZJ.btCardReform && dataSource?.viewMode == .transparent
    }
    
    private func updateNotice(_ type: BTRecordHeaderNoticeType) {
        switch type {
        case .none:
            notice.isHidden = true
        case .archived:
            notice.isHidden = false
            notice.updateConfigAndRefreshUI(archivedNoticeConfig)
        case .proAdd:
            notice.isHidden = false
            notice.updateConfigAndRefreshUI(proAddNoticeConfig)
        case .filtered:
            notice.isHidden = false
            notice.updateConfigAndRefreshUI(filteredNoticeConfig)
        }
    }
    
    private func updateTitleTextViewVisibility(_ dataSource: DataSource) {
        if UserScopeNoChangeFG.ZYS.recordHeaderSafeAreaFixRevertV2 {
            return
        }
        titleTextView.attributedText = dataSource.title
        switch dataSource.mode {
        case .normal, .indRecord, .submit, .form, .stage, .link:
            titleTextView.isHidden = false
        case .invisible, .loading, .timeOut:
            titleTextView.isHidden = true
        }
    }
    
    private func updateLayoutV2() {
        guard UserScopeNoChangeFG.ZJ.btCardReform else {
            return
        }
        updateButton()
        rightIconStackView.snp.remakeConstraints { make in
            make.centerY.equalTo(titleTextView)
            make.right.equalToSuperview().offset(dataSource?.viewMode == .transparent ? -14 : -12)
        }
        let contentViewHeight = getContentViewHeight()
        contentView.snp.remakeConstraints { make in
            make.height.equalTo(contentViewHeight)
            make.top.equalTo(topMaskView.snp.bottom)
            make.left.right.equalToSuperview()
            if !notice.isHidden {
                make.bottom.equalTo(notice.snp.top)
            } else {
                make.bottom.equalToSuperview()
            }
        }
        
        if !notice.isHidden {
            let height = getNoticeViewHeight()
            notice.snp.remakeConstraints { make in
                make.left.right.bottom.equalToSuperview()
                make.top.equalTo(contentView.snp.bottom)
                make.height.equalTo(height)
            }
        }
    }
    
    private func loadData() {
        guard let ds = dataSource else { return }
        topBar.backgroundColor = ds.topColor
        updateNotice(ds.noticeType)
        updateTitleTextViewVisibility(ds)
        switch ds.mode {
        case .normal, .form, .indRecord, .link, .stage:
            if ds.mode == .stage, !UserScopeNoChangeFG.ZJ.btCardReform  {
                return
            }
            if UserScopeNoChangeFG.ZYS.recordHeaderSafeAreaFixRevertV2 {
            titleTextView.attributedText = ds.title
            }
            cancelButton.isHidden = true
            newLabel.isHidden = true
            confirmButton.isHidden = true
            closeButton.isHidden = false
            let landscapeDisable = LKFeatureGating.ccmios16Orientation && LKDeviceOrientation.isLandscape()
            let enableInd = ds.mode.isIndRecord
            let enableDel = ds.canDelete
            let enableAddRecord = ds.canAddRecord
            moreButton.isHidden = landscapeDisable || !(enableInd || enableDel || enableAddRecord)

            if shouldOptimizeForSubscribe() {
                subscribeButton.isHidden = !(ds.subscribeStatue == .unSubscribe || ds.subscribeStatue == .subscribe)
                isSubscribing = false
                if !subscribeAnimationView.isAnimationPlaying {
                    subscribeButton.button.isSelected = ds.subscribeStatue == .subscribe
                }
            } else {
                let coverChangeAble = dataSource?.coverChangeAble ?? false
                operateCoverButton.isHidden = !UserScopeNoChangeFG.ZJ.btCardReform || !coverChangeAble
            }
            
            if UserScopeNoChangeFG.ZYS.baseRecordShareV2 {
                shareButton.isHidden = !ds.canShare
            }
            if !UserScopeNoChangeFG.ZJ.btCardReform {
                bottomLine.isHidden = false
            } else if ds.mode == .link, dataSource?.viewMode == .normal {
                // 关联卡片不显示封面的情况下，标题需要常驻显示
                titleTextView.alpha = 1
            }
        case .invisible:
            cancelButton.isHidden = true
            newLabel.isHidden = true
            confirmButton.isHidden = true
            if UserScopeNoChangeFG.ZYS.recordHeaderSafeAreaFixRevertV2 {
            titleTextView.isHidden = true
            }
            closeButton.isHidden = false
            moreButton.isHidden = true
            shareButton.isHidden = true
            if !UserScopeNoChangeFG.ZJ.btCardReform {
                bottomLine.isHidden = true
            }
            subscribeButton.isHidden = true
            operateCoverButton.isHidden = true
            if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
                // 设计稿和代码修改前线上表现冲突，如果是 invisible 不能展示 proAddNotice
//                if dataSource?.btViewMode.isLinkedRecord == true {
                // 目前线上仅新增了isLinkedRecord场景展示出无权限的记录，这个场景设计稿无notice，隐藏，如果新增其他场景，请按照设计稿适配
                updateNotice(.none)
//                }
            }
        case .timeOut, .loading:
            cancelButton.isHidden = true
            newLabel.isHidden = true
            confirmButton.isHidden = true
            if UserScopeNoChangeFG.ZYS.recordHeaderSafeAreaFixRevertV2 {
            titleTextView.isHidden = true
            }
            closeButton.isHidden = true
            moreButton.isHidden = true
            shareButton.isHidden = true
            if !UserScopeNoChangeFG.ZJ.btCardReform {
                bottomLine.isHidden = true
            } else {
                closeButton.isHidden = false
            }
            subscribeButton.isHidden = true
            operateCoverButton.isHidden = true
        case .submit:
            let userNewStyle: Bool
            if ds.btViewMode == .addRecord {
                userNewStyle = true
            } else if ds.btViewMode == .submit, UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable {
                userNewStyle = true
            } else {
                userNewStyle = false
            }
            if userNewStyle {
                cancelButton.isHidden = true
                newLabel.isHidden = true
                confirmButton.isHidden = true
                if UserScopeNoChangeFG.ZYS.recordHeaderSafeAreaFixRevertV2 {
                titleTextView.isHidden = true
                }
                closeButton.isHidden = false
                moreButton.isHidden = true
                shareButton.isHidden = false
                subscribeButton.isHidden = true
                operateCoverButton.isHidden = true
                if ds.shouldShowSubmitTopTip {
                    DocsTracker.newLog(enumEvent: .bitableCardLimitedTipsView, parameters: [:])
                }
                
                if !UserScopeNoChangeFG.ZJ.btCardReform {
                    bottomLine.isHidden = false
                }
            } else {
                cancelButton.isHidden = false
            	newLabel.isHidden = false
            	confirmButton.isHidden = false
                if UserScopeNoChangeFG.ZYS.recordHeaderSafeAreaFixRevertV2 {
            	titleTextView.isHidden = true
                }
            	closeButton.isHidden = true
            	moreButton.isHidden = true
            	shareButton.isHidden = true
            	subscribeButton.isHidden = true
            	operateCoverButton.isHidden = true
                if ds.shouldShowSubmitTopTip {
                    DocsTracker.newLog(enumEvent: .bitableCardLimitedTipsView, parameters: [:])
                }
                
                if !UserScopeNoChangeFG.ZJ.btCardReform {
                    bottomLine.isHidden = false
                }
            }
        }
        // 属性都设置完成后再layout
        updateLayoutV2()
    }
    
    @objc
    private func cancelButtonClick() {
        delegate?.didClickHeaderButton(action: .cancel)
    }
    
    @objc
    private func confirmButtonClick() {
        delegate?.didClickHeaderButton(action: .confirm)
    }
    
    @objc
    private func closeButtonClick() {
        delegate?.didClickHeaderButton(action: .exit)
    }
    
    @objc
    private func panAction(_ gesture: UIPanGestureRecognizer) {
        delegate?.handlePanGesture(gesture)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard UserScopeNoChangeFG.ZJ.btCardReform else {
            return
        }
        topMaskView.snp.updateConstraints { make in
            make.height.equalTo(self.safeAreaInsets.top)
        }
    }
    
    private func getNoticeViewHeight() -> CGFloat {
        guard let type = dataSource?.noticeType, type != .none else {
            return 0
        }
        
        let controllerSize = self.nodeViewController?.view.frame.size ??
        CGSize(width: CGFloat.greatestFiniteMagnitude,
               height: CGFloat.greatestFiniteMagnitude)
        let containerWidth = controllerSize.width - 32
        let noticeHeight = notice.sizeThatFits(CGSize(width: containerWidth,
                                                            height: CGFloat.greatestFiniteMagnitude)).height
        return noticeHeight
    }
    
    private func getContentViewHeight() -> CGFloat {
        return 56
    }
    
    func setHeaderAlpha(alpha: CGFloat) {
        guard UserScopeNoChangeFG.ZJ.btCardReform else {
            return
        }
        self.backgroundColor = UDColor.bgBody.withAlphaComponent(alpha)
        if dataSource?.mode == .link, dataSource?.viewMode == .normal {
            self.titleTextView.alpha = 1
        } else {
            self.titleTextView.alpha = alpha
        }

        updateButtonBlurAlpha(alpha: alpha)
    }

    private func updateButtonBlurAlpha(alpha: CGFloat) {
        let realAlpha = dataSource?.viewMode == .transparent ? alpha : 1
        self.closeButton.updateHeaderAlpha(alpha: realAlpha)
        self.shareButton.updateHeaderAlpha(alpha: realAlpha)
        if shouldOptimizeForSubscribe() {
            self.subscribeButton.updateHeaderAlpha(alpha: realAlpha)
        } else {
            self.operateCoverButton.updateHeaderAlpha(alpha: realAlpha)
        }
        self.moreButton.updateHeaderAlpha(alpha: realAlpha)
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        guard !UserScopeNoChangeFG.ZJ.btCardReform else {
            return size
        }
        // 旧版本header不贯通到safearea
        size.height = getViewHeight(safeAreaInsetTop: 0)
        return size
    }
    
    func getViewHeight(safeAreaInsetTop: CGFloat) -> CGFloat {
        return getNoticeViewHeight() + getContentViewHeight() + safeAreaInsetTop
    }
    // loading 里用的，为了对齐位置
    func onlyShowClose() {
        cancelButton.isHidden = true
        newLabel.isHidden = true
        confirmButton.isHidden = true
        titleTextView.isHidden = true
        closeButton.isHidden = false
        moreButton.isHidden = true
        shareButton.isHidden = true
        subscribeButton.isHidden = true
        operateCoverButton.isHidden = true
        notice.isHidden = true
    }
}

// MARK: - 订阅相关
extension BTRecordHeaderView {
    private func shouldOptimizeForSubscribe() -> Bool {
        let fgEnable = UserScopeNoChangeFG.PXR.bitableRecordSubscribeEnable
        return fgEnable
    }
    private func showSubscribeAnimation(completion: @escaping () -> Void) {
        guard !subscribeAnimationView.isAnimationPlaying else { return }
        guard let imgView = subscribeButton.button.imageView else { return }
        subscribeAnimationView.frame = imgView.bounds
        imgView.addSubview(subscribeAnimationView)
        subscribeAnimationView.play() { [weak self] _ in
            guard let self = self else { return }
            self.subscribeAnimationView.removeFromSuperview()
            self.subscribeAnimationView = BTRecordHeaderView.fetchAnimationView()
            completion()
        }
    }
    @objc
    private func didSubscribeButtonPressed(sender: UIButton) {
        guard let delegate = delegate else {
            DocsLogger.warning("click subscribe button failed, BTRecordHeaderView.delegate is nil")
            return
        }
        guard isSubscribing == false else {
            DocsLogger.warning("forbidden subscribe when subscribing ")
            return
        }
        isSubscribing = true
        let isSubscribe = !sender.isSelected
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if isSubscribe {
            showSubscribeAnimation { [weak self] in
                guard let self = self else { return }
                if self.isSubscribing {
                    sender.isSelected = true
                } else {
                    sender.isSelected = self.dataSource?.subscribeStatue == .subscribe
                }
            }
            delegate.recordSubscribeViewDidClick(isSubscribe: true) { [weak self] (code) in
                guard let self = self else { return }
                if !self.subscribeAnimationView.isAnimationPlaying {
                    sender.isSelected =  code == .success
                }
                self.isSubscribing = false
            }
        } else {
            sender.isSelected = false
            delegate.recordSubscribeViewDidClick(isSubscribe: false) { [weak self] (code) in
                guard let self = self else { return }
                sender.isSelected = !(code == .success)
                self.isSubscribing = false
            }
        }
    }
}

extension BTRecordHeaderView: BTReadOnlyTextViewDelegate {
    func readOnlyTextView(_ textView: BTReadOnlyTextView, handleTapFromSender sender: UITapGestureRecognizer) {
        if titleTextView.text?.isEmpty == true { return }
        let attributes = BTUtil.getAttributes(in: titleTextView, sender: sender)
        if !attributes.isEmpty {
            delegate?.didTapTitle(withAttributes: attributes)
        }
    }
}

// MARK: - BTRecordHeaderViewDelegate
protocol BTRecordHeaderViewDelegate: AnyObject {
    func handlePanGesture(_ gesture: UIPanGestureRecognizer)
    func didClickHeaderButton(action: BTActionFromUser)
    func didTapTitle(withAttributes attributes: [NSAttributedString.Key: Any])
    func didClickMoreButton(sourceView: UIView)
    func didClickCloseNoticeButton()
    func didClickShareButton(sourceView: UIView)
    func recordHeaderViewDidClickAddCover(view: BTRecordHeaderView, sourceView: UIView)
    func recordSubscribeViewDidClick(isSubscribe: Bool, completion: @escaping (BTRecordSubscribeCode) -> Void)
}

extension BTRecordHeaderView: UniverseDesignNotice.UDNoticeDelegate {
    func handleLeadingButtonEvent(_ button: UIButton) {
        
    }
    
    func handleTextButtonEvent(URL: URL, characterRange: NSRange) {
        
    }
    
    func handleTrailingButtonEvent(_ button: UIButton) {
        delegate?.didClickCloseNoticeButton()
    }
}

enum CloseIconType {
    case leftOutlined
    case closeOutlined
}
