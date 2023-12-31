//
//  ComposePostParentVC+Delegate.swift
//  LarkChat
//
//  Created by zoujiayi on 2019/10/10.
//

import UIKit
import Foundation
import Photos
import RxSwift
import RxCocoa
import LarkUIKit
import LarkFoundation
import LarkModel
import LarkCore
import EENavigator
import UniverseDesignToast
import LarkAlertController

extension ComposePostViewContainer: SwipeContainerViewControllerDelegate {
    func configSubviewOn(containerView: UIView) {}

    func startDrag() {
        resignInputViewFirstResponder()
    }

    func disablePanGestureViews() -> [UIView] {
        return [childController.keyboardPanel]
    }

    func dismissByDrag() {
        dismissByCancel()
    }
}
