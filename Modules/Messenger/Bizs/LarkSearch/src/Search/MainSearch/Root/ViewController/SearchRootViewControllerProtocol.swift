//
//  SearchRootViewControllerProtocol.swift
//  LarkSearch
//
//  Created by chenyanjie on 2023/11/29.
//

import Foundation
public protocol SearchRootViewControllerProtocol: UIViewController {
    var circleDelegate: SearchRootViewControllerCircleDelegate? { get set }
    func enterCacheSearchVC() //进到缓存的搜索页面: 需要弹出键盘 + 上报埋点
    func getContentContainerY() -> CGFloat
    func routTo(tab: SearchTab, query: String?, shouldForceOverwriteQueryIfEmpty: Bool)
}
