//
//  ItalicCharacterParser.swift
//  LarkUIKit
//
//  Created by qihongye on 2018/12/11.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
final class ItalicCharacterParser: LKCharacterParser {
    var inputCharacterGroups: [LKTextCharacterGroup] = []

    private var attrsCommits: [LKCharacterAttrsCommit] = []

    func filter(character: LKTextCharacterGroup) -> Bool {
        guard let font = character.attributes[NSAttributedString.Key.font] as? UIFont,
            font.fontDescriptor.symbolicTraits.contains(.traitItalic) else {
            return false
        }
        return true
    }

    func parse(attributedString: NSAttributedString, context: LKTextParserContext) {
        attrsCommits = []
        guard !inputCharacterGroups.isEmpty else {
            return
        }

        consequent(defaultFont: context.defaultFont) { range, uiFont in
            attrsCommits.append(LKCharacterAttrsCommit(
                range: range,
                updateAttrs: [
                    NSAttributedString.Key.font: uiFont.noItalic(),
                    LKGlyphTransformAttributeName: NSValue(
                        cgAffineTransform: CGAffineTransform(
                            a: 1,
                            b: 0,
                            c: CGFloat(tanf(Float(15 * Double.pi / 180))),
                            d: 1,
                            tx: 0,
                            ty: 0
                        )
                    )
                ],
                removeAttrs: []
            ))
        }
    }

    func attributesCommit() -> [LKCharacterAttrsCommit] {
        return attrsCommits
    }

    func repalceCommit() -> [LKCharacterReplaceWithRunDelegateCommit] {
        return []
    }

    private func consequent(defaultFont: UIFont, callback: (NSRange, UIFont) -> Void) {
        inputCharacterGroups.forEach {
            let uiFont = ($0.attributes[NSAttributedString.Key.font] as? UIFont) ?? defaultFont
            callback($0.originRange, uiFont)
        }
    }
}
