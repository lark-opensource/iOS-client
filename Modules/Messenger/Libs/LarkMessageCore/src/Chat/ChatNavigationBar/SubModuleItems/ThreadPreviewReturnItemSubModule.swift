//
//  ThreadPreviewReturnItemSubModule.swift
//  LarkMessageCore
//
//  Created by liluobin on 2022/11/21.
//

import UIKit
import Foundation
import LarkOpenChat

class ThreadPreviewReturnItemSubModule: NavigationBarReturnItemSubModule {
    override func dismissButtonClicked(sender: UIButton) {
        self.context.chatVC().dismiss(animated: true)
    }
    override var showSmallDismissButtom: Bool {
        return true
    }
}
