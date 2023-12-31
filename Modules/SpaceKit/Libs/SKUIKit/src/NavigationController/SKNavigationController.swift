//
// Created by duanxiaochen.7 on 2020/11/4.
// Affiliated with SKUIKit.
//
// Description:

import Foundation
import LarkUIKit

open class SKNavigationController: LkNavigationController {
    open override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationBarHidden(true, animated: false)
    }
}
