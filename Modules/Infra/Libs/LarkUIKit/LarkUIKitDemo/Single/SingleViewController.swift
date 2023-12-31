//
//  SingleViewController.swift
//  LarkUIKitDemo
//
//  Created by liuwanlin on 2018/3/22.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkActionSheet

class SingleViewController: ViewController {
    override var pageTitle: String {
        return "SingleView Demos"
    }

    override func setupDatasource() {
        let swipeContainerItem = DatasourceItem(title: "SwipeContainerController") { () -> UIViewController in
            return SwipeContainerFactory.build()
        }

        let activityIndicatorItem = DatasourceItem(title: "activityIndicator") { () -> UIViewController in
            return ActivityIndicatorViewController()
        }

        datasource = [
            swipeContainerItem,
            activityIndicatorItem
        ]
    }
}
