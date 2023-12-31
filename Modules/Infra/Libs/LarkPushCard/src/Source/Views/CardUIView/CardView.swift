//
//  PushCardView.swift
//  LarkPushCard
//
//  Created by 白镜吾 on 2022/8/26.
//

import Foundation
import UIKit
import FigmaKit
import UniverseDesignButton
import UniverseDesignShadow

// swiftlint:disable all
final class CardView: UIView {

    private lazy var customWrapperView: UIView = UIView()
    private lazy var buttonConfigs: [CardButtonConfig] = []

    private var _cardSize: CGSize = .zero

    private var _lastCardSize: CGSize = .zero

    private var _customViewSize: CGSize = .zero

    private var _lastCustomViewSize: CGSize = .zero

    func updateCardSize() {
        self._customViewSize = PushCardManager.calculateCustomViewSize(model: self.model)
        self._lastCustomViewSize = _customViewSize
        self._cardSize = CGSize(width: Cons.cardWidth, height: self.calculateCardHeight())
        self._lastCardSize = _cardSize
    }

    var customViewSize: CGSize {
        guard _customViewSize != .zero else {
            self._customViewSize = PushCardManager.calculateCustomViewSize(model: self.model)
            self._lastCustomViewSize = _customViewSize
            return self._customViewSize
        }

        if _customViewSize.width != Cons.cardWidth || _customViewSize != _lastCustomViewSize {
            self._lastCustomViewSize = self._customViewSize
            self._customViewSize = PushCardManager.calculateCustomViewSize(model: self.model)
        }
        return _customViewSize
    }

    var cardSize: CGSize {
        guard _cardSize != .zero  else {
            self._cardSize = CGSize(width: Cons.cardWidth, height: self.calculateCardHeight())
            self._lastCardSize = _cardSize
            return self._cardSize
        }

        if _cardSize.width != Cons.cardWidth || _cardSize != _lastCardSize {
            self._lastCardSize = _cardSize
            self._cardSize = CGSize(width: Cons.cardWidth, height: self.calculateCardHeight())
        }
        return  _cardSize
    }

    private lazy var container: UIView = {
        let container = UIView()
        StaticFunc.setShadow(on: container)
        return container
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

    private lazy var clipView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Cons.cardBodyCornerRadius
        view.clipsToBounds = true
        return view
    }()

    private lazy var containerStackView: UIStackView = {
        let containerStackView = UIStackView()
        containerStackView.axis = .vertical
        containerStackView.spacing = Cons.cardDefaultSpacing
        containerStackView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        containerStackView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        return containerStackView
    }()

    var model: Cardable

    init(model: Cardable) {
        self.model = model
        super.init(frame: .zero)
        self.addSubview(container)
        self.container.addSubview(blurView)
        self.container.addSubview(clipView)
        self.clipView.addSubview(containerStackView)
        self.container.sendSubviewToBack(blurView)
        self.container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.blurView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.clipView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.containerStackView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview().inset(onlyCustomItem ? 0 : Cons.cardDefaultSpacing).priority(.high)
            make.top.equalToSuperview().inset(onlyCustomItem ? 0 : Cons.cardDefaultSpacing).priority(.low)
        }
        self.setHeader()
        self.setCustomView()
        self.setButtons()
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard let superView = self.superview else { return }
        self.snp.makeConstraints { make in
            make.width.equalTo(Cons.cardWidth)
            make.height.equalTo(self.cardSize.height).priority(.medium)
            make.centerY.equalTo(superView.snp.top).offset(-self.cardSize.height / 2)
            make.centerX.equalToSuperview()
        }
        self.layoutIfNeeded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CardView {

    func setHeader() {
        guard model.icon != nil || model.title != nil else { return }
        let headerStackView = UIStackView()
        headerStackView.axis = .horizontal
        headerStackView.spacing = Cons.cardBodySpacingBetweenIconAndTitle
        headerStackView.alignment = .leading
        self.containerStackView.addArrangedSubview(headerStackView)
        self.setImage(in: headerStackView)
        self.setTitle(in: headerStackView)
    }

    func setImage(in headerStackView: UIStackView) {
        guard let image = model.icon else { return }
        let imageView: UIImageView = UIImageView()
        imageView.image = image
        imageView.layer.cornerRadius = Cons.imageSize / 2
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        headerStackView.addArrangedSubview(imageView)
        imageView.snp.remakeConstraints { make in
            make.size.equalTo(Cons.imageSize)
        }
    }

    /// 设置头部标题
    func setTitle(in headerStackView: UIStackView) {
        guard let title = model.title else { return }
        let titleLabel = UILabel()
        let baselineOffset = (Cons.cardTitleFigmaHeight - Cons.cardTitleFont.lineHeight) / 2.0 / 2.0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = Cons.cardTitleFigmaHeight
        paragraphStyle.maximumLineHeight = Cons.cardTitleFigmaHeight
        paragraphStyle.lineBreakMode = .byTruncatingTail
        paragraphStyle.alignment = .left
        titleLabel.attributedText = NSAttributedString(
            string: title,
            attributes: [
                .baselineOffset: baselineOffset,
                .paragraphStyle: paragraphStyle,
                .font: Cons.cardTitleFont,
                .foregroundColor: Colors.cardTitleColor,
            ]
        )

        headerStackView.addArrangedSubview(titleLabel)
        titleLabel.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
        }
    }

    func setCustomView() {
        guard let customView = model.customView else { return }

        customWrapperView = customView
        self.containerStackView.addArrangedSubview(customWrapperView)
        self.containerStackView.snp.remakeConstraints { make in
            make.edges.equalToSuperview().inset(onlyCustomItem ? 0 : Cons.cardDefaultSpacing)
        }
        if onlyCustomItem {
            self.customWrapperView.layer.cornerRadius = Cons.cardBodyCornerRadius
            self.customWrapperView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
            self.customWrapperView.layer.cornerRadius = 0
            self.customWrapperView.snp.remakeConstraints { make in
                make.leading.equalToSuperview()
                make.trailing.equalToSuperview()
                make.height.equalTo(self.cardSize.height)
            }
        }
    }

    /// 设置卡片按钮
    func setButtons() {
        guard let buttonConfigs = model.buttonConfigs else { return }

        let buttonStackView = UIStackView()
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = Cons.cardDefaultSpacing
        buttonStackView.distribution = .fillEqually
        buttonStackView.alignment = .center
        self.containerStackView.addArrangedSubview(buttonStackView)
        buttonStackView.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
        }

        self.buttonConfigs = buttonConfigs
        for (index, buttonConfig) in buttonConfigs.enumerated() {
            let button = UDButton(.primaryBlue)
            buttonStackView.addArrangedSubview(button)
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
                make.top.bottom.equalToSuperview().priority(.required)
                make.height.equalTo(Cons.cardBodyBtnHeight).priority(.required)
            }
        }
    }

    func resetCardCustomView() {
        guard let customView = model.customView else { return }
        customWrapperView = customView
        if model.icon != nil || model.title != nil {
            self.containerStackView.insertArrangedSubview(customWrapperView, at: 1)
        } else {
            self.containerStackView.insertArrangedSubview(customWrapperView, at: 0)
        }
        if onlyCustomItem {
            self.customWrapperView.layer.cornerRadius = Cons.cardBodyCornerRadius
            self.customWrapperView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
            self.customWrapperView.layer.cornerRadius = 0
            self.customWrapperView.snp.remakeConstraints { make in
                make.leading.equalToSuperview()
                make.trailing.equalToSuperview()
                make.height.equalTo(self.customViewSize.height)
            }
        }
    }

    @objc
    func buttonAction(sender: UDButton) {
        buttonConfigs[sender.tag].action(model)
    }
}

extension CardView {
    func calculateCardHeight() -> CGFloat {
        if onlyCustomItem, model.customView != nil {
            return customViewSize.height
        } else {
            var height: CGFloat = Cons.cardDefaultSpacing
            if self.model.title != nil || self.model.icon != nil {
                height += Cons.imageSize + Cons.cardDefaultSpacing
            }
            if self.model.customView != nil {
                height += self.customViewSize.height + Cons.cardDefaultSpacing
            }

            height += Cons.cardBodyBtnHeight + Cons.cardDefaultSpacing
            return height
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, alpha > 0.01 else {
            return nil
        }

        for subview in subviews.reversed() {
            let insidePoint = convert(point, to: subview)
            if let hitView = subview.hitTest(insidePoint, with: event) {
                return hitView
            }
        }
        return self
     }

    var onlyCustomItem: Bool {
        return (model.icon == nil || model.title == nil)
            && (model.buttonConfigs == nil)
            && (model.customView != nil)
    }
}
