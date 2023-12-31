//
//  DecryptedFailedContentViewModel.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2023/4/12.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import RichLabel
import LarkCore
import EENavigator
import LarkUIKit

public final class DecryptedFailedContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: DecryptedFailedContentContext>: MessageSubViewModel<M, D, C> {
    override public var identifier: String {
        return "decryptedFailed"
    }

    var preferMaxLayoutWidth: CGFloat {
        return self.metaModelDependency.getContentPreferMaxWidth(self.message) - 2 * metaModelDependency.contentPadding
    }

    let labelFont: UIFont = UIFont.ud.body0

    private(set) lazy var attributedString: NSAttributedString = {
        let systemColor = UIColor.ud.textCaption
        let attributeStr = NSMutableAttributedString(
            string: BundleI18n.LarkMessageCore.Lark_IM_SecureChat_UnableLoadMessage_Text,
            attributes: LKLabel.lu.basicAttribute(foregroundColor: UIColor.ud.textCaption, font: labelFont)
        )
        return attributeStr
    }()
}
