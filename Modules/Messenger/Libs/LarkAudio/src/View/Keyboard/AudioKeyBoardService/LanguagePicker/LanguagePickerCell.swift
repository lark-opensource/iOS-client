//
//  LanguagePickerCell.swift
//  LarkAudio
//
//  Created by 白镜吾 on 2023/2/16.
//

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignColor
import LarkLocalizations

final class LanguagePickerCell: UITableViewCell {

    private lazy var languageNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ud.textTitle
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .left
        return label
    }()

    private lazy var checkIcon: UIImageView = {
        let checkIcon = UIImageView()
        let iconSize = CGSize(width: 16, height: 16)
        let iconColor = UIColor.ud.textLinkHover
        checkIcon.image = UDIcon.getIconByKey(.listCheckBoldOutlined, iconColor: iconColor, size: iconSize)
        return checkIcon
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        self.contentView.backgroundColor = UIColor.ud.bgBody
        self.contentView.addSubview(languageNameLabel)
        self.contentView.addSubview(checkIcon)

        languageNameLabel.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(96)
        }

        checkIcon.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 24, height: 24))
        }

    }
}

extension LanguagePickerCell {
    func configure(_ cellShownLangi18n: String?, isChecked: Bool) {
        guard let cellShownLangi18n = cellShownLangi18n else {
            return
        }
        self.languageNameLabel.text = cellShownLangi18n
        self.checkIcon.isHidden = !isChecked
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.languageNameLabel.text = nil
        self.checkIcon.isHidden = true
    }
}
