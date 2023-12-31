//
//  CTADialogDebugItem.swift
//  CTADialog
//
//  Created by aslan on 2023/10/10.
//

#if !LARK_NO_DEBUG

import Foundation
import LarkDebugExtensionPoint
import Swinject
import LarkNavigator
import EENavigator

struct CTADialogDebugItem: DebugCellItem {
    let title: String = "CTADialog"
    let type: DebugCellType = .disclosureIndicator

    private let resolver: Resolver
    init(resolver: Resolver) {
        self.resolver = resolver
    }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        let vc =  CTADialogDebugController()
        if let fromViewController = Navigator.shared.mainSceneWindow?.fromViewController {
            Navigator.shared.showDetailOrPush(vc, from: fromViewController)
        }
    }
}

#endif
