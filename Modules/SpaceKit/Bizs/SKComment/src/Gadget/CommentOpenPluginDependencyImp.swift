//
//  CommentPluginDependencyImp.swift
//  SKCommon
//
//  Created by huayufan on 2021/7/27.
//  


import UIKit
import SpaceInterface

class CommentOpenPluginDependencyImp: CommentPluginDependency {

    weak var topViewController: UIViewController?
    /// 是否展示水印
    var shouldShowWatermark: Bool = true
    
    init(topViewController: UIViewController?) {
        self.topViewController = topViewController
    }
}
