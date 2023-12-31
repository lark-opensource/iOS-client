//
//  FeetSettingCheckCell.swift
//  LarkFeed
//
//  Created by ByteDance on 2023/11/12.
//

import Foundation
import UIKit
import UniverseDesignCheckBox
import RxSwift
import UniverseDesignFont

final class FeetSettingCheckCell: UITableViewCell {
    private lazy var iconView: UIImageView = UIImageView()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.systemFont(ofSize: 16.0, weight: .regular)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()
    private lazy var checkBox: UDCheckBox = UDCheckBox()

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        setupViews()
    }

    private func setupViews() {
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(checkBox)

        iconView.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }

        checkBox.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalTo(iconView)
            make.width.height.equalTo(20)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconView.snp.right).offset(8)
            make.right.equalTo(checkBox.snp.left).offset(-12)
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
        contentView.backgroundColor = UIColor.ud.bgFloat
    }

    func config(viewModel: FeedSettingCheckCellViewModel) {
        iconView.image = viewModel.icon
        titleLabel.text = viewModel.title
        var config = UDCheckBoxUIConfig()
        config.style = .circle
        checkBox.updateUIConfig(boxType: viewModel.boxType, config: config)
        checkBox.isEnabled = viewModel.enable
        checkBox.isSelected = viewModel.selected
        checkBox.isUserInteractionEnabled = false
    }
}
