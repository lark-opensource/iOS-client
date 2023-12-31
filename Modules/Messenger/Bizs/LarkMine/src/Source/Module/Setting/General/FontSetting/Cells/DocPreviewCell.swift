//
//  DocPreviewCell.swift
//  LarkMine
//
//  Created by Hayden Wang on 2021/7/7.
//

import Foundation
import UIKit
import LarkZoomable
import UniverseDesignColor
import UniverseDesignFont

final class DocPreviewCell: UITableViewCell {

    func configure(with model: DocPreview, zoom: Zoom) {
        let titleFont = UDFont.getTitle0(for: zoom)
        let messageFont = UDFont.getBody0(for: zoom)
        let dotSize = LarkConstraint.auto(6, forZoom: zoom)
        titleLabel.setText(model.title, font: titleFont)
        messageLabel.setText(model.message, font: messageFont)
        highlightLabel.setText(model.highlight, font: messageFont)
        listLabel1.setText(model.list1, font: messageFont)
        listLabel2.setText(model.list2, font: messageFont)
        listDot1.snp.updateConstraints { update in
            update.width.height.equalTo(dotSize)
            update.top.equalTo(listLabel1).offset((messageFont.figmaHeight - dotSize) / 2)
        }
        listDot2.snp.updateConstraints { update in
            update.width.height.equalTo(dotSize)
            update.top.equalTo(listLabel2).offset((messageFont.figmaHeight - dotSize) / 2)
        }
        highlightIcon.snp.updateConstraints { update in
            update.width.height.equalTo(UDFont.getBody0(for: zoom).figmaHeight)
        }
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var highlightView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloatOverlay
        view.ud.setLayerBorderColor(UIColor.ud.lineBorderCard)
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 4
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var highlightIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Resources.doc_highlight_icon
        return imageView
    }()

    private lazy var highlightLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var listDot1: UIView = {
        let view = ListDotView()
        view.backgroundColor = UIColor.ud.functionInfoContentDefault
        return view
    }()

    private lazy var listDot2: UIView = {
        let view = ListDotView()
        view.backgroundColor = UIColor.ud.functionInfoContentDefault
        return view
    }()

    private lazy var listLabel1: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var listLabel2: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textTitle
        return label
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
    }

    private func setupSubviews() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(messageLabel)
        contentView.addSubview(highlightView)
        contentView.addSubview(listDot1)
        contentView.addSubview(listLabel1)
        contentView.addSubview(listDot2)
        contentView.addSubview(listLabel2)
        highlightView.addSubview(highlightIcon)
        highlightView.addSubview(highlightLabel)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Cons.hMargin)
            make.trailing.equalToSuperview().inset(Cons.hMargin)
            make.top.equalToSuperview().offset(26)
        }
        messageLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Cons.hMargin)
            make.trailing.equalToSuperview().inset(Cons.hMargin)
            make.top.equalTo(titleLabel.snp.bottom).offset(9)
        }
        listLabel1.snp.makeConstraints { make in
            make.leading.equalTo(listDot1.snp.trailing).offset(13)
            make.trailing.equalToSuperview().inset(Cons.hMargin)
            make.top.equalTo(messageLabel.snp.bottom).offset(16)
        }
        listLabel2.snp.makeConstraints { make in
            make.leading.equalTo(listDot2.snp.trailing).offset(13)
            make.trailing.equalToSuperview().inset(Cons.hMargin)
            make.top.equalTo(listLabel1.snp.bottom).offset(4)
            make.bottom.equalToSuperview().inset(26)
        }
        listDot1.snp.makeConstraints { make in
            make.width.height.equalTo(6)
            make.centerY.equalTo(listLabel1)
            make.top.equalTo(listLabel1)
            make.leading.equalToSuperview().offset(Cons.hMargin)
        }
        listDot2.snp.makeConstraints { make in
            make.width.height.equalTo(6)
            make.top.equalTo(listLabel2)
            make.leading.equalToSuperview().offset(Cons.hMargin)
        }
        highlightIcon.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
            make.width.height.equalTo(24)
        }
        highlightLabel.snp.makeConstraints { make in
            make.top.equalTo(highlightIcon)
            make.leading.equalTo(highlightIcon.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }
        highlightView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Cons.hMargin)
            make.trailing.equalToSuperview().inset(Cons.hMargin)
            make.top.equalTo(listLabel2.snp.bottom).offset(16)
        }
    }

    private func setupAppearance() {
        selectionStyle = .none
        backgroundColor = UIColor.ud.bgBody
    }
}

extension DocPreviewCell {

    enum Cons {
        static var hMargin: CGFloat { 26 }
    }
}

final class ListDotView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(bounds.width, bounds.height) / 2
    }
}

extension UILabel {

    func setText(_ text: String, font: UIFont) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = font.figmaHeight
        paragraphStyle.maximumLineHeight = font.figmaHeight
        attributedText = NSAttributedString(
            string: text, attributes: [
                .font: font,
                .paragraphStyle: paragraphStyle,
                .baselineOffset: (font.figmaHeight - font.lineHeight) / 4
            ]
        )
    }
}
