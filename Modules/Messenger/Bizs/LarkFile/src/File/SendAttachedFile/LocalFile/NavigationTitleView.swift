//
//  NavigationTitleView.swift
//  LarkFile
//
//  Created by 王元洵 on 2020/10/27.
//

import UIKit
import Foundation
import LKCommonsTracker
import Homeric
import LarkFeatureGating
import UniverseDesignColor

///标题点击代理协议
protocol NavigationTitleViewDelagate: AnyObject {
    func onTitleViewClick()
}

final class NavigationTitleView: UIControl {
    weak var delegate: NavigationTitleViewDelagate?

    ///标题文本
    var titleText: String = "" {
        didSet {
            titleLabel.text = titleText
        }
    }

    private lazy var container: UIStackView = {
        let container = UIStackView()
        container.axis = .horizontal
        container.alignment = .center
        container.distribution = .fill
        container.spacing = 4
        container.isUserInteractionEnabled = false
        return container
    }()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.medium)
        titleLabel.textColor = UIColor.ud.textTitle
        return titleLabel
    }()

    private lazy var arrowImageView: UIImageView = {
        let arrowImageView = UIImageView(image: Resources.arrow.ud.withTintColor(UIColor.ud.textTitle))
        arrowImageView.transform = CGAffineTransform(rotationAngle: .pi / 2)
        arrowImageView.isUserInteractionEnabled = false
        return arrowImageView
    }()

    private(set) var isFolded: Bool = true

    init() {
        super.init(frame: CGRect.zero)

        container.addArrangedSubview(titleLabel)
        container.addArrangedSubview(arrowImageView)
        addSubview(container)
        container.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        addTarget(self, action: #selector(onClick), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func onClick() {
        Tracker.post(TeaEvent(Homeric.CLICK_ATTACH_ICON_PHONESTORAGE))
        setArrowPresentation()
        delegate?.onTitleViewClick()
    }

    ///改变箭头指向
    func setArrowPresentation() {
        isFolded = !isFolded
        let angle: CGFloat = isFolded ? (.pi / 2) : -(.pi / 2)
        arrowImageView.transform = CGAffineTransform(rotationAngle: -angle)
        UIView.animate(withDuration: 0.2) {
            self.arrowImageView.transform = CGAffineTransform(rotationAngle: angle)
        }
    }
}
