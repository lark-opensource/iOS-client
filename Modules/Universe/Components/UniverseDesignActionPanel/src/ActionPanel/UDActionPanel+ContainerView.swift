//
//  UDActionPanel+ContainerView.swift
//  UniverseDesignActionPanel
//
//  Created by 姚启灏 on 2020/11/4.
//

import UIKit
import Foundation
import UniverseDesignStyle

class UDActionPanelContainerView: UIView {
    private let maskLayer = CAShapeLayer()

    private let iconView: UIView = {
        let iconView = UIView()
        iconView.layer.cornerRadius = UDStyle.lessSmallRadius
        iconView.backgroundColor = UDActionPanelColorTheme.acPrimaryIconNormalColor
        return iconView
    }()

    private var contentView: UIView?

    var showIcon: Bool = true {
        didSet {
            self.iconView.isHidden = !showIcon
        }
    }

    override var frame: CGRect {
        didSet {
            self.updateMaskLayer()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.clipsToBounds = true
        self.addMaskLayer()
        self.addSubview(iconView)
    }

    func add(contentView: UIView, showIcon: Bool) {

        self.contentView?.removeFromSuperview()
        self.showIcon = showIcon
        self.addSubview(contentView)
        self.contentView = contentView
        if showIcon {
            iconView.snp.remakeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview().offset(7)
                make.height.equalTo(4)
                make.width.equalTo(40)
            }
            contentView.snp.remakeConstraints { (make) in
                make.top.equalTo(iconView.snp.bottom).offset(8)
                make.leading.trailing.bottom.equalToSuperview()
            }
        } else {
            contentView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }

    func addMaskLayer() {
        self.updateMaskLayer()
        self.layer.mask = maskLayer
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateMaskLayer() {
        // 取最大屏幕宽 避免转屏是黑边
        let maxScreenLength = max(UIScreen.main.bounds.height, UIScreen.main.bounds.width)
        let maskBounds = CGRect(x: 0, y: 0, width: self.bounds.width, height: maxScreenLength)
        if maskBounds == maskLayer.frame { return }
        let maskPath = UIBezierPath(
            roundedRect: maskBounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: 12, height: 12)
        )
        maskLayer.frame = maskBounds
        maskLayer.path = maskPath.cgPath
    }
}
