//
//  PassportMigrationViewController.swift
//  LarkAccount
//
//  Created by Nix Wang on 2021/12/7.
//

import UIKit
import SnapKit
import LarkUIKit
import UniverseDesignTheme

class PassportMigrationViewController: UIViewController {
    
    private let loadingView = LoadingPlaceholderView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.ud.bgLogin
        view.addSubview(loadingView)
        loadingView.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        loadingView.text = BundleI18n.suiteLogin.Lark_Passport_InitializeDataLoading
        loadingView.isHidden = false
    }

}
