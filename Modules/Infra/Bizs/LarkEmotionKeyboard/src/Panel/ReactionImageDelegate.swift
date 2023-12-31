//
//  ReactionImageDelegate.swift
//  LarkReactionPanel
//
//  Created by 王元洵 on 2021/2/8.
//

import UIKit
import Foundation
public protocol ReactionImageDelegate: AnyObject {
    static func reactionViewImage(_ reactionKey: String, callback: @escaping (UIImage?) -> Void)
}

/// default reaction image service
public let defaultReactionImageService: ReactionImageDelegate.Type? = {
    #if LarkEmotion_Reaction
    return PanelIconDefaultImpl.self
    #else
    return nil
    #endif
}()
