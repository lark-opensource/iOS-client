//
//  CommentTableViewCell.swift
//  SpaceKit
//
//  Created by xurunkang on 2018/10/30.
//
//  swiftlint:disable file_length

import UIKit
import RxSwift
import RxCocoa
import LarkAudioKit
import LarkReactionView
import LarkEmotion
import Lottie
import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignFont
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignLoading
import SpaceInterface
import ByteWebImage
import SKCommon

class CommentTableViewCell: CommentShadowBaseCell {

    enum CommentCellVersion: String {
        case v1
        case v2
        case iPad
    }

    /// 公共参数
    let translateIconWidth: CGFloat = 16.0
    let translateBgBottomTopGap: CGFloat = 2.0
    let translateBgLeftRightGap: CGFloat = 4.0
    
    static var LeftRightPadding: CGFloat { 16.0 }
    
    /// 评论内容左右间距
    var leftRightPadding: CGFloat {
        return Self.LeftRightPadding
    }
    
    var avatarImagWidth: CGFloat {
        return 40.0
    }
    
    var titleLeftMargin: CGFloat {
        return 12.0
    }
    
    var reactionTopMargin: CGFloat {
        return 4.0
    }
    
    var reactionBottomMargin: CGFloat {
        return 3.0
    }
    
    var contentInset: CGFloat {
        return 12.0
    }
    

    /// sendingState相关布局参数
    let sendingDeleteIconHeight: CGFloat = 24.0
    let sendingFailIconHeight: CGFloat = 16.0
    let sendingLoadingIconHeight: CGFloat = 0
    let sendingFailLabelHeight: CGFloat = 18.0
    let sendingRetryBtnHeight: CGFloat = 24.0
    let sendingFailIconTopGap: CGFloat = 6.0
    let sendingRetryBtnTopGap: CGFloat = 6.0
    
    /// 新样式的追加在文本后面的长方形的loadingview的宽度
    let sendingNewLoadingViewWidth: CGFloat = 46.0
    /// loadingview内部转圈loading宽高
    let sendingNewLoadingWH: CGFloat = 14.0
    
    let defaultNameMaxWidth: CGFloat = 280

    weak var delegate: CommentTableViewCellDelegate? {
        didSet {
            imagePreview.cellDelegate = delegate
        }
    }

    var canShowMoreActionButton: Bool = true
    var canShowReactionView: Bool = true
    var cellWidth: CGFloat? {
        didSet {
            updateReactionViewMaxWidth(cellWidth: cellWidth)
        }
    }

    private(set) var item: CommentItem? {
        didSet {
            _update(item)
        }
    }

    var permission: CommentPermission?
    var contentAtInfos: [AtInfo] = []
    var atInfoPermissionBlock: PermissionQuerryBlock?

    var isHiddenAudioView: Bool = true

    var translateConfig: CommentTranslateConfig?
    
    var estimated = false
    // 头像
    private(set) lazy var avatarImageView: UIImageView = _setupAvatarImageView()
    // 名称
    private(set) lazy var titleLabel: TitleView = {
        let view = TitleView()
        view.setFont(font: .systemFont(ofSize: titleFontSize), nameColor: UIColor.ud.N900, extraInfoColor: timeLabelColor)
        return view
    }()
    // 内容
    private(set) lazy var contentLabel: UILabel = _setupContentLabel()
    // Reaction
    private(set) lazy var reactionView: ReactionView = _setupReactionView()
    // 图片
    private(set) lazy var imagePreview: CommentCardImagesPreview = setupImagePreview()
    // 富文本点击处理
    private(set) lazy var singleTapGesture: UITapGestureRecognizer = _setupSingleTap()
    private(set) lazy var singleTapGesture2: UITapGestureRecognizer = _setupSingleTap2()
    // 更多按钮
    private(set) lazy var moreActionButton: UIButton = _setupMoreButton()
    // 长按点击
    private(set) lazy var longPressGesture: UILongPressGestureRecognizer = _setupLongPress()
    // 翻译
    private(set) lazy var translationView: TranslationViewV2 = _setupTranslationView()
    // 翻译view背景view
    private(set) lazy var translationBgView: UIView = _setupTranslationBgView()
    // 翻译icon
    private(set) var translationLoadingView = AnimationViews.commentTranslting!
    // 翻译icon点击手势
    private var translateIconTapGueture: UITapGestureRecognizer!

    // 发送过程删除按钮
    private(set) var sendingDeleteButton: UIButton!
    // 发送过程失败icon
    private(set) var sendingFailedIcon: UIImageView = .init(image: nil)
    // 发送过程失败文案
    private(set) var sendingFailedLabel: UILabel = .init()
    // 发送过程重试按钮
    private(set) var sendingRetryButton: UIButton!
    // 发送过程loadingIcon
    private(set) var sendingIndicatorView: LOTAnimationView!
    
    // 覆盖在翻译icon上，用于代替翻译事件，间接扩大事件响应范围
    private(set) var translateIconCover = UIView()
    
    // 覆盖在内容上的loadingView
    lazy var loadingView: UIView = {
        let loadingView = CommentLoadingView(spinColor: .primary)
        loadingView.udpate(backgroundColor: UDColor.bgFloat, alphe: 0.7)
        loadingView.isHidden = true
        loadingView.clipsToBounds = true
       return loadingView
    }()
    
    // 新的loadingview样式，追加在文字后面，长方形的LoadingView
    // 包含：渐变色的白色背景，和居右显示的转圈loading
    lazy var newLoadingView: CommentNewLoadingView = {
        let loadingView = CommentNewLoadingView()
        loadingView.isHidden = true
        loadingView.clipsToBounds = true
        contentLabel.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.width.height.equalTo(0)
            make.left.top.equalTo(0)
        }
        return loadingView
    }()
    
    // 失败时覆盖在内容上的mask view
    lazy var errorMaskView: UIView = {
        let errorView = UIView()
        errorView.backgroundColor = UDColor.bgFloat
        errorView.alpha = 0.7
        errorView.isHidden = true
        return errorView
    }()
    

    private let disposeBag = DisposeBag()

    var zoomable: Bool = false {
        didSet {
            currentContentFont = zoomable ? UIFont.ud.body0 : UIFont.systemFont(ofSize: 16)
        }
    }
    
    var isFailState: Bool = false
    var isLoadingState: Bool = false
    var cellVersion: CommentCellVersion {
        return .v1
    }

    var timeLabelColor: UIColor {
        return UIColor.ud.N500
    }

    var titleFontSize: CGFloat {
        return 14
    }
 
    var textColor: UIColor {
        return UIColor.ud.textTitle
    }
    
    var currentContentFont = UIFont.systemFont(ofSize: 16)
    
    var contentFont: UIFont {
        return currentContentFont
    }

    var fontLineSpace: CGFloat? {
        return nil
    }

    var emptySpaceForContent: CGFloat {
        return CGFloat(leftRightPadding * 2 + avatarImagWidth + titleLeftMargin)
    }
    
    var translateDisplayType: CommentTranslateConfig.DisplayType {
        if UserScopeNoChangeFG.HYF.commentTranslateConfig {
            return translateConfig?.displayType ?? .unKnown
        } else {
            return SpaceTranslationCenter.standard.commentConfig?.displayType ?? .unKnown
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        constructUI()
        setupUI()
        setupConstraints()
        setupBind()
        NotificationCenter.default.addObserver(self, selector: #selector(featchAtUserPermissionResult), name: Notification.Name.FeatchAtUserPermissionResult, object: nil)
    }

    @objc
    func featchAtUserPermissionResult() {
        guard contentAtInfos.count > 0, atInfoPermissionBlock != nil else { return }
        _update(item)
    }

    func configCellData(_ item: CommentItem, isFailState: Bool = false, isLoadingState: Bool = false) {
        self.isFailState = isFailState
        self.isLoadingState = isLoadingState
        self.item = item
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    enum LoadingStatus {
        case start
        case stop
    }
    func setLoading(status: LoadingStatus, layoutViews: Bool = false) {
        switch status {
        case .start:
            translationLoadingView.backgroundColor = .clear
            translationLoadingView.isHidden = false
            translationLoadingView.play()
            if layoutViews {
                updateViewsLayoutIfNeed()
            }
        case .stop:
            translationLoadingView.stop()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        setLoading(status: .stop)
    }

    func isShowingTranslationView() -> Bool {
        return !translationView.isHidden
    }
    
    @objc
    private func handleTapReactionIcon(_ data: Any) {
        guard let (reactionVM, tapType) = data as? (ReactionInfo, ReactionTapType) else { return }
        delegate?.didClickReaction(item, reactionVM: reactionVM, tapType: tapType)
    }
}

extension CommentTableViewCell {

    private func _update(_ item: CommentItem?) {

        contentAtInfos.removeAll()
        contentLabel.isHidden = false
        imagePreview.isHidden = false


        _setTitleLabelText(item)

        let placeholder = BundleResources.SKResource.Common.Collaborator.avatar_placeholder
        avatarImageView.bt.setLarkImage(with: .default(key: item?.avatarURL ?? ""),
                                        placeholder: placeholder,
                                        trackStart: {
            return TrackInfo(biz: .Docs,
                             scene: .Unknown,
                             fromType: .image)
        }, completion: { result in
            switch result {
            case .failure(let error):
                DocsLogger.error("load comment avatar error", error: error, component: LogComponents.comment)
            default:
                break
            }
        })

        _updateReaction(item)

        updateContentViewAndTranslateView(item)

        imagePreview.updateView(item: item, imageInfos: item?.previewImageInfos ?? [])
 
        updateViewsLayoutIfNeed()

        _setupAccessibilityIdentifier(for: self, item: self.item)
        updateSendingState()
        updateMoreBtnHidden()

    }

    private func updateContentViewAndTranslateView(_ item: CommentItem?) {
        contentLabel.attributedText = getContentLabelText(item)
        contentLabel.accessibilityIdentifier = item?.content
        if let content = item?.content {
            moreActionButton.accessibilityIdentifier = "docs.comment.more.button." + content
        }

        translationView.content.attributedText = item?.attrTranslationContent(font: contentFont,
                                                                             color: textColor,
                                                                       lineSpacing: fontLineSpace,
                                                                     lineBreakMode: nil,
                                                                   permissionBlock: atInfoPermissionBlock,
                                                                   needUrlAttributed: !estimated)

        var enableCommentTranslate = SpaceTranslationCenter.standard.enableCommentTranslate
        if UserScopeNoChangeFG.HYF.commentTranslateConfig {
            enableCommentTranslate = translateConfig?.enableCommentTranslate ?? false
        }
        guard enableCommentTranslate else {
            translationView.isHidden = true
            translationLoadingView.isHidden = true
            translationBgView.isHidden = true
            return
        }

        if let translateStatus = item?.translateStatus {
            switch translateStatus {
            case .loading:
                setLoading(status: .start)
            case .error, .success:
                setLoading(status: .stop)
            }
        }
        translationLoadingView.isHidden = !self.shouldShowTranslatedIcon(item)
        translationView.isHidden = !self.shouldShowTranslatedView(item)
        translationBgView.isHidden = translationView.isHidden
    }

    private func getContentLabelText(_ item: CommentItem?) -> NSAttributedString? {
        guard let item = item else { return nil }
        if translateDisplayType == .onlyShowTranslation, shouldShowTranslationInOriginContent(item) {
            return item.attrTranslationContent(font: contentFont, color: textColor, lineSpacing: fontLineSpace, lineBreakMode: .byWordWrapping, permissionBlock: atInfoPermissionBlock, needUrlAttributed: !estimated)
        } else {
            var selfNameMaxWidth = self.bounds.width - (leftRightPadding * 2)
            selfNameMaxWidth = selfNameMaxWidth <= 0 ? defaultNameMaxWidth: selfNameMaxWidth
            return item.attrContent(font: contentFont,
                                   color: textColor,
                             lineSpacing: fontLineSpace,
                           lineBreakMode: .byWordWrapping,
                        selfNameMaxWidth: selfNameMaxWidth,
                         permissionBlock: atInfoPermissionBlock)
        }
    }

    private func shouldShowTranslatedView(_ item: CommentItem?) -> Bool {
        guard let item = item else { return false }
        switch translateDisplayType {
        case .onlyShowTranslation:
            return false
        case .bothShow:
            let isTranslateEmpty = item.translateContent?.isEmpty ?? true
            let hadClickTranslateBtn = CommentTranslationTools.shared.contain(store: item)
            if !isTranslateEmpty && !hadClickTranslateBtn {
                return true
            } else {
                return false
            }
        default:
            return false
        }
    }

    private func shouldShowTranslatedIcon(_ item: CommentItem?) -> Bool {
        guard let item = item else { return false }
        if let status = item.translateStatus, status == .loading {
            return true
        }
        switch translateDisplayType {
        case .onlyShowTranslation:
            return shouldShowTranslationInOriginContent(item)

        case .bothShow:
            let isTranslateEmpty = item.translateContent?.isEmpty ?? true
            let hadClickTranslateBtn = CommentTranslationTools.shared.contain(store: item)
            if !isTranslateEmpty && !hadClickTranslateBtn {
                return true
            } else {
                return false
            }
        default:
            return false
        }
    }

    // 是否应该把译文显示在原文里面
    func shouldShowTranslationInOriginContent(_ item: CommentItem) -> Bool {
        switch translateDisplayType {
            case .onlyShowTranslation:
                let isTranslateEmpty = item.translateContent?.isEmpty ?? true
                let hadClickTranslateBtn = CommentTranslationTools.shared.contain(store: item)
                if !isTranslateEmpty && !hadClickTranslateBtn {
                    return true
                } else {
                    return false
                }
            case .bothShow:
                return false
            default: return false
        }
/// 这方式有bug，如果翻译和原文一样就有问题
//        if let contentStr = contentLabel.attributedText?.string, let translateStr = item?.attrTranslationContent(fontSize: contentFontSize)?.string {
//            return contentStr == translateStr
//        } else {
//            return false
//        }
    }

    private func updateMoreBtnHidden() {
        if self.isLoadingState || self.isFailState {
            moreActionButton.isHidden = true
        } else {
            moreActionButton.isHidden = !canShowMoreActionButton
        }
    }

    private func updateSendingState() {
        if self.isLoadingState {
            sendingIndicatorView.isHidden = false
            sendingFailedIcon.isHidden = true
            sendingFailedLabel.isHidden = true
            sendingRetryButton.isHidden = true
            sendingDeleteButton.isHidden = true
            sendingIndicatorView.play()
            
            errorMaskView.isHidden = true
        } else if self.isFailState {
            sendingFailedLabel.text = item?.errorMsgFromCode
            sendingIndicatorView.isHidden = true
            sendingFailedIcon.isHidden = false
            sendingFailedLabel.isHidden = false
            sendingRetryButton.isHidden = false
            let canDeleteComment = item?.enumError?.canDeleteComment ?? true
            sendingDeleteButton.isHidden = !canDeleteComment
            sendingIndicatorView.stop()
            
            
            // error
            // 排除非图片下载错误
            if item?.enumError == .loadImageError {
                errorMaskView.isHidden = true
            } else {
                errorMaskView.isHidden = false
            }
        } else {
            sendingIndicatorView.stop()
            sendingIndicatorView.isHidden = true
            sendingFailedIcon.isHidden = true
            sendingFailedLabel.isHidden = true
            sendingRetryButton.isHidden = true
            sendingDeleteButton.isHidden = true
            errorMaskView.isHidden = true
        }
        
        //新的loading
        setNewLoadingState()
    }
    
    //loading 蒙层处理
    private func setLoadingMaskState() {
        if self.isLoadingState {
           loadingView.isHidden = false
        } else {
           loadingView.isHidden = true
        }
    }
    
    //只处理新 loading 显示
    private func setNewLoadingState() {
        if self.isLoadingState {
            //是否有图片
            if let previewImageInfos = self.item?.previewImageInfos, previewImageInfos.count > 0 {
                //隐藏文本loading
                newLoadingView.isHidden = true
                newLoadingView.endStop()
                
                //显示图片loading
                imagePreview.showLoading(true)
                
                newLoadingView.snp.updateConstraints { make in
                    make.width.height.equalTo(0)
                    make.left.top.equalTo(0)
                }
                
            } else {
                //显示文本loading
                newLoadingView.isHidden = false
                newLoadingView.startPlay()
                //隐藏图片loading
                imagePreview.showLoading(false)
                
                //获取文本loading位置
                let (newLoadingPoint, lineHight, isAddTail) = calculateNewLoadingViewPosition()
                //是否显示白色渐变蒙层
                newLoadingView.showBgMask(isAddTail)
                newLoadingView.snp.updateConstraints { make in
                    make.width.equalTo(sendingNewLoadingViewWidth)
                    make.height.equalTo(lineHight)
                    make.left.equalTo(newLoadingPoint.x)
                    make.top.equalTo(newLoadingPoint.y)
                }
            }
        } else {
            //隐藏文本loading
            newLoadingView.isHidden = true
            newLoadingView.endStop()
            //隐藏图片loading
            imagePreview.showLoading(false)
            newLoadingView.snp.updateConstraints { make in
                make.width.height.equalTo(0)
                make.left.top.equalTo(0)
            }
        }
    }


    private func setupBind() {
        moreActionButton.rx.tap.bind { [weak self] in
            guard let self = self else { return }
            if let item = self.item {
                if self.isLoadingState || self.errorMaskView.isHidden == false {
                    DocsLogger.info("moreActionButton rejected with loading or error", component: LogComponents.comment)
                    return
                }
                self.delegate?.didClickMoreAction(button: self.moreActionButton, cell: self, commentItem: item)
            }
        }.disposed(by: disposeBag)

        addGestureRecognizer(longPressGesture)

    }

    // 点击翻译icon
    @objc
    private func translateIconTap() {
        guard let item = item else { return }
        delegate?.didClickTranslationIcon(item, self)
    }

    // 点击头像
    @objc
    private func didClickAvatarImage() {
        if let item = item, !item.userID.isEmpty {
            delegate?.didClickAvatarImage(item: item, newInput: false)
        }
    }

    // 点击富文本
    @objc
    private func didClickDetail(sender: UIGestureRecognizer) {
        guard let item = item else {
            return
        }
        let detailLocation = sender.location(in: contentLabel)
        if contentLabel.bounds.contains(detailLocation), let attributedText = contentLabel.attributedText {
            let storage = NSTextStorage(attributedString: attributedText)
            let manager = NSLayoutManager()
            storage.addLayoutManager(manager)
            let container = NSTextContainer(size: CGSize(width: contentLabel.bounds.size.width, height: CGFloat.greatestFiniteMagnitude))
            container.lineFragmentPadding = 0
            container.maximumNumberOfLines = contentLabel.numberOfLines
            container.lineBreakMode = .byWordWrapping
            manager.addTextContainer(container)
            let index = manager.characterIndex(for: detailLocation, in: container, fractionOfDistanceBetweenInsertionPoints: nil)
            let attributes = attributedText.attributes(at: index, effectiveRange: nil)
            let rect = CGRect(origin: CGPoint(x: detailLocation.x - 18, y: detailLocation.y - 18), size: CGSize(width: 18, height: 40))
            if let atInfo = attributes[AtInfo.attributedStringAtInfoKey] as? AtInfo {
                delegate?.didClickAtInfo(atInfo, item: item, rect: rect, rectInView: contentLabel)
            } else if let urlInfo = attributes[AtInfo.attributedStringURLKey] as? URL {
                if urlInfo.docs.isEmail {
                    delegate?.didClickURL(urlInfo)
                } else if let modifiedUrl = urlInfo.docs.avoidNoDefaultScheme {
                    delegate?.didClickURL(modifiedUrl)
                } else { // 基本不会走这里
                    DocsLogger.info("urlInfo:\(urlInfo) is invalid", component: LogComponents.comment)
                }
            } else if let attachment = attributes[.attachment] as? NSTextAttachment,
                let atInfo = attachment.additionalInfo as? AtInfo {
                // 处理@自己的情况。
                delegate?.didClickAtInfo(atInfo, item: item, rect: rect, rectInView: contentLabel)
            } else {
                didHightLightTap(sender: sender)
            }
        }
    }

    @objc
    private func didClickDetail2(sender: UIGestureRecognizer) {
        guard let item = item else {
            return
        }
        let contentLabel = self.translationView.content
        let detailLocation = sender.location(in: contentLabel)
        if contentLabel.bounds.contains(detailLocation), let attributedText = contentLabel.attributedText {
            let storage = NSTextStorage(attributedString: attributedText)
            let manager = NSLayoutManager()
            storage.addLayoutManager(manager)
            let container = NSTextContainer(size: CGSize(width: contentLabel.bounds.size.width, height: CGFloat.greatestFiniteMagnitude))
            container.lineFragmentPadding = 0
            container.maximumNumberOfLines = contentLabel.numberOfLines
            container.lineBreakMode = contentLabel.lineBreakMode
            manager.addTextContainer(container)
            let index = manager.characterIndex(for: detailLocation, in: container, fractionOfDistanceBetweenInsertionPoints: nil)
            let attributes = attributedText.attributes(at: index, effectiveRange: nil)
            let rect = CGRect(origin: CGPoint(x: detailLocation.x - 18, y: detailLocation.y - 18), size: CGSize(width: 18, height: 40))
            if let atInfo = attributes[AtInfo.attributedStringAtInfoKey] as? AtInfo {
                delegate?.didClickAtInfo(atInfo, item: item, rect: rect, rectInView: contentLabel)
            } else if let urlInfo = attributes[AtInfo.attributedStringURLKey] as? URL {
                if urlInfo.docs.isEmail {
                    delegate?.didClickURL(urlInfo)
                } else if let modifiedUrl = urlInfo.docs.avoidNoDefaultScheme {
                    delegate?.didClickURL(modifiedUrl)
                } else { // 基本不会走这里
                    DocsLogger.info("urlInfo:\(urlInfo) is invalid", component: LogComponents.comment)
                }
            } else if let attachment = attributes[.attachment] as? NSTextAttachment,
                let atInfo = attachment.additionalInfo as? AtInfo {
                // 处理@自己的情况。
                delegate?.didClickAtInfo(atInfo, item: item, rect: rect, rectInView: contentLabel)
            } else {
                didHightLightTap(sender: sender)
            }
        }
    }

    private func _setupAccessibilityIdentifier(for cell: UITableViewCell, item: CommentItem?) {
        guard let content = item?.content else { return }
        
        let expression: NSRegularExpression? = AtInfo.mentionRegex
        
        guard let pattern = expression else { return }
        
        let legacyAction = { () -> [AtInfo.AtInfoOrString] in
            return AtInfo.baseParseMessageContent(in: content, pattern: pattern)
        }
        
        let results: [AtInfo.AtInfoOrString]
        do {
            results = try AtInfo.parseMessageContent(in: content, pattern: pattern, makeInfo: AtInfoXMLParser.getMentionDataFrom)
        } catch {
            results = legacyAction()
        }
        
        var accessibilityIdentifier = ""

        for result in results {
            switch result {
            case .atInfo(let info):
                accessibilityIdentifier += ("<" + "\(info.type.rawValue)" + info.at + ">")
                contentAtInfos.append(info)
            case .string(let content):
                accessibilityIdentifier += content
            }
        }

        contentLabel.accessibilityIdentifier = accessibilityIdentifier
    }

    private func _setTitleLabelText(_ item: CommentItem?) {
        let editted = (item?.modify == 1)
        let timeStamp = editted ? item?.updateTimeStamp : item?.createTimeStamp
        // TODO: displayName 待后续接入
//        titleLabel.config(displayName: item?.displayName, timeString: timeStamp?.stampDateFormatter, editted: editted)
        titleLabel.config(displayName: item?.name, timeString: timeStamp?.stampDateFormatter, editted: editted)
    }

    private func _updateReaction(_ item: CommentItem?) {
        guard let reactions = item?.reactions,
              !reactions.isEmpty,
              canShowReactionView else {
            reactionView.reactions = []
            reactionView.isHidden = true
            return
        }
        reactionView.isHidden = false
        if reactionView.preferMaxLayoutWidth <= 0 {
            updateReactionViewMaxWidth(cellWidth: cellWidth)
        }
        UIView.performWithoutAnimation {
            self.reactionView.reactions = reactions.map({ $0.toLarkReactionInfo() })
        }
        reactionView.tagBackgroundColor = UIColor.ud.udtokenReactionBgGreyFloat
    }

    /// 点击发送中的删除
    @objc
    func deleteClick(_ sender: UIButton) {
        guard let item = item else { return }
        delegate?.didClickSendingDelete(item)
    }

    /// 点击发送中的重试
    @objc
    func retryClick(_ sender: UIButton) {
        guard let item = item else { return }
        delegate?.didClickRetry(item)
    }
}

extension CommentTableViewCell: ReactionViewDelegate {
    func reactionBeginTap(_ reactionVM: ReactionInfo, tapType: ReactionTapType) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        let data = (reactionVM, tapType)
        let delay = ReactionView.iconAnimationDuration
        self.perform(#selector(handleTapReactionIcon), with: data, afterDelay: delay)
    }

    func reactionDidTapped(_ reactionVM: ReactionInfo, tapType: ReactionTapType) {
        switch tapType {
        case .name, .more:
            handleTapReactionIcon((reactionVM, tapType))
        case .icon: break
        @unknown default: break
        }
    }

    func reactionViewImage(_ reactionVM: ReactionInfo, callback: @escaping (UIImage) -> Void) {
        if let image = EmotionResouce.shared.imageBy(key: reactionVM.reactionKey) {
            callback(image)
        }
    }
}

extension CommentTableViewCell {
    @objc
    dynamic func setupUI() {
        selectionStyle = .none
        contentView.addSubview(avatarImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(contentLabel)
        contentView.addSubview(moreActionButton)
        contentView.addSubview(reactionView)
        contentView.addSubview(translationBgView)
        contentView.addSubview(translationView)
        contentView.addSubview(translationLoadingView)
        translationLoadingView.addSubview(translateIconCover)
        translateIconCover.backgroundColor = .clear
        contentView.addSubview(imagePreview)
        /// 发送中的控件
        contentView.addSubview(sendingDeleteButton)
        contentView.addSubview(sendingFailedIcon)
        contentView.addSubview(sendingFailedLabel)
        contentView.addSubview(sendingRetryButton)
        contentView.addSubview(sendingIndicatorView)
        
        contentView.addSubview(loadingView)
        contentView.addSubview(errorMaskView)

        translationLoadingView.isHidden = true
        avatarImageView.layer.cornerRadius = avatarImagWidth / 2.0
        
        translateIconCover.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(translateIconTap)))
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if !translationLoadingView.isHidden {
            let convertPoint = translateIconCover.convert(point, from: self)
            if translateIconCover.bounds.contains(convertPoint) {
                return translateIconCover
            }
        }
        return super.hitTest(point, with: event)
    }
    
    @objc
    dynamic func setupConstraints() {
        translationLoadingView.snp.makeConstraints { (make) in
            make.right.equalTo(moreActionButton.snp.right)
            make.height.width.equalTo(translateIconWidth)
            make.top.equalTo(contentLabel.snp.bottom).offset(-3)
        }
        avatarImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: avatarImagWidth, height: avatarImagWidth))
            make.left.equalToSuperview().offset(leftRightPadding)
            make.top.equalToSuperview().offset(14)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarImageView.snp.right).offset(titleLeftMargin)
            make.right.equalTo(moreActionButton.snp.left).offset(-2)
            make.top.equalTo(avatarImageView.snp.top)
        }
        contentLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(5)
            make.left.equalTo(titleLabel)
            make.right.lessThanOrEqualToSuperview().offset(-leftRightPadding)
        }
        moreActionButton.snp.makeConstraints { (make) in
            make.height.equalTo(24)
            make.width.equalTo(30)
            make.right.equalTo(-leftRightPadding - 2)
            make.centerY.equalTo(titleLabel)
        }
        translationBgView.snp.makeConstraints { (make) in
            make.left.equalTo(translationView.snp.left).offset(-translateBgLeftRightGap)
            make.right.equalTo(translationView.snp.right).offset(translateBgLeftRightGap)
            make.top.equalTo(translationView.snp.top).offset(-translateBgBottomTopGap)
            make.bottom.equalTo(translationView.snp.bottom).offset(translateBgBottomTopGap)
        }
        translationView.snp.makeConstraints { (make) in
            make.left.equalTo(contentLabel)
            make.right.lessThanOrEqualToSuperview().offset(-leftRightPadding)
            make.top.equalTo(contentLabel.snp.bottom).offset(8)
        }
        imagePreview.snp.makeConstraints { (make) in
            make.top.equalTo(translationView.snp.bottom)
            make.left.equalToSuperview().offset(leftRightPadding)
            make.right.equalToSuperview().offset(-leftRightPadding)
        }
        reactionView.snp.makeConstraints { (make) in
            make.top.equalTo(imagePreview.snp.bottom).offset(reactionTopMargin)
            make.left.equalTo(contentLabel)
            make.right.equalTo(-leftRightPadding)
            make.bottom.equalToSuperview().offset(-reactionBottomMargin)
        }
        /// sendState相关view
        sendingDeleteButton.snp.makeConstraints { (make) in
            make.height.equalTo(sendingDeleteIconHeight)
            make.width.equalTo(sendingDeleteIconHeight)
            make.right.equalTo(-leftRightPadding)
            make.centerY.equalTo(titleLabel)
        }

        loadingView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(avatarImageView)
            make.bottom.equalToSuperview().offset(-contentInset)
        }
        
        errorMaskView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.left.equalTo(contentLabel)
            make.top.equalTo(contentLabel)
            make.bottom.equalTo(reactionView)
        }
    }

    
    @objc
    dynamic func updateViewsLayoutIfNeed() {
        let isLoadingOrFail = self.isLoadingState || self.isFailState
        let translationViewHidden = translationView.isHidden
        let translationIconHidden = translationLoadingView.isHidden
        let isReactionViewHidden = reactionView.isHidden
        let (appendIconAtLastLine, moreThanOneLine) = needAppendIconAtLastLine()

        translationView.snp.remakeConstraints { (make) in
            make.left.equalTo(contentLabel)
            make.right.lessThanOrEqualToSuperview().offset(-leftRightPadding)
            if translationViewHidden {
                make.top.equalTo(contentLabel.snp.bottom).offset(0)
                make.height.equalTo(0)
            } else {
                make.top.equalTo(contentLabel.snp.bottom).offset(8)
            }
        }

        translationBgView.snp.remakeConstraints { (make) in
            make.left.equalTo(translationView.snp.left).offset(-translateBgLeftRightGap)
            make.top.equalTo(translationView.snp.top).offset(-translateBgBottomTopGap)
            make.bottom.equalTo(translationView.snp.bottom).offset(translateBgBottomTopGap)
            if moreThanOneLine {
                make.right.equalToSuperview().offset(-leftRightPadding + translateBgLeftRightGap)
            } else {
                make.right.equalTo(translationView.snp.right).offset(translateBgLeftRightGap)
            }
        }

        translationLoadingView.snp.remakeConstraints { (make) in
            make.right.equalToSuperview().offset(-leftRightPadding + translateBgLeftRightGap)

            make.right.equalTo(moreActionButton.snp.right)
            if !translationIconHidden {
                make.height.width.equalTo(translateIconWidth)
                if translationViewHidden {
                    make.top.equalTo(contentLabel.snp.bottom).offset(appendIconAtLastLine ? -translateIconWidth : 0)
                } else {
                    make.top.equalTo(translationView.snp.bottom).offset(appendIconAtLastLine ? -translateIconWidth + translateBgBottomTopGap : translateBgBottomTopGap + 2)
                }
            } else {
                make.height.width.equalTo(0)
                make.top.equalTo(contentLabel.snp.bottom).offset(0)
            }
        }

        imagePreview.snp.remakeConstraints { (make) in
            make.top.equalTo(translationLoadingView.snp.bottom)
            make.left.equalTo(contentLabel)
            make.right.equalTo(-leftRightPadding)
        }

        reactionView.snp.remakeConstraints { (make) in
            make.left.right.equalTo(contentLabel)
            if isLoadingOrFail == false {
                make.bottom.equalToSuperview().offset(-reactionBottomMargin)
            }
            if isReactionViewHidden {
                make.top.equalTo(imagePreview.snp.bottom).offset(0)
                make.height.equalTo(0)
            } else {
                make.top.equalTo(imagePreview.snp.bottom).offset(reactionTopMargin)
            }
        }

        // 发送中
        if self.isLoadingState {
            contentView.bringSubviewToFront(loadingView)
            sendingIndicatorView.snp.remakeConstraints { (make) in
                make.top.equalTo(reactionView.snp.bottom).offset(sendingFailIconTopGap)
                make.left.equalTo(contentLabel)
                make.height.equalTo(sendingLoadingIconHeight)
                make.width.equalTo(sendingLoadingIconHeight)
                make.bottom.equalToSuperview().offset(-contentInset)
            }
            sendingFailedIcon.snp.remakeConstraints { (make) in
                make.width.height.equalTo(0)
                make.left.top.equalTo(0)
            }
            sendingFailedLabel.snp.remakeConstraints { (make) in
                make.width.height.equalTo(0)
                make.left.top.equalTo(0)
            }
            sendingRetryButton.snp.remakeConstraints { (make) in
                make.width.height.equalTo(0)
                make.left.top.equalTo(0)
            }
        // 发送失败
        } else if self.isFailState {
            contentView.bringSubviewToFront(errorMaskView)
            sendingIndicatorView.snp.remakeConstraints { (make) in
                make.width.height.equalTo(0)
                make.left.top.equalTo(0)
            }
            sendingFailedIcon.snp.remakeConstraints { (make) in
                make.top.equalTo(reactionView.snp.bottom).offset(sendingFailIconTopGap)
                make.left.equalTo(contentLabel)
                make.height.equalTo(sendingFailIconHeight)
                make.width.equalTo(sendingFailIconHeight)
            }
            sendingFailedLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(sendingFailedIcon.snp.right).offset(6)
                make.top.equalTo(sendingFailedIcon).offset(-1.5)
                make.right.equalTo(-leftRightPadding)
            }
            sendingRetryButton.snp.remakeConstraints { (make) in
                make.top.equalTo(sendingFailedLabel.snp.bottom).offset(sendingRetryBtnTopGap)
                make.left.equalTo(sendingFailedIcon)
                make.height.equalTo(sendingRetryBtnHeight)
                make.bottom.equalToSuperview().offset(-contentInset)
            }
        // 正常场景
        } else {
            sendingFailedIcon.snp.remakeConstraints { (make) in
                make.width.height.equalTo(0)
                make.left.top.equalTo(0)
            }
            sendingFailedLabel.snp.remakeConstraints { (make) in
                make.width.height.equalTo(0)
                make.left.top.equalTo(0)
            }
            sendingRetryButton.snp.remakeConstraints { (make) in
                make.width.height.equalTo(0)
                make.left.top.equalTo(0)
            }
            sendingIndicatorView.snp.remakeConstraints { (make) in
                make.width.height.equalTo(0)
                make.left.top.equalTo(0)
            }
        }
    }

    func updateReactionViewMaxWidth(cellWidth: CGFloat? = nil) {
        let cellCopy = cellWidth ?? self.contentView.frame.size.width
        if cellCopy > 84 {
            self.reactionView.preferMaxLayoutWidth = reactionMaxLayoutWidth(cellCopy)
        }
    }

    @objc
    dynamic func reactionMaxLayoutWidth(_ cellWidth: CGFloat) -> CGFloat {
        return CGFloat(cellWidth - 84)
    }

    private func _setupMoreButton() -> UIButton {
        let button = UIButton()
        let image = UDIcon.getIconByKey(.moreOutlined, renderingMode: .alwaysOriginal, iconColor: UIColor.ud.iconN3, size: .init(width: 16, height: 16))
        button.setImage(image, for: .normal)
        button.setImage(image, for: .highlighted)
        button.contentHorizontalAlignment = .center
        button.isHidden = true
        button.docs.addHighlight(with: UIEdgeInsets(top: -2, left: -4, bottom: -2, right: -4), radius: 4)
        return button
    }

    private func _setupSingleTap() -> UITapGestureRecognizer {
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(didClickDetail))
        singleTap.delegate = self
        return singleTap
    }

    private func _setupSingleTap2() -> UITapGestureRecognizer {
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(didClickDetail2))
        singleTap.delegate = self
        return singleTap
    }

    private func _setupLongPress() -> UILongPressGestureRecognizer {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleGesuture(gesture:)))
        longPress.minimumPressDuration = 0.4
        longPress.delegate = self
        return longPress
    }

    @objc
    func handleGesuture(gesture: UILongPressGestureRecognizer) {
        
        if self.isLoadingState || errorMaskView.isHidden == false {
            DocsLogger.info("press gesture rejected with loading or error", component: LogComponents.comment)
            return
        }
        delegate?.didLongPressToShowReaction(self, gesture: gesture)
    }

    private func constructUI() {
        sendingDeleteButton = UIButton().construct({
            $0.isHidden = true
            $0.addTarget(self, action: #selector(deleteClick(_ :)), for: .touchUpInside)
            $0.imageView?.contentMode = .scaleAspectFill
            $0.contentHorizontalAlignment = .fill
            $0.setBackgroundImage(BundleResources.SKResource.Common.Comment.comment_delete,
                                  for: .normal)
        })

        sendingIndicatorView = AnimationViews.commentSendLoadingAnimation.construct({
            $0.isHidden = true
            $0.loopAnimation = true
            $0.autoReverseAnimation = false
            $0.backgroundColor = UIColor.clear
        })

        sendingFailedIcon = UIImageView().construct({
            $0.isHidden = true
            $0.image = UDIcon.warningRedColorful
        })

        sendingFailedLabel = UILabel().construct({
            $0.isHidden = true
            $0.numberOfLines = 0
            $0.font = contentFont
            $0.textColor = UIColor.ud.N600
        })

        sendingRetryButton = UIButton().construct({
            $0.isHidden = true
            $0.addTarget(self, action: #selector(retryClick(_ :)), for: .touchUpInside)
            $0.setTitle(BundleI18n.SKResource.Doc_Comment_Retry, for: .normal)
            $0.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
            $0.titleLabel?.font = contentFont
        })

        translateIconTapGueture = UITapGestureRecognizer().construct({
            $0.addTarget(self, action: #selector(translateIconTap))
            $0.delegate = self
        })
        translationLoadingView.addGestureRecognizer(translateIconTapGueture)
    }

    private func _setupReactionView() -> ReactionView {
        let reactionView = ReactionView()
        reactionView.delegate = self
        reactionView.tagBackgroundColor = UIColor.ud.udtokenReactionBgGreyFloat
        return reactionView
    }

    private func setupImagePreview() -> CommentCardImagesPreview {
        let imagePreview = CommentCardImagesPreview()
        imagePreview.delegate = self
        return imagePreview
    }

    private func _setupContentLabel() -> UILabel {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(singleTapGesture)
        return label
    }

    private func _setupTranslationView() -> TranslationViewV2 {
        let view = TranslationViewV2(frame: .zero)
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(singleTapGesture2)
        return view
    }

    private func _setupTranslationBgView() -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.ud.N200
        view.layer.cornerRadius = 4
        view.layer.masksToBounds = true
        return view
    }

    private func _setupAvatarImageView() -> UIImageView {
        let imageView = SKAvatar(configuration: .init(style: .circle,
                                               contentMode: .scaleAspectFill))
        imageView.layer.masksToBounds = true
        imageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didClickAvatarImage))
        tapGesture.delegate = self
        imageView.addGestureRecognizer(tapGesture)
        return imageView
    }
    
    func updateMoreButton(_ length: CGFloat) {
        let image = UDIcon.getIconByKey(.moreOutlined, renderingMode: .alwaysOriginal, iconColor: UIColor.ud.iconN3, size: .init(width: length, height: length))
        moreActionButton.setImage(image, for: .normal)
        moreActionButton.setImage(image, for: .highlighted)
    }
}

extension CommentTableViewCell: CommentImagesEventProtocol {
    func didClickPreviewImage(imageInfo: CommentImageInfo) {
        guard let item = self.item else {
            DocsLogger.error("item is nil", component: LogComponents.comment)
            return
        }
        self.delegate?.didClickPreviewImage(item, imageInfo: imageInfo)
    }
    
    func loadImagefailed(item: CommentItem?, imageInfo: CommentImageInfo) {
        guard let itemForImageInfo = item else {
            DocsLogger.error("itemForImageInfo is nil", component: LogComponents.comment)
            return
        }
        self.delegate?.didLoadImagefailed(itemForImageInfo, imageInfo: imageInfo)
    }
}
