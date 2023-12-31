//
//  MinutesMoreSwitchCell.swift
//  Minutes
//
//  Created by lvdaqian on 2021/2/23.
//

import Foundation
import UniverseDesignColor

struct MinutesMoreSwitchItem: MinutesMoreItem {
    var height: CGFloat = 56

    var title: String {
        return titleValue(initValue)
    }

    var subtitle: String {
        return subtitleValue(initValue)
    }

    let shouldDismiss: Bool = false

    let identifier = MinutesMoreSwitchCell.description()

    var icon: UIImage

    var titleValue: (Bool) -> String

    var subtitleValue: (Bool) -> String

    var initValue: Bool

    var action: (Bool) -> Void

    func onSwitch(_ value: Bool) {
        action(value)
    }

    func onSelect() {

    }

}

class MinutesMoreSwitchCell: UITableViewCell, MinutesMoreTableViewCell {
    private lazy var moreImageView: UIImageView = {
        let imageView: UIImageView = UIImageView(frame: CGRect.zero)
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.numberOfLines = 1
        label.textAlignment = .left
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 17)
        return label
    }()

    private lazy var subTitleLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.numberOfLines = 1
        label.textAlignment = .left
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    private lazy var switchButton: UISwitch = {
        let switchButton = UISwitch()
        switchButton.onTintColor = UIColor.ud.colorfulBlue
        switchButton.backgroundColor = UIColor.ud.N400
        switchButton.layer.cornerRadius = 15.5
        switchButton.addTarget(self, action: #selector(switchButtonClicked), for: .valueChanged)
        return switchButton
    }()

    private var item: MinutesMoreSwitchItem?

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = UIColor.ud.bgFloat

        contentView.addSubview(moreImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subTitleLabel)
        contentView.addSubview(switchButton)
        createConstraints()
        
        let selectedBackgroundView: UIView = UIView()
        selectedBackgroundView.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.05)
        self.selectedBackgroundView = selectedBackgroundView
    }

    func createConstraints() {
        moreImageView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(20)
        }
        titleLabel.snp.makeConstraints {
            $0.left.equalTo(moreImageView.snp.right).offset(12)
            $0.top.equalToSuperview().offset(8)
            $0.height.equalTo(22)
        }
        subTitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom)
            $0.left.equalTo(titleLabel)
            $0.height.equalTo(18)
            $0.width.equalTo(titleLabel)
        }
        switchButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.right.equalToSuperview().inset(12)
            $0.left.equalTo(titleLabel.snp.right)
        }
        switchButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    @objc
    private func switchButtonClicked(sender: UISwitch) {
        self.item?.onSwitch(sender.isOn)
        titleLabel.text = self.item?.titleValue(switchButton.isOn)
        subTitleLabel.text = self.item?.subtitleValue(switchButton.isOn)
    }

    func onSelect() {
        switchButton.isOn = !switchButton.isOn
        self.item?.onSwitch(switchButton.isOn)
        titleLabel.text = self.item?.titleValue(switchButton.isOn)
        subTitleLabel.text = self.item?.subtitleValue(switchButton.isOn)
    }

    func setupItem(_ item: MinutesMoreItem) {
        moreImageView.image = item.icon
        titleLabel.text = item.title
        if let switchItem = item as? MinutesMoreSwitchItem {
            self.item = switchItem
            switchButton.isOn = switchItem.initValue
            subTitleLabel.text = switchItem.subtitle
        }
    }
}
