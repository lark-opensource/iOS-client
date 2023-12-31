//
// Created by duanxiaochen.7 on 2021/8/29.
// Affiliated with SKBitable.
//
// Description:

import Foundation
import UIKit
import SKUIKit
import LarkUIKit

final class BTNavigationController: LkNavigationController {

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }
}
