//
//  FontSizePanelView.swift
//  MailSDK
//
//  Created by Ryan on 2020/6/11.
//

import UIKit
import UniverseDesignColor

let maxHeight: CGFloat = 60
let radius: CGFloat = 10

class FontSizePanelView: UIView {
    let itemViews: [FontSizeButton]
    let data: [EditorToolBarButtonIdentifier]
    weak var delegate: AttributeButtonDelegate?

    init(frame: CGRect, data: [EditorToolBarButtonIdentifier]) {
        let width = frame.size.width / 4
        var tempItems = [FontSizeButton]()
        for idx in 0...3 {
            var title = ""
            var fontSize: CGFloat = 0
            switch idx {
            case 0:
                title = BundleI18n.MailSDK.Mail_FormatFontSize_SmallSize
                fontSize = 12
            case 1:
                title = BundleI18n.MailSDK.Mail_FormatFontSize_NormalSize
                fontSize = 16
            case 2:
                title = BundleI18n.MailSDK.Mail_FormatFontSize_BigSize
                fontSize = 20
            case 3:
                title = BundleI18n.MailSDK.Mail_FormatFontSize_ExtraBigSize
                fontSize = 24
            default:
                mailAssertionFailure("error")
            }
            let item = FontSizeButton(frame: CGRect(x: CGFloat(idx) * width, y: 0, width: width, height: frame.height), fontSize: fontSize)
            item.setTitle(title, for: .normal)
            tempItems.append(item)
        }
        itemViews = tempItems
        self.data = data
        super.init(frame: frame)
        layer.cornerRadius = radius
        backgroundColor = UIColor.ud.bgBody
        itemViews.forEach { (itemView) in
            addSubview(itemView)
        }
    }

    func updateStatus(_ status: [EditorToolBarButtonIdentifier: EditorToolBarItemInfo]) {
        let fontKeys = [EditorToolBarButtonIdentifier.fontSmall, EditorToolBarButtonIdentifier.fontNormal, EditorToolBarButtonIdentifier.fontLarge, EditorToolBarButtonIdentifier.fontHuge]
        let tempInfo = status.first { (key, value) -> Bool in
            guard fontKeys.contains(key) else {
                return false
            }
            return value.isSelected
        }

        var selectedIdx = -1
        if let info = tempInfo, let idx = fontKeys.firstIndex(where: { $0.rawValue == info.value.identifier }) {
            selectedIdx = idx
        }

        for (idx, itemView) in itemViews.enumerated() {
            itemView.isSelected = idx == selectedIdx
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func enableScroll(on: Bool) {
        guard let scrollView = superview?.superview as? UIScrollView else {
            mailAssertionFailure("must be a scrollview")
            return
        }
        scrollView.isScrollEnabled = on
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        renderItemView(point: touches.first?.location(in: self))
        enableScroll(on: false)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        renderItemView(point: touches.first?.location(in: self))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        renderItemView(point: touches.first?.location(in: self), callJS: true)
        enableScroll(on: true)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        renderItemView(point: touches.first?.location(in: self))
        enableScroll(on: true)
    }

    func renderItemView(point: CGPoint?, callJS: Bool = false) {
        guard let point = point else { mailAssertionFailure("must have point"); return }
        guard frame.contains(convert(point, to: superview)) else {
            return
        }
        itemViews.forEach { (itemView) in
            itemView.isSelected = itemView.frame.contains(point)
        }
        guard let selectedIdx = itemViews.firstIndex(where: { $0.isSelected }) else { mailAssertionFailure("must select"); return }
        selectAtIdx(selectedIdx, callJS)

        for (index, itemView) in itemViews.enumerated() {
            itemView.backgroundColor = index == selectedIdx ? UIColor.ud.primaryFillSolid02 : .clear
        }
    }

    func selectAtIdx(_ idx: Int, _ callJS: Bool = false) {
        let info = EditorToolBarItemInfo(identifier: data[idx].rawValue)
        let button = AttributeButton(frame: .zero, info: info)
        button.itemInfo = info
        button.backgroundColor = UIColor.ud.primaryFillSolid02
        if callJS {
            delegate?.didClickAttributeButton(button)
        }
    }
}

class FontSizeButton: UIButton {
    override var isSelected: Bool {
        didSet {
            if isSelected {
                backgroundColor = UIColor.ud.primaryFillSolid02
            } else {
                backgroundColor = .clear
            }
        }
    }
    init(frame: CGRect, fontSize: CGFloat) {
        super.init(frame: frame)
        layer.cornerRadius = radius
        isUserInteractionEnabled = false
        setTitleColor(UIColor.ud.textCaption, for: .normal)
        setTitleColor(UIColor.ud.primaryContentPressed, for: .selected)
        titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
