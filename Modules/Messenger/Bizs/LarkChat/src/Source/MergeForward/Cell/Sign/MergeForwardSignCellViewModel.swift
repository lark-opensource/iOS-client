//
//  MergeForwardSignCellViewModel.swift
//  LarkChat
//
//  Created by 李勇 on 2019/11/13.
//

import UIKit
import Foundation
import AsyncComponent
import LarkMessageCore
import LarkMessageBase

final class MergeForwardSignCellViewModel: SignCellViewModel<MergeForwardContext> {
    final override var identifier: String {
        return "message-sign"
    }

    final override var centerText: String {
        return BundleI18n.LarkChat.Lark_Legacy_NewMessageSign
    }

    final override var backgroundColor: UIColor {
        return UIColor.clear
    }

    init(context: MergeForwardContext) {
        super.init(context: context, binder: SignCellComponentBinder<MergeForwardContext>(context: context))
    }
}
