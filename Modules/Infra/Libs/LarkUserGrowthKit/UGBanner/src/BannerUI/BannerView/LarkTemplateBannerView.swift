//
//  LarkTemplateBannerView.swift
//  LarkBanner
//
//  Created by mochangxing on 2020/12/29.
//

import UIKit
import Foundation
import ServerPB
import UniverseDesignColor

struct TemplateCardModel {
    let bgImageUrl: String
    let fgImageUrl: String
    let categoryName: String
    let backgroundColor: String
    let frameColor: String?
    let link: String
    let layout: ServerPB_Ug_reach_material_TemplateBannerMaterial.Layout
    let isMore: Bool
}

final class LarkTemplateBannerView: LarkBaseBannerView {
    static let titleLineHeight: CGFloat = 22.0
    static let subTitleLineHeight: CGFloat = 17.0
    static let maxLineNumber: Int = 4

    private let bgMaskView = UIView()
    private let textContainer = UIView()
    private let titleLabel = UILabel()
    private let subTitleLabel = UILabel()
    private var scrollView = UIScrollView()
    var cardViews: [TemplateCardView] = []
    var titleHeight: CGFloat = 0
    var subTitleHeight: CGFloat = 0

    lazy var cardViewSize: CGSize = {
        switch bannerData.templateBanner.layout {
        case .style1:
            return StyleLayout.cardViewSize1
        case .style2:
            return StyleLayout.cardViewSize2
        case .style3, .style4:
            return StyleLayout.cardViewSize3
        @unknown default:
            return StyleLayout.cardViewSize3
        }
    }()

    lazy var scrollViewSize: CGSize = {
        return CGSize(width: cardViewSize.width + StyleLayout.cardViewOffset,
                      height: cardViewSize.height)
    }()

    lazy var scrollViewBottom: CGFloat = {
        switch bannerData.templateBanner.layout {
        case .style1:
            return 18
        case .style2, .style3, . style4:
            return 9
        @unknown default:
            return 9
        }
    }()

    public override init(bannerData: LarkBannerData, bannerWidth: CGFloat) {
        super.init(bannerData: bannerData, bannerWidth: bannerWidth)
        self.setupSubviews()
        self.bindData(bannerData: bannerData)
        self.setupLayouts()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateBgColor(_ content: BannerTemplateContent) {
        if content.hasBackgroundColor {
            contentView.backgroundColor = UIColor.rgba(content.backgroundColor)
        }

        if content.hasFrameColor {
            contentView.layer.borderWidth = 1
            contentView.layer.ud.setBorderColor(UIColor.rgba(content.frameColor))
        }
    }

    func updateTitle(_ content: BannerTemplateContent, _ containerSize: CGSize) -> Int {
        var subTitleLines = Self.maxLineNumber
        if content.hasTitle {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = LarkTemplateBannerView.titleLineHeight - titleLabel.font.lineHeight
            let color = content.hasTitleColor ? UIColor.rgba(content.titleColor) : UIColor.ud.textTitle
            let attributes: [NSAttributedString.Key: Any] = [
                .paragraphStyle: paragraphStyle,
                .foregroundColor: color
            ]

            titleLabel.attributedText = NSAttributedString(string: content.title.content, attributes: attributes)
            titleLabel.lineBreakMode = .byTruncatingTail
            let forBounds = CGRect(x: 0, y: 0, width: containerSize.width, height: containerSize.height)
            titleHeight = titleLabel.textRect(forBounds: forBounds,
                                              limitedToNumberOfLines: Self.maxLineNumber).height
            let lines = Int(ceil(titleHeight / Self.titleLineHeight))
            subTitleLines = Self.maxLineNumber - lines
        }

        if content.hasTitleColor {
            titleLabel.textColor = UIColor.rgba(content.titleColor)
        }
        return subTitleLines
    }

    func updateSubTitle(_ content: BannerTemplateContent, _ subTitleLines: Int, _ containerSize: CGSize) {
        if content.hasSubTitle && subTitleLines > 0 {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = Self.subTitleLineHeight - subTitleLabel.font.lineHeight
            let color = content.hasSubTitleColor ? UIColor.rgba(content.subTitleColor) : UIColor.ud.textCaption
            let attributes: [NSAttributedString.Key: Any] = [
                .paragraphStyle: paragraphStyle,
                .foregroundColor: color
            ]
            subTitleLabel.numberOfLines = subTitleLines
            subTitleLabel.attributedText = NSAttributedString(string: content.subTitle.content, attributes: attributes)
            subTitleLabel.lineBreakMode = .byTruncatingTail
            subTitleHeight = subTitleLabel.textRect(forBounds: CGRect(x: 0,
                                                                      y: 0,
                                                                      width: containerSize.width,
                                                                      height: containerSize.height),
                                                    limitedToNumberOfLines: subTitleLines).height
        }
    }

    func updateCloseBtn(_ content: BannerTemplateContent) {
        if content.hasBannerCloseableColor {
            bannerCloseView.color = UIColor.rgba(content.bannerCloseableColor)
        }
        bannerCloseView.isHidden = !content.bannerCloseable
    }

    func transformToCardModles(_ content: BannerTemplateContent) -> [TemplateCardModel] {
        let layout = content.layout

        var models = content.templateCategories.map { template in
            TemplateCardModel(bgImageUrl: template.dymPics.first?.cdnImage.url ?? "",
                              fgImageUrl: template.frontPic.cdnImage.url,
                              categoryName: template.categoryName.content,
                              backgroundColor: template.backgroundColor,
                              frameColor: template.frameColor,
                              link: template.link.content,
                              layout: layout,
                              isMore: false)
        }

        let templateMore = content.templateMore
        let moreModel = TemplateCardModel(bgImageUrl: templateMore.contentPic.cdnImage.url,
                                          fgImageUrl: "",
                                          categoryName: templateMore.name.content,
                                          backgroundColor: templateMore.backgroundColor,
                                          frameColor: templateMore.frameColor,
                                          link: templateMore.link.content,
                                          layout: layout,
                                          isMore: true)
        models.append(moreModel)
        return models
    }

    func updateScrollView(_ content: BannerTemplateContent) {
        let models = transformToCardModles(content)
        cardViews.forEach { $0.removeFromSuperview() }
        cardViews.removeAll()
        let contentWidth = bannerWidth - StyleLayout.contentInset.left - StyleLayout.contentInset.right
        for i in 0..<models.count {
            let cardModel = models[i]
            let cardView = TemplateCardView(cardModel: cardModel)
            cardViews.append(cardView)
            scrollView.addSubview(cardView)
            cardView.snp.makeConstraints { (make) in
                make.top.bottom.equalToSuperview()
                make.left.equalToSuperview().offset(StyleLayout.cardViewOffset + scrollViewSize.width * CGFloat(i))
                make.size.equalTo(cardViewSize)
                if i == models.count - 1 {
                    make.right.equalToSuperview().offset(contentWidth
                                                            - StyleLayout.cardViewOffset
                                                            - scrollViewSize.width)
                }
            }
            cardView.tapBlock = { [weak self] in
                   guard let self = self else { return }
                   self.delegate?.onBannerClick(bannerView: self, url: cardModel.link)
            }
        }
    }

    override func bindData(bannerData: LarkBannerData) {
//        assert(bannerData.bizName == .dynamic && bannerData.dyData.bannerType == .template,
//               "only dynamic banner can created by LarkBannerFactory")

        let content = bannerData.templateBanner
        let containerSize = CGSize(width: getTextContainerWidth(),
                                   height: CGFloat.greatestFiniteMagnitude)

        updateBgColor(content)
        let subTitleLines = updateTitle(content, containerSize)
        updateSubTitle(content, subTitleLines, containerSize)
        updateCloseBtn(content)
        updateScrollView(content)
    }

    public override func updateLayout() {
        titleLabel.snp.updateConstraints { (make) in
            make.height.equalTo(titleHeight)
        }
        subTitleLabel.snp.updateConstraints { (make) in
            make.height.equalTo(subTitleHeight)
        }
    }

    private func setupSubviews() {
        contentView.backgroundColor = UIColor.ud.primaryFillSolid02

        contentView.layer.cornerRadius = 8.0
        contentView.layer.masksToBounds = true

        bgMaskView.isUserInteractionEnabled = false
        bgMaskView.backgroundColor = UIColor.clear & UIColor.ud.fillImgMask

        titleLabel.numberOfLines = 4
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)

        subTitleLabel.numberOfLines = 4
        subTitleLabel.textColor = UIColor.ud.textCaption
        subTitleLabel.font = UIFont.systemFont(ofSize: 12)
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.clipsToBounds = false

        contentView.addSubview(textContainer)
        textContainer.addSubview(titleLabel)
        textContainer.addSubview(subTitleLabel)
        contentView.addSubview(scrollView)
        contentView.addSubview(bgMaskView)
    }

    func getTextContainerWidth() -> CGFloat {
        var textContentWidth: CGFloat = 0
        textContentWidth = bannerWidth
              - StyleLayout.contentInset.left
              - StyleLayout.contentInset.right
              - StyleLayout.titleLeading
              - StyleLayout.titleTrailing
        return textContentWidth
    }

    /// 内容高度
    override func getContentSize() -> CGSize {
        let contentHeight = StyleLayout.titleTop +
            titleHeight +
            StyleLayout.subtitleTop +
            subTitleHeight +
            StyleLayout.subtitleBottom +
            cardViewSize.height +
            scrollViewBottom

        var height: CGFloat = 0.0
        height += StyleLayout.contentInset.top
        height += contentHeight
        height += StyleLayout.contentInset.bottom
        return CGSize(width: bounds.width, height: height)
    }

    private func setupLayouts() {
        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(StyleLayout.contentInset)
        }

        bgMaskView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
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
            make.top.equalTo(titleLabel.snp.bottom).offset(StyleLayout.subtitleTop)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(subTitleHeight)
        }

        textContainer.snp.makeConstraints { (make) in
            make.leading.equalTo(StyleLayout.titleLeading)
            make.trailing.equalTo(bannerCloseView.snp.leading).offset(-StyleLayout.titleTrailing)
            make.top.equalToSuperview().offset(StyleLayout.titleTop)
            make.bottom.equalTo(subTitleLabel.snp.bottom)
        }

        bannerCloseView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(StyleLayout.closeButtonTop)
            make.size.equalTo(StyleLayout.closeButtonSize)
            make.trailing.equalToSuperview().offset(-StyleLayout.closeButtonTrailing)
        }

        scrollView.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(-scrollViewBottom)
            make.size.equalTo(scrollViewSize)
            make.left.equalToSuperview()
        }
    }

    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hotZoneRect = CGRect(x: scrollView.frame.minX,
                                 y: scrollView.frame.minY,
                                 width: self.frame.width,
                                 height: scrollViewSize.height)
        // 首先判断是否在 scrollView 热区内
        if hotZoneRect.contains(point) {
            // 是否存在可以响应事件的 subview
            let targetView = scrollView.subviews.first { (subview) -> Bool in
                // 坐标转换
                let newPoint = self.convert(point, to: subview)
                return subview.hitTest(newPoint, with: event) != nil
            }
            return targetView ?? scrollView
        }
        return super.hitTest(point, with: event)
    }
}

extension LarkTemplateBannerView {
    enum StyleLayout {
        static let contentInset: UIEdgeInsets = UIEdgeInsets(top: 12.0, left: 12.0, bottom: 0.0, right: 12.0)

        static let titleLeading: CGFloat = 12.0
        static let titleTrailing: CGFloat = 8.0
        static let titleTop: CGFloat = 12.0

        static let subtitleTop: CGFloat = 4.0
        static let subtitleBottom: CGFloat = 8.0

        static let closeButtonTop: CGFloat = 6.0
        static let closeButtonTrailing: CGFloat = 6.0
        static let closeButtonSize: CGSize = CGSize(width: 28.0, height: 28.0)

        static let cardViewSize1 = CGSize(width: 88, height: 94)
        static let cardViewSize2 = CGSize(width: 170, height: 122)
        static let cardViewSize3 = CGSize(width: 170, height: 125)
        static let cardViewOffset: CGFloat = 12
    }
}
