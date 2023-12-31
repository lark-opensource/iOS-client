//
//  BTChooseLocationViewController.swift
//  SKBitable
//
//  Created by 曾浩泓 on 2022/5/3.
//  

import LarkUIKit
import LarkLocationPicker
import SKResource

final class BTChooseLocationViewController: ChooseLocationViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        if let rightBarButtonItem = self.navigationItem.rightBarButtonItem as? LKBarButtonItem {
            rightBarButtonItem.button.setTitle(BundleI18n.SKResource.Bitable_Common_ButtonSave, for: .normal)
        }
    }
}
