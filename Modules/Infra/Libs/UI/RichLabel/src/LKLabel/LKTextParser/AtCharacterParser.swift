//
//  AtCharacterParser.swift
//  LarkUIKit
//
//  Created by qihongye on 2018/12/11.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation

final class AtCharacterParser: LKCharacterParser {

    var inputCharacterGroups: [LKTextCharacterGroup] = []

    private var replaceCommits: [LKCharacterReplaceWithRunDelegateCommit] = []

    func filter(character: LKTextCharacterGroup) -> Bool {
        return character.attributes[LKAtAttributeName] is UIColor
    }

    func parse(attributedString: NSAttributedString, context: LKTextParserContext) {
        self.replaceCommits = []
        guard !inputCharacterGroups.isEmpty else {
            return
        }

        consequent { (start, end) in
            let replaceRange = NSRange(
                location: inputCharacterGroups[start].originRange.lowerBound,
                length: inputCharacterGroups[end].originRange.upperBound - inputCharacterGroups[start].originRange.lowerBound
            )
            let replaceAttrStr = attributedString.attributedSubstring(from: replaceRange)
            let ctline = CTLineCreateWithAttributedString(replaceAttrStr)
            let runDelegate = LKTextRun.createCTRunDelegate(
                LKTextLine.getLineDetail(line: ctline),
                dealloc: { (pointer) in
                    pointer.deallocate()
                }, getAscent: { (pointer) -> CGFloat in
                    return pointer.assumingMemoryBound(to: LKLineDetail.self).pointee.ascent + 1
                }, getDescent: { (pointer) -> CGFloat in
                    return pointer.assumingMemoryBound(to: LKLineDetail.self).pointee.descent + 1
                }, getWidth: { (pointer) -> CGFloat in
                    let lineDetail = pointer.assumingMemoryBound(to: LKLineDetail.self).pointee
                    return lineDetail.width + (lineDetail.ascent + lineDetail.descent) / 2
                }
            )
            var updateAttrs = [
                LKAtBackgroungColorAttributeName: inputCharacterGroups[start].attributes[LKAtAttributeName] as Any
            ]
            if replaceAttrStr.length > 0 {
                updateAttrs.merge(
                    replaceAttrStr.attributes(at: 0, effectiveRange: nil),
                    uniquingKeysWith: { (current, _) in current }
                )
            }
            self.replaceCommits.append(LKCharacterReplaceWithRunDelegateCommit(
                range: replaceRange,
                runDelegate: runDelegate,
                updateAttrs: updateAttrs
            ))
        }
    }

    func attributesCommit() -> [LKCharacterAttrsCommit] {
        return []
    }

    func repalceCommit() -> [LKCharacterReplaceWithRunDelegateCommit] {
        return replaceCommits
    }

    private func consequent(callback: (Int, Int) -> Void) {
        var start = 0
        var end = 0
        for i in 1..<inputCharacterGroups.count {
            if inputCharacterGroups[i].originRange.lowerBound == inputCharacterGroups[i - 1].originRange.upperBound {
                end = i
            } else {
                callback(start, end)
                start = i
                end = i
            }
        }
        callback(start, end)
    }
}
