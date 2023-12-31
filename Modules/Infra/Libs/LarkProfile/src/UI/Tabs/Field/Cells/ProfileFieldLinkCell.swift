//
//  ProfileFieldLinkCell.swift
//  EEAtomic
//
//  Created by 姚启灏 on 2021/6/29.
//

import UIKit
import Foundation
import EENavigator

public final class ProfileFieldLinkItem: ProfileFieldNormalItem {
    public var url: String
    public var tapCallback: ((String, UIViewController) -> Void)?

    public init(fieldKey: String = "",
                title: String = "",
                contentText: String = "",
                url: String = "",
                tapCallback: ((String, UIViewController) -> Void)? = nil) {
        self.url = url
        self.tapCallback = tapCallback

        super.init(type: .link,
                   fieldKey: fieldKey,
                   title: title,
                   contentText: contentText,
                   enableLongPress: true)
    }
}

public final class ProfileFieldLinkCell: ProfileFieldNormalCell {
    public override class func canHandle(item: ProfileFieldItem) -> Bool {
        guard let cellItem = item as? ProfileFieldLinkItem else {
            return false
        }
        return cellItem.type == .link
    }

    override func commonInit() {
        super.commonInit()
        contentLabel.textColor = Cons.linkColor
    }

    public override func didTap() {
        super.didTap()

        guard let cellItem = item as? ProfileFieldLinkItem, let fromVC = context.fromVC else {
            return
        }

        if let callback = cellItem.tapCallback {
            callback(cellItem.url, fromVC)
        } else if let url = try? URL.forceCreateURL(string: cellItem.url) {
            self.navigator?.push(url, from: fromVC)
        }
    }
}
