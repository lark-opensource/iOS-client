//
//  LDStyleHelpers.swift
//  NewLarkDynamic
//
//  Created by qihongye on 2019/6/21.
//

import Foundation
import EEFlexiable
import UniverseDesignColor

struct StyleHelpers {
    static func cornerRadius(borderRadius: CSSValue, elementSize: CGSize) -> CGFloat {
        var cornerRadius: CGFloat = 0
        switch borderRadius.unit {
        case .point:
            let half = min(elementSize.width, elementSize.height) * 0.5
            let radius = min(CGFloat(borderRadius.value), half)
            cornerRadius = max(0, radius)
        case .percent:
            if elementSize.width == elementSize.height {
                var percent = min(50, borderRadius.value)
                percent = max(0, percent)
                cornerRadius = CGFloat(percent / 100) * elementSize.width
            }
        default:
            break
        }
        return cornerRadius
    }
    static func __floatValue(_ value: String) -> CGFloat? {
        if let floatValue = Float(value) {
            return CGFloat(floatValue)
        }
        detailLog.error("__floatValue parse value failed \(value)")
        return nil
    }
    static func floatValue(_ value: String) -> CGFloat? {
        let trimValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let number = NumberFormatter().number(from: trimValue) else {
            detailLog.error("floatValueParse value NumberFormatter failed \(trimValue)")
            return StyleHelpers.__floatValue(value)
        }
        guard let result = CGFloat(exactly: number) else {
            detailLog.error("floatValueParse value CGFloat.exactly failed \(number)")
            return StyleHelpers.__floatValue(value)
        }
        return StyleHelpers.__floatValue(value)
    }
}
