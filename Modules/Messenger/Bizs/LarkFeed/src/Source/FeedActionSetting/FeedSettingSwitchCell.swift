//
//  FeedSettingSwitchCell.swift
//  LarkFeed
//
//  Created by ByteDance on 2023/11/12.
//

import UIKit
import LarkUIKit
import UniverseDesignSwitch
import UniverseDesignFont

class FeedSettingSwitchCell: UITableViewCell {
    private struct Layout {
        static let horizontalMargin = 16.0
        static let verticalMargin = 12.0
        static let titleSwitchMargin = 12.0
        static let fontSize = 16.0
    }
    var didChangeSwitch: ((Bool) -> Void)?
    // MARK: - UI
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.systemFont(ofSize: Layout.fontSize, weight: .regular)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    private lazy var switchButton: UDSwitch = UDSwitch()

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        contentView.backgroundColor = UIColor.ud.bgFloat
        self.contentView.addSubview(self.switchButton)
        self.switchButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.switchButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-Layout.horizontalMargin)
        }
        self.switchButton.valueChanged = { [weak self] value in
            guard let self = self else { return }
            self.didChangeSwitch?(value)
        }
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(Layout.horizontalMargin)
            make.right.lessThanOrEqualTo(self.switchButton.snp.left).offset(-Layout.titleSwitchMargin)
            make.top.equalToSuperview().offset(Layout.verticalMargin)
            make.bottom.equalToSuperview().offset(-Layout.verticalMargin)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func config(viewModel: FeedSettingSwitchCellViewModel) {
        titleLabel.text = viewModel.title
        switchButton.setOn(viewModel.status, animated: false, ignoreValueChanged: true)
    }
}
