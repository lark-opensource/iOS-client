//
//  AttachmentCharacterParser.swift
//  LarkUIKit
//
//  Created by qihongye on 2018/12/11.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
final class AttachmentCharacterParser: LKCharacterParser {

    var inputCharacterGroups: [LKTextCharacterGroup] = []

    private var attrsCommits: [LKCharacterAttrsCommit] = []

    func filter(character: LKTextCharacterGroup) -> Bool {
        return character.attributes[LKAttachmentAttributeName] is LKAttachmentProtocol
    }

    func parse(attributedString: NSAttributedString, context: LKTextParserContext) {
        self.attrsCommits = []

        for character in self.inputCharacterGroups {
            // swiftlint:disable:next force_cast
            let attachment = character.attributes[LKAttachmentAttributeName] as! LKAttachmentProtocol
            let runDelegate = LKTextRun.createCTRunDelegate(
                attachment,
                dealloc: { (rawPointer) in
                    let pointer = rawPointer.assumingMemoryBound(to: LKAttachmentProtocol.self)
                    pointer.deinitialize(count: 1)
                    pointer.deallocate()
                },
                getAscent: { (rawPointer) -> CGFloat in
                    let attachment = rawPointer.assumingMemoryBound(to: LKAttachmentProtocol.self).pointee
                    switch attachment.verticalAlignment {
                    case .top:
                        return attachment.fontAscent
                    case .bottom:
                        let height = attachment.size.height + attachment.margin.bottom + attachment.margin.top
                        return height - attachment.fontDescent
                    case .middle:
                        let height = attachment.size.height + attachment.margin.bottom + attachment.margin.top
                        return height / 2 + (attachment.fontAscent + attachment.fontDescent) / 2
                    }
                },
                getDescent: { (rawPointer) -> CGFloat in
                    let attachment = rawPointer.assumingMemoryBound(to: LKAttachmentProtocol.self).pointee
                    switch attachment.verticalAlignment {
                    case .top:
                        let height = attachment.size.height + attachment.margin.bottom + attachment.margin.top
                        return height - attachment.fontAscent
                    case .bottom:
                        return attachment.fontDescent
                    case .middle:
                        let height = attachment.size.height + attachment.margin.bottom + attachment.margin.top
                        return height / 2 - (attachment.fontAscent + attachment.fontDescent) / 2
                    }
                },
                getWidth: { (rawPointer) -> CGFloat in
                    let attachment = rawPointer.assumingMemoryBound(to: LKAttachmentProtocol.self).pointee
                    return attachment.size.width + attachment.margin.left + attachment.margin.right
                }
            )
            self.attrsCommits.append(LKCharacterAttrsCommit(
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
