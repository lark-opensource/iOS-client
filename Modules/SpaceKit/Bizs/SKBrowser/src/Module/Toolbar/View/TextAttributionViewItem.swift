//
//  TextAttributionViewItem.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/7/22.
//

import UIKit
import SnapKit
import UniverseDesignColor

private typealias Const = TextAttributionBaseItem.LayoutConst
class TextAttributionBaseItem: UIView {
    class LayoutConst {
        static let horizMargin: CGFloat = 16
        static let itemPadding: CGFloat = 1
        static let buttonHeight: CGFloat = 48
        static let containerRadius: CGFloat = 8
    }
    
    var buttonClickCallback: ((AttributeButton) -> Void)?

    fileprivate var _cachedButton: [BarButtonIdentifier: AttributeButton] = [:]
    fileprivate var _itemInfos: [BarButtonIdentifier: ToolBarItemInfo] = [:]

    func paint(_ layoutData: [[BarButtonIdentifier]]) { }

    func updateStatus(_ status: [BarButtonIdentifier: ToolBarItemInfo]) {
        status.forEach { key, val in
            if let button = _cachedButton[key] {
                button.itemInfo = val
                button.loadStatus()
                updateQuickTouchHintSelect(btn: button)
            }
            if _itemInfos[key] != nil {
                _itemInfos[key] = val
            }
        }
    }
}

extension TextAttributionBaseItem: AttributeButtonDelegate {
    fileprivate func dequeueButton(identifier: BarButtonIdentifier) -> AttributeButton {
        var button: AttributeButton
        if let btn = _cachedButton[identifier] {
            button = btn
            button.delegate = self
        } else {
            button = AttributeButton(frame: CGRect(x: 0, y: 0, width: 0, height: 0), info: nil)
            button.delegate = self
        }
        if let info = _itemInfos[identifier] {
            button.itemInfo = info
            button.loadStatus()
        }
        if button.iconImageView.image == nil {
            button.iconImageView.image = ToolBarItemInfo.loadImage(by: identifier.rawValue)
        }
        _cachedButton.updateValue(button, forKey: identifier)
        return button
    }

    func didClickAttributeButton(_ btn: AttributeButton) {
         buttonClickCallback?(btn)
    }

    func updateQuickTouchHintSelect(btn: AttributeButton) {
        guard let info = btn.itemInfo else { return }
        let quickFireIdentifiers: Set<String> = [BarButtonIdentifier.copy.rawValue,
                                                 BarButtonIdentifier.paste.rawValue,
                                                 BarButtonIdentifier.cut.rawValue,
                                                 BarButtonIdentifier.clear.rawValue]

        btn.quickTouchFireSelect = quickFireIdentifiers.contains(info.identifier)
    }

}

// 支持滚动的ItemView
/*
 *  Line ViewPort ↘
 *  --------------------
 *  |  ________________|_______________
 *  |  |X|X|X|X|X|X|X|X||X|X|X|X|X|X|X|
 *  |  ----------------|---------------
 *  --------------------       ←🖕
 */
class TextAttributeionScrollableItem: TextAttributionBaseItem {
    fileprivate var _cachedScrollView: [String: UIScrollView] = [:]
    var contentClipsToMargin: Bool = false

    override func paint(_ layoutdata: [[BarButtonIdentifier]]) {
        guard let data = layoutdata.first else { return }
        var w = frame.width, h = frame.height, itemWidth = _itemWidth(data), xOffset: CGFloat
        let contentHorizPadding: CGFloat = contentClipsToMargin ? 0 : Const.horizMargin
        xOffset = contentHorizPadding

        let scrollView = _dequeueContainer("唱跳Rap篮球")
        scrollView.frame = CGRect(x: Const.horizMargin - contentHorizPadding, y: 0, width: w - (Const.horizMargin - xOffset) * 2, height: h)
        scrollView.isScrollEnabled = data.count > Int(Const.maxUnscrollableCount)
        for (idx, item) in data.enumerated() {
            let button = dequeueButton(identifier: item)
            button.frame = CGRect(x: xOffset, y: 0, width: itemWidth, height: h)
            if button.superview == nil { scrollView.addSubview(button) }
            switch idx {
            case 0:             _generateRadius(button, cornerRadius: Const.containerRadius, corners: [.topLeft, .bottomLeft])
            case data.count - 1:  _generateRadius(button, cornerRadius: Const.containerRadius, corners: [.topRight, .bottomRight])
            default:            _clearRadius(button)
            }
            xOffset += itemWidth + Const.itemPadding
        }
        scrollView.contentSize = CGSize(width: xOffset - Const.itemPadding + contentHorizPadding, height: h)
        scrollView.layer.cornerRadius = contentClipsToMargin ? Const.containerRadius : 0
        if scrollView.superview == nil { addSubview(scrollView) }
    }

    private func _generateRadius(_ view: UIView, cornerRadius: CGFloat, corners: UIRectCorner) {
        if view.layer.mask != nil && view.layer.mask?.bounds.size == view.frame.size {
            view.layer.mask?.bounds = view.frame
            view.layer.mask?.position = view.center
            return
        }
        let shape = CAShapeLayer()
        shape.bounds = view.frame
        shape.position = view.center
        shape.path = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)).cgPath
        view.layer.mask = shape
    }

    private func _clearRadius(_ view: UIView) {
        if view.layer.mask == nil { view.layer.mask = nil }
    }

    private func _itemWidth(_ layoutdata: [BarButtonIdentifier]) -> CGFloat {
        let w = frame.size.width
        // 可滚动列表应有部分露出以暗示用户此处可滚动，根据UI设计，逻辑如下：
        // 若item <= maxUnscrollableCount，则撑开，即    | left-padding |x|x|x|x| right-padding |
        // 若item > maxUnscrollableCount，则在忽略右padding的基础上显示4.5个按钮，即  | left-padding |X|X|X|X|＞|    ←(最右边的只显示一半)
        var activeItemCnt: CGFloat
        if CGFloat(layoutdata.count) > Const.maxUnscrollableCount {
            activeItemCnt = 4.5
            let emptyWidth = w - Const.horizMargin - Const.itemPadding * (Const.maxUnscrollableCount)
            return emptyWidth / activeItemCnt
        }
        activeItemCnt = min(Const.maxUnscrollableCount, CGFloat(layoutdata.count))
        let emptyWidth = w - Const.horizMargin * 2 - Const.itemPadding * (activeItemCnt - 1)
        return emptyWidth / activeItemCnt
    }

    private func _dequeueContainer(_ uid: String) -> UIScrollView {
        if let sv = _cachedScrollView[uid] {
            return sv
        }
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
        scrollView.clipsToBounds = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        _cachedScrollView[uid] = scrollView
        return scrollView
    }
}

extension Const {
    static let maxUnscrollableCount: CGFloat = 4
}

// 支持分节的ItemView
/*
 *  Line ViewPort ↘
 *  --------------------------------------
 *  |    _________   _____    _______    |
 *  |    |X|X|X|X|   |X|X|    |X|X|X|    |
 *  |    ---------   -----    -------    |
 *  --------------------------------------
 */
class TextAttributionSectionalItem: TextAttributionBaseItem {
    fileprivate var _cachedContainer: [String: UIView] = [:]

    override func paint(_ layoutdata: [[BarButtonIdentifier]]) {
        var secXOffset = Const.horizMargin, secWidth: CGFloat, itemCnt: CGFloat
        let itemHeight = frame.size.height, itemWidth = _itemWidth(layoutdata)
        var secCon: UIView

        for (secIdx, items) in layoutdata.enumerated() {
            itemCnt = CGFloat(items.count)
            secWidth = itemWidth * itemCnt + Const.itemPadding * (itemCnt - 1)
            secCon = _dequeueContainer("Cached(\(secIdx))")
            if secCon.superview == nil { addSubview(secCon) }
            secCon.frame = CGRect(x: secXOffset, y: 0, width: secWidth, height: frame.size.height)

            var innerXOffset: CGFloat = 0
            for item in items {
                let button = dequeueButton(identifier: item)
                button.frame = CGRect(x: innerXOffset, y: 0, width: itemWidth, height: itemHeight)
                if button.superview == nil { secCon.addSubview(button) }
                innerXOffset += itemWidth + Const.itemPadding
            }
            secXOffset += itemWidth * itemCnt + Const.itemPadding * (itemCnt - 1) + Const.sectionPadding - Const.itemPadding
        }
    }

    private func _itemWidth(_ layoutdata: [[BarButtonIdentifier]]) -> CGFloat {
        let w = frame.size.width
        var sectionCnt = CGFloat(layoutdata.count), itemCnt: CGFloat = 0
        layoutdata.forEach { itemCnt += CGFloat($0.count) }

        let emptyWidth = w
            - Const.horizMargin * 2
            - Const.itemPadding * (itemCnt - sectionCnt)
            - Const.sectionPadding * (sectionCnt - 1)
        return emptyWidth / itemCnt
    }

    private func _dequeueContainer(_ uid: String) -> UIView {
        if let scontainer = _cachedContainer[uid] {
            return scontainer
        }
        let con = UIView()
        con.layer.cornerRadius = Const.containerRadius
        con.backgroundColor = UDColor.bgBody
        con.layer.masksToBounds = true
        _cachedContainer[uid] = con
        return con
    }
}

extension Const {
    static let sectionPadding: CGFloat = 10
}
