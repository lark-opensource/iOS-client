//
//  PushCardCell.swift
//  LarkPushCard
//
//  Created by 白镜吾 on 2022/8/25.
//

import Foundation
import UIKit
import FigmaKit
import UniverseDesignShadow
import UniverseDesignTheme
import UniverseDesignIcon
import UniverseDesignButton

// swiftlint:disable all
final class PushCardBaseCell: UICollectionViewCell {
    static var identifier = "PushCardCell"

    private var model: Cardable?

    private lazy var onlyCustomItem: Bool = false

    private lazy var imageView: UIImageView = UIImageView()
    private lazy var titleLabel = UILabel()
    private lazy var bodyLabel = UILabel()
    private lazy var buttonConfigs: [CardButtonConfig] = []

    private lazy var container: UIView = UIView()
    private lazy var containerStackView: UIStackView = {
        let containerStackView = UIStackView()
        containerStackView.axis = .vertical
        containerStackView.spacing = Cons.cardDefaultSpacing
        containerStackView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        containerStackView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        return containerStackView
    }()

    private lazy var headerStackView: UIStackView = {
        let headerStackView = UIStackView()
        headerStackView.axis = .horizontal
        headerStackView.spacing = Cons.cardBodySpacingBetweenIconAndTitle
        headerStackView.alignment = .leading
        headerStackView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        headerStackView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return headerStackView
    }()

    private var customWrapperView: UIView?
    private lazy var buttonStackView: UIStackView = {
        let buttonStackView = UIStackView()
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = Cons.cardDefaultSpacing
        buttonStackView.distribution = .fillEqually
        buttonStackView.alignment = .center
        return buttonStackView
    }()

    private lazy var blurView: BackgroundBlurView = {
        let blurView = BackgroundBlurView()
        blurView.fillColor = Colors.bgColor
        blurView.fillOpacity = 0.9
        blurView.blurRadius = 50
        blurView.layer.cornerRadius = Cons.cardBodyCornerRadius
        blurView.clipsToBounds = true
        return blurView
    }()

    private lazy var wrapperView: UIView = UIView()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.contentView.clipsToBounds = true
        self.contentView.layer.cornerRadius = Cons.cardBodyCornerRadius
        self.backgroundColor = .clear
        self.backgroundView?.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        self.contentView.addSubview(container)
        self.container.addSubview(blurView)
        self.container.addSubview(containerStackView)
        self.container.sendSubviewToBack(self.blurView)
        self.container.snp.makeConstraints { make in
            make.width.equalTo(Cons.cardWidth)
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview().priority(749)
        }

        self.blurView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.layer.shadowOpacity = 0

        self.imageView.image = nil
        self.titleLabel.attributedText = nil
        self.titleLabel.text = nil
        self.onlyCustomItem = false
        self.customWrapperView = nil
        
        for subView in buttonStackView.arrangedSubviews {
            subView.removeFromSuperview()
        }

        for subView in headerStackView.arrangedSubviews {
            subView.removeFromSuperview()
        }

        for subView in containerStackView.arrangedSubviews {
            subView.removeFromSuperview()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.container.snp.updateConstraints { make in
            make.width.equalTo(Cons.cardWidth)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(model: Cardable) {
        self.model = model
        self.onlyCustomItem = (model.icon == nil || model.title == nil) && (model.buttonConfigs == nil) && (model.customView != nil)
        self.containerStackView.snp.remakeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview().inset(onlyCustomItem ? 0 : Cons.cardDefaultSpacing).priority(.high)
            make.top.equalToSuperview().inset(onlyCustomItem ? 0 : Cons.cardDefaultSpacing).priority(.low)
        }
        self.setHeader()
        self.setCustomView()
        self.setButtons()
    }

    func updateShadow(pushCardState: PushCardState, index: Int = 0) {
        self.layer.shadowOpacity = 0
        switch pushCardState {
        case .hidden:
            return
        case .stacked:
            switch index {
            case 0, 1, 2:
                StaticFunc.setShadow(on: self)
            default:
                self.layer.shadowOpacity = 0
            }
        case .expanded:
            StaticFunc.setShadow(on: self)
        }
    }

}

private extension PushCardBaseCell {
    func setHeader() {
        if self.model?.icon != nil || self.model?.title != nil {
            self.containerStackView.addArrangedSubview(headerStackView)

            self.setImageView()
            self.setTitleLabel()
        }
    }

    func setImageView() {
        guard let image = self.model?.icon else {
            self.imageView.isHidden = true
            return
        }
        self.imageView.image = image
        self.headerStackView.addArrangedSubview(imageView)
        imageView.layer.cornerRadius = Cons.imageSize / 2
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        self.imageView.snp.remakeConstraints { make in
            make.size.equalTo(Cons.imageSize)
        }
    }

    func setTitleLabel() {
        guard let text = self.model?.title else {
            self.titleLabel.isHidden = true
            return
        }

        let baselineOffset = (Cons.cardTitleFigmaHeight - Cons.cardTitleFont.lineHeight) / 2.0 / 2.0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = Cons.cardTitleFigmaHeight
        paragraphStyle.maximumLineHeight = Cons.cardTitleFigmaHeight
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.alignment = .left
        self.titleLabel.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .baselineOffset: baselineOffset,
                .paragraphStyle: paragraphStyle,
                .font: Cons.cardTitleFont,
                .foregroundColor: Colors.cardTitleColor,
            ]
          )

        self.headerStackView.addArrangedSubview(titleLabel)
        self.titleLabel.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.equalTo(Cons.imageSize)
        }
    }

    func setCustomView() {
        guard let customView = model?.customView else {
            return
        }

        customWrapperView = customView
        guard let customWrapperView = customWrapperView else { return }

        self.containerStackView.addArrangedSubview(customWrapperView)

        self.containerStackView.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(onlyCustomItem ? 0 : Cons.cardDefaultSpacing)
        }

        if onlyCustomItem {
            customWrapperView.layer.cornerRadius = Cons.cardBodyCornerRadius
            customWrapperView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
            customWrapperView.layer.cornerRadius = 0
            customWrapperView.snp.remakeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(PushCardManager.calculateCustomViewSize(model: self.model).height).priority(749)
            }
        }
    }

    func setButtons() {

        guard let buttonConfigs = model?.buttonConfigs else { return }

        guard !buttonConfigs.isEmpty else { return }

        self.buttonConfigs = buttonConfigs
        self.containerStackView.addArrangedSubview(buttonStackView)
        self.buttonStackView.snp.remakeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
        }
        for (index, buttonConfig) in buttonConfigs.enumerated() {
            let button = UDButton(.primaryBlue)
            self.buttonStackView.addArrangedSubview(button)
            switch buttonConfig.buttonColorType {
            case .primaryBlue:
                button.config = .primaryBlue
            case .secondary:
                button.config = .secondaryGray
            }
            button.tag = index
            button.setTitle(buttonConfig.title, for: .normal)
            button.titleLabel?.lineBreakMode = .byTruncatingMiddle
            button.titleLabel?.font = .systemFont(ofSize: 16, weight: UIFont.Weight.regular)
            button.clipsToBounds = true
            button.config.type = .big
            button.addTarget(self, action: #selector(buttonAction(sender:)), for: .touchUpInside)

            button.snp.remakeConstraints { make in
                make.height.equalTo(Cons.cardBodyBtnHeight).priority(999)
            }
        }
    }

    @objc
    func buttonAction(sender: UIButton) {
        guard let model = model else { return }
        buttonConfigs[sender.tag].action(model)
    }
}
