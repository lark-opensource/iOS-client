//
//  LKZoomTransitionPage.swift
//  LKBaseAssetBrowser
//
//  Created by Hayden Wang on 2022/1/25.
//

import UIKit

/// 在Zoom转场时使用
public protocol LKZoomTransitionPage: UIView {
    /// 内容视图
    var showContentView: UIView { get }
}
