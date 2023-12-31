//
//  ChatPinListCardContainerCell.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/5/10.
//

import Foundation
import UniverseDesignIcon
import LarkMessageCore

class ChatPinListCardBaseCell: UICollectionViewCell {

    struct ContainerUIConfig {
        static var horizontalMargin: CGFloat = 16
        static var verticalMargin: CGFloat = 6
        static var containerCornerRadius: CGFloat = 8
    }

    var containerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.ud.bgFloat
        return containerView
    }()

    private lazy var shadowView: UIView = {
        let shadowView = UIView()
        shadowView.layer.cornerRadius = ContainerUIConfig.containerCornerRadius
        shadowView.backgroundColor = UIColor.ud.bgFloat
        shadowView.layer.ud.setShadow(type: .s3Down)
        shadowView.isHidden = true
        return shadowView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.clear
        self.contentView.addSubview(shadowView)
        self.contentView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(ContainerUIConfig.horizontalMargin)
            make.top.bottom.equalToSuperview().inset(ContainerUIConfig.verticalMargin)
        }
        shadowView.snp.makeConstraints { make in
            make.edges.equalTo(containerView)
        }
        containerView.layer.cornerRadius = ContainerUIConfig.containerCornerRadius
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateDragState(isDragging: Bool) {
        shadowView.isHidden = !isDragging
    }
}

final class ChatPinListCardContainerCell: ChatPinListCardBaseCell {

    static var innerPadding: CGFloat { 12 }
    static var moreIconSize: CGFloat { 16 }
    static var titleMargin: CGFloat { 8 }
    static var contentHorizontalMargin: CGFloat { 12 }
    static var HeaderExtraMargin: CGFloat {
        return ContentExtraMargin + titleMargin * 2 + moreIconSize
    }
    static var ContentExtraMargin: CGFloat {
        return ContainerUIConfig.horizontalMargin * 2 + contentHorizontalMargin * 2
    }
    private static var showMoreHeight: CGFloat {
        return ShowMoreButton.caculatedSize.height + 28
    }

    lazy var iconView: UIImageView = {
        let iconView = UIImageView()
        iconView.layer.masksToBounds = true
        return iconView
    }()

    lazy var moreButton: UIButton = {
        let moreButton = ExpandMoreButton()
        moreButton.setBackgroundImage(UDIcon.getIconByKey(.moreOutlined, size: CGSize(width: Self.moreIconSize, height: Self.moreIconSize)).ud.withTintColor(UIColor.ud.iconN2), for: .normal)
        moreButton.addTarget(self, action: #selector(clickMore(_:)), for: .touchUpInside)
        return moreButton
    }()
    private class ExpandMoreButton: UIButton {
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            let relativeFrame = self.bounds
            let hitFrame = relativeFrame.inset(by: UIEdgeInsets(top: -16, left: -16, bottom: -16, right: -16))
            return hitFrame.contains(point)
        }
    }
    var actionHandler: ((UIView) -> Void)?

    lazy var contentConatiner: UIView = UIView()
    lazy var titleContainer: UIView = UIView()
    lazy var pinChatterContainer: UIView = UIView()

    private lazy var showMoreView: ShowMoreButtonMaskView = {
        let showMoreView = ShowMoreButtonMaskView()
        showMoreView.setBackground(colors: [UIColor.ud.bgFloat.withAlphaComponent(0), UIColor.ud.bgFloat])
        return showMoreView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.containerView.addSubview(iconView)
        self.containerView.addSubview(titleContainer)
        self.containerView.addSubview(moreButton)
        self.containerView.addSubview(contentConatiner)
        self.containerView.addSubview(pinChatterContainer)
        self.containerView.addSubview(showMoreView)
        contentConatiner.layer.masksToBounds = true
        moreButton.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(15)
            make.right.equalToSuperview().inset(Self.contentHorizontalMargin)
            make.size.equalTo(Self.moreIconSize)
        }
    }

    func sync(
        layoutResult: ChatPinCardContainerCellLayoutManager.LayoutResult,
        showMore: Bool,
        showMoreHandler: @escaping () -> Void
    ) {
        self.iconView.frame = layoutResult.iconFrame
        self.titleContainer.frame = layoutResult.titleFrame
        self.contentConatiner.frame = layoutResult.contentFrame
        self.contentConatiner.isHidden = (layoutResult.contentFrame.height == .zero)
        self.pinChatterContainer.frame = layoutResult.pinChatterFrame
        self.pinChatterContainer.isHidden = (layoutResult.pinChatterFrame.height == .zero)
        if showMore {
            showMoreView.isHidden = false
            showMoreView.frame = CGRect(
                x: layoutResult.contentFrame.minX,
                y: layoutResult.contentFrame.maxY - Self.showMoreHeight,
                width: layoutResult.contentFrame.width,
                height: Self.showMoreHeight
            )
        } else {
            showMoreView.isHidden = true
        }
        showMoreView.showMoreHandler = showMoreHandler
    }

    @objc
    private func clickMore(_ button: UIButton) {
        self.actionHandler?(button)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct ChatPinCardContainerCellLayoutManager {
    struct LayoutResult {
        var iconFrame: CGRect
        var titleFrame: CGRect
        var contentFrame: CGRect
        var pinChatterFrame: CGRect
    }

    static func calculate(iconSize: CGSize, titleSize: CGSize, contentSize: CGSize, pinChatterSize: CGSize) -> (layoutResult: LayoutResult, cellHeight: CGFloat) {
        var iconFrame: CGRect = .zero
        var titleFrame: CGRect = .zero
        if iconSize == .zero {
            iconFrame = .zero
            titleFrame = CGRect(origin: CGPoint(x: ChatPinListCardContainerCell.contentHorizontalMargin, y: max(12, 23 - titleSize.height / 2)), size: titleSize)
        } else {
            iconFrame = CGRect(origin: CGPoint(x: ChatPinListCardContainerCell.contentHorizontalMargin, y: 23 - iconSize.height / 2), size: iconSize)
            titleFrame = CGRect(origin: CGPoint(x: iconFrame.maxX + ChatPinListCardContainerCell.titleMargin, y: max(12, 23 - titleSize.height / 2)), size: titleSize)
        }
        var offsetY: CGFloat = titleFrame.maxY + titleFrame.minY

        var contentFrame: CGRect = .zero
        if contentSize.height != 0 {
            contentFrame = CGRect(origin: CGPoint(x: ChatPinListCardContainerCell.contentHorizontalMargin, y: offsetY), size: contentSize)
            offsetY = contentFrame.maxY + ChatPinListCardContainerCell.contentHorizontalMargin
        }

        var pinChatterFrame: CGRect = .zero
        if pinChatterSize.height != 0 {
            pinChatterFrame = CGRect(origin: CGPoint(x: ChatPinListCardContainerCell.contentHorizontalMargin, y: offsetY), size: pinChatterSize)
            offsetY = pinChatterFrame.maxY + ChatPinListCardContainerCell.contentHorizontalMargin
        }

        return (layoutResult: LayoutResult(iconFrame: iconFrame,
                                           titleFrame: titleFrame,
                                           contentFrame: contentFrame,
                                           pinChatterFrame: pinChatterFrame),
                cellHeight: offsetY + ChatPinListCardContainerCell.ContainerUIConfig.verticalMargin * 2)
    }
}
