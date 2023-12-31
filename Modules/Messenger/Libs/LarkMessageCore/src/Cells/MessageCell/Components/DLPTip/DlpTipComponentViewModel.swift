//
//  DLPTipComponentViewModel.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2022/6/20.
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

public protocol DlpTipComponentViewModelContext: ViewModelContext { }

public class DlpTipComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: DlpTipComponentViewModelContext>: MessageSubViewModel<M, D, C> {
    public var textFont: UIFont { UIFont.ud.caption1 }
    public var iconSize: CGSize { .square(textFont.pointSize) }

    public private(set) var text = BundleI18n.LarkMessageCore.Lark_IM_DLP_UnableToSendMessageContainSensitiveInfo_Text

    var icon: UIImage {
        return Resources.dlp_tip
    }

    public func dlpTipDidTapped() {
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkMessageCore.Lark_IM_DLP_UnableToSend_Title)
        alertController.setContent(text: BundleI18n.LarkMessageCore.Lark_IM_DLP_UnableToSendMessageContainSensitiveInfo_Desc)
        alertController.addPrimaryButton(text: BundleI18n.LarkMessageCore.Lark_IM_DLP_UnableToSend_GotIt_Button)
        context.navigator(type: .present, controller: alertController, params: nil)
    }
}

public final class ThreadDlpTipComponentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: DlpTipComponentViewModelContext>: DlpTipComponentViewModel<M, D, C> {
    override public var textFont: UIFont { UIFont.ud.caption2 }
}
