//
//  NormalSettingTableCell.swift
//  ExpandableTable
//
//  Created by Hayden Wang on 2021/8/25.
//

import Foundation
import UIKit
import UniverseDesignIcon

public class NormalSettingTableCell: BaseTableCell {

    enum TextLayout {
        case horizontal
        case vertical
    }

    enum ControlType {
        case none
        case arrow
        case check
    }

    var textLayout: TextLayout = .horizontal {
        didSet {
            adjustTextLayout()
        }
    }

    var controlType: ControlType = .none {
        didSet {
            switch controlType {
            case .none:
                controlView.isHidden = true
            case .arrow:
                controlView.isHidden = false
                controlView.image = UDIcon.rightOutlined.ud.withTintColor(UIColor.ud.iconN3)
            case .check:
                controlView.isHidden = false
                controlView.image = UDIcon.checkOutlined.ud.withTintColor(UIColor.ud.primaryContentDefault)
            }
        }
    }

    var icon: UIImage? {
        didSet {
            iconView.isHidden = icon == nil
            iconView.image = icon
        }
    }

    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }

    var detail: String? {
        didSet {
            detailLabel.isHidden = detail == nil
            detailLabel.text = detail
        }
    }

    public func setDividingLineHidden(_ isHidden: Bool) {
        dividingLine.isHidden = isHidden
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        setInitialViewState()
    }

    /// 横向 Cell 内容容器
    lazy var contentContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        return stack
    }()

    /// 左侧的图标
    public private(set) lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    /// 中间的文字容器（标题、内容）
    private lazy var textContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        return stack
    }()

    /// 右侧的控制按钮（箭头、删除、对勾）
    private lazy var controlView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    /// 标题
    public private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        return label
    }()

    /// 内容
    public private(set) lazy var detailLabel: UILabel = {
        let label = UILabel()
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        return label
    }()

    /// 标题和内容中间的占位
    private lazy var paddingView: UIView = {
        let view = UIView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return view
    }()

    /// 下方分割线
    private lazy var dividingLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
        setupSubclass()
    }

    func setupSubclass() {}

    private func setupSubviews() {
        contentView.addSubview(contentContainer)
        contentContainer.addArrangedSubview(iconView)
        contentContainer.addArrangedSubview(textContainer)
        contentContainer.addArrangedSubview(controlView)
        textContainer.addArrangedSubview(titleLabel)
        textContainer.addArrangedSubview(paddingView)
        textContainer.addArrangedSubview(detailLabel)
        contentView.addSubview(dividingLine)
    }

    private func setupConstraints() {
        contentContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
            make.height.greaterThanOrEqualTo(28)
        }
        dividingLine.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.trailing.bottom.equalToSuperview()
            make.leading.equalTo(textContainer)
        }
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
        }
        controlView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
        }
        paddingView.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(10)
        }
        textContainer.spacing = 2
        contentContainer.spacing = 12
    }

    private func setupAppearance() {
        setInitialViewState()
    }

    private func setInitialViewState() {
        // 默认样式
        iconView.isHidden = true
//        paddingView.isHidden = true
        detailLabel.isHidden = true
        controlView.isHidden = true
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        detailLabel.textColor = UIColor.ud.textPlaceholder
        detailLabel.font = UIFont.systemFont(ofSize: 14)
    }

    private func adjustTextLayout() {
        switch textLayout {
        case .horizontal:
            textContainer.axis = .horizontal
            detailLabel.numberOfLines = 1
        case .vertical:
            textContainer.axis = .vertical
            detailLabel.numberOfLines = 0
        }
    }
}
