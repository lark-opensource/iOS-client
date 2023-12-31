//
//  MsgCardStringExtension.swift
//  LarkMessageCard
//
//  Created by ByteDance on 2023/7/13.
//

import Foundation
import LKRichView

extension String {
    // 获取指定字体下当前字符串的宽度
    func getStrWidth(font: UIFont, weight: FontWeight? = nil) -> CGFloat{
        let text = LKTextElement(text: self)
        text.style.font(font)
        text.style.fontSize(.point(font.pointSize))
        if let weight = weight { text.style.fontWeight(weight) }
        return LKRichElement.getElementWidth(element: text)
    }
    // 将字符串截断至指定宽度
    func cut(cutWidth: CGFloat, font: UIFont, weight: FontWeight? = nil) -> String {
        let width = getStrWidth(font: font, weight: weight)
        // 算裁剪的宽和正常宽的比值
        let cutWidthRadio = cutWidth / width
        // 通过比值算出当前第几个字符, 如果字符本身有宽度差异,如中英文,可能会有一定的不准确
        var cutCount = max(0, cutWidthRadio * CGFloat(count))
        var subStr = self
        // 当字符串中出现中英混杂或者和其他字宽不一样的文字混合时,会出现无法按比例计算的问题
        // 为确保不因为字体过多导致换行, 进行一定弥补
        while subStr.getStrWidth(font: font, weight: weight) > cutWidth && cutCount > 0 {
            subStr = String(prefix(Int(floor(cutCount))))
            cutCount = cutCount - 1
        }
        return subStr
    }
}
