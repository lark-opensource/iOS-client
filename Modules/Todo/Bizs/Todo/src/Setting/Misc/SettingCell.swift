//
//  SettingCell.swift
//  Todo
//
//  Created by wangwanxin on 2021/6/6.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignFont

/// title + subTitle + check mark
final class SettingCheckMarkCell: UITableViewCell {

    var isChecked: Bool = false {
        didSet {
            guard oldValue != isChecked else { return }
            checkMarkView.isHidden = !isChecked
        }
    }

    var isShowSeparteLine: Bool = false {
        didSet {
            separateLine.isHidden = !isShowSeparteLine
        }
    }

    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        return label
    }()

    private lazy var separateLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    private lazy var checkMarkView: UIImageView = {
        let icon = UDIcon.getIconByKey(
            .doneOutlined,
            renderingMode: .automatic,
            iconColor: UIColor.ud.primaryContentDefault,
            size: CGSize(width: 20, height: 20)
        )
        let imageView = UIImageView()
        imageView.image = icon
        imageView.isHidden = true
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = UIColor.ud.bgFloat
        contentView.backgroundColor = UIColor.ud.bgFloat
        contentView.addSubview(checkMarkView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(separateLine)
        titleLabel.snp.makeConstraints {
            $0.left.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(13)
            $0.right.equalTo(checkMarkView.snp.left).offset(-12)
            $0.bottom.equalToSuperview().offset(-13)
            $0.height.greaterThanOrEqualTo(22)
        }
        checkMarkView.snp.makeConstraints {
            $0.width.height.equalTo(20)
            $0.centerY.equalToSuperview()
            $0.right.equalToSuperview().offset(-16)
        }
        separateLine.snp.makeConstraints { make in
            make.height.equalTo(CGFloat(1.0 / UIScreen.main.scale))
            make.left.right.equalToSuperview().offset(16)
            make.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// title + switch
final class SettingSwitchCell: UITableViewCell {

    let contentCell = SettingSwitchBtnCell()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor.ud.bgFloat
        contentView.backgroundColor = UIColor.ud.bgFloat
        contentView.addSubview(contentCell)
        contentCell.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

/// header & footer
final class SettingHeaderView: UITableViewHeaderFooterView {

    let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UDFont.systemFont(ofSize: 12, weight: .regular)
        return label
    }()

    private let containerView = UIView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.backgroundColor = UIColor.ud.bgFloatBase
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.frame = bounds
        let titleSize = titleLabel.sizeThatFits(
            CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        )
        titleLabel.frame = CGRect(
            x: 4,
            y: frame.height - titleSize.height - 4,
            width: frame.width - 4,
            height: titleSize.height
        )
    }

}
