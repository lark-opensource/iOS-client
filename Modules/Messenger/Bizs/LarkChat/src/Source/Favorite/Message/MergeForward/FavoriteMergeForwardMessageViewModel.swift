//
//  FavoriteMergeForwardMessageViewModel.swift
//  Lark
//
//  Created by lichen on 2018/6/7.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import LarkFoundation
import LarkCore

public final class FavoriteMergeForwardMessageViewModel: FavoriteMessageViewModel {
    override public class var identifier: String {
        return String(describing: FavoriteMergeForwardMessageViewModel.self)
    }

    override public var identifier: String {
        return FavoriteMergeForwardMessageViewModel.identifier
    }

    public var mergeForwardContent: MergeForwardContent? {
        return self.message.content as? MergeForwardContent
    }

    public var title: String {
        guard let content = self.mergeForwardContent else {
            return ""
        }
        return content.title
    }

    public var contentText = NSAttributedString(string: "")

    public override func setupMessage() {
        super.setupMessage()

        guard let content = self.mergeForwardContent else {
            return
        }
        self.contentText = content.getContentText(userResolver: userResolver)
    }

    override public var needAuthority: Bool {
        return false
    }
}
