//
//  ShareGroupQRCodeViewController.swift
//  LarkChatSetting
//
//  Created by 姜凯文 on 2020/4/20.
//

import UIKit
import Foundation
import LarkSegmentedView
import LarkMessengerInterface
import LarkUIKit

final class ShareGroupQRCodeViewController: GroupQRCodeController, ShareGroupQRCodeController {

    override var navigationBarStyle: NavigationBarStyle {
        return .`default`
    }

    // MARK: - JXSegmentedListContainerViewListDelegate
    func listView() -> UIView {
        return view
    }
}
