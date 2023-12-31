//
//  ChatWidgetSortAndDeleteCollectionCell.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/3/28.
//

import Foundation
import LarkUIKit
import UniverseDesignColor
import UniverseDesignIcon

final class ChatWidgetSortAndDeleteCollectionCell: UICollectionViewCell {

    struct UIConfig {
        static let dragTransform = CGAffineTransform(scaleX: 1.03, y: 1.03)
        static let maxCardHeight: CGFloat = 200
        static let contentTopMargin: CGFloat = 8
    }

    static func calculateCellHeightInfo(_ contentHeight: CGFloat) -> (CGFloat, Bool) {
        var cellHeight: CGFloat = UIConfig.contentTopMargin
        let exceedLimit: Bool
        if contentHeight > UIConfig.maxCardHeight {
            cellHeight += UIConfig.maxCardHeight
            exceedLimit = true
        } else {
            cellHeight += contentHeight
            exceedLimit = false
        }
        return (cellHeight, exceedLimit)
    }

    final class ExpandDeleteButton: UIButton {
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            let relativeFrame = self.bounds
            let hitFrame = relativeFrame.inset(by: UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10))
            return hitFrame.contains(point)
        }
    }

    private lazy var deleteButton: UIButton = {
        let deleteButton = ExpandDeleteButton()
        let icon = UDIcon.getIconByKey(.deleteColorful, size: CGSize(width: 24, height: 24))
        deleteButton.setImage(icon, for: .normal)
        deleteButton.addTarget(self, action: #selector(clickDelete), for: .touchUpInside)
        return deleteButton
    }()

    private lazy var contentMaskView: GradientView = {
        let maskView = GradientView()
        maskView.backgroundColor = UIColor.clear
        maskView.locations = [0.0, 1.0]
        maskView.layer.cornerRadius = 12
        let corner: UIRectCorner = [.bottomLeft, .bottomRight]
        maskView.layer.maskedCorners = CACornerMask(rawValue: corner.rawValue)
        maskView.clipsToBounds = true
        maskView.automaticallyDims = false
        maskView.isUserInteractionEnabled = false
        maskView.isHidden = true
        return maskView
    }()

    private var deleteHandler: (() -> Void)?

    lazy var containerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.ud.bgFloat
        containerView.isUserInteractionEnabled = false
        containerView.layer.cornerRadius = 12
        containerView.layer.masksToBounds = true
        return containerView
    }()

    var isUserDragging: Bool = false {
        didSet {
            self.deleteButton.isHidden = isUserDragging
            if isUserDragging {
                self.transform = UIConfig.dragTransform
            } else {
                self.transform = CGAffineTransform.identity
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.clear
        self.contentView.addSubview(containerView)
        self.contentView.addSubview(deleteButton)
        self.contentView.addSubview(contentMaskView)
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(UIConfig.contentTopMargin)
            make.left.right.equalToSuperview().inset(12)
            make.bottom.equalToSuperview()
        }
        deleteButton.snp.makeConstraints { make in
            make.top.equalTo(containerView).offset(-4)
            make.right.equalTo(containerView).offset(4)
            make.size.equalTo(24)
        }
        contentMaskView.snp.makeConstraints { make in
            make.bottom.left.right.equalTo(containerView)
            make.height.equalTo(49)
        }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.contentMaskView.colors = [UIColor.ud.bgFloat.withAlphaComponent(0), UIColor.ud.bgFloat]
    }

    func set(hideMask: Bool, deleteHandler: @escaping () -> Void) {
        self.contentMaskView.isHidden = hideMask
        self.deleteHandler = deleteHandler
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func clickDelete() {
        self.deleteHandler?()
    }
}
