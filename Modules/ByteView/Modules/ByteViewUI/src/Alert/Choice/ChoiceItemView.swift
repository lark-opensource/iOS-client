//
//  ChoiceItemView.swift
//  ByteViewUI
//
//  Created by fakegourmet on 2023/4/19.
//

import Foundation
import ByteViewCommon
import UniverseDesignCheckBox
import UniverseDesignIcon

class ChoiceItemView: UIView, UIGestureRecognizerDelegate {

    private let contentView: UIView = {
        let contentView = UIView()
        contentView.backgroundColor = .clear
        return contentView
    }()

    private var checkboxConfig = UDCheckBoxUIConfig()

    private(set) var checkbox = UDCheckBox(boxType: .multiple)

    private var textStyleConfig: VCFontConfig = .body

    let label: IconActionLabel = {
        let label = IconActionLabel(frame: .zero)
        label.backgroundColor = .clear
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()
    var imageSize = CGSize(width: 20, height: 20)

    lazy var headCount: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textPlaceholder
        label.isHidden = true
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }

    private func initialize() {
        addSubview(contentView)
        contentView.addSubview(checkbox)
        contentView.addSubview(label)
        contentView.addSubview(headCount)

        contentView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.top.equalTo(0.0)
        }

        checkbox.snp.makeConstraints { make in
            make.width.equalTo(imageSize.width)
            make.height.equalTo(imageSize.height)
            make.left.equalToSuperview()
            make.centerY.equalTo(label.snp.top).offset(textStyleConfig.lineHeight / 2.0)
            make.bottom.lessThanOrEqualToSuperview()
        }

        label.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalTo(checkbox.snp.right).offset(12)
            make.bottom.lessThanOrEqualToSuperview()
        }

        headCount.snp.makeConstraints { make in
            make.left.equalTo(label.snp.right).offset(5)
            make.centerY.equalTo(label)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if self.label.preferredMaxLayoutWidth != self.label.bounds.width {
            self.label.preferredMaxLayoutWidth = self.label.bounds.width
            self.label.attributedText = { self.label.attributedText }()
        }
    }

    func setItem(_ item: AnyChoiceItem) {
        self.textStyleConfig = item.textStyle
        if item.preferredLabelWidth > 0 {
            label.preferredMaxLayoutWidth = item.preferredLabelWidth - 48 - 16 - 32
        }
        let content: NSMutableAttributedString = .init(string: item.content,
                                                       config: item.textStyle,
                                                       textColor: item.isEnabled ? UIColor.ud.textTitle : UIColor.ud.textDisabled)
        content.addAttributes([.baselineOffset: -1], range: NSRange(location: 0, length: content.length))
        if item.isEnabled {
            label.attributedText = content
        } else {
            if item.useBasicDisableStyle {
                label.configBasicLabel(with: content, textStyle: item.textStyle)
            } else {
                label.configLabel(with: content,
                                  textStyle: item.textStyle,
                                  image: UDIcon.getIconByKey(.infoOutlined, iconColor: .ud.iconDisabled, size: CGSize(width: 16, height: 16)),
                                  size: CGSize(width: 16, height: 16),
                                  action: item.tapAction)

            }
        }
        checkbox.updateUIConfig(boxType: item.isSupportUnselected ? .multiple : .single, config: checkboxConfig)
        checkbox.isSelected = item.isSelected
        checkbox.isEnabled = item.isEnabled
    }

    func configCountNum(count: Int) {
        headCount.text = "(\(count))"
        headCount.isHidden = false
    }
}
