//
//  EmojiCharacterParser.swift
//  LarkUIKit
//
//  Created by qihongye on 2018/12/11.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
final class EmojiCharacterParser: LKCharacterParser {

    var inputCharacterGroups: [LKTextCharacterGroup] = []

    private var attrsCommits: [LKCharacterAttrsCommit] = []

    func filter(character: LKTextCharacterGroup) -> Bool {
        return character.attributes[LKEmojiAttributeName] is LKEmoji
    }

    func parse(attributedString: NSAttributedString, context: LKTextParserContext) {
        attrsCommits = []
        for character in inputCharacterGroups {
            // swiftlint:disable:next force_cast
            let emoji = character.attributes[LKEmojiAttributeName] as! LKEmoji
            let runDelegate = LKTextRun.createCTRunDelegate(
                emoji,
                dealloc: { (rawPointer) in
                    let pointer = rawPointer.assumingMemoryBound(to: LKEmoji.self)
                    pointer.deinitialize(count: 1)
                    pointer.deallocate()
                },
                getAscent: { (rawPointer) -> CGFloat in
                    let emoji = rawPointer.assumingMemoryBound(to: LKEmoji.self).pointee
                    return emoji.ascent
                },
                getDescent: { (rawPointer) -> CGFloat in
                    let emoji = rawPointer.assumingMemoryBound(to: LKEmoji.self).pointee
                    return emoji.descent
                },
                getWidth: { (rawPointer) -> CGFloat in
                    let emoji = rawPointer.assumingMemoryBound(to: LKEmoji.self).pointee
                    return emoji.frame.width
                })
            attrsCommits.append(LKCharacterAttrsCommit(
                range: character.originRange,
                updateAttrs: [CTRunDelegateAttributeName: runDelegate],
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
}
