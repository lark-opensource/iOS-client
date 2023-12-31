//
//  LarkVoteUtils.swift
//  LarkVote
//
//  Created by bytedance on 2022/5/7.
//

import UIKit
import Foundation

public final class LarkVoteUtils {
    // 根据字符串计算label高度
    public static func calculateLabelSize(text: String, font: UIFont, size: CGSize) -> CGSize {
        guard !text.isEmpty  else {
            return CGSize.zero
        }
        guard let str = text as? NSString else {
            return CGSize.zero
        }
        let origin = NSStringDrawingOptions.usesLineFragmentOrigin
        let lead = NSStringDrawingOptions.usesFontLeading
        let rect = str.boundingRect(with: size, options: [origin, lead], attributes: [NSAttributedString.Key.font: font], context: nil)
        return rect.size
    }
}
