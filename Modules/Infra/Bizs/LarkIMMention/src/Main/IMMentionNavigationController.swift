//
//  IMMentionNavigationController.swift
//  LarkIMMention
//
//  Created by jiangxiangrui on 2022/7/20.
//

import UIKit
import Foundation

final class IMMentionNavigationController: UINavigationController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationBar.isHidden = true
    }
}
