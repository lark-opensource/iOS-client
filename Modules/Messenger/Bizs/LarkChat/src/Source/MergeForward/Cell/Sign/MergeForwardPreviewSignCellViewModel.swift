//
//  MergeForwardPreviewSignCellViewModel.swift
//  LarkChat
//
//  Created by ByteDance on 2022/10/9.
//

import UIKit
import Foundation
import AsyncComponent
import LarkMessageCore
import LarkMessageBase

final class MergeForwardPreviewSignCellViewModel: PreviewSignCellViewModel<MergeForwardContext> {
    final override var identifier: String {
        return "preview-sign"
    }

    final override var centerText: String {
        return BundleI18n.LarkChat.Lark_IM_MoreMessagesViewInChat_Text
    }

    final override var backgroundColor: UIColor {
        return UIColor.clear
    }

    final override var textColor: UIColor {
        return UIColor.ud.textPlaceholder
    }

    init(context: MergeForwardContext) {
        super.init(context: context, binder: PreviewSignCellComponentBinder<MergeForwardContext>(context: context))
    }
}
