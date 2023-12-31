//
//  ProfileFieldNormalCell.swift
//  EEAtomic
//
//  Created by 姚启灏 on 2021/6/29.
//

import Foundation
import UIKit
import UniverseDesignToast

public class ProfileFieldNormalItem: ProfileFieldItem {
    public var type: ProfileFieldType

    public var fieldKey: String

    public var title: String

    public var contentText: String

    /// 是否支持长按
    public var enableLongPress: Bool

    public init(type: ProfileFieldType = .normal,
                fieldKey: String = "",
                title: String = "",
                contentText: String = "",
                enableLongPress: Bool = true) {
        self.type = type
        self.fieldKey = fieldKey
        self.title = title
        self.contentText = contentText
        self.enableLongPress = enableLongPress
    }
}

public class ProfileFieldNormalCell: ProfileFieldCell {

    lazy var contentLabel: UILabel = {
        let contentLabel = UILabel()
        contentLabel.numberOfLines = 0
        contentLabel.font = Cons.contentFont
        contentLabel.textColor = Cons.contentColor
        contentLabel.textAlignment = .left
        return contentLabel
    }()

    lazy var contentWrapperView: UIView = UIView()

    public override class func canHandle(item: ProfileFieldItem) -> Bool {
        guard let cellItem = item as? ProfileFieldNormalItem else {
            return false
        }
        return cellItem.type == .normal
    }

    override func commonInit() {
        super.commonInit()

        self.contentView.addSubview(contentLabel)
        stackView.addArrangedSubview(contentWrapperView)
        contentWrapperView.addSubview(contentLabel)
        contentWrapperView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
        }

        contentLabel.snp.makeConstraints { make in
            make.top.right.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
            make.left.greaterThanOrEqualToSuperview()
        }
    }

    override func updateData() {
        super.updateData()

        guard let cellItem = item as? ProfileFieldNormalItem else {
            return
        }
        contentLabel.text = cellItem.contentText
    }

    @objc
    public override func longPressHandle() {
        guard let cellItem = item as? ProfileFieldNormalItem else {
            return
        }
        if ProfilePasteboardUtil.pasteboardPersonalItemInfo(text: cellItem.contentText) {
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
