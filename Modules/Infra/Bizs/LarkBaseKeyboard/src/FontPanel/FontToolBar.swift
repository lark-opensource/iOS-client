//
//  FontToolBar.swift
//  LarkChat
//
//  Created by liluobin on 2021/8/17.
//

import UIKit
import Foundation
import LarkRichTextCore
import LarkKeyboardView

public enum FontActionType: Int {
    case goback = 0
    case bold
    case italic
    case strikethrough
    case underline
}

public final class KeyboardFontButton: KeyboardIconButton {
    public let type: FontActionType
    public init(type: FontActionType) {
        self.type = type
        super.init(frame: .zero, key: KeyboardItemKey.font.rawValue)
    }
    public override var isSelected: Bool {
        didSet {
            self.backgroundColor = isSelected ? UIColor.ud.fillSelected : UIColor.clear
            self.layer.cornerRadius = isSelected ? 6 : 0
        }
    }
    func setButtonByResource(_ resource: FontToolBarItemResouce) {
        setImage(resource.image, for: .normal)
        setImage(resource.selectedImage, for: .selected)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
public final class FontToolBar: UIView {
    public static let size = CGSize(width: 32, height: 32)
    public static var underlineStyle: Int { NSUnderlineStyle.single.rawValue }
    public static var strikethroughStyle: Int { 1 }
    // 决定fontbar是否能动态显隐的style
    public let style: FontBarStyle
    public let height: CGFloat
    public var buttonSpace: ButtonSpace {
        didSet {
            guard buttonSpace != oldValue else {
                return
            }
            updateBtnsFrame()
        }
    }

    public enum ButtonSpace: CGFloat {
        case normal = 24
        case compact = 12 //紧凑型布局
    }

    private var itemTypes: [FontActionType] = [.goback, .bold, .strikethrough, .italic, .underline]
    let clickCallBack: ((KeyboardFontButton) -> Void)?
    private var btns: [KeyboardFontButton] = []

    public init(itemTypes: [FontActionType]? = nil,
                style: FontBarStyle,
                height: CGFloat,
                buttonSpace: ButtonSpace,
                clickCallBack: ((KeyboardFontButton) -> Void)?) {
        if let types = itemTypes {
            self.itemTypes = types
        }
        self.style = style
        self.height = height
        self.clickCallBack = clickCallBack
        self.buttonSpace = buttonSpace
        super.init(frame: .zero)
        setupView()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        for idx in 0..<itemTypes.count {
            let btnType = itemTypes[idx]
            let btn = KeyboardFontButton(type: btnType)
            btn.frame = getFrameForButtonIndex(idx)
            btn.setButtonByResource(getResouceFromButtonType(btnType))
            btn.addTarget(self, action: #selector(btnClick(_:)), for: .touchUpInside)
            self.addSubview(btn)
            btns.append(btn)
        }
    }

    private func updateBtnsFrame() {
        for (idx, btn) in btns.enumerated() {
            btn.frame = getFrameForButtonIndex(idx)
        }
    }

    private func getFrameForButtonIndex(_ idx: Int) -> CGRect {
        return CGRect(x: 12 + CGFloat(idx) * (Self.size.width + buttonSpace.rawValue), y: (self.height - Self.size.height) / 2.0, width: Self.size.width, height: Self.size.height)
    }

    @objc
    func btnClick(_ btn: UIButton) {
        btn.isSelected = !btn.isSelected
        if let btn = btn as? KeyboardFontButton {
            self.clickCallBack?(btn)
        }
    }

    public func updateStatus(_ item: FontToolBarStatusItem) {
        let currentItem = getCurrentStatusItem()
        if currentItem == item {
            return
        }
        btns.forEach { btn in
            switch btn.type {
            case .bold:
                btn.isSelected = item.isBold
            case .italic:
                btn.isSelected = item.isItalic
            case .underline:
                btn.isSelected = item.isUnderline
            case .strikethrough:
                btn.isSelected = item.isStrikethrough
            default:
                break
            }
        }
    }

    public func getCurrentStatusItem() -> FontToolBarStatusItem {
        var isBold = false
        var isItalic = false
        var isStrikethrough = false
        var isUnderline = false
        btns.forEach { btn in
            switch btn.type {
            case .bold:
                isBold = btn.isSelected
            case .italic:
                isItalic = btn.isSelected
            case .underline:
                isUnderline = btn.isSelected
            case .strikethrough:
                isStrikethrough = btn.isSelected
            default:
                break
            }
        }
        return FontToolBarStatusItem(style: style,
                                     isBold: isBold,
                                     isItalic: isItalic,
                                     isStrikethrough: isStrikethrough,
                                     isUnderline: isUnderline)
    }

    public func updateBarStatusWithAttributeStr(_ attributeStr: NSAttributedString) {
        let allRange = NSRange(location: 0, length: attributeStr.length)
        var isBold = false
        var isItalic = false
        var isUnderline = false
        var isStrikethrough = false
        attributeStr.enumerateAttribute(FontStyleConfig.boldAttributedKey, in: allRange, options: []) { value, range, _ in
            if range == allRange, value != nil {
                isBold = true
            }
        }
        attributeStr.enumerateAttribute(FontStyleConfig.italicAttributedKey, in: allRange, options: []) { value, range, _ in
            if range == allRange, value != nil {
                isItalic = true
            }
        }
        attributeStr.enumerateAttribute(FontStyleConfig.underlineAttributedKey, in: allRange, options: []) { value, range, _ in
            if range == allRange, value != nil {
                isUnderline = true
            }
        }
        attributeStr.enumerateAttribute(FontStyleConfig.strikethroughAttributedKey, in: allRange, options: []) { value, range, _ in
            if range == allRange, value != nil {
                isStrikethrough = true
            }
        }
        let item = FontToolBarStatusItem(isBold: isBold,
                                         isItalic: isItalic,
                                         isStrikethrough: isStrikethrough,
                                         isUnderline: isUnderline)
        self.updateStatus(item)
    }
}

struct FontToolBarItemResouce {
    let image: UIImage
    let selectedImage: UIImage
}

extension FontToolBar {
    private func getResouceFromButtonType(_ type: FontActionType) -> FontToolBarItemResouce {
        switch type {
        case .goback:
            let image = Resources.arrow_goback_fontbar
            return FontToolBarItemResouce(image: image, selectedImage: image)
        case .bold:
            return FontToolBarItemResouce(image: Resources.bold_fontbar,
                                          selectedImage: Resources.bold_fontbar_selected)
        case .italic:
            return FontToolBarItemResouce(image: Resources.italic_fontbar,
                                          selectedImage: Resources.italic_fontbar_selected)
        case .strikethrough:
            return FontToolBarItemResouce(image: Resources.strikethrough_fontbar,
                                          selectedImage: Resources.strikethrough_fontbar_selected)
        case .underline:
            return FontToolBarItemResouce(image: Resources.underline_fontbar,
                                          selectedImage: Resources.underline_fontbar_selected)
        }
    }
}
