//
//  MomentsMenuViewController.swift
//  Moment
//
//  Created by bytedance on 2/17/22.
//

import UIKit
import Foundation
import LarkMenuController

final class MomentsMenuViewController: MenuViewController {
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.dismiss(animated: true, params: nil)
    }
}
