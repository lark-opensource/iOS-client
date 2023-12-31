//
//  PadToolBarCombinedView.swift
//  ByteView
//
//  Created by wulv on 2023/10/24.
//

import Foundation

class PadToolBarCombinedView: PadToolBarItemView {

    struct Layout {
        static let lineW: CGFloat = 1
        static let lineH: CGFloat = 16
    }

    private lazy var lines: [UIView] = .init(repeating: UIView(), count: max(0, itemViews.count - 1))
    let itemViews: [PadToolBarItemView]

    init(item: ToolBarItem, itemViews: [PadToolBarItemView]) {
        self.itemViews = itemViews
        super.init(item: item)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupSubviews() {
        super.setupSubviews()
        button.isHidden = true
        iconView.isHidden = true
        animationView.isHidden = true
        backgroundColor = .clear
        for view in itemViews {
            addSubview(view)
        }
        for line in lines {
            line.backgroundColor = .ud.lineDividerDefault
            addSubview(line)
        }
    }

    override func reset() {
        super.reset()
        for view in itemViews {
            view.reset()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateShowingViewsCorner()
        var startX: CGFloat = 0
        var j = 0
        var needLine = false
        for i in 0..<itemViews.count {
            let view = itemViews[i]
            if view.item.actualPadLocation == .inCombined {
                if needLine {
                    let line = lines[j]
                    line.isHidden = false
                    line.frame = CGRect(x: startX, y: (bounds.height - Layout.lineH) / 2, width: Layout.lineW, height: Layout.lineH)
                    j += 1
                }
                view.isHidden = false
                view.frame = CGRect(x: startX, y: 0, width: view.itemWidth, height: bounds.height)
                startX = view.frame.maxX
                needLine = true
            } else {
                view.isHidden = true
            }
        }
        for _ in j..<lines.count {
            lines[j].isHidden = true
        }
    }

    private func updateShowingViewsCorner() {
        let showingViews = itemViews.filter({ $0.item.actualPadLocation == .inCombined })
        for (i, view) in showingViews.enumerated() {
            if showingViews.count == 1 {
                view.button.layer.cornerRadius = 8
                view.button.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
            } else if i == 0 {
                view.button.layer.cornerRadius = 8
                view.button.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
            } else if i == itemViews.count - 1 {
                view.button.layer.cornerRadius = 8
                view.button.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
            } else {
                view.button.layer.cornerRadius = 0
            }
        }
    }

    func itemView(for type: ToolBarItemType) -> PadToolBarItemView? {
        itemViews.first(where: { $0.itemType == type && $0.item.actualPadLocation == .inCombined })
    }

    override var itemWidth: CGFloat {
        let showingItems = itemViews.compactMap { $0.item.actualPadLocation == .inCombined ? $0 : nil }
        return showingItems.reduce(0, { $0 + $1.itemWidth })
    }

    override func toolbarItemDidChange(_ item: ToolBarItem) {
        if itemViews.contains(where: { $0.itemType == item.itemType }) {
            item.notifySizeListeners()
        }
    }
}
