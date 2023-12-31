//
//  DayAllDayPageView.swift
//  Calendar
//
//  Created by 张威 on 2020/8/23.
//

import UIKit

/// DayScene - AllDay - PageView
///
///  - 以 page 为粒度进行交互
///  - 以 section 为粒度进行加载数据

// MARK: Layout

typealias DayAllDayPageItemLayout = DayAllDayPageView.ItemLayout

// MARK: Item

protocol DayAllDayPageViewItemType {
    var view: UIView { get }
    var layout: DayAllDayPageItemLayout { get }
}

// MARK: Delegate

protocol DayAllDayPageViewDelegate: BasePageViewDelegate {
    func pageView(_ pageView: DayAllDayPageView, willLoad itemView: UIView, for layout: DayAllDayPageItemLayout)
    func pageView(_ pageView: DayAllDayPageView, didLoad itemView: UIView, for layout: DayAllDayPageItemLayout)
    func pageView(_ pageView: DayAllDayPageView, willUnload itemView: UIView, for layout: DayAllDayPageItemLayout)
    func pageView(_ pageView: DayAllDayPageView, didUnload itemView: UIView, for layout: DayAllDayPageItemLayout)

    func pageView(_ pageView: DayAllDayPageView, didChangePageOffset pageOffset: PageOffset)
    func pageView(_ pageView: DayAllDayPageView, didChangeVisiblePageRange visiblePageRange: PageRange)
    func pageView(_ pageView: DayAllDayPageView, didChangeVisibleRowCount visibleRowCount: Int)
}

extension DayAllDayPageViewDelegate {
    func pageView(_ pageView: DayAllDayPageView, willLoad itemView: UIView, for layout: DayAllDayPageItemLayout) {}
    func pageView(_ pageView: DayAllDayPageView, didLoad itemView: UIView, for layout: DayAllDayPageItemLayout) {}
    func pageView(_ pageView: DayAllDayPageView, willUnload itemView: UIView, for layout: DayAllDayPageItemLayout) {}
    func pageView(_ pageView: DayAllDayPageView, didUnload itemView: UIView, for layout: DayAllDayPageItemLayout) {}

    func pageView(_ pageView: DayAllDayPageView, didChangePageOffset pageOffset: PageOffset) {}
    func pageView(_ pageView: DayAllDayPageView, didChangeVisiblePageRange visiblePageRange: PageRange) {}
    func pageView(_ pageView: DayAllDayPageView, didChangeVisibleRowCount visibleRowCount: Int) {}
}

// MARK: DataSource

protocol DayAllDayPageViewDataSource: AnyObject {
    func pageView(_ pageView: DayAllDayPageView, itemsIn section: Int) -> [DayAllDayPageViewItemType]
}

// MARK: PageView

final class DayAllDayPageView: BasePageView {

    // Section 是 item 的加载单位
    typealias Section = Int

    struct Configuration {
        let getSectionByPage: (PageIndex) -> Section
        let getPageRangeFromSection: (Section) -> PageRange
    }

    struct ItemLayout {
        var pageRange: PageRange
        var row: Int
    }

    // MARK: Properties

    weak var delegate: DayAllDayPageViewDelegate?
    weak var dataSource: DayAllDayPageViewDataSource? {
        didSet {
            if dataSource != nil {
                reloadData()
            }
        }
    }

    /// `pageCountPerScene = 3` means there are always 3 pageItemViews in PageView
    override var pageCountPerScene: Int {
        didSet {
            guard oldValue != pageCountPerScene else { return }
            setNeedsLayout()
        }
    }

    var rowHeight: CGFloat = 22.0 {
        didSet {
            guard oldValue != rowHeight else { return }
            setNeedsLayout()
        }
    }

    var rowSpacing: CGFloat = 3.0 {
        didSet {
            guard oldValue != rowSpacing else { return }
            setNeedsLayout()
        }
    }

    var configuration: Configuration

    private(set) var visibleRowCount: Int = 0

    private var loadedSectionViews = [Int: [DayAllDayPageViewItemType]]()

    init(frame: CGRect = .zero, totalPageCount: Int, configuration: Configuration) {
        self.configuration = configuration
        super.init(frame: frame, totalPageCount: totalPageCount, direction: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // relayout item views
        loadedSectionViews.flatMap({ $0.value }).forEach({ setFrame(for: $0.view, with: $0.layout) })
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        updateItemViewsIfNeeded()
        updateVisibleRowCountIfNeeded()
    }

    // MARK: Loaded Items

    func loadedItemViews() -> [DayAllDayPageViewItemType] {
        return loadedSectionViews.flatMap { $0.value }
    }

    // MARK: Reload Data

    func reloadData() {
        // unload all item views
        loadedSectionViews.keys.sorted().forEach(unloadItemViews(in:))

        updateItemViewsIfNeeded()
        updateVisibleRowCountIfNeeded()
    }

    private func loadItemViews(in section: Section) {
        guard let dataSource = dataSource else { return }

        unloadItemViews(in: section)

        // fetch items
        let items = dataSource.pageView(self, itemsIn: section)
        for item in items {
            // before load item view
            delegate?.pageView(self, willLoad: item.view, for: item.layout)

            setFrame(for: item.view, with: item.layout)
            if item.view.superview != scrollView {
                scrollView.addSubview(item.view)
            }

            // after load item view
            delegate?.pageView(self, didLoad: item.view, for: item.layout)
        }
        loadedSectionViews[section] = items

        #if DEBUG
        let testRange = configuration.getPageRangeFromSection(section)
        let rowCount = self.rowCount(in: testRange)
        var matrixColors = (0..<rowCount).map { _ in [Bool].init(repeating: false, count: testRange.count) }
        for item in items {
            // 检验确保 layout 不会越界
            assert(item.layout.pageRange.lowerBound >= testRange.lowerBound
                && item.layout.pageRange.upperBound <= testRange.upperBound)
            // 检验确保没有发生重叠
            for i in item.layout.pageRange {
                let index = i - testRange.lowerBound
                assert(!matrixColors[item.layout.row][index])
                // 对已被占用区域进行着色
                matrixColors[item.layout.row][index] = true
            }
        }
        #endif
    }

    private func unloadItemViews(in section: Section) {
        guard let items = loadedSectionViews[section] else { return }

        loadedSectionViews.removeValue(forKey: section)

        for item in items {
            delegate?.pageView(self, willUnload: item.view, for: item.layout)
            Self.logger.info("will unload view: \(ObjectIdentifier(item.view)), layout: \(item.layout)")
            item.view.removeFromSuperview()
            delegate?.pageView(self, didUnload: item.view, for: item.layout)
            Self.logger.info("did unload view: \(ObjectIdentifier(item.view)), layout: \(item.layout)")
        }
    }

    @inline(__always)
    private func setFrame(for view: UIView, with layout: ItemLayout) {
        let minX = CGFloat(layout.pageRange.lowerBound) * pageSize.width
        let width = CGFloat(layout.pageRange.count) * pageSize.width
        let minY = CGFloat(layout.row) * (rowHeight + rowSpacing)
        let frame = CGRect(x: minX, y: minY, width: width, height: rowHeight)
        if frame != view.frame {
            view.frame = frame
        }
    }

    @inline(__always)
    private func rowCount(in range: PageRange) -> Int {
        let maxRowIndex = loadedSectionViews
            .flatMap { $0.value }
            .filter { $0.layout.pageRange.overlaps(range) }
            .map { $0.layout.row }
            .max()
        return maxRowIndex == nil ? 0 : maxRowIndex! + 1
    }

    private func section(for page: PageIndex) -> Int {
        return configuration.getSectionByPage(page)
    }

    private func updateItemViewsIfNeeded() {
        guard visiblePageRange.upperBound > visiblePageRange.lowerBound else { return }

        let startSection = section(for: visiblePageRange.lowerBound)
        let endSection = section(for: visiblePageRange.upperBound - 1)
        let visibleSections = startSection...endSection

        // remove invisible sectionItemViews if needed
        loadedSectionViews.keys
            .filter { !visibleSections.contains($0) }
            .forEach(unloadItemViews(in:))

        // load missing sectionItemViews if needed
        if window != nil {
            for section in visibleSections where loadedSectionViews[section] == nil {
                loadItemViews(in: section)
            }
        }
    }

    private func updateVisibleRowCountIfNeeded() {
        let visibleRowCount = rowCount(in: visiblePageRange)
        if visibleRowCount != self.visibleRowCount {
            self.visibleRowCount = visibleRowCount
            delegate?.pageView(self, didChangeVisibleRowCount: visibleRowCount)
        }
    }

    override func visiblePageRangeDidChange() {
        super.visiblePageRangeDidChange()
        updateItemViewsIfNeeded()
        delegate?.pageView(self, didChangeVisiblePageRange: visiblePageRange)
        updateVisibleRowCountIfNeeded()
    }

    override func pageOffsetDidChange() {
        super.pageOffsetDidChange()
        delegate?.pageView(self, didChangePageOffset: pageOffset)
    }

}
