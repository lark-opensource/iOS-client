//
//  LarkMenuGridView.swift
//  LarkSheetMenu
//
//  Created by liluobin on 2023/5/24.
//

import UIKit
import SnapKit
import LarkBadge
import UniverseDesignColor

class LarkMenuGridItemView: UIView {

    lazy var badgeView: BadgeView = {
        let badgeView = BadgeView(with: .dot(.web))
        return badgeView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        return label
    }()

    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.clear
        return imageView
    }()

    let config: LarkMenuGridItemConfig

    init(config: LarkMenuGridItemConfig) {
        self.config = config
        super.init(frame: .zero)
        self.setupView()
        self.backgroundColor = UIColor.dynamic(light: .ud.bgFloat, dark: .ud.bgFloatOverlay)
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
    }

    func setupView() {
        self.addSubview(titleLabel)
        self.addSubview(iconImageView)
        self.addSubview(badgeView)
        let iconHeight = config.iconHeight
        iconImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: iconHeight, height: iconHeight))
            make.top.equalTo(self.config.topMargin)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(self.iconImageView.snp.bottom).offset(self.config.itemSpace)
            make.left.equalToSuperview().offset(self.config.labelMargin)
            make.right.equalToSuperview().offset(-self.config.labelMargin)
            make.height.lessThanOrEqualTo(32)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap))
        self.addGestureRecognizer(tap)

        iconImageView.image = config.icon
        titleLabel.font = config.titleFont
        titleLabel.text = config.title
        let isGrey = config.actionItem.isGrey
        iconImageView.alpha = isGrey ? 0.3 : 1
        titleLabel.textColor = isGrey ? .ud.iconDisabled : .ud.textTitle
        badgeView.isHidden = !config.actionItem.isShowDot
        badgeView.snp.makeConstraints { make in
            make.bottom.equalTo(iconImageView.snp.top).offset(-0.25)
            make.left.equalTo(iconImageView.snp.right).offset(-0.25)
            make.width.height.equalTo(6)
        }
    }

    @objc
    func tap() {
        config.actionItem.tapAction()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LarkMenuGridView: UIView {

    private let layout: LarkMenuGridViewLayoutProtocol

    init(layout: LarkMenuGridViewLayoutProtocol = LarkMenuGridViewLayout()) {
        self.layout = layout
        super.init(frame: .zero)
    }

    func layoutForData(_ data: [LarkSheetMenuActionItem],
                       width: CGFloat) {
        guard width > 0 else { return }
        self.layout.layoutForData(data, width: width) { [weak self] result in
            guard let self = self else { return }
            self.layoutSubView(result: result)
        }
    }

    private func layoutSubView(result: [LarkMenuGridItemConfig]) {
        self.subviews.forEach { $0.removeFromSuperview() }
        result.forEach { config in
            let view = LarkMenuGridItemView(config: config)
            self.addSubview(view)
            let frame = config.frame
            view.snp.makeConstraints { make in
                make.left.equalTo(frame.origin.x)
                make.top.equalTo(frame.origin.y + 8)
                make.width.equalTo(frame.size.width)
                make.height.equalTo(frame.height)
                make.bottom.equalToSuperview()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LarkMenuGridItemConfig {

    let iconHeight: CGFloat

    let title: String

    let titleFont: UIFont

    let icon: UIImage

    let labelMargin: CGFloat

    var topMargin: CGFloat

    var bottomMargin: CGFloat

    var itemSpace: CGFloat

    var frame: CGRect

    let actionItem: LarkSheetMenuActionItem

    init(title: String,
         titleFont: UIFont,
         icon: UIImage,
         topMargin: CGFloat,
         bottomMargin: CGFloat,
         itemSpace: CGFloat,
         labelMargin: CGFloat,
         iconHeight: CGFloat,
         frame: CGRect,
         actionItem: LarkSheetMenuActionItem) {
        self.title = title
        self.titleFont = titleFont
        self.icon = icon
        self.topMargin = topMargin
        self.bottomMargin = bottomMargin
        self.itemSpace = itemSpace
        self.labelMargin = labelMargin
        self.frame = frame
        self.actionItem = actionItem
        self.iconHeight = iconHeight
    }
}

protocol LarkMenuGridViewLayoutProtocol: AnyObject {
    func layoutForData(_ data: [LarkSheetMenuActionItem],
                       width: CGFloat,
                       finish:(([LarkMenuGridItemConfig]) -> Void)?)
}
/// 负责每个Item的计算以及布局
class LarkMenuGridViewLayout: LarkMenuGridViewLayoutProtocol {

    /// 文字的左右边距
    let labelMargin: CGFloat = 2
    /// 正常字体
    let textFont: UIFont = UIFont.systemFont(ofSize: 12)
    /// 最小字体
    let minTextFont: UIFont = UIFont.systemFont(ofSize: 10)

    /// 异步计算 主线程回调
    /// - Parameters:
    ///   - data: 数组
    ///   - width: 供展示的宽度
    /// - Returns: 布局结构
    func layoutForData(_ data: [LarkSheetMenuActionItem],
                       width: CGFloat,
                       finish:(([LarkMenuGridItemConfig]) -> Void)?) {
        /// 如果这有一个 不在计算范畴
        guard data.count > 1, width > 0 else {
            finish?([])
            return
        }
        /// 按钮之间的间距
        let space: CGFloat = 6
        let topMargin: CGFloat = 18
        let bottomMargin: CGFloat = 3
        let itemSpace: CGFloat = 7

        let itemWidth: CGFloat = (width - ((CGFloat(data.count) - 1) * CGFloat(space))) / CGFloat(data.count)

        /// 宫格卡片固定高度为
        let height: CGFloat = 80
        let iconHeight: CGFloat = 20
        var configItems: [LarkMenuGridItemConfig] = []
        for (idx, item) in data.enumerated() {
            let result = self.numberOfline(item.text, onWidth: itemWidth, font: self.textFont)
            let frame = CGRect(x: (itemWidth + 6) * CGFloat(idx),
                               y: 0,
                               width: itemWidth,
                               height: height)
            let config = LarkMenuGridItemConfig(title: item.text,
                                              titleFont: result.1 > 2 ? self.minTextFont : self.textFont,
                                              icon: item.icon,
                                              topMargin: topMargin,
                                              bottomMargin: bottomMargin,
                                              itemSpace: itemSpace,
                                              labelMargin: self.labelMargin,
                                              iconHeight: iconHeight,
                                              frame: frame,
                                              actionItem: item)
            configItems.append(config)
        }
        finish?(configItems)
    }

    private func numberOfline(_ string: String, onWidth: CGFloat, font: UIFont) -> (CGFloat, Int) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping

        let rect = (string as NSString).boundingRect(
            with: CGSize(width: onWidth, height: CGFloat(MAXFLOAT)),
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font,
                         .paragraphStyle: paragraph], context: nil)
        let lineHeight = font.lineHeight
        return (rect.height, Int(ceil(rect.height) / lineHeight))
    }

}
