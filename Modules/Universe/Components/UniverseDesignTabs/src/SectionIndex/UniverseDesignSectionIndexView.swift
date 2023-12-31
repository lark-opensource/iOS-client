//
//  UniverseDesignSectionIndexView.swift
//  UniverseDesignTabs
//
//  Created by Yaoguoguo on 2023/2/7.
//

import UIKit

// MARK: - SectionIndexViewDataSource

public protocol UDSectionIndexViewDataSource: AnyObject {
    func numberOfItemViews(in sectionIndexView: UDSectionIndexView) -> Int

    func sectionIndexView(_ sectionIndexView: UDSectionIndexView, itemViewAt section: Int) -> UDSectionIndexViewItem

    func sectionIndexView(_ sectionIndexView: UDSectionIndexView, itemPreviewFor section: Int) -> UDSectionIndexViewItemPreview
}

// MARK: - SectionIndexViewDelegate

public protocol UDSectionIndexViewDelegate: AnyObject {
    func sectionIndexView(_ sectionIndexView: UDSectionIndexView, didSelect section: Int)

    func sectionIndexView(_ sectionIndexView: UDSectionIndexView, toucheMoved section: Int)

    func sectionIndexView(_ sectionIndexView: UDSectionIndexView, toucheCancelled section: Int)
}

// MARK: - SectionIndexViewItemPreviewDirection
public enum UDSectionIndexViewItemPreviewDirection: Int {
    case left, right
}

// MARK: - SectionIndexView
public final class UDSectionIndexView: UIView {

    var panGesture: UIPanGestureRecognizer?
    var tapGesture: UITapGestureRecognizer?

    public weak var dataSource: UDSectionIndexViewDataSource? {
        didSet {
            loadView()
        }
    }

    public weak var delegate: UDSectionIndexViewDelegate?

    public var isShowItemPreview: Bool = true

    public var itemPreviewDirection: UDSectionIndexViewItemPreviewDirection = .left

    public var itemPreviewMargin: CGFloat = 0

    public var isItemPreviewAlwaysInCenter = false

    public var currentItem: UDSectionIndexViewItem? {
        return _currentItem
    }

    // MARK: - private
    private var items = [UDSectionIndexViewItem]()

    private var itemPreviews = [UDSectionIndexViewItemPreview]()

    private var _currentItem: UDSectionIndexViewItem?

    private var touchItem: UDSectionIndexViewItem?

    fileprivate var currentItemPreview: UIView?

    public override init(frame: CGRect) {
        super.init(frame: frame)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        pan.cancelsTouchesInView = false
        self.addGestureRecognizer(pan)
        self.panGesture = pan

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        self.addGestureRecognizer(tap)
        self.tapGesture = tap
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func handleTap() {
        guard let tap = tapGesture else { return }
        let point = tap.location(in: self)

        if let section = getSectionBy(point: point) {
            if delegate?.sectionIndexView(self, didSelect: section) != nil {
                //
            } else {
                selectItem(at: section)
                showItemPreview(at: section, hideAfter: 0.2)
            }
            return
        }

        for i in 0..<items.count {
            let result = (items[i] == _currentItem)
            if result {
                delegate?.sectionIndexView(self, didSelect: i)
            }
        }
    }

    @objc
    private func handlePan() {
        guard let ges = panGesture else { return }
        let point = ges.location(in: self)

        switch ges.state {
        case .began, .changed:
            var item: UDSectionIndexViewItem
            for i in 0..<items.count {
                item = items[i]
                if touchItem != item && point.y <= (item.frame.origin.y + item.frame.size.height) && point.y >= item.frame.origin.y {
                    if  delegate?.sectionIndexView(self, toucheMoved: i) != nil {
                        //
                    } else {
                        selectItem(at: i)
                        showItemPreview(at: i)
                    }
                    touchItem = item
                    return
                }
            }
        case .ended:
            if let section = getSectionBy(point: point) {
                if delegate?.sectionIndexView(self, didSelect: section) != nil {
                    //
                } else {
                    selectItem(at: section)
                    showItemPreview(at: section, hideAfter: 0.2)
                }
                return
            }

            for i in 0..<items.count {
                let result = (items[i] == _currentItem)
                if result {
                    delegate?.sectionIndexView(self, didSelect: i)
                }
            }
        case .cancelled, .failed:
            if  let section = getSectionBy(point: point) {
                currentItemPreview?.removeFromSuperview()
                if delegate?.sectionIndexView(self, toucheCancelled: section) != nil {
                    //
                }
            }
        default:
            break
        }
    }

    // MARK: - Func
    public func loadView() {
        if let numberOfItemViews = dataSource?.numberOfItemViews(in: self) {
            let height = bounds.height / CGFloat(numberOfItemViews)
            itemPreviews = [UDSectionIndexViewItemPreview]()
            for i in 0..<numberOfItemViews {
                if let itemView = dataSource?.sectionIndexView(self, itemViewAt: i) {
                    items.append(itemView)
                    itemView.frame = CGRect(x: 0, y: height * CGFloat(i), width: bounds.width, height: height)
                    addSubview(itemView)
                }
                if let itemPreview = dataSource?.sectionIndexView(self, itemPreviewFor: i) {
                    itemPreviews.append(itemPreview)
                }
            }
        }
    }

    public func reloadData() {
        for itemView in items {
            itemView.removeFromSuperview()
        }
        items.removeAll()
        loadView()
    }

    public func item(at section: Int) -> UDSectionIndexViewItem? {
        if section >= items.count || section < 0 {
            return nil
        }
        return items[section]
    }

    public func selectItem(at section: Int) {
        if section >= items.count || section < 0 {
            return
        }
        deselectCurrentItem()
        _currentItem = items[section]
        items[section].select()
    }

    public func deselectCurrentItem() {
        _currentItem?.deselect()
    }

    public func showItemPreview(at section: Int, hideAfter delay: Double) {
        showItemPreview(at: section)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.currentItemPreview?.removeFromSuperview()
        }
    }

    public func showItemPreview(at section: Int) {
        guard
            isShowItemPreview == true,
            section < itemPreviews.count && section >= 0,
            let currentItem = _currentItem
            else { return }
        let preview = itemPreviews[section]
        currentItemPreview?.removeFromSuperview()

        var x,
        y: CGFloat
        switch itemPreviewDirection {
        case .right:
            x = currentItem.bounds.width + preview.bounds.width * 0.5 + itemPreviewMargin
        case .left:
            x = -(preview.bounds.width * 0.5 + itemPreviewMargin)
        }
        let centerY = currentItem.center.y
        y = isItemPreviewAlwaysInCenter == true ? (bounds.height - currentItem.bounds.height) * 0.5 : centerY
        preview.center = CGPoint(x: x, y: y)

        addSubview(preview)
        currentItemPreview = preview
    }

    private func getSectionBy(touches: Set<UITouch>) -> Int? {
        if let touch = touches.first {
            let point = touch.location(in: self)
            return getSectionBy(point: point)
        }
        return nil
    }

    private func getSectionBy(point: CGPoint) -> Int? {
        var item: UDSectionIndexViewItem
        for i in 0..<items.count {
            item = items[i]
            if item.frame.contains(point) == true {
                return i
            }
        }
        return nil
    }
}
