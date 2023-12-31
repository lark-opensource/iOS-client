//
//  ChatExtensionFunctionsPanel.swift
//  LarkChatSetting
//
//  Created by zc09v on 2020/5/21.
//

import Foundation
import UIKit
import RxSwift
import SnapKit
import LarkUIKit
import LarkBadge

final class ChatSettingAppItemView: UIView {
    var tapHandler: () -> Void

    init(name: String,
         iconInfo: ExtensionFunctionImageInfo,
         tapHandler: @escaping () -> Void,
         badgePath: Path?) {
        self.tapHandler = tapHandler
        super.init(frame: .zero)

        let icon = UIButton(type: .custom)
        switch iconInfo {
        case .key(let key):
            icon.bt.setLarkImage(with: .default(key: key), for: .normal,
                                 completion: { [weak icon] result in
                                    icon?.setImage(try? result.get().image, for: .highlighted)
                                 })
        case .image(normal: let image):
            icon.setImage(image, for: .normal)
            icon.setImage(image, for: .highlighted)
        }
        icon.addTarget(self, action: #selector(iconClick), for: .touchUpInside)
        icon.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        self.addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.top.centerX.equalToSuperview()
            make.width.lessThanOrEqualTo(48)
            make.height.lessThanOrEqualTo(48)
        }

        if let badgePath = badgePath {
            let badgeView = UIView()
            self.addSubview(badgeView)
            badgeView.snp.makeConstraints { (make) in
                make.size.equalTo(CGSize(width: 5, height: 5))
                make.right.equalTo(icon.snp.right).offset(4)
                make.top.equalTo(icon.snp.top).offset(-4)
            }
            badgeView.badge.observe(for: badgePath)
            badgeView.badge.set(offset: CGPoint(x: -4.5, y: 4.5))
        }

        let nameLabel = UILabel(frame: .zero)
        nameLabel.numberOfLines = 2
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        // 这里使用 0.1 能在启用连字符的情况下，尽量保证先从空格处截断
        paragraphStyle.hyphenationFactor = 0.1
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.ud.caption1(.fixed),
            .foregroundColor: UIColor.ud.textCaption,
            .paragraphStyle: paragraphStyle
        ]
        nameLabel.attributedText = NSAttributedString(string: name, attributes: attributes)
        self.addSubview(nameLabel)

        nameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(icon.snp.bottom).offset(2)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview().offset(-2)
        }
    }

    @objc
    func iconClick() {
        self.tapHandler()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
