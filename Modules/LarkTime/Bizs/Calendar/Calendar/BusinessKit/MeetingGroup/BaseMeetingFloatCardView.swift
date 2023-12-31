//
//  BaseMeetingFloatCardView.swift
//  Calendar
//
//  Created by chaishenghua on 2023/12/12.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor

class BaseMeetingFloatCardView: UIView {
    class CloseButton: UIButton {
        override init(frame: CGRect) {
            super.init(frame: frame)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            let biggerFrame = self.bounds.inset(by: UIEdgeInsets.init(top: -6, left: -6, bottom: -6, right: -6))
            let isInside = biggerFrame.contains(point)
            if isInside {
                return isInside
            } else {
                return super.point(inside:point, with: event)
            }
        }
    }

    private lazy var iconView = UIImageView()
    lazy var contentView = UIView()
    private lazy var closeButton = {
        let button = CloseButton()
        if let lightImage = UDIcon.closeOutlined.colorImage(UDColor.iconN2.alwaysLight),
           let darkImage = UDIcon.closeOutlined.colorImage(UDColor.iconN2.alwaysDark) {
            let image = UIImage.dynamic(light: lightImage, dark: darkImage)
            button.setImage(image.ud.resized(to: CGSize(width: 16, height: 16)),
                            for: .normal)
        }
        return button
    }()

    init(icon: UIImage, backgroundColor: UIColor) {
        super.init(frame: .zero)
        iconView.image = icon
        self.backgroundColor = backgroundColor
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        self.addSubview(iconView)
        self.addSubview(contentView)
        self.addSubview(closeButton)

        iconView.snp.makeConstraints {
            $0.left.equalToSuperview().inset(16)
            $0.top.equalToSuperview().inset(14)
            $0.height.width.equalTo(16)
        }
        contentView.snp.makeConstraints {
            $0.left.equalTo(iconView.snp.right).offset(8)
            $0.right.equalTo(closeButton.snp.left).offset(-8)
            $0.top.bottom.equalToSuperview().inset(12)
        }
        closeButton.snp.makeConstraints {
            $0.right.equalToSuperview().inset(16)
            $0.top.equalToSuperview().inset(14)
            $0.height.width.equalTo(16)
        }
    }

    func addCloseAction(target: Any?, action: Selector) {
        self.closeButton.addTarget(target, action: action, for: .touchUpInside)
    }

    func addClickAction(target: Any?, action: Selector) {
        let tap = UITapGestureRecognizer(target: target, action: action)
        tap.numberOfTapsRequired = 1
        self.addGestureRecognizer(tap)
    }
}
