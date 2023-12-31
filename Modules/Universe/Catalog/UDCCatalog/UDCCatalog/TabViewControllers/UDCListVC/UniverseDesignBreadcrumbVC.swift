//
//  UniverseDesignBreadcrumbVC.swift
//  UDCCatalog
//
//  Created by 强淑婷 on 2020/8/20.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import UIKit
import Foundation
import UniverseDesignBreadcrumb
import SnapKit

class UniverseDesignBreadcrumbVC: UIViewController {
    private let breadcrumbView = UDBreadcrumb()
    private let secondBreadcrumbView = UDBreadcrumb()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.ud.bgBody
        self.title = "UniverseDesignBreadcrumb"

        let titles = ["颜色", "样式", "图标"]
        breadcrumbView.backgroundColor = UIColor.ud.bgBody
        breadcrumbView.setItems(titles)
        breadcrumbView.tapCallback = { [weak self] (index) in
            if index == 0 {
                self?.navigationController?.pushViewController(UniverseDesignColorVC(), animated: true)
            } else if index == 1 {
                self?.navigationController?.pushViewController(UniverseDesignStyleVC(), animated: true)
            } else {
                self?.navigationController?.pushViewController(UniverseDesignFontVC(), animated: true)
            }
        }

        self.view.addSubview(breadcrumbView)
        breadcrumbView.snp.makeConstraints { (make) in
            make.top.equalTo(100)
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
        }

        let titles2 = ["颜色", "样式", "图标", "颜色", "样式", "图标", "大小", "样式", "图标"]
        secondBreadcrumbView.backgroundColor = UIColor.ud.bgBody
        secondBreadcrumbView.setItems(titles2)
        secondBreadcrumbView.tapCallback = { [weak self] (index) in
            if index == 0 {
                self?.navigationController?.pushViewController(UniverseDesignColorVC(), animated: true)
            } else if index == 1 {
                self?.navigationController?.pushViewController(UniverseDesignStyleVC(), animated: true)
            } else {
                self?.navigationController?.pushViewController(UniverseDesignFontVC(), animated: true)
            }
        }
        self.view.addSubview(secondBreadcrumbView)
        secondBreadcrumbView.snp.makeConstraints { (make) in
            make.top.equalTo(300)
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
        }
    }
}
