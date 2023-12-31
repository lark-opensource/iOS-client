//
//  DocsLoadingViewProtocol.swift
//  SpaceInterface
//
//  Created by huangzhikai on 2023/3/16.
//

import Foundation
//From DocsStatusViewManager
public protocol DocsLoadingViewProtocol: AnyObject {
    var text: String { get set }
    var displayContent: UIView { get }
    // 字体大小
    var textFontSize: CGFloat { get set }
    // 文字和图标间距
    var textTopMargin: CGFloat { get set }
    // 动画图标大小
    var loadingSize: CGSize? { get set }
    func startAnimation()
    func stopAnimation()
}
