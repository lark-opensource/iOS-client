//
//  MinutesCommentsContentViewModelFactory.swift
//  Minutes
//
//  Created by ByteDance on 2023/10/26.
//

import Foundation
import UniverseDesignColor
import LarkContainer
import LarkAccountInterface
import MinutesNetwork

class MinutesCommentsContentViewModelFactory {
     static func build(resolver: UserResolver, contentWidth: CGFloat, isInTranslationMode: Bool, content: CommentContent, originalContent: CommentContent? = nil) -> MinutesCommentsContentViewModel {
         if content.contentForIM == nil ||  ((content.contentForIM?.isEmpty) == true) {
             return MinutesCommentsContentViewModel(resolver: resolver, contentWidth: contentWidth, content: content, originalContent: originalContent, isInTranslationMode: isInTranslationMode)
         } else {
             return MinutesCommentsContentForIMViewModel(resolver: resolver, contentWidth: contentWidth, content: content, originalContent: originalContent, isInTranslationMode: isInTranslationMode)
         }
    }
}
