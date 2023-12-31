//
//  RestrictViewModel.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/1/3.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import RichLabel
import EENavigator
import LarkCore
import LarkUIKit
import LarkMessengerInterface
import EEAtomic
import LarkAlertController

public protocol RestrictComponentViewModelContext: ViewModelContext { }

public class RestrictComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: RestrictComponentViewModelContext>: MessageSubViewModel<M, D, C> {
    public var textFont: UIFont { UIFont.ud.caption1 }
    public var iconSize: CGSize { CGSize(width: UIFont.ud.caption2.rowHeight,
                                         height: UIFont.ud.caption2.rowHeight) }

    public private(set) var text = BundleI18n.LarkMessageCore.Lark_IM_MessageRestrictedOthersCantSee_Text

    var icon: UIImage {
        return Resources.restrict_tip
    }
}
