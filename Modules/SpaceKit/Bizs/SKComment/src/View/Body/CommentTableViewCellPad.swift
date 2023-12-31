//
//  CommentTableViewCellPad.swift
//  SKCommon
//
//  Created by chenhuaguan on 2021/2/2.
//  swiftlint:disable function_body_length

import UIKit
import RxSwift
import RxCocoa
import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignFont
import SpaceInterface

class CommentTableViewCellPad: CommentTableViewCell, CommentTextInputCellType {

    // nolint-next-line: magic number
    static var LeftRightGapPad: CGFloat { 12.0 }
    // nolint-next-line: magic number
    static var ContentRightPad: CGFloat { 12.0 + 32.0 + 8.0 }
    /// 布局参数
    private let leftRightGapPad: CGFloat = LeftRightGapPad
    private let contentRightPad: CGFloat = ContentRightPad
    private let contentTopBottomGapPad: CGFloat = 8.0
    private let reactionViewLeftGapPad: CGFloat = 12.0
    private let reactionViewRightGapPad: CGFloat = 12.0
    private let reactionViewTopGapPad: CGFloat = 4.0
    private let sendingLoadingTopGapPad: CGFloat = 6.0
    private let sendingRetryBtnTopGapPad: CGFloat = 3.0
    private let sendingFailIconTopGapPad: CGFloat = 10.0

    static let avatarImagWidthPad: CGFloat = 32.0

    override var cellVersion: CommentCellVersion {
        return .iPad
    }

    override var timeLabelColor: UIColor {
        return UIColor.ud.N500
    }

    override var titleFontSize: CGFloat {
        // nolint-next-line: magic number
        return 12
    }

    override var zoomable: Bool {
        didSet {
            currentContentFont = zoomable ? UIFont.ud.body2 : UIFont.systemFont(ofSize: 14)
        }
    }
    
    override var contentFont: UIFont {
        return currentContentFont
    }

    override var fontLineSpace: CGFloat? {
        return 4
    }

    override var emptySpaceForContent: CGFloat {
        return CGFloat(leftRightGapPad + contentRightPad + bgShadowLeftRightGap * 2)
    }

    private(set) var isCommentEditing: Bool = false
    weak var inputTextView: InputTextView?
    
    weak var toolbarView: CommentToolBar?
    //weak var inputViewEditingDelegate: CommentInputViewEditingDelegate?
    
    weak var textDelegate: CommentTextViewTextChangeDelegate?

    var textViewActiveWorkItem: DispatchWorkItem?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(statusBarOrientationChange),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        currentContentFont = UIFont.systemFont(ofSize: 14)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentLabel.preferredMaxLayoutWidth = self.contentView.frame.size.width - leftRightGapPad - contentRightPad - bgShadowLeftRightGap * 2
    }

    @objc
    func statusBarOrientationChange() {
        let delay = TimeInterval(0.3)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.updateReactionViewMaxWidth()
        }
    }

    public override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touchView = touch.view else {
            return true
        }
        if gestureRecognizer == highLightTap {
            if touchView.isDescendant(of: self.reactionView), touchView.superview != self.reactionView, touchView != self.reactionView {
                return false
            }
            if let inputTextView = inputTextView, touchView.isDescendant(of: inputTextView) {
                return false
            }
            return true
        }
        return true
    }

    @objc
    override func handleGesuture(gesture: UILongPressGestureRecognizer) {
        if highLighted, isCommentEditing == false {
            super.handleGesuture(gesture: gesture)
        }
    }

    weak var textViewDependency: AtInputTextViewDependency?
    
    var textView: AtInputTextView?
    
    override func setupUI() {
        contentView.addSubview(bgShadowView)
        super.setupUI()
        translationLoadingView.isHidden = true
        avatarImageView.layer.cornerRadius = Self.avatarImagWidthPad / 2.0
        let delay = TimeInterval(0.05)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.updateReactionViewMaxWidth()
        }
    }

    override func updateViewsLayoutIfNeed() {
        if self.isCommentEditing == true {
            updateEditingLayout()
        } else {
            updateNormalLayout()
        }
    }

    func updateEditingLayout() {
        DocsLogger.info("updateEditingLayout inputTextView", component: LogComponents.comment)
        
        textView?.snp.makeConstraints { make in
            make.left.equalTo(bgShadowView).offset(12)
            make.right.equalTo(bgShadowView).offset(-12)
            make.top.equalTo(avatarImageView.snp.bottom).offset(8)
            make.bottom.equalTo(bgShadowView).offset(-16)
        }
        textView?.isHidden = false
        // normal下的控件
        let subviews = [contentLabel, translationView, translationBgView, translationLoadingView, imagePreview,
                        reactionView, sendingIndicatorView, sendingFailedIcon, sendingFailedLabel, sendingRetryButton]
        removeAndHideSubview(subviews: subviews)
        moreActionButton.isHidden = true
        sendingDeleteButton.isHidden = true
    }

    private func removeAndHideSubview(subviews: [UIView?]) {
        subviews.forEach {
            $0?.snp.removeConstraints()
            $0?.isHidden = true
        }
    }
    
    override func reactionMaxLayoutWidth(_ cellWidth: CGFloat) -> CGFloat {
        return CGFloat(cellWidth - leftRightGapPad - contentRightPad - bgShadowLeftRightGap * 2)
    }


    func updateEditingState(isEditing: Bool, inputView: InputTextView?, toolbarView: CommentToolBar?, commentContent: CommentContent?) {
        self.isCommentEditing = isEditing
        guard let inputTextView = inputView else { return }
        if isEditing {
            DocsLogger.info("update editing inputTextView", component: LogComponents.comment)
            if inputTextView.superview == nil || inputTextView.superview != contentView {
                inputTextView.snp.removeConstraints()
                self.inputTextView = inputTextView
                inputTextView.removeFromSuperview()
                contentView.addSubview(inputTextView)
            }
            guard let toolView = toolbarView else { return }
            if toolView.superview == nil || toolView.superview != contentView {
                toolView.snp.removeConstraints()
                self.toolbarView = toolView
                toolView.removeFromSuperview()
                contentView.addSubview(toolView)
            }

        }
    }
    
    override func configCellData(_ item: CommentItem, isFailState: Bool = false, isLoadingState: Bool = false) {
        super.configCellData(item, isFailState: isFailState, isLoadingState: isLoadingState)
        isCommentEditing = item.isEditing
        self.highLighted = curCommment?.isActive ?? false
        if case .edit(let isFirstResponser) = item.viewStatus {
            if textView == nil {
                textView = AtInputTextView(dependency: textViewDependency, font: item.padFont, ignoreRotation: true)
                textView?.textChangeDelegate = textDelegate
                textView?.focusType = .edit
                textView?.fixPadKeyboardInputView = UserScopeNoChangeFG.LJW.sheetInputViewFix
                contentView.addSubview(textView!)
            }
            let workItem = DispatchWorkItem(block: { [weak self] in
                if isFirstResponser {
                    self?.textView?.textviewBecomeFirstResponder()
                } else {
                    self?.textView?.textViewResignFirstResponder()
                }
            })
            textViewActiveWorkItem = workItem
            DispatchQueue.main.async(execute: workItem)
            updateEditingLayout()
            longPressGesture.isEnabled = false
        } else {
            updateNormalLayout()
            longPressGesture.isEnabled = true
        }
        textView?.toolBar.forceVoiceButtonHidden = !item.showVoice
    }
    
    func update(wrapper: CommentWrapper?) {
        textView?.commentWrapper = wrapper
        guard let item = item, let wrapper = wrapper else { return }
        if case .edit = item.viewStatus {
            textView?.restoreDraft()
        }
    }
    
    override func featchAtUserPermissionResult() {
        if item?.viewStatus.isEdit == true {
            // 正在编辑时，不接受权限通知刷新
            return
        }
        super.featchAtUserPermissionResult()
    }
}

extension CommentTableViewCellPad {
    
    override func setupConstraints() {
        bgShadowView.snp.remakeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(bgShadowLeftRightGap)
            make.right.equalToSuperview().offset(-bgShadowLeftRightGap)
        }
        avatarImageView.snp.remakeConstraints { (make) in
            make.size.equalTo(CGSize(width: Self.avatarImagWidthPad, height: Self.avatarImagWidthPad))
            make.left.equalTo(bgShadowView.snp.left).offset(leftRightGapPad)
            make.top.equalTo(bgShadowView.snp.top).offset(contentTopBottomGapPad)
        }
        titleLabel.snp.remakeConstraints { (make) in
            make.left.equalTo(avatarImageView.snp.right).offset(8)
            make.top.equalTo(avatarImageView.snp.top)
            make.height.equalTo(17)
            make.right.lessThanOrEqualTo(moreActionButton.snp.left).offset(-5)
        }

        moreActionButton.snp.remakeConstraints { (make) in
            make.height.equalTo(24)
            make.width.equalTo(24)
            make.right.equalTo(bgShadowView.snp.right).offset(-leftRightGapPad)
            make.centerY.equalTo(titleLabel)
        }
        sendingDeleteButton.snp.remakeConstraints { (make) in
            make.height.equalTo(sendingDeleteIconHeight)
            make.width.equalTo(sendingDeleteIconHeight)
            make.right.equalTo(bgShadowView.snp.right).offset(-leftRightGapPad)
            make.centerY.equalTo(titleLabel)
        }
        translateIconCover.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(40)
        }

        loadingView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-contentInset)
        }
        
        errorMaskView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.left.equalTo(contentLabel)
            make.top.equalTo(contentLabel)
            make.bottom.equalTo(reactionView)
        }
    }
    
    func updateNormalLayout() {
        // editing下的控件
        
        textView?.snp.removeConstraints()
        textView?.isHidden = true
        
        moreActionButton.isHidden = !canShowMoreActionButton

        let isLoadingOrFail = self.isLoadingState || self.isFailState
        let translationViewHidden = translationView.isHidden
        let translationIconHidden = translationLoadingView.isHidden
        let isReactionViewHidden = reactionView.isHidden
        let (appendIconAtLastLine, moreThanOneLine) = needAppendIconAtLastLine()

        contentLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(7)
            //make.left.equalTo(bgShadowView.snp.left).offset(leftRightGapPad)
            make.left.equalTo(titleLabel.snp.left).offset(0)
            make.right.lessThanOrEqualTo(bgShadowView.snp.right).offset(-leftRightGapPad)
        }

        translationView.snp.remakeConstraints { (make) in
            make.left.equalTo(contentLabel)
            make.right.lessThanOrEqualTo(bgShadowView.snp.right).offset(-leftRightGapPad)
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
                make.right.equalTo(bgShadowView.snp.right).offset(-leftRightGapPad + translateBgLeftRightGap)
            } else {
                make.right.equalTo(translationView.snp.right).offset(translateBgLeftRightGap)
            }
        }

        translationLoadingView.snp.remakeConstraints { (make) in
            make.right.equalTo(bgShadowView.snp.right).offset(-leftRightGapPad + translateBgLeftRightGap)

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
            //make.left.equalTo(bgShadowView.snp.left).offset(leftRightGapPad)
            make.left.equalTo(titleLabel.snp.left).offset(0)
            make.right.equalTo(bgShadowView.snp.right).offset(-leftRightGapPad)
        }

        reactionView.snp.remakeConstraints { (make) in
            //make.left.equalTo(bgShadowView.snp.left).offset(reactionViewLeftGapPad)
            make.left.equalTo(titleLabel.snp.left).offset(0)
            make.right.equalTo(bgShadowView.snp.right).offset(-reactionViewRightGapPad)
            if isLoadingOrFail == false {
                make.bottom.equalTo(bgShadowView.snp.bottom).offset(-contentTopBottomGapPad)
            }
            if isReactionViewHidden {
                make.top.equalTo(imagePreview.snp.bottom).offset(0)
                make.height.equalTo(0)
            } else {
                make.top.equalTo(imagePreview.snp.bottom).offset(reactionViewTopGapPad)
            }
        }

        // 发送中
        if self.isLoadingState {
            contentView.bringSubviewToFront(loadingView)
            sendingIndicatorView.snp.remakeConstraints { (make) in
                make.top.equalTo(reactionView.snp.bottom).offset(sendingLoadingTopGapPad)
                make.left.equalTo(contentLabel)
                make.height.equalTo(sendingLoadingIconHeight)
                make.width.equalTo(sendingLoadingIconHeight)
                make.bottom.equalTo(bgShadowView.snp.bottom).offset(-contentTopBottomGapPad)
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
                make.top.equalTo(reactionView.snp.bottom).offset(sendingFailIconTopGapPad)
                make.left.equalTo(contentLabel)
                make.height.equalTo(sendingFailIconHeight)
                make.width.equalTo(sendingFailIconHeight)
            }
            sendingFailedLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(sendingFailedIcon.snp.right).offset(6)
                make.top.equalTo(sendingFailedIcon).offset(-1.5)
                make.right.equalTo(bgShadowView.snp.right).offset(-leftRightGapPad)
            }
            sendingRetryButton.snp.remakeConstraints { (make) in
                make.top.equalTo(sendingFailedLabel.snp.bottom).offset(sendingRetryBtnTopGapPad)
                make.left.equalTo(sendingFailedIcon)
                make.height.equalTo(sendingRetryBtnHeight)
                make.bottom.equalTo(bgShadowView.snp.bottom).offset(-contentTopBottomGapPad)
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

}
