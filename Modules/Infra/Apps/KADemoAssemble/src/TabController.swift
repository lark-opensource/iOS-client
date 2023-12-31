//
//  TabController.swift
//  KADemoAssemble
//
//  Created by Supeng on 2021/12/15.
//

import UIKit
import Foundation
import KATabInterface

@objc
public class TabBarController: UITabBarController, UIGestureRecognizerDelegate {
    private var firstAppeared: Bool = true
    private var tabControls: [UIControl] = []

    @objc
    public init(configs: [KATabConfig]) {
        super.init(nibName: nil, bundle: nil)
        viewControllers = configs.map(TabViewWrapper.init(config:))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        defer { firstAppeared = false }

        if firstAppeared {
            self.tabBar.subviews.forEach {
                if String(describing: $0).contains("UITabBarButton") {
                    if let control = $0 as? UIControl {
                        tabControls.append(control)
                        let singleTap = UITapGestureRecognizer(target: self, action: #selector(tapGestureInvoked(gesture:)))
                        let double = UITapGestureRecognizer(target: self, action: #selector(tapGestureInvoked(gesture:)))
                        singleTap.shouldRequireFailure(of: double)
                        singleTap.numberOfTapsRequired = 1
                        control.addGestureRecognizer(singleTap)
                        double.numberOfTapsRequired = 2
                        control.addGestureRecognizer(double)
                    }
                }
            }
        }
    }

    @objc
    private func tapGestureInvoked(gesture: UITapGestureRecognizer) {
        if let selectedIndex = tabControls.firstIndex(where: { $0 === gesture.view }) {
            self.selectedIndex = selectedIndex
            let currentViewController = (viewControllers ?? [])[selectedIndex]
            if gesture.numberOfTapsRequired == 1 {
                (currentViewController as? TabViewWrapper)?.config.tabSingleClick?()
            } else if gesture.numberOfTapsRequired == 2 {
                (currentViewController as? TabViewWrapper)?.config.tabDoubleClick?()
            }
        }
    }
}

class TabViewWrapper: UIViewController {
    fileprivate let config: KATabConfig
    private var childVC: UIViewController?
    private var childVCConstrains: [NSLayoutConstraint] = []

    init(config: KATabConfig) {
        self.config = config

        super.init(nibName: nil, bundle: nil)

        tabBarItem.title = config.tabName
        tabBarItem.image = config.tabIcon
        tabBarItem.selectedImage = config.testSelectedIcon
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let childVC = config.tabViewController()
        self.childVC = childVC
        addChild(childVC)
        view.addSubview(childVC.view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let childVC = self.childVC else { return }
        childVC.view.translatesAutoresizingMaskIntoConstraints = false
        if !childVCConstrains.isEmpty {
            childVC.view.removeConstraints(childVCConstrains)
            childVCConstrains = []
        }
        if config.showNaviBar {
            childVCConstrains.append(childVC.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor))
        } else {
            childVCConstrains.append(childVC.view.topAnchor.constraint(equalTo: view.topAnchor))
        }
        childVCConstrains.append(childVC.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor))
        childVCConstrains.append(childVC.view.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor))
        childVCConstrains.append(childVC.view.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor))
        childVCConstrains.forEach { $0.isActive = true }

        tabBarController?.navigationController?.setNavigationBarHidden(!config.showNaviBar, animated: false)
        if config.showNaviBar {
            tabBarController?.title = String(config.naviBarTitle ?? "")
            tabBarController?.navigationItem.rightBarButtonItems = [config.firstNaviBarButton, config.secondNaviBarButton]
                .compactMap({ $0?(childVC) })
                .map { UIBarButtonItem(customView: $0) }
        }
    }
}
