//
//  NormalSettingTableHeaderView.swift
//  ExpandableTable
//
//  Created by Hayden Wang on 2021/8/31.
//

import Foundation
import UIKit

final class NormalSettingTableHeaderView: UITableViewHeaderFooterView {

    var title: String? {
        didSet {
            setTitleWithLineHeight(title)
            titleLabel.isHidden = title == nil
        }
    }

    private lazy var container: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .leading
        return stack
    }()

    /// 标题
    public private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.isHidden = true
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
    }

    private func setupSubviews() {
        contentView.addSubview(container)
        container.addArrangedSubview(titleLabel)
    }

    private func setupConstraints() {
        container.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(4)
            make.trailing.equalToSuperview().offset(0)
            make.top.equalToSuperview().offset(14)
            make.bottom.equalToSuperview().offset(-2)
        }
    }

    private func setTitleWithLineHeight(_ text: String?) {
        guard let title = text else {
            titleLabel.text = nil
            return
        }
        let font = UIFont.systemFont(ofSize: 14)
        let lineHeight: CGFloat = 22
        let baselineOffset = (lineHeight - font.lineHeight) / 2.0 / 2.0

        // Paragraph style.
        let mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.minimumLineHeight = lineHeight
        mutableParagraphStyle.maximumLineHeight = lineHeight

        // Set.
        titleLabel.attributedText = NSAttributedString(
          string: title,
          attributes: [
            .baselineOffset: baselineOffset,
            .paragraphStyle: mutableParagraphStyle
          ]
        )
    }
}
