//
//  SceneSwitcherTableViewCell.swift
//  LarkSceneManager
//
//  Created by Saafo on 2021/4/1.
//

import UIKit
import Foundation
import SnapKit
import UniverseDesignColor

// MARK: Table Cell

final class SceneSwitcherTableViewCell: UITableViewCell {
    let iconView = UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
    let label = UILabel()
    let keyBindingLabel = UILabel()

    convenience init(image: UIImage?, text: String, keyBindingInput: String? = nil) {
        self.init()
        iconView.image = image
        label.text = text
        // ui
        backgroundColor = .clear
        layer.cornerRadius = 12
        selectedBackgroundView = SelectView()
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        // layout
        contentView.addSubview(iconView)
        iconView.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(24)
            $0.width.height.equalTo(24)
            $0.centerY.equalToSuperview()
        }
        contentView.addSubview(label)
        label.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(64)
            $0.trailing.lessThanOrEqualToSuperview().inset(24)
            $0.centerY.equalToSuperview()
        }
        if let keyBindingInput = keyBindingInput {
            keyBindingLabel.text = "⌃    " + keyBindingInput
            keyBindingLabel.textColor = UIColor.ud.textTitle
            keyBindingLabel.font = .systemFont(ofSize: 16)
            label.numberOfLines = 1
            contentView.addSubview(keyBindingLabel)
            keyBindingLabel.snp.makeConstraints {
                $0.leading.equalTo(contentView.snp.trailing).inset(44 + 24)
                $0.trailing.equalToSuperview()
                $0.centerY.equalToSuperview()
            }
            label.snp.remakeConstraints {
                $0.leading.equalToSuperview().inset(64)
                $0.trailing.lessThanOrEqualTo(keyBindingLabel.snp.leading).offset(-24)
                $0.centerY.equalToSuperview()
            }
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: false)
        if keyBindingLabel.superview != nil {
            keyBindingLabel.isHidden = highlighted
        }
    }

    final class SelectView: UIView {
        public override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = UIColor.ud.fillHover.withAlphaComponent(0.08)
            layer.cornerRadius = 12
            clipsToBounds = true
        }
        public required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
