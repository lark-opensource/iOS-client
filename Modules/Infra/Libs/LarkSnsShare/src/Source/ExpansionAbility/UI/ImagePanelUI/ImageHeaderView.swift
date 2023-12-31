//
//  ImagePanelUI.swift
//  LarkSnsShare
//
//  Created by Siegfried on 2021/12/14.
//

import Foundation
import UIKit
import LarkEmotion

final class ImageHeaderView: UIView {
    weak var delegate: PanelHeaderCloseDelegate?
    var productLevel: String
    var scene: String

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
    private let cancelTitleBaselineOffset = (ShareCons.panelCancelTitleFontHeight - ShareCons.panelCancelTitleFont.lineHeight) / 2.0 / 2.0
    private let cancelMutableParagraphStyle: NSMutableParagraphStyle = {
        let mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.minimumLineHeight = ShareCons.panelCancelTitleFontHeight
        mutableParagraphStyle.maximumLineHeight = ShareCons.panelCancelTitleFontHeight
        mutableParagraphStyle.alignment = .center
        mutableParagraphStyle.lineBreakMode = .byWordWrapping
        mutableParagraphStyle.lineBreakMode = .byTruncatingTail
        return mutableParagraphStyle
    }()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 1
        titleLabel.attributedText = NSAttributedString(
            string: BundleI18n.LarkSnsShare.Lark_UD_SharePanelShareImage,
            attributes: [
                .baselineOffset: titleBaselineOffset,
                .paragraphStyle: mutableParagraphStyle,
                .font: ShareCons.panelTitleFont,
                .foregroundColor: ShareColor.panelTitleColor
            ]
          )
        return titleLabel
    }()

    private lazy var cancelTitleLabel: UILabel = {
        let cancelLabel = UILabel()
        cancelLabel.numberOfLines = 1
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCancelTitle))
        cancelLabel.addGestureRecognizer(tap)
        cancelLabel.isUserInteractionEnabled = true
        cancelLabel.attributedText = NSAttributedString(
            string: BundleI18n.LarkSnsShare.Lark_Legacy_CancelOpen,
            attributes: [
                .baselineOffset: cancelTitleBaselineOffset,
                .paragraphStyle: cancelMutableParagraphStyle,
                .font: ShareCons.panelCancelTitleFont,
                .foregroundColor: ShareColor.panelCancelTitleColor
            ]
          )
        return cancelLabel
    }()

    init(_ productLevel: String,
         _ scene: String) {
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
        self.addSubview(cancelTitleLabel)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(200)
        }
        cancelTitleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(ShareCons.defaultSpacing)
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didTapCancelTitle() {
        self.delegate?.dismissCurrentVC(animated: true)
        SharePanelTracker.trackerPublicSharePanelClick(productLevel: self.productLevel,
                                                       scene: self.scene,
                                                       clickItem: nil,
                                                       clickOther: "close",
                                                       panelType: .imagePanel)
    }
}
