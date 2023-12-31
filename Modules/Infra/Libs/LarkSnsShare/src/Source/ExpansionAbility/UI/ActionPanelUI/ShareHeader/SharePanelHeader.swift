//
//  SharePanelHeader.swift
//  LarkSnsPanel
//
//  Created by Siegfried on 2021/11/19.
//

import Foundation
import UIKit
import UniverseDesignIcon
import LarkEmotion

final class SharePanelHeader: UIView {
    weak var delegate: PanelHeaderCloseDelegate?
    var productLevel: String
    var scene: String

    var title: String? {
        didSet {
            guard let title = title else { return }
            titleLabel.attributedText = NSAttributedString(
                string: title,
                attributes: [
                    .baselineOffset: titleBaselineOffset,
                    .paragraphStyle: mutableParagraphStyle,
                    .font: ShareCons.panelTitleFont,
                    .foregroundColor: ShareColor.panelTitleColor
                ]
              )
        }
    }
    private let titleBaselineOffset = (ShareCons.panelTitleFontHeight - ShareCons.panelTitleFont.lineHeight) / 2.0 / 2.0
    private let mutableParagraphStyle: NSMutableParagraphStyle = {
        let mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.minimumLineHeight = ShareCons.panelTitleFontHeight
        mutableParagraphStyle.maximumLineHeight = ShareCons.panelTitleFontHeight
        mutableParagraphStyle.alignment = .center
        mutableParagraphStyle.lineBreakMode = .byWordWrapping
        mutableParagraphStyle.lineBreakMode = .byTruncatingTail
        return mutableParagraphStyle
    }()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()

        return titleLabel
    }()

    internal lazy var closeIcon: UIImageView = {
        let icon = UIImageView()
        icon.image = UDIcon.getIconByKey(.closeSmallOutlined, iconColor: ShareColor.panelCloseIconColor)
        icon.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCloseIcon))
        icon.addGestureRecognizer(tap)
        return icon
    }()

    private lazy var divideLineView: UIView = {
        let line = UIView()
        line.backgroundColor = ShareColor.panelDivideLineColor
        return line
    }()

    init(_ productLevel: String, _ scene: String) {
        self.productLevel = productLevel
        self.scene = scene
        super.init(frame: .zero)
        setup()
    }
    private func setup() {
        setupSubViews()
        setupConstraints()
    }

    private func setupSubViews() {
        self.addSubview(titleLabel)
        self.addSubview(closeIcon)

    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        closeIcon.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(ShareCons.defaultSpacing)
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didTapCloseIcon() {
        self.delegate?.dismissCurrentVC(animated: true)
        SharePanelTracker.trackerPublicSharePanelClick(productLevel: self.productLevel,
                                                       scene: self.scene,
                                                       clickItem: nil,
                                                       clickOther: "close",
                                                       panelType: .actionPanel)
    }
}
