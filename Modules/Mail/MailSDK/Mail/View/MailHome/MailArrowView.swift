//
//  MailArrowView.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2022/8/25.
//

import Foundation
import UIKit
import UniverseDesignIcon

class MailArrowView: UIView {
    static func makeDefaultView() -> MailArrowView {
        let view = MailArrowView(frame: .zero)
        view.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 22, height: 22))
        }
        return view
    }

    private var isFolded = true
    lazy private(set) var arrowImageView: UIImageView = {
        let image = UDIcon.getIconByKey(.expandRightFilled, size: CGSize(width: 11, height: 11)).withRenderingMode(.alwaysTemplate)
        let arrowImageView = UIImageView(image: image)
        arrowImageView.tintColor = UIColor.ud.iconN1
        arrowImageView.transform = CGAffineTransform(rotationAngle: .pi / 2)
        arrowImageView.setContentHuggingPriority(.required, for: .horizontal)
        arrowImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return arrowImageView
    }()
    lazy private(set) var bgView = UIView()
    lazy private(set) var dotView = UIView()

    func setArrowColor(_ color: UIColor) {
        arrowImageView.tintColor = color
        bgView.backgroundColor = color.withAlphaComponent(0.1)
    }

    func setDot(isHidden: Bool, isRed: Bool) {
        dotView.isHidden = isHidden
        dotView.backgroundColor = isRed ? UIColor.ud.functionDangerContentDefault : UIColor.ud.iconDisabled
    }

    func setArrowPresentation(folded: Bool?, animated: Bool = true) {
        isFolded = folded ?? !isFolded
        let angle: CGFloat = isFolded ? (.pi / 2) : -(.pi / 2)
        if animated {
            self.arrowImageView.transform = CGAffineTransform(rotationAngle: -angle)
            UIView.animate(withDuration: timeIntvl.uiAnimateNormal) {
                self.arrowImageView.transform = CGAffineTransform(rotationAngle: angle)
            }
        } else {
            self.arrowImageView.transform = CGAffineTransform(rotationAngle: angle)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        bgView.layer.cornerRadius = 11
        bgView.layer.masksToBounds = true
        addSubview(bgView)
        bgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addSubview(arrowImageView)
        arrowImageView.center = self.center
        arrowImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        dotView.layer.cornerRadius = 3
        dotView.layer.masksToBounds = true
        dotView.isHidden = true
        addSubview(dotView)
        dotView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalTo(16)
            make.size.equalTo(CGSize(width: 6, height: 6))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
