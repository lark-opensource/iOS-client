//
//  LDDivComponent.swift
//  NewLarkDynamic
//
//  Created by Jiayun Huang on 2019/6/23.
//

import Foundation
import AsyncComponent
import LarkModel
import EEFlexiable
import ECOInfra
import SwiftUI

fileprivate let pWidthSettingsKey = "messagecard_p_width_type_config"
fileprivate let pWidthType = "p_width_type"

enum SettingsPWidthType: Int {
    case flex = 1
    case onlyP = 2
    case all = 3
}

class DivComponentFactory: ComponentFactory {
    override var tag: RichTextElement.Tag {
        return .div
    }

    override var needChildren: Bool {
        return true
    }

    override func create<C: LDContext>(
        richtext: RichText,
        element: RichTextElement,
        elementId: String,
        children: [RichTextElement],
        style: LDStyle,
        context: C?,
        translateLocale: Locale? = nil) -> ComponentWithSubContext<C, C> {
        updateStyleWidth(element: element, style: style)
        return DivComponent<C>(props: DivComponentProps(), style: style, context: context)
    }
}

class DivComponentProps: ASComponentProps {
    override func equalTo(_ props: ASComponentProps) -> Bool {
        let len = children.count
        if props.children.count != len {
            return false
        }
        for i in 0..<len where children[i].key != props.children[i].key {
            return false
        }
        return true
    }
}

final class PComponentFactory: DivComponentFactory {
    override var tag: RichTextElement.Tag {
        return .p
    }
}

class DivView: UIView {  }

class DivComponent<C: LDContext>: LDComponent<ASComponentProps, DivView, C> {
}

@inline(__always)
private func updateStyleWidth(element: RichTextElement, style: LDStyle) {

    if element.tag == .p && element.styleKeys.contains("block_column_width_auto") {
        style.width.unit = .auto
        return
    }

    if let settings = ECOConfig.service().getDictionaryValue(for: pWidthSettingsKey),
       let type = settings[pWidthType] as? Int {
        switch SettingsPWidthType(rawValue: type) {
        case .flex where style.display == .flex: return
        case .onlyP where element.tag == .p: return
        case .all: return
        default: break
        }
    }
    if style.width.unit == .auto {
        style.width = CSSValue(value: 100.0, unit: .percent)
    }
}
