//
//  CloudDriveSwitchView.swift
//  SKSpace
//
//  Created by Weston Wu on 2023/1/31.
//

import Foundation
import SKUIKit
import SKFoundation
import SnapKit
import UniverseDesignTabs
import UniverseDesignColor
import UniverseDesignShadow
import RxSwift
import RxRelay
import RxCocoa

private extension CloudDriveSwitchView {
    enum Layout {
        static var itemWidthIncrement: CGFloat { 40 }
        static var itemSpacing: CGFloat { 2 }
        static var contentInsets: UIEdgeInsets { UIEdgeInsets(top: 0, left: 2, bottom: 0, right: 2) }
    }
}

class CloudDriveSwitchView: UIView {
    private lazy var switchView: UDTabsTitleView = {
        let view = UDTabsTitleView()
        view.backgroundColor = UDColor.N200
        view.layer.cornerRadius = 16
        view.layer.masksToBounds = true
        view.collectionView.isScrollEnabled = false
        // 以下配置参考 IM 会话过滤器 FilterFixedView
        let config = view.getConfig()
        config.isSelectedAnimable = true
        config.isShowGradientMaskLayer = true
        config.isTitleColorGradientEnabled = false
        config.isContentScrollViewClickTransitionAnimationEnabled = true
        config.maskColor = .clear
        config.titleNormalColor = UDColor.textCaption
        config.titleNormalFont = .systemFont(ofSize: 14, weight: .regular)
        config.titleSelectedColor = UDColor.colorfulBlue & UDColor.N1000
        config.titleSelectedFont = .systemFont(ofSize: 14, weight: .medium)
        config.contentEdgeInsetLeft = Layout.contentInsets.left
        config.contentEdgeInsetRight = Layout.contentInsets.right
        config.itemSpacing = Layout.itemSpacing
        config.itemWidthIncrement = Layout.itemWidthIncrement
        config.maskVerticalPadding = 2
        config.isItemSpacingAverageEnabled = false
        config.titleLineBreakMode = .byTruncatingMiddle
        view.setConfig(config: config)

        let indicator = UDTabsIndicatorLineView()
        indicator.layer.ud.setShadowColor(UDShadowColorTheme.s3DownColor)
        indicator.layer.shadowOpacity = 0.2
        indicator.layer.shadowRadius = 18
        indicator.layer.shadowOffset = CGSize(width: 0, height: 6)
        indicator.indicatorHeight = 28
        indicator.indicatorRadius = 14
        indicator.indicatorColor = UDColor.N00 & UDColor.N500
        indicator.verticalOffset = 2
        indicator.indicatorMaskedCorners = .all
        view.indicators = [indicator]

        view.delegate = self
        return view
    }()

    var titles: [String] {
        get { switchView.titles }
        set {
            switchView.titles = newValue
            setNeedsLayout()
        }
    }

    var selectedIndex: Int { switchView.selectedIndex }

    private(set) lazy var toolBar = SpaceListToolBar()

    private var sectionChangedRelay = PublishRelay<Int>()
    var sectionChangedSignal: Signal<Int> { sectionChangedRelay.asSignal() }

    let listToolConfigInput = PublishRelay<[SpaceListTool]>()

    private var disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBody
        addSubview(switchView)
        addSubview(toolBar)

        switchView.snp.makeConstraints { make in
            make.height.equalTo(32)
            make.left.equalToSuperview().inset(8)
            make.top.bottom.equalToSuperview().inset(8)
            make.right.lessThanOrEqualTo(toolBar.snp.left)
            make.width.equalTo(0)
        }

        toolBar.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview()
        }

        switchView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        switchView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        listToolConfigInput.asSignal()
            .emit(onNext: { [weak self] newTools in
                guard let self else { return }
                self.toolBar.reset()
                self.toolBar.update(tools: newTools)
            })
            .disposed(by: disposeBag)

        toolBar.layoutAnimationSignal
            .emit(onNext: { [weak self] in
                guard let self = self else { return }
                UIView.animate(withDuration: 0.3) {
                    self.layoutIfNeeded()
                }
            })
            .disposed(by: disposeBag)
    }

    private func updateSwitchLayout() {
        // 计算压缩的属性前，先重置之前设置过的约束
        let config = switchView.getConfig()
        config.itemWidthIncrement = Layout.itemWidthIncrement
        config.itemMaxWidth = CGFloat.greatestFiniteMagnitude
        switchView.setConfig(config: config)
        // 计算未压缩过的 item 宽度和总宽度，与可用空间做比较
        let itemWidths = titles.enumerated().map { (index, _) -> CGFloat in
            switchView.preferredTabsView(widthForItemAt: index)
        }
        let initialWidth = Layout.contentInsets.left
        + Layout.contentInsets.right
        - Layout.itemSpacing
        let contentMaxWidth = itemWidths.reduce(initialWidth) { partialResult, itemWidth in
            return partialResult + itemWidth + Layout.itemSpacing
        }
        let maxWidth = toolBar.frame.minX - 16 // 左右两侧缩进
        updateSwitchViewConfig(itemWidths: itemWidths, contentMaxWidth: contentMaxWidth, maxWidth: maxWidth)
        let width = min(maxWidth, contentMaxWidth)
        switchView.snp.updateConstraints { make in
            make.width.equalTo(width)
        }
    }

    private func updateSwitchViewConfig(itemWidths: [CGFloat],
                                        contentMaxWidth: CGFloat,
                                        maxWidth: CGFloat) {
        guard contentMaxWidth > 0, maxWidth > 0 else { return }

        let config = switchView.getConfig()
        let titlesCount = CGFloat(itemWidths.count)
        guard titlesCount > 0 else {
            return
        }
        // 这里要取当前的 config.itemWidthIncrement
        var itemWidthIncrement = config.itemWidthIncrement
        let currentItemMaxWidth = config.itemMaxWidth
        let exceedWidth = contentMaxWidth - maxWidth
        // 实际宽度超过最大宽度，减小 title 间距
        if exceedWidth > 0 {
            itemWidthIncrement -= exceedWidth / titlesCount
        }
        // title 间距不够压缩，改为限制 title 最大宽度
        if itemWidthIncrement < 0 {
            itemWidthIncrement = 0
            // 计算 title 实际可用宽度
            let titlesContentWidth = maxWidth
            - Layout.contentInsets.left
            - Layout.contentInsets.right
            - (titlesCount - 1) * Layout.itemSpacing
            var itemMaxWidth = titlesContentWidth / titlesCount
            for (index, itemExtendedWidth) in itemWidths.sorted(by: <).enumerated() {
                let itemWidth = itemExtendedWidth - config.itemWidthIncrement
                guard itemWidth < itemMaxWidth else {
                    // 后面的都更大，不用再比较了
                    break
                }
                // 小于平均宽度的 item 可以出让多余的宽度给后面的 item
                itemMaxWidth = itemMaxWidth + ((itemMaxWidth - itemWidth) / (titlesCount - 1 - CGFloat(index)))
            }
            config.itemMaxWidth = itemMaxWidth
        } else {
            config.itemMaxWidth = CGFloat.greatestFiniteMagnitude
        }
        if config.itemWidthIncrement == itemWidthIncrement,
           config.itemMaxWidth == currentItemMaxWidth {
            return
        }
        config.itemWidthIncrement = itemWidthIncrement
        switchView.setConfig(config: config)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateSwitchLayout()
    }
}

extension CloudDriveSwitchView: UDTabsViewDelegate {
    func tabsView(_ tabsView: UDTabsView, didSelectedItemAt index: Int) {
        sectionChangedRelay.accept(index)
    }
}
