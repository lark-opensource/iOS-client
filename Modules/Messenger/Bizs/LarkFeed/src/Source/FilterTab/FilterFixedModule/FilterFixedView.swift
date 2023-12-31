//
//  FilterFixedView.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/4/18.
//

import Foundation
import UIKit
import UniverseDesignTabs
import UniverseDesignShadow
import UniverseDesignColor
import LarkUIKit
import RxSwift
import RxCocoa
import LarkMessengerInterface
import EENavigator
import RustPB

final class FilterSelectedTabView: UIView {
    private let shadowView = UIView()
    private let button = UIButton(type: .custom)
    private let closeImageView = UIButton(type: .custom)
    private var unfixedTitle: String?
    var cancelHandler: (() -> Void)?
    var longPress: (() -> Void)?

    init() {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(_ title: String?) {
        unfixedTitle = title
        button.setTitle(title, for: .normal)
    }

    private func setupView() {
        shadowView.layer.ud.setShadowColor(UDShadowColorTheme.s3DownColor)
        shadowView.layer.shadowOpacity = 0.2
        shadowView.layer.shadowRadius = 18
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 6)
        shadowView.layer.cornerRadius = FilterFixedViewLayout.indicatorHeight / 2
        addSubview(shadowView)
        shadowView.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalToSuperview().inset(2)
        }

        button.backgroundColor = UDMessageColorTheme.imFeedBgBody
        button.setTitleColor(UDMessageColorTheme.imFeedTextPriSelected, for: .normal)
        button.titleLabel?.font = UIFont.ud.body1
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 8)
        button.layer.cornerRadius = FilterFixedViewLayout.indicatorHeight / 2
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(clickAction), for: .touchUpInside)
        shadowView.addSubview(button)
        button.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }

        addSubview(closeImageView)
        closeImageView.isUserInteractionEnabled = false
        closeImageView.setImage(Resources.filter_close, for: .normal)
        closeImageView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(10)
            make.centerY.equalTo(shadowView)
            make.width.height.equalTo(12)
        }
        let longPressGes = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(gesture:)))
        longPressGes.minimumPressDuration = 0.5
        longPressGes.numberOfTouchesRequired = 1
        button.addGestureRecognizer(longPressGes)
    }

    @objc
    private func clickAction() {
        self.cancelHandler?()
    }

    @objc
    private func longPressed(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            longPress?()
        }
    }
}

final class FilterFixedView: UIView {
    weak var delegate: FilterTabsViewDelegate?
    private let tabsView = FilterTabsView()
    private let viewModel: FilterFixedViewModel
    private let selectedTabView = FilterSelectedTabView()
    // 非固定栏的type
    private var unfixedType: Feed_V1_FeedFilter.TypeEnum?
    private var limitWidth: CGFloat = 0.0
    private var widthArray: [CGFloat]?

    var selectedIndex: Int {
        tabsView.selectedIndex
    }

    var titles: [String] {
        tabsView.titles
    }

    let disposeBag = DisposeBag()

    var currentWidth: CGFloat = 0
    init(viewModel: FilterFixedViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if currentWidth != bounds.size.width {
            reloadData(forcelayout: true)
            currentWidth = bounds.size.width
        }
    }

    private func setupView() {
        self.backgroundColor = UIColor.ud.bgBody

        tabsView.backgroundColor = UIColor.ud.N200
        tabsView.layer.cornerRadius = (FilterFixedViewLayout.fixedViewHeight) / 2
        tabsView.layer.masksToBounds = true
        tabsView.collectionView.isScrollEnabled = false
        self.addSubview(tabsView)
        tabsView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(4)
        }
        tabsView.delegate = self
        let config = tabsView.getConfig()
        config.isSelectedAnimable = true
        config.isContentScrollViewClickTransitionAnimationEnabled = true
        config.maskColor = UDMessageColorTheme.imFeedBgBody
        config.titleNormalColor = UIColor.ud.textCaption
        config.titleSelectedColor = UDMessageColorTheme.imFeedTextPriSelected
        config.titleNormalFont = UIFont.ud.body2
        config.titleSelectedFont = UIFont.ud.body1
        config.contentEdgeInsetLeft = FilterFixedViewLayout.contentEdgeInsetLeft
        config.contentEdgeInsetRight = FilterFixedViewLayout.contentEdgeInsetRight
        config.itemSpacing = FilterFixedViewLayout.itemSpacing
        config.itemWidthIncrement = FilterFixedViewLayout.itemWidthIncrement
        config.maskVerticalPadding = 2
        config.isItemSpacingAverageEnabled = false
        config.titleLineBreakMode = .byTruncatingMiddle
        tabsView.setConfig(config: config)

        let indicator = UDTabsIndicatorLineView()
        indicator.layer.ud.setShadowColor(UDShadowColorTheme.s3DownColor)
        indicator.layer.shadowOpacity = 0.2
        indicator.layer.shadowRadius = 18
        indicator.layer.shadowOffset = CGSize(width: 0, height: 6)
        indicator.indicatorHeight = FilterFixedViewLayout.indicatorHeight
        indicator.indicatorRadius = FilterFixedViewLayout.indicatorHeight / 2
        indicator.indicatorColor = UDMessageColorTheme.imFeedBgBody
        indicator.verticalOffset = 2
        indicator.indicatorMaskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        tabsView.indicators = [indicator]

        selectedTabView.backgroundColor = UIColor.ud.N200
        selectedTabView.layer.cornerRadius = (FilterFixedViewLayout.fixedViewHeight) / 2
        selectedTabView.layer.masksToBounds = true
        selectedTabView.alpha = 0
        self.addSubview(selectedTabView)
        selectedTabView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(4)
        }
        selectedTabView.cancelHandler = { [weak self] in
            guard let self = self else { return }
            if let item = self.viewModel.fixedDataSource.first as? FilterItemModel {
                self.viewModel.subSelectedTab = nil
                self.changeViewTab(item.type)
                self.delegate?.tabsView(self.tabsView, didClickSelectedItemAt: 0)
            }
        }

        // 临时tab
        selectedTabView.longPress = { [weak self] in
            guard let self = self,
                  let unfixedType = self.unfixedType else { return }
            if let subSelectedTab = self.viewModel.subSelectedTab {
                // 二级
                self.viewModel.dependency.filterActionHandler.groupActionSubject.onNext(.secondLevel(subSelectedTab))
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } else {
                // 一级
                self.viewModel.dependency.filterActionHandler.tryShowFilterActionsSheet(filterType: unfixedType, view: nil)
            }
        }

        // 固定分组栏tab长按Action
        tabsView.longPressCallBack = { [weak self] index in
            guard let self = self else { return }
            // 一级
            guard index < self.viewModel.fixedDataSource.count else { return }
            let filterItem = self.viewModel.fixedDataSource[index]
            self.viewModel.dependency.filterActionHandler.tryShowFilterActionsSheet(filterType: filterItem.type, view: nil)
        }
    }
}

// MARK: - 布局配置
extension FilterFixedView {
    func reload() {
        // 刷新固定栏数据
        let titles = viewModel.fixedDataSource.map({ filter -> String in
            return filter.title
        })
        if !titles.isEmpty {
            self.tabsView.titles = titles
            self.reloadData()
        }

        // 刷新非固定栏数据
        if let unfixedType = unfixedType,
           let unfixedFilter = viewModel.dataSource.first(where: { $0.type == unfixedType }) {
            let unfixedTitle = transformToTitle(filter: unfixedFilter)
            selectedTabView.setTitle(unfixedTitle)
            selectedTabView.snp_remakeConstraints { make in
                make.left.top.bottom.equalToSuperview().inset(4)
                make.width.equalTo(unfixedTitle.lu.width(font: UIFont.ud.body1) +
                                   FilterFixedViewLayout.selectedItemWidthIncrement)
            }
        }
    }

    func setTabViewLimitWidth(_ limitWidth: CGFloat) {
        self.limitWidth = limitWidth - 8
    }

    // 计算的时机: 1.获取limitWidth 2.reload 3.reloadData 4.update
    func updateTabViewConfig(realWidth: CGFloat, limitWidth: CGFloat) {
        guard !titles.isEmpty else { return }
        guard realWidth > 0, limitWidth > 0 else { return }
        let diff = limitWidth - realWidth
        let count = CGFloat(titles.count)
        var itemWidthIncrement = FilterFixedViewLayout.itemWidthIncrement
        // diff为负数时，减小Padding宽度
        if diff < 0 {
            itemWidthIncrement += (diff / count)
        }
        var config = tabsView.getConfig()
        // Padding不够压缩时，改为限制最大宽度
        if itemWidthIncrement < 0 {
            itemWidthIncrement = 0.0
            let itemTotalLimitWidth = (limitWidth
                                       - FilterFixedViewLayout.contentEdgeInsetLeft
                                       - FilterFixedViewLayout.contentEdgeInsetRight
                                       - (count - 1) * FilterFixedViewLayout.itemSpacing)
            if let widthArray = widthArray,
               let maxWidth = calculateMaxWidth(widthArray: widthArray, limitWidth: itemTotalLimitWidth) {
                config.itemMaxWidth = maxWidth
            } else {
                config.itemMaxWidth = itemTotalLimitWidth / (count)
            }
        } else {
            config.itemMaxWidth = CGFloat.greatestFiniteMagnitude
        }
        FeedContext.log.info("feedlog/filter/fixedTab/updateConfig. itemMaxWidth: \(config.itemMaxWidth)")
        if config.itemWidthIncrement == itemWidthIncrement {
            return
        }
        config.itemWidthIncrement = itemWidthIncrement
        tabsView.setConfig(config: config)
    }

    private func calculateMaxWidth(widthArray: [CGFloat], limitWidth: CGFloat) -> CGFloat? {
        guard !widthArray.isEmpty else { return nil }
        var sortArray = widthArray.sorted()
        var num = widthArray.count
        var tempWidth = limitWidth
        var maxWidth: CGFloat?
        while num > 0 {
            let first = sortArray[0]
            if (tempWidth - first) >= CGFloat(num - 1) * first {
                maxWidth = first
                tempWidth -= first
                sortArray.remove(at: 0)
                num -= 1
            } else {
                maxWidth = tempWidth / CGFloat(num)
                num = 0
            }
        }
        return maxWidth
    }

    private func needUpateTabViewConfig(realWidth: CGFloat, limitWidth: CGFloat) -> Bool {
        guard !titles.isEmpty else { return false }
        guard realWidth > 0, limitWidth > 0, realWidth - limitWidth > 0 else { return false }
        return true
    }

    func changeViewTab(_ type: Feed_V1_FeedFilter.TypeEnum) {
        if type == .flag {
            // 切到标记，但未展示过标记tab
            viewModel.showFlagInCommonlyUsedFiltersIfNeed()
        }

        if let index = belongToFixedTab(type) {
            showFixedTab(type, index)
            return
        }

        if belongToUnfixedTab(type) {
            showUnfixedTab(type)
            return
        }

        let errorMsg = "change wrong type: \(type)"
        let info = FeedBaseErrorInfo(type: .error(), errorMsg: errorMsg)
        FeedExceptionTracker.Filter.fixedTab(node: .changeViewTab, info: info)
    }

    private func belongToFixedTab(_ type: Feed_V1_FeedFilter.TypeEnum) -> Int? {
        guard let index = viewModel.fixedDataSource.firstIndex(where: { $0.type == type }) else { return nil }
        if isSelectedSubTab(type) {
            // 多级tab且subTab被选中时，则展示为非固定栏分组项
            return nil
        }
        return index
    }

    // 展示固定栏tab
    private func showFixedTab(_ type: Feed_V1_FeedFilter.TypeEnum, _ index: Int) {
        viewModel.subSelectedTab = nil
        unfixedType = nil
        reload()
        selectItemAt(index)
        viewModel.dependency.updateFilterSelection(FeedFilterSelection(type: type, secLevelId: nil))
        UIView.animate(withDuration: 0.2) {
            self.tabsView.alpha = 1
            self.selectedTabView.alpha = 0
        }
    }

    private func belongToUnfixedTab(_ type: Feed_V1_FeedFilter.TypeEnum) -> Bool {
        guard let item = viewModel.dataSource.first(where: { $0.type == type }) else { return false }
        return true
    }

    // 展示非固定栏tab
    private func showUnfixedTab(_ type: Feed_V1_FeedFilter.TypeEnum) {
        if !isSelectedSubTab(type) {
            viewModel.subSelectedTab = nil
        }
        unfixedType = type
        reload()
        viewModel.dependency.updateFilterSelection(FeedFilterSelection(type: type, secLevelId: viewModel.subSelectedTab?.tabId))
        UIView.animate(withDuration: 0.2) {
            self.tabsView.alpha = 0
            self.selectedTabView.alpha = 1
        }
    }

    private func isSelectedSubTab(_ type: Feed_V1_FeedFilter.TypeEnum) -> Bool {
        guard viewModel.multiLevelTabList.contains(type) else { return false }
        guard let subTab = viewModel.subSelectedTab, subTab.type == type, !subTab.tabId.isEmpty else { return false }
        return true
    }

    private func transformToTitle(filter: FilterItemModel) -> String {
        // 二级tab标题
        if let subTab = viewModel.subSelectedTab,
           let subUnread = viewModel.dependency.getSubTabUnreadNum(type: subTab.type, subId: subTab.tabId) {
            let title = filter.name + getValidUnread(subUnread)
            return title
        }
        return filter.title
    }

    private func getValidUnread(_ unread: Int) -> String {
        guard unread > 0 else { return "" }
        var countStr: String
        if unread <= FiltersModel.maxNumber {
            countStr = " \(unread)"
        } else if unread == FiltersModel.maxNumber + 1 {
            countStr = " 1M"
        } else {
            countStr = " 1M+"
        }
        return countStr
    }

    private func reloadData(forcelayout: Bool = false) {
        // 记录上一次滚动位置，否则收到新消息刷新tabsView时，会自动滚动到首tab上
        let offset = self.tabsView.collectionView.contentOffset
        self.tabsView.reloadData()
        let realContentWidth = getRealContentWidth()
        let needUpdate = needUpateTabViewConfig(realWidth: realContentWidth, limitWidth: limitWidth)
        if forcelayout || needUpdate {
            self.updateTabViewConfig(realWidth: realContentWidth, limitWidth: limitWidth)
        }
        self.tabsView.collectionView.setContentOffset(offset, animated: false)
        self.tabsView.snp_remakeConstraints { make in
            make.left.top.bottom.equalToSuperview().inset(4)
            make.width.equalTo(needUpdate ? getCustomContentWidth() : getContentWidth())
        }
    }

    func getRealContentWidth() -> CGFloat {
        var width: CGFloat = 0
        guard !tabsView.titles.isEmpty else { return width }
        var count = tabsView.titles.count
        guard count == self.viewModel.fixedDataSource.count else { return width }
        var widthArray: [CGFloat] = []
        let itemIncrement = FilterFixedViewLayout.itemWidthIncrement
        let titleNormalFont = tabsView.getConfig().titleNormalFont
        for title in titles {
            let titleWidth = title.lu.width(font: titleNormalFont)
            widthArray.append(titleWidth)
            width += titleWidth + itemIncrement
            width += FilterFixedViewLayout.itemSpacing
        }
        self.widthArray = widthArray
        width += FilterFixedViewLayout.contentEdgeInsetLeft + FilterFixedViewLayout.contentEdgeInsetRight
        return width
    }

    func getCustomContentWidth() -> CGFloat {
        var width: CGFloat = 0
        guard !tabsView.titles.isEmpty else { return width }
        var count = tabsView.titles.count
        guard count == self.viewModel.fixedDataSource.count else { return width }
        let itemIncrement = tabsView.getConfig().itemWidthIncrement
        let itemMaxWidth = tabsView.getConfig().itemMaxWidth
        let titleNormalFont = tabsView.getConfig().titleNormalFont
        for title in titles {
            let titleWidth = title.lu.width(font: titleNormalFont) + itemIncrement
            width += min(titleWidth, itemMaxWidth)
            width += FilterFixedViewLayout.itemSpacing
        }
        if count > 2 {
            width += 0.5 * (CGFloat(count) - 2) // offset微调
        }
        width += FilterFixedViewLayout.contentEdgeInsetLeft + FilterFixedViewLayout.contentEdgeInsetRight
        return width
    }

    func getContentWidth() -> CGFloat {
        var width: CGFloat = 0
        guard !tabsView.titles.isEmpty else { return width }
        var count = tabsView.titles.count
        guard count == self.viewModel.fixedDataSource.count else { return width }
        guard let lastItem = self.viewModel.fixedDataSource.last else { return width }
        if count == 1, lastItem.type == .unknown { return width }
        if lastItem.type == .unknown {
            count -= 1
        }
        for i in 0..<count {
            width += tabsView.preferredTabsView(widthForItemAt: i)
            width += FilterFixedViewLayout.itemSpacing
        }
        width -= FilterFixedViewLayout.itemSpacing
        width += FilterFixedViewLayout.contentEdgeInsetLeft + FilterFixedViewLayout.contentEdgeInsetRight
        return width
    }
}

// MARK: - FilterTabsViewDelegate
extension FilterFixedView: FilterTabsViewDelegate {
    // 代码选中指定index
    func selectItemAt(_ index: Int) {
        self.tabsView.selectItemAt(index: index)
    }

    func selectItemAt(_ index: Int, selectedType: UniverseDesignTabs.UDTabsViewItemSelectedType) {
        self.tabsView.selectItemAt(index: index, selectedType: selectedType)
    }

    func tabsView(_ tabsView: UDTabsView, didSelectedItemAt index: Int) {
        self.delegate?.tabsView(tabsView, didSelectedItemAt: index)
    }

    func tabsView(_ tabsView: UDTabsView, didClickSelectedItemAt index: Int) {
        guard index < viewModel.fixedDataSource.count else { return }
        let filterItem = viewModel.fixedDataSource[index]
        viewModel.dependency.updateFilterSelection(FeedFilterSelection(type: filterItem.type, secLevelId: nil))

        self.delegate?.tabsView(tabsView, didClickSelectedItemAt: index)
    }

    func tabsView(_ tabsView: UDTabsView, didScrollSelectedItemAt index: Int) {
        self.delegate?.tabsView(tabsView, didScrollSelectedItemAt: index)
    }

    func tabsView(_ tabsView: UDTabsView, scrollingFrom leftIndex: Int, to rightIndex: Int, percent: CGFloat) {
        self.delegate?.tabsView(tabsView, scrollingFrom: leftIndex, to: rightIndex, percent: percent)
    }

    func tabsView(_ tabsView: UDTabsView, canClickItemAt index: Int) -> Bool {
        return self.delegate?.tabsView(tabsView, canClickItemAt: index) ?? true
    }

    func didEnterSetting(_ tabsView: UDTabsView, index: Int) {}
}

// MARK: - 布局配置
enum FilterFixedViewLayout {
    static var contentEdgeInsetLeft: CGFloat { 2.auto() }
    static var contentEdgeInsetRight: CGFloat { 2.auto() }
    static var itemSpacing: CGFloat { 2.auto() }
    static var itemWidthIncrement: CGFloat { 40.auto() }
    static var selectedItemWidthIncrement: CGFloat { 56.auto() }
    static var indicatorHeight: CGFloat { 28 }
    static var verticalPadding: CGFloat { 4 }
    static var menuButtonWidth: CGFloat { FilterContainerView.FilterViewHeight - 16 }
    static var fixedViewHeight: CGFloat { FilterContainerView.FilterViewHeight - 16 }
    static var menuWidth: CGFloat { 52 }
}
