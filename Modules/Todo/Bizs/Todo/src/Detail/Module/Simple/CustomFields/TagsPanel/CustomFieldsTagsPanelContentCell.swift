//
//  CustomFieldsTagsPanelContentCell.swift
//  Todo
//
//  Created by baiyantao on 2023/4/23.
//

import Foundation
import UniverseDesignTag
import UniverseDesignIcon

struct CustomFieldsTagsPanelContentCellData {
    var tagText: String
    var colorToken: DetailCustomFields.ColorToken?
    var isChecked: Bool

    var option: Rust.SelectFieldOption
}

final class CustomFieldsTagsPanelContentCell: UITableViewCell {

    var viewData: CustomFieldsTagsPanelContentCellData? {
        didSet {
            guard let data = viewData else { return }
            tagView.text = data.tagText
            if let colorToken = data.colorToken {
                var configuration = tagView.configuration
                configuration.textColor = DetailCustomFields.getColor(by: colorToken.textColor)
                if let backgroundColor = DetailCustomFields.getColor(by: colorToken.color) {
                    configuration.backgroundColor = backgroundColor
                }
                tagView.updateConfiguration(configuration)
            }
            checkView.isHidden = !data.isChecked
        }
    }

    private lazy var containerView = UIView()
    private lazy var tagView = UDTag()
    private lazy var checkView = initCheckView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.ud.bgBody
        selectionStyle = .none

        contentView.addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
        }

        containerView.addSubview(checkView)
        checkView.snp.makeConstraints {
            $0.centerY.right.equalToSuperview()
            $0.width.height.equalTo(16)
        }

        containerView.addSubview(tagView)
        tagView.snp.makeConstraints {
            $0.centerY.left.equalToSuperview()
            $0.right.lessThanOrEqualTo(checkView.snp.left).offset(-16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initCheckView() -> UIImageView {
        let view = UIImageView()
        view.image = UDIcon.listCheckBoldOutlined
            .ud.withTintColor(UIColor.ud.primaryContentDefault)
        return view
    }
}
