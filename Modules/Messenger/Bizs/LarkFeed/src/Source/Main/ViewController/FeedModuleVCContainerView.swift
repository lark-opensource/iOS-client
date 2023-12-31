//
//  FeedModuleVCContainerView.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/5.
//  Copyright © 2021 夏汝震. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import RustPB
import AnimatedTabBar
import LarkOpenFeed
import LarkContainer

// 类似于collectionView
final class FeedModuleVCContainerView: UIView {
    var currentScrollView: FeedTableView? {
        return currentListVC?.tableView
    }
    private(set) var currentListVC: FeedModuleVCInterface?
    private var map = [Feed_V1_FeedFilter.TypeEnum: FeedModuleVCInterface]()
    private let layoutConfig: FeedLayoutConfig?
    // 子controller需要透传resolver，这里加上限制防止遗漏
    weak var parentViewController: (UIViewController & FeedModuleVCDelegate & UserResolverWrapper)?

    init(_ layoutConfig: FeedLayoutConfig?) {
        self.layoutConfig = layoutConfig
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBody
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = UIColor.ud.bgBody
        if let layoutConfig = layoutConfig,
           !CGSizeEqualToSize(layoutConfig.containerSize, self.frame.size) {
            layoutConfig.storeContainerSize(self.frame.size)
        }
    }

    func change(oldTab: Feed_V1_FeedFilter.TypeEnum, newTab: Feed_V1_FeedFilter.TypeEnum) {
        guard let parentViewController = self.parentViewController else { return }
        let oldModuleVC = map[oldTab]
        oldModuleVC?.willResignActive()
        // Todo: 是否不需要设置为nil & true
        oldModuleVC?.delegate = nil
        oldModuleVC?.beginAppearanceTransition(false, animated: true)
        oldModuleVC?.view.isHidden = true
        oldModuleVC?.endAppearanceTransition()

        let willShowModuleVC: FeedModuleVCInterface
        if let existModuleVC = map[newTab] {
            willShowModuleVC = existModuleVC
            willShowModuleVC.view.isHidden = false
            willShowModuleVC.delegate = parentViewController
            willShowModuleVC.willActive()
            willShowModuleVC.beginAppearanceTransition(true, animated: true)
            self.bringSubviewToFront(willShowModuleVC.view)
            willShowModuleVC.endAppearanceTransition()
            currentListVC = willShowModuleVC
        } else {
            if let responder = FeedFilterTabSourceFactory.source(for: newTab)?.responder {
              do {
                switch responder {
                case .subVC(let vcBuilder):
                    willShowModuleVC = try vcBuilder(newTab, parentViewController as UserResolverWrapper)
                    willShowModuleVC.delegate = parentViewController
                    parentViewController.addChildController(willShowModuleVC, parentView: self)
                    let bottom = parentViewController.animatedTabBarController?.tabbarHeight ?? 52
                    // 为了适配tabbar毛玻璃样式，列表要透到tabbar底部
                    willShowModuleVC.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottom, right: 0)
                    willShowModuleVC.willActive()
                    map[newTab] = willShowModuleVC
                    currentListVC = willShowModuleVC
                case .tapHandler(let tapHandler):
                    FeedContext.log.info("feedlog/changeTab/tap. \(newTab)")
                    try tapHandler(newTab, parentViewController as UserResolverWrapper)
                @unknown default:
                    break
                }
              } catch {
                  let info = FeedBaseErrorInfo(type: .error(), error: error)
                  FeedExceptionTracker.Filter.changeTab(node: .changeViewTab, info: info)
              }
            } else {
                let info = FeedBaseErrorInfo(type: .error(), errorMsg: "feedFilterTab source responder is nil")
                FeedExceptionTracker.Filter.changeTab(node: .changeViewTab, info: info)
            }
        }
    }

    func remove(_ tab: Feed_V1_FeedFilter.TypeEnum) {
        let oldModuleVC = map[tab]
        // oldModuleVC?.willResignActive() // 需要进一步判断是否需要增加willResignActive的调用
        oldModuleVC?.willDestroy()
        self.map.removeValue(forKey: tab)
        oldModuleVC?.removeSelfFromParent()
    }
}

extension UIViewController {

    func addChildController(_ child: UIViewController, parentView: UIView) {
        child.willMove(toParent: self)
        self.addChild(child)
        parentView.addSubview(child.view)
        child.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        child.didMove(toParent: self) // 通知子视图控制器已经被加入到父视图控制器中
    }

    func removeSelfFromParent() {
        guard parent != nil else {
            return
        }
        willMove(toParent: nil) // 通知子视图控制器将要从父视图控制器中移除
        view.removeFromSuperview()
        self.removeFromParent()
    }
}
