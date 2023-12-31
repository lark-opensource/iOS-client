//
//  MergeForwardDateCellViewModel.swift
//  LarkChat
//
//  Created by 李勇 on 2019/11/13.
//

import UIKit
import Foundation
import LarkMessageCore
import LarkCore
import LarkMessageBase
import LarkExtensions

final class MergeForwardDateCellViewModel: SignCellViewModel<MergeForwardContext> {
    final override var identifier: String {
        return "message-date"
    }

    private let date: TimeInterval

    final var dateStr: String {
        return date.lf.cacheFormat("t_date", formater: { $0.lf.formatedDate() })
    }

    final override var lineColor: UIColor {
        return UIColor.ud.lineBorderComponent
    }

    final override var textColor: UIColor {
        return UIColor.ud.textTitle
    }

    final override var backgroundColor: UIColor {
        return .clear
    }

    final override var centerText: String {
        return dateStr
    }

    init(date: TimeInterval, context: MergeForwardContext) {
        self.date = date
        super.init(context: context, binder: SignCellComponentBinder<MergeForwardContext>(context: context))
    }
}
