//
//  ChatTabsListContainerView.swift
//  LarkChat
//
//  Created by 赵家琛 on 2021/8/8.
//

import UIKit
import Foundation
import UniverseDesignTabs

//final class ChatTabsListContainerView: UDTabsListContainerView, ChatTabsCacheDelegate {
//    func removeContent(_ index: Int) {
//        guard let delegate = self.validListDict.removeValue(forKey: index) else { return }
//        var listVC: UIViewController?
//        if let vc = delegate as? UIViewController, vc.parent != nil {
//            listVC = vc
//        } else if let vc = delegate.listVC(), vc.parent != nil {
//            listVC = vc
//        }
//        listVC?.willMove(toParent: nil)
//        delegate.listView().removeFromSuperview()
//        listVC?.removeFromParent()
//    }
//}
