//
//  PhoneToolBar.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/9.
//

import UIKit

class PhoneToolBar: UIView {
    private var itemViews: [PhoneToolBarItemView] = []

    private var viewMap: [ToolBarItemType: PhoneToolBarItemView] = [:]

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !itemViews.isEmpty else { return }

        let itemWidth = frame.width / CGFloat(itemViews.count)

        for i in 0..<itemViews.count {
            itemViews[i].frame = CGRect(x: CGFloat(i) * itemWidth, y: 0, width: itemWidth, height: frame.height)
        }
    }

    // MARK: - Public

    func addItemViews(_ itemViews: [PhoneToolBarItemView]) {
        for (i, itemView) in itemViews.enumerated() {
            insertItemView(itemView, at: i)
        }
    }

    func insertItemView(_ itemView: PhoneToolBarItemView, at position: Int) {
        guard itemView.superview == nil, position <= itemViews.count else {
            return
        }
        viewMap[itemView.itemType] = itemView
        itemViews.insert(itemView, at: position)
        addSubview(itemView)
    }

    func removeItemView(at position: Int) {
        guard position < itemViews.count else { return }
        let view = itemViews[position]
        viewMap.removeValue(forKey: view.itemType)
        view.removeFromSuperview()
        itemViews.remove(at: position)
    }

    func view(for type: ToolBarItemType) -> UIView? {
        viewMap[type]
    }
}
