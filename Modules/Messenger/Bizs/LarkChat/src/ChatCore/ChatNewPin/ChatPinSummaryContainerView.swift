//
//  ChatPinSummaryContainerView.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/5/18.
//

import Foundation
import LarkUIKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignBadge
import RxSwift
import RxCocoa
import LarkOpenChat
import LKCommonsLogging
import ByteWebImage
import RichLabel
import LarkMessageCore

final class ChatPinSummaryContainerView: UIView {
    static let ViewHeight: CGFloat = 52
    static var onboardingDotKey: String {
        "im.chat.pin.onboard.card.badge"
    }

    struct UIConfig {
        static var cellInnerPadding: CGFloat { 8 }
        static var buttonSize: CGFloat { 36 }
        static var buttonIconSize: CGSize { CGSize(width: 16, height: 16) }
        static var containerLeftMargin: CGFloat { 8 }
        static var containerRightMargin: CGFloat { 16 }
        static var lastItemWidthLimit: CGFloat { 80 }
    }

    private let disposeBag = DisposeBag()
    private var totalCount: Int = 0
    private var originTabModels: [ChatPinSummaryUIModel] = []
    /// collection 数据源
    private var dataSource: [ChatPinSummaryUIModel] = []
    /// 计算的文本宽度缓存
    private var titleWidthCache: [(NSAttributedString, CGFloat)] = []
    private var containerWidth: CGFloat

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = UIConfig.cellInnerPadding
        layout.headerReferenceSize = CGSize(width: UIConfig.cellInnerPadding, height: 0)
        layout.footerReferenceSize = CGSize(width: UIConfig.cellInnerPadding, height: 0)
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(ChatPinSummaryCell.self, forCellWithReuseIdentifier: ChatPinSummaryCell.reuseIdentifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.clear
        return collectionView
    }()

    private lazy var button: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(clickMore(_:)), for: .touchUpInside)
        button.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.05) & UIColor.ud.staticWhite.withAlphaComponent(0.1)
        button.layer.cornerRadius = 8
        if self.viewModel.guideService?.checkShouldShowGuide(key: Self.onboardingDotKey) ?? false {
            button.addBadge(.dot, anchor: .topRight, offset: .init(width: -8, height: 10))
        }
        return button
    }()

    private weak var targetVC: UIViewController?
    private let viewModel: ChatPinSummaryContainerViewModel

    var displayBehaviorRelay: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    /// 左 or 右对齐
    private let supportLeftLayout: Bool
    /// 是否展示置顶总数
    private let displayTotalCount: Bool
    private var auditShowPin: Bool = false

    init(targetVC: UIViewController, supportLeftLayout: Bool, displayTotalCount: Bool, viewModel: ChatPinSummaryContainerViewModel) {
        self.targetVC = targetVC
        self.supportLeftLayout = supportLeftLayout
        self.displayTotalCount = displayTotalCount
        self.viewModel = viewModel
        self.containerWidth = targetVC.view.bounds.width
        super.init(frame: .zero)
        self.backgroundColor = UIColor.clear
        self.isHidden = true
        self.snp.makeConstraints { make in
            make.height.equalTo(ChatPinSummaryContainerView.ViewHeight)
        }

        self.addSubview(collectionView)
        self.addSubview(button)

        if supportLeftLayout {
            collectionView.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(UIConfig.containerLeftMargin)
            }
        } else {
            button.snp.makeConstraints { make in
                make.right.equalToSuperview().inset(UIConfig.containerRightMargin)
            }
        }

        collectionView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.equalTo(ChatPinSummaryContainerView.ViewHeight)
            make.width.equalTo(0)
        }

        button.snp.makeConstraints { make in
            make.size.equalTo(UIConfig.buttonSize)
            make.centerY.equalToSuperview()
            make.left.equalTo(collectionView.snp.right)
        }

        self.viewModel.pinSummaryRefreshDriver
            .drive(onNext: { [weak self] (items, totalCount) in
                guard let self = self else { return }
                self.setModels(models: items, totalCount: totalCount)
                self.handleDisplay()
            }).disposed(by: self.disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 输入框弹起的时候隐藏
    private var _keyboardContentIsFold: Bool = true
    func handleKeyboardContentHeightWillChange(_ isFold: Bool) {
        guard self._keyboardContentIsFold != isFold else { return }
        self._keyboardContentIsFold = isFold
        self.handleDisplay()
    }

    /// 聊天页面多选的时候隐藏
    private var _multiSelecting: Bool = false
    func handleMultiselect(_ multiSelecting: Bool) {
        guard self._multiSelecting != multiSelecting else { return }
        self._multiSelecting = multiSelecting
        self.handleDisplay()
    }

    private func handleDisplay() {
        if !_keyboardContentIsFold || _multiSelecting || self.originTabModels.isEmpty {
            self.isHidden = true
            self.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
            self.displayBehaviorRelay.accept(false)
        } else {
            self.isHidden = false
            self.snp.updateConstraints { make in
                make.height.equalTo(ChatPinSummaryContainerView.ViewHeight)
            }
            self.displayBehaviorRelay.accept(true)
        }
    }

    func setup() {
        self.viewModel.setup()
    }

    func getGuideTargetView() -> UIView? {
        guard self.displayBehaviorRelay.value else {
            return nil
        }
        return self.collectionView.cellForItem(at: IndexPath(item: 0, section: 0))
    }

    private func setModels(models: [ChatPinSummaryUIModel], totalCount: Int64) {
        self.originTabModels = models
        self.totalCount = Int(totalCount)
        self.reloadData()
    }

    func resizeIfNeeded(_ width: CGFloat) {
        guard self.containerWidth != width else { return }
        self.containerWidth = width
        self.reloadData()
    }

    private func reloadData() {
        var displayDigits: Int = 1
        var result: (contentWidth: CGFloat, widthItems: [WidthItem]) = self.calculateCollectionLayout(
            self.originTabModels,
            collectionRightMargin: self.getButtonWidth(displayDigits) + UIConfig.containerRightMargin
        )
        if result.widthItems.count >= totalCount || !displayTotalCount {
            let icon = UDIcon.getIconByKey(.pinListOutlined, size: UIConfig.buttonIconSize).ud.withTintColor(UIColor.ud.iconN1)
            button.setImage(icon, for: .normal)
            button.setImage(icon, for: .highlighted)
            button.setTitle(nil, for: .normal)
        } else {
            let maxDigits = self.getDigits(totalCount - result.widthItems.count)
            if maxDigits > displayDigits {
                for digit in (displayDigits + 1)...maxDigits {
                    result = self.calculateCollectionLayout(self.originTabModels, collectionRightMargin: self.getButtonWidth(digit) + UIConfig.containerRightMargin)
                    let buttonNumber = totalCount - result.widthItems.count
                    if getDigits(buttonNumber) == digit {
                        displayDigits = digit
                        break
                    }
                }
            }
            button.setImage(nil, for: .normal)
            button.setImage(nil, for: .highlighted)
            button.setTitle("+\(totalCount - result.widthItems.count)", for: .normal)
            button.setTitleColor(UIColor.ud.textTitle, for: .normal)
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = 0.5
            button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        }

        let widthItems = result.widthItems
        self.dataSource = Array(self.originTabModels.prefix(widthItems.count))
        for index in 0..<self.dataSource.count {
            var uiModel = self.dataSource[index]
            uiModel.width = widthItems[index].currentWidth
            self.dataSource[index] = uiModel
        }
        self.button.snp.updateConstraints { make in
            make.size.equalTo(CGSize(width: self.getButtonWidth(displayDigits), height: UIConfig.buttonSize))
        }
        self.collectionView.reloadData()
        self.collectionView.collectionViewLayout.invalidateLayout()
        self.collectionView.snp.updateConstraints { make in
            make.width.equalTo(result.contentWidth)
        }
        if !self.auditShowPin {
            self.auditShowPin = true
            let auditIds = self.dataSource.compactMap { uimodel in
                return uimodel.auditId
            }
            self.viewModel.auditService?.auditEvent(.chatPin(type: .showChatPinInChat(chatId: self.viewModel.chat.value.id,
                                                                                      pinIds: auditIds)),
                                                    isSecretChat: false)
        }
    }

    private func getDigits(_ number: Int) -> Int {
        var digit = 1
        var number = number
        while number / 10 != 0 {
            number /= 10
            digit += 1
        }
        return digit
    }

    /// 不同位数按钮的宽度
    private func getButtonWidth(_ digits: Int) -> CGFloat {
        switch digits {
        case ...1:
            return 36
        case 2:
            return 44
        case 3:
            return 54
        default:
            return CGFloat((digits - 3) * 10 + 54)
        }
    }

    private lazy var textParser: LKTextParserImpl = {
        let textParser = LKTextParserImpl()
        return textParser
    }()
    private lazy var layoutEngine: LKTextLayoutEngineImpl = {
        let layoutEngine = LKTextLayoutEngineImpl()
        let outOfRangeText = NSMutableAttributedString(string: "\u{2026}", attributes: [
            .foregroundColor: UIColor.ud.textTitle,
            .font: UIFont.systemFont(ofSize: 14)
        ])
        layoutEngine.outOfRangeText = outOfRangeText
        layoutEngine.numberOfLines = 1
        return layoutEngine
    }()

    private func calculateTitleWidth(_ titleAttr: NSAttributedString) -> CGFloat {
        if let item = self.titleWidthCache.first(where: { $0.0.isEqual(to: titleAttr) }) {
            return item.1
        } else {
            textParser.originAttrString = titleAttr
            textParser.parse()
            layoutEngine.attributedText = textParser.renderAttrString
            let titleWidth = layoutEngine.layout(size: CGSize(width: CGFloat.infinity, height: Self.ViewHeight)).width
            self.titleWidthCache.append((titleAttr, titleWidth))
            return titleWidth
        }
    }

    class WidthItem {
        var currentWidth: CGFloat
        let maxWidth: CGFloat

        init(currentWidth: CGFloat, maxWidth: CGFloat) {
            self.currentWidth = currentWidth
            self.maxWidth = maxWidth
        }

        func consume(width: CGFloat) -> CGFloat? {
            currentWidth += width
            if currentWidth <= maxWidth {
                return nil
            } else {
                let extraWidth = currentWidth - maxWidth
                currentWidth = maxWidth
                return extraWidth
            }
        }
    }

    private func calculate(items: [WidthItem], extraWidth: CGFloat) {
        if items.isEmpty || extraWidth <= 0 { return }

        var remainItems: [WidthItem] = []
        var remainTotalCount: CGFloat = 0
        let averageWidth: CGFloat = extraWidth / CGFloat(items.count)

        items.forEach { item in
            if let remainWidth = item.consume(width: averageWidth) {
                remainTotalCount += remainWidth
            } else {
                remainItems.append(item)
            }
        }
        calculate(items: remainItems, extraWidth: remainTotalCount)
    }

    private func calculateCollectionLayout(_ models: [ChatPinSummaryUIModel], collectionRightMargin: CGFloat) -> (contentWidth: CGFloat, widthItems: [WidthItem]) {
        var totalContentWidth: CGFloat = UIConfig.cellInnerPadding
        let collectionLeftMargin: CGFloat = UIConfig.containerLeftMargin
        let maxCollectionWidth = self.containerWidth - collectionRightMargin - collectionLeftMargin
        guard maxCollectionWidth > UIConfig.cellInnerPadding * 2 else {
            /// 避免计算出来的 cell width 存在负数的情况
            return (0, [])
        }

        var widthItems: [WidthItem] = []
        for (index, model) in models.enumerated() {
            let cellWidth: CGFloat = ChatPinSummaryCell.Layout.calculateCellWidth(titleWidth: self.calculateTitleWidth(model.titleAttr), hasIcon: model.iconConfig != nil)
            let maxCellWidth: CGFloat = 200
            let widthItem = WidthItem(currentWidth: min(cellWidth, maxCellWidth), maxWidth: cellWidth)
            widthItems.append(widthItem)
            let addedWidth: CGFloat = widthItem.currentWidth + UIConfig.cellInnerPadding
            totalContentWidth += addedWidth
            if totalContentWidth > maxCollectionWidth {
                let remainWidth: CGFloat = maxCollectionWidth - totalContentWidth + addedWidth

                if index >= 1 {
                    widthItems.removeLast()
                    /// 尝试把剩余宽度分给前面的 Item
                    calculate(items: widthItems, extraWidth: remainWidth)
                    var currentContentWidth = UIConfig.cellInnerPadding
                    widthItems.forEach { item in
                        currentContentWidth += item.currentWidth
                        currentContentWidth += UIConfig.cellInnerPadding
                    }
                    let newRemainWidth = maxCollectionWidth - currentContentWidth
                    if newRemainWidth >= UIConfig.lastItemWidthLimit + UIConfig.cellInnerPadding {
                        /// 剩余空间可以再展示一个
                        let lastCellWidth = newRemainWidth - UIConfig.cellInnerPadding
                        widthItems.append(WidthItem(currentWidth: lastCellWidth, maxWidth: lastCellWidth))
                        return (maxCollectionWidth, widthItems)
                    } else {
                        return (currentContentWidth, widthItems)
                    }
                } else {
                    /// 第一个都完全展示不下
                    let firstCellWidth = maxCollectionWidth - UIConfig.cellInnerPadding * 2
                    return (maxCollectionWidth, [WidthItem(currentWidth: firstCellWidth, maxWidth: firstCellWidth)])
                }
            }
        }
        /// 尝试把剩余宽度分给前面的 Item
        calculate(items: widthItems, extraWidth: maxCollectionWidth - totalContentWidth)
        var currentContentWidth = UIConfig.cellInnerPadding
        widthItems.forEach { item in
            currentContentWidth += item.currentWidth
            currentContentWidth += UIConfig.cellInnerPadding
        }
        return (currentContentWidth, widthItems)
    }

    @objc
    private func clickMore(_ button: UIButton) {
        button.badge?.removeFromSuperview()
        button.badge = nil
        self.viewModel.clickMore()
    }
}

extension ChatPinSummaryContainerView: UICollectionViewDataSource, UICollectionViewDelegate {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let model = dataSource[indexPath.item]
        model.tapHandler?()
    }

    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ChatPinSummaryCell.reuseIdentifier, for: indexPath) as? ChatPinSummaryCell else {
            return UICollectionViewCell()
        }
        cell.reloadData(model: dataSource[indexPath.item])
        return cell
    }
}

extension ChatPinSummaryContainerView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.dataSource[indexPath.item].width, height: ChatPinSummaryCell.Layout.cellHeight)
    }
}

final class ChatPinSummaryCell: UICollectionViewCell {
    static let logger = Logger.log(ChatPinSummaryCell.self, category: "Module.IM.ChatPin")
    static var reuseIdentifier: String { return String(describing: ChatPinSummaryCell.self) }

    struct Layout {
        static var minCellWidth: CGFloat { 68 }
        static var marginRight: CGFloat { 8 }
        static var marginLeft: CGFloat { 8 }
        static var iconSize: CGFloat { 16 }
        static var internalSpacing: CGFloat { 8 }
        static var cellHeight: CGFloat { ChatPinSummaryContainerView.ViewHeight - 16 }
        private static var cellExtraWidthWithoutIcon: CGFloat {
            marginLeft + marginRight
        }
        private static var cellExtraWidth: CGFloat {
            marginLeft + iconSize + internalSpacing + marginRight
        }

        static func calculateCellWidth(titleWidth: CGFloat, hasIcon: Bool) -> CGFloat {
            if hasIcon {
                return max(titleWidth + cellExtraWidth, Layout.minCellWidth)
            } else {
                return max(titleWidth + cellExtraWidthWithoutIcon, Layout.minCellWidth)
            }
        }
    }

    private lazy var titleLabel: LKLabel = {
        let outOfRangeText = NSMutableAttributedString(string: "\u{2026}", attributes: [
            .foregroundColor: UIColor.ud.textTitle,
            .font: UIFont.systemFont(ofSize: 14)
        ])
        let label = LKLabel(frame: .zero)
        label.numberOfLines = 1
        label.backgroundColor = UIColor.clear
        label.outOfRangeText = outOfRangeText
        label.autoDetectLinks = false
        return label
    }()

    private lazy var iconView: UIImageView = {
        let iconView = UIImageView()
        iconView.layer.masksToBounds = true
        return iconView
    }()

    private var disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.layer.cornerRadius = 8
        self.contentView.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.05) & UIColor.ud.staticWhite.withAlphaComponent(0.1)
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        iconView.snp.makeConstraints { make in
            make.size.equalTo(Layout.iconSize)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(Layout.marginLeft)
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(Layout.marginLeft + Layout.iconSize + Layout.internalSpacing)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(Layout.marginRight)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reloadData(model: ChatPinSummaryUIModel) {
        self.disposeBag = DisposeBag()
        if let iconConfig = model.iconConfig {
            iconView.isHidden = false
            titleLabel.snp.updateConstraints { make in
                make.left.equalToSuperview().inset(Layout.marginLeft + Layout.iconSize + Layout.internalSpacing)
            }
            URLPreviewPinIconTransformer.renderIcon(iconView,
                                                    iconResource: iconConfig.iconResource,
                                                    iconCornerRadius: iconConfig.cornerRadius,
                                                    disposeBag: self.disposeBag)
        } else {
            iconView.isHidden = true
            titleLabel.snp.updateConstraints { make in
                make.left.equalToSuperview().inset(Layout.marginLeft)
            }
        }
        let mutableAttributedString = NSMutableAttributedString(attributedString: model.titleAttr)
        let mutableParagraphStyle = NSMutableParagraphStyle()
        /// 这里只展示一行，尽可能多的展示内容
        // swiftlint:disable ban_linebreak_byChar
        mutableParagraphStyle.lineBreakMode = .byCharWrapping
        // swiftlint:enable ban_linebreak_byChar
        mutableAttributedString.addAttributes([.paragraphStyle: mutableParagraphStyle], range: NSRange(location: 0, length: mutableAttributedString.length))
        self.titleLabel.attributedText = mutableAttributedString
    }
}

struct ChatPinSummaryUIModel {
    let titleAttr: NSAttributedString
    let iconConfig: ChatPinIconConfig?
    let tapHandler: (() -> Void)?
    let auditId: String?
    var width: CGFloat = 0
}
