//
//  LinearShrinkButtonView.swift
//  ByteView
//
//  Created by fakegourmet on 2022/8/17.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor
import UIKit

class LinearShrinkButtonView: UIView {

    private var bg1 = UIView()

    lazy var button: VisualButton = {
        let button = VisualButton()
        button.setImage(UDIcon.getIconByKey(.vcToolbarUpFilled, iconColor: UIColor.ud.iconN2, size: CGSize(width: 16, height: 16)), for: .normal)
        button.extendEdge = UIEdgeInsets(top: -2, left: -2, bottom: -2, right: -2)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(button)
        button.snp.makeConstraints {
            let edgeInset = UIEdgeInsets(top: 41.0, left: 20.0, bottom: 45.0, right: 12.0)
            $0.edges.equalTo(edgeInset)
        }
    }

    func updateBackgroundColor() {
        if #available(iOS 12.0, *), traitCollection.userInterfaceStyle == .dark {
            // 直接读 UIColor.ud.bgBase.alwaysDark 存在色值不准问题，此处直接写死
            backgroundColor = UIColor.fromGradientWithDirection(.leftToRight, frame: frame, colors: [
                UIColor.ud.rgb("0x0A0A0A").withAlphaComponent(0.0),
                UIColor.ud.rgb("0x0A0A0A").withAlphaComponent(1.0)
            ], locations: [0, 0.5])
        } else {
            backgroundColor = UIColor.fromGradientWithDirection(.leftToRight, frame: frame, colors: [
                UIColor.ud.bgBase.alwaysLight.withAlphaComponent(0.0),
                UIColor.ud.bgBase.alwaysLight.withAlphaComponent(1.0)
            ], locations: [0, 0.5])
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
