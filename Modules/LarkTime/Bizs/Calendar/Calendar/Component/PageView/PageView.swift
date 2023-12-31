//
//  PageView.swift
//  PageView
//
//  Created by zhangwei on 2020/3/17.
//  Copyright © 2020 zhangwei. All rights reserved.
//

import UIKit
import CTFoundation

// MARK: - PageViewDataSource

protocol PageViewDataSource: AnyObject {
    func itemView(at index: PageIndex, in pageView: PageView, loggerModel: CaVCLoggerModel) -> UIView
}

// MARK: - PageViewDelegate

protocol PageViewDelegate: BasePageViewDelegate {
    func pageView(_ pageView: PageView, willLoad itemView: UIView, at index: PageIndex)
    func pageView(_ pageView: PageView, didLoad itemView: UIView, at index: PageIndex)
    func pageView(_ pageView: PageView, willUnload itemView: UIView, at index: PageIndex)
    func pageView(_ pageView: PageView, didUnload itemView: UIView, at index: PageIndex)

    func pageView(_ pageView: PageView, didChangePageOffset pageOffset: PageOffset)
    func pageView(_ pageView: PageView, didChangeVisiblePageRange visiblePageRange: CAValue<PageRange>)
}

extension PageViewDelegate {
    func pageView(_ pageView: PageView, willLoad itemView: UIView, at index: PageIndex) {}
    func pageView(_ pageView: PageView, didLoad itemView: UIView, at index: PageIndex) {}
    func pageView(_ pageView: PageView, willUnload itemView: UIView, at index: PageIndex) {}
    func pageView(_ pageView: PageView, didUnload itemView: UIView, at index: PageIndex) {}

    func pageView(_ pageView: PageView, didChangePageOffset pageOffset: PageOffset) {}
    func pageView(_ pageView: PageView, didChangeVisiblePageRange visiblePageRange: CAValue<PageRange>) {}
}

// MARK: - PageView

final class PageView: BasePageView {

    // MARK: Properties

    weak var delegate: PageViewDelegate? {
        didSet { baseDelegate = delegate }
    }

    weak var dataSource: PageViewDataSource? {
        didSet {
            if dataSource != nil {
                reloadData(in: 0..<totalPageCount, loggerModel: .init())
            }
        }
    }

    private var loadedItemViews = [PageIndex: UIView]()

    override func layoutSubviews() {
        super.layoutSubviews()
        // layout item views if needed
        loadedItemViews.forEach { setFrame(for: $1, at: $0) }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        updateItemViewsIfNeeded(loggerModel: .init())
    }

    // MARK: Index <-> ItemView

    /// return `nil` if item view at index has not been loaded.
    func itemView(at index: PageIndex) -> UIView? {
        return loadedItemViews[index]
    }

    // MARK: Reload Data

    func reloadData(loggerModel: CaVCLoggerModel) {
        reloadData(in: visiblePageRange, loggerModel: loggerModel)
    }

    func reloadData(at index: PageIndex, loggerModel: CaVCLoggerModel) {
        reloadData(in: index..<index + 1, loggerModel: loggerModel)
    }

    func reloadData(in range: PageRange, loggerModel: CaVCLoggerModel) {
        let lowerBoundMax = max(range.lowerBound, visiblePageRange.lowerBound)
        let upperBoundMin = min(range.upperBound, visiblePageRange.upperBound)
        guard upperBoundMin > lowerBoundMax else {
            EffLogger.log(model: loggerModel.createNewModelByTask(.abort), toast: "range not change")
            return
        }
        let reloadRange = lowerBoundMax..<upperBoundMin
        reloadRange.forEach{ unloadItemView(at: $0, loggerModel: loggerModel) }
        updateItemViewsIfNeeded(loggerModel: loggerModel)
    }

    // MARK: Page Item Management

    private func setFrame(for itemView: UIView, at index: PageIndex) {
        assert(index >= 0 && index < totalPageCount)
        var origin = CGPoint.zero
        if direction == .horizontal {
            origin.x = CGFloat(index) * pageSize.width
        } else {
            origin.y = CGFloat(index) * pageSize.height
        }
        itemView.frame = CGRect(origin: origin, size: pageSize)
    }

    private func loadItemView(at index: Int, loggerModel: CaVCLoggerModel) {
        guard index >= 0 && index < totalPageCount else { return }

        guard let dataSource = dataSource else { return }
        let oldView = itemView(at: index)

        // fetch itemView
        let newItemView = dataSource.itemView(at: index, in: self, loggerModel: loggerModel)

        // before load itemView
        delegate?.pageView(self, willLoad: newItemView, at: index)
        Self.logger.info("will load view: \(ObjectIdentifier(newItemView)), index: \(index)")

        // unload old itemView if needed
        if let oldView = oldView, oldView != newItemView {
            delegate?.pageView(self, willUnload: oldView, at: index)
            Self.logger.info("will unload view: \(ObjectIdentifier(oldView)), index: \(index)")
            oldView.removeFromSuperview()
            delegate?.pageView(self, didUnload: oldView, at: index)
            Self.logger.info("did unload view: \(ObjectIdentifier(oldView)), index: \(index)")
        }

        setFrame(for: newItemView, at: index)

        if newItemView.superview != scrollView {
            scrollView.addSubview(newItemView)
        }

        loadedItemViews[index] = newItemView
        #if DEBUG
        newItemView.pageIndex = index
        #endif

        // after load itemView
        delegate?.pageView(self, didLoad: newItemView, at: index)
        Self.logger.info("did load view: \(ObjectIdentifier(newItemView)), index: \(index), frame: \(newItemView.frame)")
    }

    private func unloadItemView(at index: Int, loggerModel: CaVCLoggerModel) {
        guard let view = loadedItemViews[index] else { return }

        loadedItemViews.removeValue(forKey: index)

        guard view.superview == scrollView else { return }

        delegate?.pageView(self, willUnload: view, at: index)
        Self.logger.info("will unload view: \(ObjectIdentifier(view)), index: \(index)")
        view.removeFromSuperview()
        delegate?.pageView(self, didUnload: view, at: index)
        Self.logger.info("did unload view: \(ObjectIdentifier(view)), index: \(index)")
    }

    // MARK: - Page State

    private func updateItemViewsIfNeeded(loggerModel: CaVCLoggerModel) {
        // remove invisible item views if needed
        loadedItemViews.keys
            .filter { !visiblePageRange.contains($0) }
            .forEach { unloadItemView(at: $0, loggerModel: loggerModel) }

        // load missing item views if needed
        if window != nil {
            for index in visiblePageRange {
                let view = loadedItemViews[index]
                if view == nil || view!.superview != scrollView {
                    loadItemView(at: index, loggerModel: loggerModel)
                }
            }
            if isShowEffLog {
                // 打印渲染结果
                logFrameInfo(loggerModel: loggerModel)
            }
        }
    }

    private func logFrameInfo(loggerModel: CaVCLoggerModel) {
        guard EffLogger.shouldLog else { return }
        if case .default = loggerModel.getCurrentTask() { return }
        let reloadLogger = loggerModel.createNewModelByTask(.reload)
        // 按照时间排序
        let newList = loadedItemViews.sorted { lhs, rhs in
            let lhsDate = JulianDayUtil.date(from: lhs.key)
            let rhsDate = JulianDayUtil.date(from: rhs.key)
            return lhsDate.day < rhsDate.day
        }
        let toast = newList.reduce("render:") { partialResult, item in
            if let view = item.value as? DayNonAllDayView, let viewData = view.viewData {
                let frames = viewData.items.reduce("") { partialResult, type in
                    let key = EffLogger.isCutLog ? String(type.viewData.uniqueId.prefix(10)) : type.viewData.uniqueId
                    let desc = " key = \(key), y = \(Int(type.frame.origin.y)) |"
                    return partialResult + desc
                }
                let date = JulianDayUtil.date(from: viewData.julianDay)
                let desc = " day = \(date.month)-\(date.day): { \(frames)} "
                return partialResult + desc
            }
            return partialResult
        }
        EffLogger.log(model: reloadLogger, toast: toast)
        reloadLogger.logEnd("")
    }

    override func visiblePageRangeDidChange() {
        super.visiblePageRangeDidChange()
        // window为空时无意义，需要过滤掉日志
        let loggerModel = CaVCLoggerModel(task: window != nil ? .action : .default)
        if isShowEffLog {
            EffLogger.log(model: loggerModel, toast: "visiblePageRangeDidChange")
        }
        let processModel = loggerModel.createNewModelByTask(.process)
        updateItemViewsIfNeeded(loggerModel: processModel)
        delegate?.pageView(self, didChangeVisiblePageRange: .init(visiblePageRange, processModel))

        #if DEBUG
        guard window != nil else { return }
        // 自检：
        //  - 没有出现空页
        //  - itemView 出现在正确的位置
        //  - itemView 的编号正确
        visiblePageRange.forEach { index in
            // 不出现空页
            guard let view = itemView(at: index),
                let superview = view.superview,
                superview == scrollView else {
                assertionFailure()
                return
            }
            // 页码正确
            guard let pageIndex = view.pageIndex, pageIndex == index else {
                assertionFailure()
                return
            }
            // frame 正确
            var origin = CGPoint.zero
            if direction == .horizontal {
                origin.x = CGFloat(index) * pageSize.width
            } else {
                origin.y = CGFloat(index) * pageSize.height
            }
            guard abs(origin.x - view.frame.minX) < 0.0001,
                  abs(origin.y - view.frame.minY) < 0.0001,
                  abs(pageSize.width - view.frame.width) < 0.0001,
                  abs(pageSize.height - view.frame.height) < 0.0001 else {
                // assertionFailure()
                return
            }
        }
        #endif
    }

    override func pageOffsetDidChange() {
        super.pageOffsetDidChange()
        delegate?.pageView(self, didChangePageOffset: pageOffset)
    }

}

#if DEBUG
extension UIView {
    private struct AssociatedKeys {
        static var pageIndex = "pageIndex"
    }

    var pageIndex: PageIndex? {
        set {
            var num: NSNumber?
            if let value = newValue {
                num = NSNumber(value: value)
            }
            objc_setAssociatedObject(self, &AssociatedKeys.pageIndex, num, .OBJC_ASSOCIATION_RETAIN)
        }
        get {
            guard let num = objc_getAssociatedObject(self, &AssociatedKeys.pageIndex) as? NSNumber else {
                return nil
            }
            return num.intValue
        }
    }
}
#endif
