//
//  FlagMergeForwardMessageViewModel.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import LarkCore

public final class FlagMergeForwardMessageViewModel: FlagMessageCellViewModel {
    override public class var identifier: String {
        return String(describing: FlagMergeForwardMessageViewModel.self)
    }

    override public var identifier: String {
        return FlagMergeForwardMessageViewModel.identifier
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
