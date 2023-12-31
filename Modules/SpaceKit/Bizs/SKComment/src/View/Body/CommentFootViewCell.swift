//
//  CommentFootViewCell.swift
//  SKCommon
//
//  Created by chenhuaguan on 2021/2/14.
//

import Foundation
import SKFoundation
import SKResource
import SKUIKit
import UIKit
import SpaceInterface
import SKCommon

protocol CommentTextInputCellType {
    var textView: AtInputTextView? { get }
    var textViewActiveWorkItem: DispatchWorkItem? { get }
}

class CommentFootViewCell: CommentShadowBaseCell, CommentTextInputCellType {
    
    private let leftRightGapPad: CGFloat = 16.0
    private let contentTopBottomGapPad: CGFloat = 12.0

    weak var inputTextView: InputTextView?
    
    weak var toolbarView: CommentToolBar?
    
    weak var delegate: CommentTableViewCellDelegate?
    var newInputComment: Comment?
    // 头像
    private(set) lazy var avatarImageView: UIImageView = setupAvatarImageView()
    // 名称
    private(set) lazy var titleLabel: UILabel = setupTitleLabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    weak var textViewDependency: AtInputTextViewDependency?
    
    var textView: AtInputTextView?

    var item: CommentItem?

    var textViewActiveWorkItem: DispatchWorkItem?
    
    func setupUI() {
        selectionStyle = .none
        contentView.addSubview(bgShadowView)
        contentView.addSubview(avatarImageView)
        contentView.addSubview(titleLabel)
        avatarImageView.layer.cornerRadius = CommentTableViewCellPad.avatarImagWidthPad / 2.0
        bgShadowView.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.top.equalToSuperview()
            make.height.greaterThanOrEqualTo(16)
            make.left.right.equalToSuperview().inset(bgShadowLeftRightGap)
        }
        
        avatarImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 0, height: 0))
            make.left.equalTo(bgShadowView.snp.left).offset(leftRightGapPad)
            make.top.equalTo(bgShadowView.snp.top).offset(contentTopBottomGapPad)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarImageView.snp.right).offset(8)
            make.height.equalTo(20)
            make.centerY.equalTo(avatarImageView)
            make.right.lessThanOrEqualTo(bgShadowView.snp.right).offset(-leftRightGapPad)
        }
    }
    
    func setupFullTextView(_ item: CommentItem, _ textDelegate: CommentTextViewTextChangeDelegate) {
        if textView == nil {
            textView = AtInputTextView(dependency: textViewDependency, font: item.padFont, ignoreRotation: true)
            textView?.fixPadKeyboardInputView = UserScopeNoChangeFG.LJW.sheetInputViewFix
            textView?.focusType = .new
            textView?.textChangeDelegate = textDelegate
            contentView.addSubview(textView!)
        }
    }

    func update(item: CommentItem, textDelegate: CommentTextViewTextChangeDelegate) {
        self.item = item
        updateAvatarAndTitle()

        let canShow = item.isNewInput && item.canComment && item.isActive
        avatarImageView.snp.updateConstraints { (make) in
            let wh: CGFloat = canShow ? CommentTableViewCellPad.avatarImagWidthPad : 0
            make.size.equalTo(CGSize(width: wh, height: wh))
        }
        titleLabel.snp.updateConstraints { (make) in
            let height: CGFloat = canShow ? 20 : 0
            make.height.equalTo(height)
        }
        avatarImageView.isHidden = !canShow
        titleLabel.isHidden = !canShow

        if case .reply(let isFirstResponser) = item.viewStatus { // 显示输入框
            bgShadowView.snp.updateConstraints { make in
                make.height.greaterThanOrEqualTo(8)
            }
            setupFullTextView(item, textDelegate)
            textView?.isHidden = false
            textView?.snp.remakeConstraints { (make) in
                if item.isNewInput {
                    make.left.right.equalTo(bgShadowView).inset(8)
                    make.top.equalTo(avatarImageView.snp.bottom).offset(16)
                } else {
                    make.left.right.equalTo(bgShadowView).inset(12)
                    make.top.equalToSuperview().offset(8)
                }
                make.bottom.equalToSuperview().offset(-14)
            }
            let workItem = DispatchWorkItem(block: { [weak self] in
                if isFirstResponser, !item.permission.contains(.disableAutoActiveKeyboard) {
                    self?.textView?.textviewBecomeFirstResponder()
                } else {
                    self?.textView?.textViewResignFirstResponder()
                }
            })
            textViewActiveWorkItem = workItem
            DispatchQueue.main.async(execute: workItem)
        } else { // 隐藏输入框
            bgShadowView.snp.updateConstraints { make in
                make.height.greaterThanOrEqualTo(16)
            }
            textView?.snp.removeConstraints()
            textView?.isHidden = true
        }
        textView?.toolBar.forceVoiceButtonHidden = !item.showVoice
    }
    
    func update(wrapper: CommentWrapper?) {
        textView?.commentWrapper = wrapper
        guard let item = item, let wrapper = wrapper else { return }
        if case .reply = item.viewStatus {
            textView?.restoreDraft()
        }
    }

    func updateView(needInputView: Bool, inputView: InputTextView?, toolbarView: CommentToolBar?, newInput: Bool) {
        guard needInputView else {
            bgShadowView.snp.remakeConstraints { (make) in
                make.bottom.equalToSuperview()
                make.top.equalToSuperview()
                make.height.greaterThanOrEqualTo(16)
                make.left.equalToSuperview().offset(bgShadowLeftRightGap)
                make.right.equalToSuperview().offset(-bgShadowLeftRightGap)
            }
            avatarImageView.snp.remakeConstraints { (make) in
                make.size.equalTo(CGSize(width: 0, height: 0))
                make.left.top.equalToSuperview()
            }
            titleLabel.snp.remakeConstraints { (make) in
                make.size.equalTo(CGSize(width: 0, height: 0))
                make.left.top.equalToSuperview()
            }
            if inputView?.superview == contentView {
                inputView?.removeFromSuperview()
            }
            
            if toolbarView?.superview == contentView {
                toolbarView?.removeFromSuperview()
            }
            return
        }
        guard let inputTextView = inputView else { return }
        DocsLogger.info("update footer inputTextView", component: LogComponents.comment)
        if inputTextView.superview == nil || inputTextView.superview != contentView {
            inputTextView.snp.removeConstraints()
            self.inputTextView = inputTextView
            if inputTextView.superview != nil {
                inputTextView.removeFromSuperview()
            }
            contentView.addSubview(inputTextView)
        }
        
        if let toolbar = toolbarView,
           toolbar.superview == nil || toolbar.superview != contentView {
            toolbar.snp.removeConstraints()
            self.toolbarView = toolbar
            toolbar.removeFromSuperview()
            contentView.addSubview(toolbar)
        }

        titleLabel.isHidden = !newInput
        avatarImageView.isHidden = !newInput
        bgShadowView.snp.remakeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.top.equalToSuperview()
            make.height.greaterThanOrEqualTo(8)
            make.left.equalToSuperview().offset(bgShadowLeftRightGap)
            make.right.equalToSuperview().offset(-bgShadowLeftRightGap)
        }
        if newInput {
            updateAvatarAndTitle()

            let imageWidth = CommentTableViewCellPad.avatarImagWidthPad
            avatarImageView.snp.remakeConstraints { (make) in
                make.size.equalTo(CGSize(width: imageWidth, height: imageWidth))
                make.left.equalTo(bgShadowView.snp.left).offset(leftRightGapPad)
                make.top.equalTo(bgShadowView.snp.top).offset(contentTopBottomGapPad)
            }
            titleLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(avatarImageView.snp.right).offset(8)
                make.top.equalTo(avatarImageView.snp.top)
                make.centerY.equalTo(avatarImageView)
                make.right.lessThanOrEqualTo(bgShadowView.snp.right).offset(-leftRightGapPad)
            }
            inputTextView.snp.remakeConstraints { (make) in
                make.height.greaterThanOrEqualTo(40).priority(.required)
                make.left.equalTo(bgShadowView).offset(8)
                make.right.equalTo(bgShadowView).offset(-8)
                make.top.equalTo(avatarImageView.snp.bottom).offset(16)
                if toolbarView == nil {
                    make.bottom.equalToSuperview().offset(-8)
                }
            }
        } else {
            avatarImageView.snp.remakeConstraints { (make) in
                make.size.equalTo(CGSize(width: 0, height: 0))
                make.left.top.equalToSuperview()
            }
            titleLabel.snp.remakeConstraints { (make) in
                make.size.equalTo(CGSize(width: 0, height: 0))
                make.left.top.equalToSuperview()
            }
            inputTextView.snp.remakeConstraints { (make) in
                make.height.greaterThanOrEqualTo(40).priority(.required)
                make.left.equalTo(bgShadowView).offset(12)
                make.right.equalTo(bgShadowView).offset(-12)
                make.top.equalToSuperview().offset(8)
                if toolbarView == nil {
                    make.bottom.equalToSuperview().offset(-8)
                }
            }
        }
        
        toolbarView?.snp.makeConstraints { (make) in
            make.height.equalTo(24)
            make.left.right.equalToSuperview().inset(8)
            make.top.equalTo(inputTextView.snp.bottom).offset(10)
            make.bottom.equalToSuperview().offset(-14)
        }
    }

    private func updateAvatarAndTitle() {
        let avatarURL = User.current.info?.avatarURL ?? ""
        avatarImageView.kf.setImage(with: URL(string: avatarURL), placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder)

        let userName = (DocsSDK.currentLanguage == .zh_CN ? User.current.info?.nameCn : User.current.info?.nameEn) ?? (User.current.info?.name ?? "")
        let aTitle = NSMutableAttributedString(string: userName, attributes: [
            .foregroundColor: UIColor.ud.N900,
            .font: UIFont.systemFont(ofSize: 14)
        ])
        titleLabel.attributedText = aTitle
    }
}


extension CommentFootViewCell {
    private func setupTitleLabel() -> UILabel {
        let label = UILabel(frame: .zero)
        label.isHidden = true
        return label
    }

    private func setupAvatarImageView() -> UIImageView {
        let imageView = UIImageView(frame: .zero)
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didClickAvatarImage))
        tapGesture.delegate = self
        imageView.addGestureRecognizer(tapGesture)
        imageView.isHidden = true
        return imageView
    }

    // 点击头像
    @objc
    private func didClickAvatarImage() {
        if newInputComment != nil, let item = item {
            delegate?.didClickAvatarImage(item: item, newInput: true)
        }
    }

    public override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touchView = touch.view else {
            return true
        }
        if gestureRecognizer == highLightTap {
            if let inputTextView = inputTextView, touchView.isDescendant(of: inputTextView) {
                return false
            }
            return true
        }
        return true
    }
}
