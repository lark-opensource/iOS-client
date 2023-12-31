//
//  FileNotSafeViewModel.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2022/11/14.
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

public protocol FileNotSafeComponentViewModelContext: ViewModelContext { }

class FileNotSafeComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: FileNotSafeComponentViewModelContext>: MessageSubViewModel<M, D, C> {
    public var textFont: UIFont { UIFont.ud.caption1 }
    public var iconSize: CGSize { CGSize(width: UIFont.ud.caption1.rowHeight,
                                         height: UIFont.ud.caption1.rowHeight) }

    public private(set) var text = BundleI18n.LarkMessageCore.Lark_IM_FileRiskyMightHarmDevice_Text

    var icon: UIImage {
        return Resources.risk_file_tip
    }
}
