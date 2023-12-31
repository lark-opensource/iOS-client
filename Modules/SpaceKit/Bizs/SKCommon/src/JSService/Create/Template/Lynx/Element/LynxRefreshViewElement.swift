//
//  SKRefreshViewElement.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/11/11.
//  


import Foundation
import Lynx
import UIKit
import SKUIKit

class LynxRefreshViewElement: LynxUI<UIView> {
    static let name = "ccm-refresh-view"
    private var enableRefresh = true
    private var enableLoadMore = true
    private weak var header: LynxRefreshHeaderElement?
    private weak var footer: LynxRefreshFooterElement?
    private weak var list: LynxUI<UIView>?
    private var scrollView: UIScrollView?
    
    override var name: String {
        return Self.name
    }
    override func createView() -> UIView {
        return UIView()
    }
    override func insertChild(_ child: LynxUI<UIView>, at index: Int) {
        super.insertChild(child, at: index)
        if let header = child as? LynxRefreshHeaderElement {
            self.header = header
        } else if let footer = child as? LynxRefreshFooterElement {
            self.footer = footer
        } else {
            self.list = child
        }
    }
    override func layoutDidFinished() {
        super.layoutDidFinished()
        if scrollView == nil {
            var excludeViews: [UIView] = []
            if let headerView = header?.view() {
                excludeViews.append(headerView)
            }
            if let footerView = footer?.view() {
                excludeViews.append(footerView)
            }
            guard let scrollView = findView(with: UIScrollView.self, fromView: self.view(), excludeViews: excludeViews) as? UIScrollView else {
                return
            }
            self.scrollView = scrollView
        }
        addHeaderAndFooter()
    }
//    override func hasCustomLayout() -> Bool {
//        return true
//    }
    
    @objc
    public static func propSetterLookUp() -> [[String]] {
        return [
            ["enable-refresh", NSStringFromSelector(#selector(setEnableRefresh))],
            ["enable-loadmore", NSStringFromSelector(#selector(setEnableLoadMore))]
        ]
    }

    @objc
    func setEnableRefresh(_ value: NSNumber, requestReset: Bool) {
        enableRefresh = value.boolValue
        self.scrollView?.header?.isHidden = !enableRefresh
    }
    
    @objc
    func setEnableLoadMore(_ value: NSNumber, requestReset: Bool) {
        enableLoadMore = value.boolValue
        self.scrollView?.footer?.noMoreData = !enableLoadMore
        self.scrollView?.footer?.isHidden = !enableLoadMore
    }
    
    @objc
    class func __lynx_ui_method_config__finishRefresh() -> String {
        return "finishRefresh"
    }
    @objc
    func finishRefresh(_ params: [AnyHashable: Any], withResult _: LynxUIMethodCallbackBlock) {
        self.scrollView?.es.stopPullToRefresh()
    }
    
    @objc
    class func __lynx_ui_method_config__finishLoadMore() -> String {
        return "finishLoadMore"
    }
    @objc
    func finishLoadMore(_ params: [AnyHashable: Any], withResult _: LynxUIMethodCallbackBlock) {
        self.scrollView?.es.stopLoadingMore()
    }

    private func findView(with kind: AnyClass, fromView: UIView, excludeViews: [UIView]) -> UIView? {
        var resultView: UIView?
        let subviews = fromView.subviews
        if subviews.count <= 0 {
            return nil
        }
        for subview in subviews {
            if subview.isKind(of: kind) {
                resultView = subview
                break
            }
        }
        if resultView != nil {
            return resultView
        }
        for subview in subviews {
            guard !excludeViews.contains(where: { $0 == subview }) else {
                break
            }
            resultView = findView(with: kind, fromView: subview, excludeViews: excludeViews)
            if resultView != nil {
                break
            }
        }
        return resultView
    }
    
    private func addHeaderAndFooter() {
        if enableRefresh, self.header != nil, scrollView?.header == nil {
            scrollView?.es.addPullToRefreshOfDoc(animator: WikiHomePageRefreshAnimator(frame: .zero)) { [weak self] in
                guard let self = self else { return }
                let event = LynxDetailEvent(name: "startrefresh", targetSign: self.sign, detail: [:])
                self.context?.eventEmitter?.send(event)
            }
        }
        if enableLoadMore, self.footer != nil, scrollView?.footer == nil {
            scrollView?.es.addInfiniteScrollingOfDoc(animator: DocsThreeDotRefreshAnimator()) { [weak self] in
                guard let self = self else { return }
                let event = LynxDetailEvent(name: "startloadmore", targetSign: self.sign, detail: [:])
                self.context?.eventEmitter?.send(event)
            }
        }
    }
}
