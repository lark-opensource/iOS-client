//
//  BitablePageScrollView.swift
//  SKBitable
//
//  Created by justin on 2023/9/7.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import SKResource
import LarkSetting
import SKFoundation

public struct HomePageTabConfig {
    
    public static func tabTitles() -> (recomTitle: String, myTitle: String) {
        var recommendTitle = BundleI18n.SKResource.Bitable_Homepage_Mobile_Recommended_Header
        var baseHomeTitle = BundleI18n.SKResource.Bitable_Homepage_Mobile_Home_Header
        do {
            let homepageConfig = try SettingManager.shared.setting(with: .make(userKeyLiteral: "ccm_base_homepage"))
            if let remoteRecommendT = homepageConfig["homePageLeftTabTitle"] as? String {
                recommendTitle = remoteRecommendT
            }
            if let remoteHomeT = homepageConfig["homePageRightTabTitle"] as? String {
                baseHomeTitle = remoteHomeT
            }
        } catch {
            DocsLogger.error("ccm_base_homepage get settings error", error: error)
        }
        
        return (recommendTitle, baseHomeTitle)
    }
}


public class BitablePageContainerView: UIView {

    public typealias ViewLifeCycle = (_ currentView: UIView) -> Void
    
    let viewDidAppear: ViewLifeCycle?
    let viewDisAppear: ViewLifeCycle?
    
    public init(frame: CGRect, viewDidAppear: ViewLifeCycle?, viewDisAppear: ViewLifeCycle?) {
        self.viewDidAppear = viewDidAppear
        self.viewDisAppear = viewDisAppear
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final public class BitablePageScrollView: UIView, UIScrollViewDelegate {
    
    public var segment: Segment

    var scrollView: UIScrollView = UIScrollView()

    private var viewsWithTitle: [(title: String, view: BitablePageContainerView)] = []
    
    private var isUpdateWidth: Bool = false
    private var viewWidth: CGFloat
    private var selectIndex: Int

    private var currentScrollIndex: CGFloat {
        scrollView.layoutIfNeeded()
        guard scrollView.bounds.size.width != 0 else { return 0 }
        return scrollView.contentOffset.x / scrollView.bounds.size.width
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public init(segment: Segment) {
        self.segment = segment
        self.viewWidth = 0.0
        self.selectIndex = 0
        super.init(frame: CGRect.zero)
        self.addSubview(segment.getControlView())
        segment.getControlView().snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(segment.height)
        }

        segment.tapTo = { [weak self] (index) in
            guard let `self` = self else { return }
            self.scrollView.setContentOffset(CGPoint(x: self.viewWidth * CGFloat(index), y: 0), animated: true)
        }

        self.scrollView.bounces = false
        self.scrollView.isPagingEnabled = true
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.delegate = self
        self.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.left.right.width.bottom.equalToSuperview()
            make.top.equalTo(segment.getControlView().snp.bottom)
        }

        // 避免scrollView遮挡segment的投影
        bringSubviewToFront(segment.getControlView())
    }

    public func set(views: [(title: String, view: BitablePageContainerView)], selectIndex:Int = 0) {
        clear()
        self.viewsWithTitle = views
        segment.setItems(titles: views.map { $0.title })
        self.setViews(views: views.map { $0.view })
        self.setCurrentView(index: selectIndex, animated: false)
    }

    func clear() {
        segment.clearAllItems()
        viewsWithTitle.forEach { $0.view.removeFromSuperview() }
        viewsWithTitle = []
        self.scrollView.contentSize = CGSize.zero
    }

    public func setCurrentView(index: Int, animated: Bool = true) {
        guard index < viewsWithTitle.count && index >= 0 else {
            return
        }
        if !animated {
            segment.setSelectedItem(index: index, isScrolling: false)
        }
        let preIndex = self.selectIndex
        self.selectIndex = index
        self.scrollView.setContentOffset(CGPoint(x: viewWidth * CGFloat(index), y: 0), animated: animated)
        updateSelectIndexView(index: self.selectIndex, preIndex: preIndex)
    }

    private func setViews(views: [BitablePageContainerView]) {
        self.scrollView.contentSize = CGSize(width: viewWidth * CGFloat(views.count), height: 0)
        for i in 0..<views.count {
            let view = views[i]
            let viewLeftConstraint = i == 0 ? scrollView.snp.left : views[i - 1].snp.right
            self.scrollView.addSubview(view)
            view.snp.remakeConstraints({ (make) in
                make.left.equalTo(viewLeftConstraint)
                make.height.centerY.equalTo(scrollView)
                make.width.equalTo(scrollView)
            })
        }
    }

    public override func layoutSubviews() {
        isUpdateWidth = true
        defer { isUpdateWidth = false }
        super.layoutSubviews() // trigger autolayout update, may call scrollViewDidScroll
        let currentViewWidth = scrollView.bounds.width
        if abs(viewWidth - currentViewWidth) > 0.01 {
            viewWidth = currentViewWidth
            updateUI()
        }
    }

    private func updateUI() {
        if !self.viewsWithTitle.isEmpty {
            // 设置内容页
            self.scrollView.contentSize = CGSize(width: viewWidth * CGFloat(self.viewsWithTitle.count), height: 0)
            
            // 设置选中区
            segment.updateUI(width: viewWidth)
            self.setCurrentView(index: self.selectIndex, animated: false)
        }
    }
    
    private func updateSelectIndexView(index: Int, preIndex: Int) {
        // 前一个选中view disappear
        if index != preIndex && preIndex >= 0 && preIndex < viewsWithTitle.count {
            let preSelectView = viewsWithTitle[preIndex].view
            preSelectView.viewDisAppear?(preSelectView)
        }
        
        // 选中view appear
        if index >= 0 && index < viewsWithTitle.count {
            let selectView = viewsWithTitle[index].view
            selectView.viewDidAppear?(selectView)
        }
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        /* 当屏幕修改后会设置scrollView在新宽度下的偏移量，会触发这个方法。在这里加锁避免偏移 */
        guard !isUpdateWidth else {
            return
        }
        self.segment.setOffset(offset: currentScrollIndex, isDragging: scrollView.isDragging)
        
        let currentIndex = Int(currentScrollIndex)
        if self.selectIndex != currentIndex {
            let preIndex = self.selectIndex
            self.selectIndex = currentIndex
            updateSelectIndexView(index: self.selectIndex, preIndex: preIndex)
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.segment.setOffset(offset: currentScrollIndex, isDragging: false)
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.segment.setOffset(offset: currentScrollIndex, isDragging: false)
    }
}
