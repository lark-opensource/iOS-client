//
//  ItemAccessoryView.swift
//  LarkListItem-Cell-Components-Core-Resources-Utils
//
//  Created by Yuri on 2023/10/9.
//

import UIKit
import SnapKit
import UniverseDesignIcon

class ItemAccessoryView: UIView, ItemViewContextable {
    var context: ListItemContext

    let stackView = UIStackView()

    lazy var targetPreviewIconView = {
        let btn = UIButton()
        let icon = UDIcon.getIconByKey(.infoOutlined, iconColor: UIColor.ud.iconN3, size: CGSize(width: 20, height: 20))
        btn.setImage(icon, for: .normal)
        btn.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 20, height: 20))
        }
        btn.buttonHitEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        btn.addTarget(self, action: #selector(onClickTargetPreview), for: .touchUpInside)
        return btn
    }()

    lazy var deleteBtn: UIButton = {
        let btn = UIButton()
        let icon = UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN3)
        btn.setImage(icon.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.tintColor = UIColor.ud.iconN3
        btn.adjustsImageWhenHighlighted = false
        btn.buttonHitEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        btn.addTarget(self, action: #selector(onClickDelete), for: .touchUpInside)
        return btn
    }()

    var node: ListItemNode? {
        didSet {
            let accessories = node?.accessories ?? []
            // TODO: 可优化成diff
            stackView.arrangedSubviews.forEach {
                stackView.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
            for accessory in accessories {
                if accessory == .targetPreview {
                    stackView.addArrangedSubview(targetPreviewIconView)
                }
                if accessory == .delete {
                    stackView.addArrangedSubview(deleteBtn)
                }
            }
            self.isHidden = accessories.isEmpty
        }
    }

    init(context: ListItemContext) {
        self.context = context
        super.init(frame: .zero)
        render()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func render() {
        stackView.axis = .horizontal
        stackView.spacing = 12
        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    @objc
    private func onClickTargetPreview() {
        if let node {
            context.delegate?.listItemDidClickAccessory(type: .targetPreview, at: node.indexPath)
        }
    }

    @objc
    private func onClickDelete() {
        if let node {
            context.delegate?.listItemDidClickAccessory(type: .delete, at: node.indexPath)
        }
    }
}

extension UIButton {
    struct AssociatedKeys {
        static var edgeInsets: Int8 = 0
    }

    public var buttonHitEdgeInsets: UIEdgeInsets {
        get {
            guard let edge = objc_getAssociatedObject(self, &AssociatedKeys.edgeInsets) as? UIEdgeInsets else {
                return .zero
            }
            return edge
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.edgeInsets, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if self.buttonHitEdgeInsets == .zero || !self.isEnabled || self.isHidden {
            return super.point(inside: point, with: event)
        }

        let relativeFrame = self.bounds
        let hitFrame = relativeFrame.inset(by: self.buttonHitEdgeInsets)
        return hitFrame.contains(point)
    }
}
