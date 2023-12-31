//
//  ProfileFieldLinkListCell.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/7/7.
//

import UIKit
import Foundation
import EENavigator
import UniverseDesignToast

public struct ProfileHref {
    public var url: String = ""
    public var text: String = ""
    public var accessible: Bool = true
    public var tappedCallback: (() -> Void)?

    public init(url: String = "",
                text: String = "",
                accessible: Bool = true,
                tappedCallback: (() -> Void)? = nil) {
        self.url = url
        self.text = text
        self.accessible = accessible
        self.tappedCallback = tappedCallback
    }
}

public final class ProfileFieldHrefListItem: ProfileFieldItem {

    public var type: ProfileFieldType

    public var fieldKey: String

    public var title: String

    public var hrefList: [ProfileHref]

    public var expandAll: Bool = false

    public var enableLongPress: Bool

    public init(type: ProfileFieldType = .linkList,
                fieldKey: String = "",
                title: String = "",
                hrefList: [ProfileHref] = [],
                enableLongPress: Bool = false) {
        self.type = type
        self.fieldKey = fieldKey
        self.title = title
        self.hrefList = hrefList
        self.enableLongPress = enableLongPress
    }
}

public final class ProfileFieldLinkListCell: ProfileFieldCell {
    private var hrefView: ProfileExpandableView?

    public override class func canHandle(item: ProfileFieldItem) -> Bool {
        guard let cellItem = item as? ProfileFieldHrefListItem else {
            return false
        }
        return cellItem.type == .linkList
    }

    override func commonInit() {
        super.commonInit()

        guard let cellItem = item as? ProfileFieldHrefListItem else {
            return
        }

        let expandItems = cellItem.hrefList.map { href -> ExpandableItem in
            return ExpandableItem(content: href.text,
                                  contentColor: href.accessible ? Cons.linkColor : Cons.contentColor,
                                  tappedCallback: { [weak self] in
                                    guard let self = self else { return }
                                    if let tappedCallback = href.tappedCallback {
                                        tappedCallback()
                                        return
                                    }
                                    let urlStr = href.url
                                    if href.accessible, let url = try? URL.forceCreateURL(string: urlStr) {
                                        if let from = self.context.fromVC {
                                            self.navigator?.open(url, from: from)
                                        }
                                    }
                                  },
                                  expandStatus: .folded)
        }
        var preferredMaxLayoutWidth: CGFloat = -1
        if let tableView = context.tableView {
            preferredMaxLayoutWidth = tableView.bounds.width - Cons.hMargin * 2 - Cons.titleWidth
        }
        let hrefView = ProfileExpandableView(
            items: expandItems,
            font: Cons.contentFont,
            expandAll: cellItem.expandAll,
            alignment: isVerticalLayout ? .left : .right,
            preferredMaxLayoutWidth: preferredMaxLayoutWidth,
            expandAllCallback: { [weak self] in
                cellItem.expandAll.toggle()
                self?.context.tableView?.reloadData()
        })

        self.hrefView = hrefView

        stackView.addArrangedSubview(hrefView)
    }

    @objc
    public override func longPressHandle() {
        guard let cellItem = item as? ProfileFieldHrefListItem, item.fieldKey == "B-DEPARTMENT" else {
            return
        }
        var stringToCopy = ""
        for (index, href) in cellItem.hrefList.enumerated() {
            (index != cellItem.hrefList.count - 1) ? (stringToCopy += (href.text + "\n")) : (stringToCopy += (href.text))
        }
        if ProfilePasteboardUtil.pasteboardPersonalItemInfo(text: stringToCopy) {
            if let window = self.context.fromVC?.view.window {
                UDToast.showSuccess(with: BundleI18n.LarkProfile.Lark_Legacy_Copied, on: window)
            }
        } else {
            if let window = self.context.fromVC?.view.window {
                UDToast.showFailure(with: BundleI18n.LarkProfile.Lark_IM_CopyContent_CopyingIsForbidden_Toast, on: window)
            }
        }
    }
}
