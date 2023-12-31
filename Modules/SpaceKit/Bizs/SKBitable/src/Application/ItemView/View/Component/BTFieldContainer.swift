// 
// Created by duanxiaochen.7 on 2020/3/29.
// Affiliated with DocsSDK.
// 
// Description:

import Foundation
import SKBrowser

final class BTFieldContainer: UIView, UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view is BTCapsuleCellWithAvatar {
            return false
        }
        return true
    }
}
