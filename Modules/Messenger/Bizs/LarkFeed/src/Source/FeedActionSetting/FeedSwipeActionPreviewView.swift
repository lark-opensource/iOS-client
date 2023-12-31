//
//  FeedSwipeActionPreviewView.swift
//  LarkFeed
//
//  Created by ByteDance on 2023/11/7.
//

import Foundation
import FigmaKit
import LarkSwipeCellKit
import UniverseDesignIcon
import UniverseDesignColor
import LarkOpenFeed
import UniverseDesignFont

class FeedSwipeActionPreviewView: UIView {
    private struct Layout {
        static let cornerRadius = 8.0
        static let subViewCornerRadius = 5.0
        static let buttonWidth = 70.0
        static let buttonHeight = 80.0
        static let avartarSize = 40.0
        static let timeViewWidth = 40.0
        static let fakeMsgViewHeight = 10.0
        static let leftMargin = 16.0
        static let titleAvatarMargin = 5.0
        static let titleTimeViewMargin = 24.0
        static let verticalMargin = 22.0
        static let titleViewTrailing = 25.0
        static let summaryViewTrailing = 53.0
    }
    private var orientation: SwipeActionsOrientation = .right
    private var actions: [FeedActionType] = []

    private var actionsContainer = UIStackView()
    private var feedCellContainer = UIView()
    private var borderView = UIView()

    func setActionsAndLayoutView(orientation: SwipeActionsOrientation,
                                 actions: [FeedActionType]) {
        self.orientation = orientation
        self.actions = actions
        resetPreview()
        setupViews()
    }

    private func resetPreview() {
        actionsContainer.removeFromSuperview()
        feedCellContainer.removeFromSuperview()
        borderView.removeFromSuperview()
        actionsContainer = UIStackView()
        feedCellContainer = UIView()
        borderView = UIView()
    }
    private func setupViews() {
        layer.cornerRadius = Layout.cornerRadius
        layer.masksToBounds = true
        clipsToBounds = true
        configFeedCell()
        configActionsContainer()
    }

    private func configActionsContainer() {
        actionsContainer.axis = .horizontal
        actionsContainer.spacing = 0
        actionsContainer.alignment = .leading
        actionsContainer.distribution = .fillEqually
        actionsContainer.setContentHuggingPriority(.required, for: .horizontal)
        actionsContainer.setContentCompressionResistancePriority(.required, for: .horizontal)
        actionsContainer.backgroundColor = .darkGray
        actionsContainer.clipsToBounds = true
        addSubview(actionsContainer)
        actionsContainer.snp.makeConstraints { make in
            if orientation == .right {
                make.leading.equalToSuperview()
            } else {
                make.trailing.equalToSuperview()
            }
            make.top.height.equalToSuperview()
            make.width.equalTo(CGFloat(actions.count) * Layout.buttonWidth)
        }

        for action in actions {
            let actionButton = FeedSwipeActionButton(icon: action.actionIcon, title: action.settingTitle)
            actionButton.backgroundColor = action.bgColor
            actionButton.clipsToBounds = true
            actionsContainer.addArrangedSubview(actionButton)
            actionButton.snp.makeConstraints { (make) in
                make.size.equalTo(CGSize(width: Layout.buttonWidth, height: Layout.buttonHeight))
                make.centerY.equalToSuperview()
            }
        }
    }

    private func configFeedCell() {
        guard !actions.isEmpty else { return }
        addSubview(feedCellContainer)
        feedCellContainer.backgroundColor = .clear
        feedCellContainer.snp.makeConstraints { make in
            if orientation == .right {
                make.leading.equalTo(CGFloat(actions.count) * Layout.buttonWidth)
                make.trailing.equalToSuperview()
            } else {
                make.trailing.equalTo(-CGFloat(actions.count) * Layout.buttonWidth)
                let leftOffset = -CGFloat(actions.count - 1) * Layout.buttonWidth
                // 整体往左移动
                make.leading.equalToSuperview().offset(leftOffset)
            }
            make.top.height.equalToSuperview()
        }

        let avatarView = UIView()
        let titleView = UIView()
        let summaryView = UIView()
        let timeView = UIView()

        feedCellContainer.addSubview(titleView)

        feedCellContainer.addSubview(summaryView)
        if orientation == .right {
            feedCellContainer.addSubview(avatarView)
            avatarView.backgroundColor = .ud.N300
            avatarView.layer.cornerRadius = Layout.avartarSize / 2.0
            avatarView.layer.masksToBounds = true
            avatarView.snp.makeConstraints { make in
                make.leading.equalTo(Layout.leftMargin)
                make.centerY.equalToSuperview()
                make.height.width.equalTo(Layout.avartarSize)
            }
        } else {
            feedCellContainer.addSubview(timeView)
            timeView.backgroundColor = .ud.N200
            timeView.layer.cornerRadius = Layout.subViewCornerRadius
            timeView.layer.masksToBounds = true
            timeView.snp.makeConstraints { make in
                make.trailing.equalTo(-Layout.leftMargin)
                make.top.equalTo(Layout.verticalMargin)
                make.height.equalTo(Layout.fakeMsgViewHeight)
                make.width.equalTo(Layout.timeViewWidth)
            }
        }

        titleView.backgroundColor = .ud.N300
        titleView.layer.cornerRadius = Layout.subViewCornerRadius
        titleView.layer.masksToBounds = true
        titleView.snp.makeConstraints { make in
            if orientation == .right {
                make.leading.equalTo(avatarView.snp.trailing).offset(Layout.titleAvatarMargin)
                make.trailing.equalTo(-Layout.titleViewTrailing)
            } else {
                make.leading.equalTo(Layout.leftMargin)
                make.trailing.equalTo(timeView.snp.leading).offset(-Layout.titleTimeViewMargin)
            }
            make.top.equalTo(Layout.verticalMargin)
            make.height.equalTo(Layout.fakeMsgViewHeight)
        }

        summaryView.backgroundColor = .ud.N200
        summaryView.layer.cornerRadius = Layout.subViewCornerRadius
        summaryView.layer.masksToBounds = true
        summaryView.snp.makeConstraints { make in
            make.leading.equalTo(titleView)
            make.trailing.equalTo(titleView).offset(-Layout.summaryViewTrailing)
            make.bottom.equalToSuperview().offset(-Layout.verticalMargin)
            make.height.equalTo(Layout.fakeMsgViewHeight)
        }

        borderView.layer.cornerRadius = Layout.cornerRadius
        borderView.layer.masksToBounds = true
        borderView.layer.borderWidth = 1.0
        borderView.backgroundColor = .clear

        let borderColor = UIColor.ud.lineBorderCard
        borderView.layer.ud.setBorderColor(borderColor)
        addSubview(borderView)
        borderView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

class FeedSwipeActionButton: UIButton {
    struct Layout {
        static let imageSize = 18.0
        static let buttonWidth = 70.0
        static let buttonHeight = 80.0
        static let titleFont = 12.0
        static let titleSmallFont = 10.0
        static let titleLineHeight = 18.0
        static let titleMultiLineHeight = 26.0
        static let titleHorizontalMargin = 4.0
        static let titleImageMargin = 4.0
    }
    private let imageSize = CGSize(width: Layout.imageSize, height: Layout.imageSize)
    private let title: String

    init(icon: UIImage, title: String) {
        self.title = title
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: Layout.buttonWidth, height: Layout.buttonHeight)))

        setTitle(title, for: .normal)
        titleLabel?.font = UDFont.systemFont(ofSize: Layout.titleFont, weight: .medium)
        titleLabel?.textAlignment = .center
        titleLabel?.lineBreakMode = .byTruncatingTail
        titleLabel?.numberOfLines = 1

        setImage(icon, for: .normal)
        imageView?.contentMode = .scaleAspectFit
        contentVerticalAlignment = .center
        contentHorizontalAlignment = .center
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let titleWith = self.title.getTextWidth(font: UDFont.systemFont(ofSize: Layout.titleFont, weight: .medium),
                                                height: Layout.titleLineHeight)
        if titleWith <= (Layout.buttonWidth - 2.0 * Layout.titleHorizontalMargin) {
            let imageY = (Layout.buttonHeight - (Layout.imageSize + Layout.titleImageMargin + Layout.titleLineHeight)) / 2.0
            let titleY = imageY + Layout.imageSize + Layout.titleImageMargin
            imageView?.frame = CGRect(origin: CGPoint(x: (frame.width - imageSize.width) / 2.0, y: imageY), size: imageSize)
            titleLabel?.frame = CGRect(origin: CGPoint(x: Layout.titleHorizontalMargin, y: titleY),
                                       size: CGSize(width: frame.width - 2.0 * Layout.titleHorizontalMargin,
                                                    height: Layout.titleLineHeight))
        } else {
            let imageY = (Layout.buttonHeight - (Layout.imageSize + Layout.titleImageMargin + Layout.titleMultiLineHeight)) / 2.0
            let titleY = imageY + Layout.imageSize + Layout.titleImageMargin
            imageView?.frame = CGRect(origin: CGPoint(x: (frame.width - imageSize.width) / 2.0, y: imageY), size: imageSize)
            titleLabel?.font = UDFont.systemFont(ofSize: Layout.titleSmallFont, weight: .medium)
            titleLabel?.numberOfLines = 2
            titleLabel?.frame = CGRect(origin: CGPoint(x: Layout.titleHorizontalMargin, y: titleY),
                                       size: CGSize(width: frame.width - 2.0 * Layout.titleHorizontalMargin,
                                                    height: Layout.titleMultiLineHeight))
        }
    }
}

extension String {
    func getTextWidth(font: UIFont, height: CGFloat) -> CGFloat {
        let rect = NSString(string: self).boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: height),
                                                       options: [.usesFontLeading, .usesLineFragmentOrigin],
                                                       attributes: [NSAttributedString.Key.font: font],
                                                       context: nil)
        return ceil(rect.width)
    }
}
