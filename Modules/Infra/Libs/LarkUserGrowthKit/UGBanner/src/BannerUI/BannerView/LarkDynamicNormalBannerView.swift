//
//  LarkBannerView.swift
//  LarkBanner
//
//  Created by mochangxing on 2020/5/22.
//

import UIKit
import Foundation
import RxSwift
import RustPB
import LKCommonsLogging
import ByteWebImage
import UniverseDesignColor

public final class LarkDynamicNormalBannerView: LarkBaseBannerView {
    static let logger = Logger.log(LarkDynamicNormalBannerView.self, category: "Module.Banner")
    static let titleLineHeight: CGFloat = 22.0
    static let subTitleLineHeight: CGFloat = 17.0
    static let maxLineNumber: Int = 4

    private let disposeBag = DisposeBag()
    private let iconView = UIImageView()
    private let textContainer = UIView()
    private let titleLabel = UILabel()
    private let subTitleLabel = UILabel()
    private let button = UIButton()
    private let backgroundIV = UIImageView()
    private let bgMaskView = UIView()

    var titleHeight: CGFloat = 0
    var subTitleHeight: CGFloat = 0

    public override init(bannerData: LarkBannerData, bannerWidth: CGFloat) {
        super.init(bannerData: bannerData, bannerWidth: bannerWidth)
        self.setupSubviews()
        self.bindData(bannerData: bannerData)
        self.setupLayouts()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupLayouts() {
        switch bannerData.normalBanner.layout {
        case .style1:
            setupStyle1Layouts()
        case .style2:
            setupStyle2Layouts()
        @unknown default:
            break
        }
    }

    override public func bindData(bannerData: LarkBannerData) {

        let content = bannerData.normalBanner
        let imageUrl = content.backgroundPic.cdnImage.url
        if content.hasBackgroundPic && !imageUrl.isEmpty {
            backgroundIV.bt.setLarkImage(with: .default(key: imageUrl))
        } else if content.hasBackgroundColor {
            contentView.backgroundColor = UIColor.rgba(content.backgroundColor)
        }

        let container = CGSize(width: getTextContainerWidth(), height: CGFloat.greatestFiniteMagnitude)
        var subTitleLines = LarkDynamicNormalBannerView.maxLineNumber
        if content.hasTitle {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = LarkDynamicNormalBannerView.titleLineHeight - titleLabel.font.lineHeight
            let color = content.hasTitleColor ? UIColor.rgba(content.titleColor) : titleLabel.textColor
            let attributes: [NSAttributedString.Key: Any] = [
                .paragraphStyle: paragraphStyle,
                .foregroundColor: color
            ]

            titleLabel.attributedText = NSAttributedString(string: content.title.content, attributes: attributes)
            titleLabel.lineBreakMode = .byTruncatingTail

            titleHeight = titleLabel.textRect(forBounds: CGRect(x: 0,
                                                                    y: 0,
                                                                    width: container.width,
                                                                    height: container.height),
                                                  limitedToNumberOfLines: LarkDynamicNormalBannerView.maxLineNumber).height
            let lines = Int(ceil(titleHeight/LarkDynamicNormalBannerView.titleLineHeight))
            subTitleLines = LarkDynamicNormalBannerView.maxLineNumber - lines
        }

        if content.hasTitleColor {
            titleLabel.textColor = UIColor.rgba(content.titleColor)
        }

        if content.hasSubTitle && subTitleLines > 0 {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = LarkDynamicNormalBannerView.subTitleLineHeight - subTitleLabel.font.lineHeight
            let color = content.hasSubTitleColor ? UIColor.rgba(content.subTitleColor) : subTitleLabel.textColor
            let attributes: [NSAttributedString.Key: Any] = [
                .paragraphStyle: paragraphStyle,
                .foregroundColor: color
            ]
            subTitleLabel.numberOfLines = subTitleLines
            subTitleLabel.attributedText = NSAttributedString(string: content.subTitle.content, attributes: attributes)
            subTitleLabel.lineBreakMode = .byTruncatingTail
            subTitleHeight = subTitleLabel.textRect(forBounds: CGRect(x: 0,
                                                                      y: 0,
                                                                      width: container.width,
                                                                      height: container.height),
                                              limitedToNumberOfLines: subTitleLines).height
        }

        if content.hasCtaTitle {
            button.setTitle(content.ctaTitle.content, for: .normal)
        }

        button.isHidden = !content.hasCtaTitle

        if content.hasCtaTitleColor {
            button.setTitleColor(UIColor.rgba(content.ctaTitleColor), for: .normal)
        }

        if content.hasCtaBackgroundColor {
            button.backgroundColor = UIColor.rgba(content.ctaBackgroundColor)
        }

        if content.hasBannerCloseableColor {
            bannerCloseView.color = UIColor.rgba(content.bannerCloseableColor)
        }

        if content.hasBannerIcon {
            let url = content.bannerIcon.cdnImage.url
            iconView.bt.setLarkImage(with: .default(key: url))
        }

        if content.hasFrameColor, !content.frameColor.isEmpty {
            contentView.layer.borderWidth = 1
            contentView.layer.ud.setBorderColor(UIColor.rgba(content.frameColor))
        }
        bannerCloseView.isHidden = !content.bannerCloseable
    }

    private func setupSubviews() {
        contentView.backgroundColor = UIColor.ud.primaryFillSolid02
        button.backgroundColor = UIColor.ud.primaryFillHover

        contentView.layer.cornerRadius = 8.0
        contentView.layer.masksToBounds = true

        iconView.layer.cornerRadius = 4.0
        iconView.layer.masksToBounds = true

        titleLabel.numberOfLines = 4
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)

        subTitleLabel.numberOfLines = 4
        subTitleLabel.textColor = UIColor.ud.textCaption
        subTitleLabel.font = UIFont.systemFont(ofSize: 12)

        bgMaskView.isUserInteractionEnabled = false
        bgMaskView.backgroundColor = UIColor.clear & UIColor.ud.fillImgMask

        if bannerData.normalBanner.layout == .style1 {
            button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        } else if bannerData.normalBanner.layout == .style2 {
            button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        }
        button.layer.cornerRadius = Style1Layout.buttonCornerRadius
        button.layer.masksToBounds = true

        contentView.addSubview(backgroundIV)
        contentView.addSubview(iconView)
        contentView.addSubview(button)
        contentView.addSubview(textContainer)
        textContainer.addSubview(titleLabel)
        textContainer.addSubview(subTitleLabel)
        contentView.addSubview(bgMaskView)

        textContainer.isUserInteractionEnabled = false
        backgroundIV.isUserInteractionEnabled = false
        button.isUserInteractionEnabled = false
        contentView.rx.controlEvent(.touchUpInside).asObservable().subscribe(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.contentView.isUserInteractionEnabled = false
            self.delegate?.onBannerClick(bannerView: self,
                                         url: self.bannerData.normalBanner.buttonLink.content)
            let when = DispatchTime.now() + 0.3
            DispatchQueue.main.asyncAfter(deadline: when) {
                self.contentView.isUserInteractionEnabled = true
            }
        }).disposed(by: self.disposeBag)
    }

    /// 内容高度
    public override func getContentSize() -> CGSize {
        switch bannerData.normalBanner.layout {
        case .style1:
            return getStyle1ContentSize()
        case .style2:
            return getStyle2ContentSize()
        @unknown default:
            return .zero
        }
    }

    public override func updateLayout() {
        titleLabel.snp.updateConstraints { (make) in
            make.height.equalTo(titleHeight)
        }
        subTitleLabel.snp.updateConstraints { (make) in
            make.height.equalTo(subTitleHeight)
        }
    }

    func getTextContainerWidth() -> CGFloat {
        var textContentWidth: CGFloat = 0
        switch bannerData.normalBanner.layout {
        case .style1:
            textContentWidth = bannerWidth
                - Style1Layout.contentInset.left
                - Style1Layout.contentInset.right
                - Style1Layout.iconLeading
                - Style1Layout.iconSize.width
                - Style1Layout.titleLeading
                - Style1Layout.titleTrailing
                - getButtonSize().width
                - Style1Layout.buttonTrailing
        case .style2:
            textContentWidth = bannerWidth
                  - Style2Layout.contentInset.left
                  - Style2Layout.contentInset.right
                  - Style2Layout.iconTrailing
                  - Style2Layout.iconSize.width
                  - Style2Layout.titleLeading
                  - Style2Layout.titleTrailing
        @unknown default:
            break
        }

        return textContentWidth
    }
    func getStyle1ContentSize() -> CGSize {
        let textContentHeight = Style1Layout.titleTop + titleHeight + Style1Layout.subtitleTop + subTitleHeight + Style1Layout.subtitleBottom
        let iconContentHeight = Style1Layout.iconVerticalMargin * 2 + Style1Layout.iconSize.height
        let maxContentHeight = max(textContentHeight, iconContentHeight)

        var height: CGFloat = 0.0
        height += Style1Layout.contentInset.top
        height += maxContentHeight
        height += Style1Layout.contentInset.bottom
        return CGSize(width: bounds.width, height: height)
    }

    func getStyle2ContentSize() -> CGSize {
        let leftContentHeight = Style2Layout.titleTop + titleHeight + Style2Layout.subtitleTop + subTitleHeight + Style2Layout.subtitleBottom + Style2Layout.buttonHeight + Style2Layout.buttonBottom

        let rightContentHeight = Style2Layout.iconVerticalMargin * 2 + Style2Layout.iconSize.height
        let maxContentHeight = max(leftContentHeight, rightContentHeight)

        var height: CGFloat = 0.0
        height += Style2Layout.contentInset.top
        height += maxContentHeight
        height += Style2Layout.contentInset.bottom
        return CGSize(width: bounds.width, height: height)
    }

    private func setupStyle1Layouts() {
        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(Style1Layout.contentInset)
        }

        bgMaskView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        backgroundIV.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        iconView.snp.makeConstraints { (make) in
            make.size.equalTo(Style1Layout.iconSize)
            make.leading.equalTo(Style1Layout.iconLeading)
            make.centerY.equalToSuperview()
        }

        textContainer.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalTo(iconView.snp.trailing).offset(Style1Layout.titleLeading)
            make.trailing.lessThanOrEqualTo(button.snp.leading).offset(-Style1Layout.titleTrailing)
            make.top.greaterThanOrEqualTo(Style1Layout.titleTop)
            make.bottom.lessThanOrEqualTo(-Style1Layout.subtitleBottom)
        }

        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        titleLabel.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(titleHeight)
        }

        subTitleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        subTitleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        subTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(Style1Layout.subtitleTop)
            make.bottom.leading.trailing.equalToSuperview()
            make.height.equalTo(subTitleHeight)
        }

        bannerCloseView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(Style1Layout.closeButtonTop)
            make.size.equalTo(Style1Layout.closeButtonSize)
            make.trailing.equalToSuperview().offset(-Style1Layout.closeButtonTrailing)
        }

        let buttonSize = getButtonSize()
        button.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-Style1Layout.buttonTrailing)
            make.width.equalTo(buttonSize.width)
            make.height.equalTo(buttonSize.height)
        }
    }

    private func setupStyle2Layouts() {
        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(Style2Layout.contentInset)
        }

        bgMaskView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        backgroundIV.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        iconView.snp.makeConstraints { (make) in
            make.size.equalTo(Style2Layout.iconSize)
            make.trailing.equalTo(-Style2Layout.iconTrailing)
            make.centerY.equalToSuperview()
        }

        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        titleLabel.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(titleHeight)
        }

        subTitleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        subTitleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        subTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(Style2Layout.subtitleTop)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(subTitleHeight)
        }

        textContainer.snp.makeConstraints { (make) in
            make.leading.equalTo(Style2Layout.titleLeading)
            make.trailing.equalTo(iconView.snp.leading).offset(-Style2Layout.titleTrailing)
            make.top.equalTo(Style2Layout.titleTop)
            make.bottom.equalTo(subTitleLabel.snp.bottom)
        }

        let buttonSize = getButtonSize()
        button.snp.makeConstraints { (make) in
            make.top.equalTo(textContainer.snp.bottom).offset(Style2Layout.buttonTop)
            make.leading.equalToSuperview().offset(Style2Layout.buttonLeading)
            make.size.equalTo(buttonSize)
        }

        bannerCloseView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(Style2Layout.closeButtonTop)
            make.size.equalTo(Style2Layout.closeButtonSize)
            make.trailing.equalToSuperview().offset(-Style2Layout.closeButtonTrailing)
        }
    }

    private func getButtonSize() -> CGSize {
        let container = CGSize(width: CGFloat.greatestFiniteMagnitude, height: Style1Layout.buttonHeight)
        let buttonWidth = (button.titleLabel?.sizeThatFits(container).width ?? 0) + Style1Layout.buttonTitleInset * 2
        return CGSize(width: buttonWidth, height: Style1Layout.buttonHeight)
    }
}

extension LarkDynamicNormalBannerView {
    enum Style1Layout {
        static let contentInset: UIEdgeInsets = UIEdgeInsets(top: 12.0, left: 16.0, bottom: 0.0, right: 16.0)

        static let iconSize: CGSize = CGSize(width: 84.0, height: 70.0)
        static let iconLeading: CGFloat = 8.0
        static let iconVerticalMargin: CGFloat = 8.0

        static let titleLeading: CGFloat = 8.0
        static let titleTrailing: CGFloat = 8.0
        static let titleTop: CGFloat = 12.0

        static let subtitleTop: CGFloat = 5.0
        static let subtitleBottom: CGFloat = 12.0

        static let buttonTrailing: CGFloat = 12.0
        static let buttonHeight: CGFloat = 28.0
        static let buttonCornerRadius: CGFloat = 6.0
        static let buttonTitleInset: CGFloat = 11.0

        static let closeButtonTop: CGFloat = 0
        static let closeButtonTrailing: CGFloat = 6.0
        static let closeButtonSize: CGSize = CGSize(width: 28.0, height: 28.0)
    }

    enum Style2Layout {
        static let contentInset: UIEdgeInsets = UIEdgeInsets(top: 12.0, left: 12.0, bottom: 0.0, right: 12.0)

        static let iconSize: CGSize = CGSize(width: 88.0, height: 88.0)
        static let iconTrailing: CGFloat = 28.0
        static let iconVerticalMargin: CGFloat = 8.0

        static let titleLeading: CGFloat = 12.0
        static let titleTrailing: CGFloat = 8.0
        static let titleTop: CGFloat = 12.0

        static let subtitleTop: CGFloat = 4.0
        static let subtitleBottom: CGFloat = 8.0

        static let buttonLeading: CGFloat = 12.0
        static let buttonHeight: CGFloat = 28.0
        static let buttonTop: CGFloat = 8.0
        static let buttonBottom: CGFloat = 12.0
        static let buttonCornerRadius: CGFloat = 6.0
        static let buttonTitleInset: CGFloat = 11.0

        static let closeButtonTop: CGFloat = 6.0
        static let closeButtonTrailing: CGFloat = 6.0
        static let closeButtonSize: CGSize = CGSize(width: 28.0, height: 28.0)
    }
}
