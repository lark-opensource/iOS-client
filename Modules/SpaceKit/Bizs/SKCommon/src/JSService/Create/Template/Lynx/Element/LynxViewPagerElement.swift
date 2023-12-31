//
//  LynxViewPager.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/11/9.
//  


import Foundation
import Lynx
import UIKit
import SnapKit
import SKFoundation
import UniverseDesignTabs

class LynxViewPager: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(listContainerView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    fileprivate var tabbar: LynxTabbar?
    fileprivate var items: [LynxViewPagerItem] = []
    fileprivate let listContainerView: UIView = UIView()
    
    fileprivate func add(item: LynxViewPagerItem) {
        items.append(item)
    }
    fileprivate func remove(item: LynxViewPagerItem) {
        items.removeAll(where: { $0 == item })
    }
    
    fileprivate func refreshLayout() {
        var y: CGFloat = 0
        if let tabbar = tabbar {
            var frame = tabbar.frame
            frame.origin = .zero
            frame.size.width = self.frame.size.width
            tabbar.view().frame = frame
            y = frame.maxY
        }
        var w = self.bounds.size.width
        var h = self.bounds.size.height - y
        listContainerView.frame = CGRect(x: 0, y: y, width: w, height: h)
        var titles: [String] = []
        for i in 0..<items.count {
            let item = items[i]
            item.updatedFrame = CGRect(x: 0, y: 0, width: w, height: h)
            titles.append(item.tag)
        }
        if let subview = listContainerView.subviews.first {
            subview.frame = listContainerView.bounds
        } else {
            if let firstItem = items.first {
                listContainerView.addSubview(firstItem.view())
                firstItem.view().frame = listContainerView.bounds
            }
        }
        tabbar?.tabView.titles = titles
        tabbar?.tabView.reloadData()
    }
}

class LynxViewPagerElement: LynxUI<LynxViewPager> {
    static let name = "ud-viewpager"
    override var name: String {
        return Self.name
    }
    override func createView() -> LynxViewPager {
        return LynxViewPager()
    }
    override func insertChild(_ child: LynxUI<UIView>, at index: Int) {
        super.insertChild(child, at: index)
        if let tabbarChild = child as? LynxTabbar {
            self.view().tabbar = tabbarChild
            tabbarChild.delegate = self
        } else if let itemChild = child as? LynxViewPagerItem {
            self.view().add(item: itemChild)
        } else {
            spaceAssertionFailure("ud-viewpager不支持添加ud-tabbar、viewpager-item之外的element")
        }
    }
    override func removeChild(_ child: LynxUI<UIView>, at index: Int) {
        super.removeChild(child, at: index)
        if let item = child as? LynxViewPagerItem {
            self.view().remove(item: item)
        }
    }
    override func layoutDidFinished() {
        super.layoutDidFinished()
        view().refreshLayout()
    }
    override func hasCustomLayout() -> Bool {
        return true
    }
}
extension LynxViewPagerElement: LynxTabbarDelegate {
    func tabbarDidSelectIndex(_ index: Int) {
        guard index >= 0, index < view().items.count else { return }
        let viewPager = view()
        viewPager.listContainerView.subviews.forEach { subview in
            subview.removeFromSuperview()
        }
        let itemView = viewPager.items[index].view()
        viewPager.listContainerView.addSubview(itemView)
        itemView.frame = viewPager.listContainerView.bounds
    }
}
