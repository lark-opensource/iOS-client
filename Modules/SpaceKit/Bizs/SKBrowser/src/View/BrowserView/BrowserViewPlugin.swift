//
//  BrowserViewPlugin.swift
//  SKBrowser
//
//  Created by lijuyou on 2021/1/19.
//  
// BrowserViewPlugin是为了将BrowserView的业务代码解耦，但并不是最好的方法
// 理想是不同业务实现不同的BrowserView子类，但这样改造存在以下困难：
// BrowserView实现了大量JSService用到的protocol，在JSService调用的时候，BrowserView需要就绪，像一些lazy var，如果第一次BrowserView没就绪，可能拿到的值就一直为nil了等等. 而JSService可能会在预加载就调用，时机没法保证，所以先不自以为是动这个逻辑
// so, 使用了组合代替继承的方式实现业务解耦，防止进一步劣化。

import Foundation
import SKCommon
import SKFoundation
import SKUIKit
import SpaceInterface

public protocol BrowserViewEditButtonAgent {
    var isEditButtonVisible: Bool { get }
    func setEditButtonVisible(_ visible: Bool)
    func modifyEditButtonProgress(_ progress: CGFloat, animated: Bool, force: Bool, completion: (() -> Void)?)
    func modifyEditButtonBottomOffset(height: CGFloat)
}

public protocol BrowserViewCatalogAgent {
    var catalogDisplayer: CatalogDisplayer? { get }
    func showCatalogIndicator(show: Bool)
}

public protocol BrowserViewPlugin: EditorScrollViewObserver, BrowserViewLifeCycleEvent {
    // 由于Plugin可以给多种类型使用，需要传入当前的DocsType
    init(_ browserView: BrowserView, docsType: DocsType)
    func mount()   //加载新类型url时加载plugin
    func unmount() //在加载新类型url后会将原来的plugin卸载
    func clear() //在BrowserView Dismiss时clear
    func shouldHideView(_ view: UIView) -> Bool //对齐BrowserView.removeSPView，按需隐藏subview

    // 一个Plugin可以给多种类型使用，故为数组类型
    var supportDocsTypes: [DocsType] { get }
    var curDocsType: DocsType { get }
    var catalogAgent: BrowserViewCatalogAgent? { get }
    var editButtnAgent: BrowserViewEditButtonAgent? { get }
}

public extension BrowserViewPlugin {
    var catalogAgent: BrowserViewCatalogAgent? { nil }
    var editButtnAgent: BrowserViewEditButtonAgent? { nil }
}
