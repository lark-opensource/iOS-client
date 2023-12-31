//
//  ChoiceItem.swift
//  ByteViewUI
//
//  Created by fakegourmet on 2023/4/19.
//

import Foundation
import ByteViewCommon

public protocol ChoiceItem {
    var content: String { get }
}

public struct AnyChoiceItem {
    var base: ChoiceItem
    var isSelected: Bool
    var isEnabled: Bool = true

    var content: String {
        return base.content
    }
    // 是否支持反选，UI会有不同
    var isSupportUnselected: Bool = false

    var textStyle: VCFontConfig = .bodyAssist

    var preferredLabelWidth: CGFloat = -1.0

    var tapAction: ((UIView?) -> Void)?

    var useBasicDisableStyle: Bool = false

    var disableHoverKey: String?

    public init(base: ChoiceItem,
                isSelected: Bool,
                isEnabled: Bool = true,
                isSupportUnselected: Bool = false,
                textStyle: VCFontConfig = .bodyAssist,
                preferredLabelWidth: CGFloat = -1.0,
                tapAction: ( (UIView?) -> Void)? = nil,
                useBasicDisableStyle: Bool = false,
                disableHoverKey: String? = nil) {
        self.base = base
        self.isSelected = isSelected
        self.isEnabled = isEnabled
        self.isSupportUnselected = isSupportUnselected
        self.textStyle = textStyle
        self.preferredLabelWidth = preferredLabelWidth
        self.tapAction = tapAction
        self.useBasicDisableStyle = useBasicDisableStyle
        self.disableHoverKey = disableHoverKey
    }
}

public struct PopupChoiceItem: ChoiceItem {
    public var content: String = ""

    public init(_ content: String) {
        self.content = content
    }
}
