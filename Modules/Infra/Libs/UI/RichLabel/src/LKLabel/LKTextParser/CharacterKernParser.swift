//
//  LKKernParser.swift
//  RichLabel
//
//  Created by Crazy凡 on 2019/4/18.
//

import Foundation
import UIKit

final class CharacterKernParser: LKCharacterParser {
    var inputCharacterGroups: [LKTextCharacterGroup] = []

    private var attributesCommits: [LKCharacterAttrsCommit] = []

    func filter(character: LKTextCharacterGroup) -> Bool {
        return (character.attributes[LKCharacterLeftKernAttributeName] ?? character.attributes[LKCharacterRightKernAttributeName]) is CGFloat
    }

    func parse(attributedString: NSAttributedString, context: LKTextParserContext) {
        self.attributesCommits = []
        guard !inputCharacterGroups.isEmpty else {
            return
        }

        inputCharacterGroups.forEach { (character) in
            if let width = character.attributes[LKCharacterLeftKernAttributeName] as? CGFloat {
                if character.originRange.location > 0 {
                    self.attributesCommits.append(LKCharacterAttrsCommit(
                        range: NSRange(location: character.originRange.location - 1, length: 1),
                        updateAttrs: [.kern: width],
                        removeAttrs: []))
                }
            }

            if let width = character.attributes[LKCharacterRightKernAttributeName] as? CGFloat {
                if character.originRange.location + character.originRange.length < attributedString.length {
                    self.attributesCommits.append(LKCharacterAttrsCommit(
                        range: NSRange(location: character.originRange.location + character.originRange.length - 1,
                                       length: 1),
                        updateAttrs: [.kern: width],
                        removeAttrs: []))
                }
            }
        }
    }

    func attributesCommit() -> [LKCharacterAttrsCommit] {
        return attributesCommits
    }

    func repalceCommit() -> [LKCharacterReplaceWithRunDelegateCommit] {
        return []
    }
}
