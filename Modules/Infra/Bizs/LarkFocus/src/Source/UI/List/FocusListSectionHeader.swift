//
//  FocusListSectionHeader.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/12/30.
//

import Foundation
import UIKit

final class FocusListSectionHeader: UITableViewHeaderFooterView {

    func configure(withTitle title: String, description: String? = nil) {
        titleLabel.setTextWithFigmaLineHeight(title)
        descLabel.setTextWithFigmaLineHeight(description ?? "")
        descLabel.isHidden = description == nil
    }

    private lazy var container: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        return stack
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.ud.body1(.fixed)
        return label
    }()

    private lazy var descLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.ud.body2(.fixed)
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
    }

    private func setupSubviews() {
        contentView.addSubview(container)
        container.addArrangedSubview(titleLabel)
        container.addArrangedSubview(descLabel)
    }

    private func setupConstraints() {
        container.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(32)
            make.trailing.equalToSuperview().offset(-32)
        }
    }

    private func setupAppearance() {

    }
}

fileprivate extension UILabel {

    func setTextWithFigmaLineHeight(_ text: String) {
        let lineHeight = font.figmaHeight
        let baselineOffset = (lineHeight - font.lineHeight) / 2.0 / 2.0

        // Paragraph style.
        let mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.minimumLineHeight = lineHeight
        mutableParagraphStyle.maximumLineHeight = lineHeight

        // Set.
        attributedText = NSAttributedString(
            string: text,
            attributes: [
                .baselineOffset: baselineOffset,
                .paragraphStyle: mutableParagraphStyle
            ]
        )
    }
}
