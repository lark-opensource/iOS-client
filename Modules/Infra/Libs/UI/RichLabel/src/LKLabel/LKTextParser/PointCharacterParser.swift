//
//  PointCharacterParser.swift
//  LarkUIKit
//
//  Created by qihongye on 2018/12/11.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

final class PointCharacterParser: LKCharacterParser {

    private var attrsCommits: [LKCharacterAttrsCommit] = []
    private var replaceCommits: [LKCharacterReplaceWithRunDelegateCommit] = []

    var inputCharacterGroups: [LKTextCharacterGroup] = []

    func filter(character: LKTextCharacterGroup) -> Bool {
        return character.attributes[LKPointAttributeName] is UIColor
    }

    func parse(attributedString: NSAttributedString, context: LKTextParserContext) {
        attrsCommits = []
        replaceCommits = []
        for character in inputCharacterGroups {
            // swiftlint:disable:next force_cast
            let pointColor = character.attributes[LKPointAttributeName] as! UIColor
            let pointRadius = (character.attributes[LKPointRadiusAttributeName] as? CGFloat) ?? (context.defaultFont.pointSize * 0.15)
            let pointChar = attributedString.attributedSubstring(from: character.originRange)
            let runDelegate = self.buildRundelegate(pointColor: pointColor, pointRadius: pointRadius, pointChar: pointChar)

            if character.originRange.length == 1 {
                attrsCommits.append(LKCharacterAttrsCommit(
                    range: character.originRange,
                    updateAttrs: [
                        LKAtStrAttributeName: pointChar,
                        CTRunDelegateAttributeName: runDelegate
                    ],
                    removeAttrs: []
                ))
            } else {
                attrsCommits.append(LKCharacterAttrsCommit(
                    range: character.originRange,
                    updateAttrs: character.attributes,
                    removeAttrs: [
                        LKPointAttributeName,
                        LKPointRadiusAttributeName,
                        LKPointInnerRadiusAttributeName
                    ]
                ))
                var updateAttrs: [NSAttributedString.Key: Any] = [
                    LKPointAttributeName: pointColor,
                    LKPointRadiusAttributeName: pointRadius
                ]
                if let innerRadius = character.attributes[LKPointInnerRadiusAttributeName] as? CGFloat {
                    updateAttrs[LKPointInnerRadiusAttributeName] = innerRadius
                }
                replaceCommits.append(LKCharacterReplaceWithRunDelegateCommit(
                    range: character.originRange,
                    runDelegate: runDelegate,
                    updateAttrs: updateAttrs
                ))
            }
        }
    }

    func attributesCommit() -> [LKCharacterAttrsCommit] {
        return attrsCommits
    }

    func repalceCommit() -> [LKCharacterReplaceWithRunDelegateCommit] {
        return replaceCommits
    }

    private func buildRundelegate(pointColor: UIColor, pointRadius: CGFloat, pointChar: NSAttributedString) -> CTRunDelegate {
        let ctline = CTLineCreateWithAttributedString(pointChar)
        var lineDetail = LKTextLine.getLineDetail(line: ctline)
        lineDetail.ascent += pointRadius
        lineDetail.width += pointRadius * 2

        return LKTextRun.createCTRunDelegate(
            lineDetail,
            dealloc: { (rawPointer) in
                let pointer = rawPointer.assumingMemoryBound(to: LKLineDetail.self)
                pointer.deinitialize(count: 1)
                pointer.deallocate()
            },
            getAscent: { (rawPointer) -> CGFloat in
                return rawPointer.assumingMemoryBound(to: LKLineDetail.self).pointee.ascent
            },
            getDescent: { (rawPointer) -> CGFloat in
                return rawPointer.assumingMemoryBound(to: LKLineDetail.self).pointee.descent
            },
            getWidth: { (rawPointer) -> CGFloat in
                return rawPointer.assumingMemoryBound(to: LKLineDetail.self).pointee.width
            }
        )
    }
}
