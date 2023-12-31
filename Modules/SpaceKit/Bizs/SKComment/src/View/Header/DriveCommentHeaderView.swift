//
//  CommentTitleView.swift
//  SpaceKit
//
//  Created by xurunkang on 2018/10/24.
//

import UIKit
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import SpaceInterface

protocol CommentDisplayProtocol: UIView {
    var currentComment: Comment? { get }
}

class DriveCommentHeaderView: UIView {

    weak var delegate: CommentHeaderViewDelegate?
    
    weak var displayView: CommentDisplayProtocol?

    // 滑动条块
    private lazy var commentPanBlock: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineBorderCard
        view.layer.cornerRadius = 2
        return view
    }()

    // 评论条数 Label
    private lazy var commentCountLabel: UILabel = {
        let commentCountLabel = UILabel()
        commentCountLabel.textAlignment = .center
        commentCountLabel.textColor = UIColor.ud.textTitle
        commentCountLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        commentCountLabel.accessibilityIdentifier = "docs.comment.headerview.count"
        return commentCountLabel
    }()

    // 返回按钮
    private lazy var commentBackButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(didClickBackButton), for: .touchUpInside)
        button.setImage(BundleResources.SKResource.Common.Global.icon_global_back_nor.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        return button
    }()

    // 向下收起按钮
    private lazy var commentCloseButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(didExitEditing), for: .touchUpInside)
        button.setImage(BundleResources.SKResource.Common.Comment.commentClose.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        return button
    }()

    // 解决评论按钮
    private lazy var commentSolveButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(didClickResolveButton(_:)), for: .touchUpInside)
        let image = UDIcon.getIconByKey(.moreOutlined, renderingMode: .alwaysOriginal, iconColor: UIColor.ud.iconN3, size: .init(width: 24, height: 24))
        button.setImage(image.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        button.setImage(image.ud.withTintColor(UIColor.ud.iconN1), for: .highlighted)
        button.contentHorizontalAlignment = .center
        button.accessibilityIdentifier = "docs.comment.headerview.more"
        button.docs.addHighlight(with: UIEdgeInsets(top: -2, left: -4, bottom: -2, right: -4), radius: 4)
        return button
    }()

    private var hideShowResolve: Bool = true

    private var commentCount: String?
    private var style: SpaceComment.Style

    init(style: SpaceComment.Style) {
        self.style = style

        super.init(frame: .zero)

        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCommentSolveButtonHidden(_ isHidden: Bool) {
        hideShowResolve = isHidden
        commentSolveButton.isHidden = isHidden
    }

    func setCommentCount(_ commentCount: String) {
        commentCountLabel.text = BundleI18n.SKResource.Doc_Facade_Comments + (style == .photo ? "" : "\(commentCount)")
        commentCountLabel.sizeToFit()
    }

    func changeStyle(_ style: SpaceComment.Style) {
        switch style {
        case .normal, .photo:
            commentCountLabel.isHidden = false
            commentBackButton.isHidden = true
            commentCloseButton.isHidden = true
            commentPanBlock.isHidden = false
            commentSolveButton.isHidden = hideShowResolve
            enablePanGesture()
        case .fullScreen:
            commentCountLabel.isHidden = true
            commentBackButton.isHidden = true
            commentCloseButton.isHidden = false
            commentPanBlock.isHidden = true
            commentSolveButton.isHidden = hideShowResolve
            disablePanGesture()
        case .edit:
            // 编辑模式隐藏三个点
            commentSolveButton.isHidden = true
        case .backV2:
            commentCountLabel.isHidden = false
            commentBackButton.isHidden = false
            commentCloseButton.isHidden = true
            commentPanBlock.isHidden = false
            commentSolveButton.isHidden = hideShowResolve
            enablePanGesture()

        default: break
        }
        self.style = style
    }

    func isHideSolveButton(_ isHidden: Bool) {
        commentSolveButton.isHidden = isHidden
    }
}

extension DriveCommentHeaderView {
    private func setupUI() {
        addSubview(commentPanBlock)
        addSubview(commentCountLabel)
        addSubview(commentBackButton)
        addSubview(commentCloseButton)
        addSubview(commentSolveButton)

        commentPanBlock.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(8)
            make.width.equalTo(40)
            make.height.equalTo(4)
        }

        commentCountLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(26)
            make.width.equalTo(200)
            make.centerX.equalToSuperview()
        }

        commentBackButton.snp.makeConstraints { (make) in
            make.left.equalTo(12)
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
        }

        commentCloseButton.snp.makeConstraints { (make) in
            make.left.equalTo(12)
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
        }

        commentSolveButton.snp.makeConstraints { (make) in
            make.right.equalTo(-18)
            make.centerY.equalToSuperview()
            make.width.equalTo(30)
            make.height.equalTo(24)
        }

        changeStyle(style)
    }

    @objc
    private func didClickBackButton() {
        delegate?.didClickBackButton()
    }

    @objc
    private func didExitEditing() {
        delegate?.didExitEditing(needReload: true)
    }

    @objc
    private func didClickResolveButton(_ sender: UIButton) {
        delegate?.didClickResolveButton(sender, comment: displayView?.currentComment)
    }

    private func disablePanGesture() {
        if let  gestureRecognizers = gestureRecognizers {
            for gesture in gestureRecognizers {
                if let gesture = gesture as? UIPanGestureRecognizer {
                    gesture.isEnabled = false
                }
            }
        }
    }

    private func enablePanGesture() {
        if let  gestureRecognizers = gestureRecognizers {
            for gesture in gestureRecognizers {
                if let gesture = gesture as? UIPanGestureRecognizer {
                    gesture.isEnabled = true
                }
            }
        }
    }
}
