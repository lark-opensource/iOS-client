//
//  UneditableFocusTitleCell.swift
//  ExpandableTable
//
//  Created by Hayden Wang on 2021/8/31.
//

import Foundation
import UIKit
import LarkEmotion
import UniverseDesignIcon

final class UneditableFocusTitleCell: UITableViewCell, FocusTitleCell {

    var iconKey: String? {
        didSet {
            if let key = iconKey {
                iconView.image = EmotionResouce.shared.imageBy(key: key) ?? Cons.defaultIcon
            } else {
                iconView.image = Cons.defaultIcon
            }
        }
    }

    var focusName: String? {
        didSet {
            titleLabel.text = focusName
        }
    }

    private lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .center
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
    }

    private func setupSubviews() {
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
    }

    private func setupConstraints() {
        iconView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(32)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(20)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-3)
        }
    }

    private func setupAppearance() {
        backgroundColor = .clear
    }
}

extension UneditableFocusTitleCell {

    enum Cons {
        static var defaultIcon: UIImage {
            EmotionResouce.placeholder
        }
    }
}
