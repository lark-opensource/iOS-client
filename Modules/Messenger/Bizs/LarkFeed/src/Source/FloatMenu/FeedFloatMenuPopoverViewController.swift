//
//  FeedFloatMenuPopoverViewController.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/8/5.
//

import UIKit
import Foundation
import UniverseDesignShadow
import LarkOpenFeed

final class FeedFloatMenuPopoverViewController: UIViewController, FeedPresentAnimationViewController {

    let menuView: FeedFloatMenuView
    let shadowView: UIView
    let scrollView = UIScrollView()

    init(menuView: FeedFloatMenuView) {
        self.menuView = menuView
        self.shadowView = UIView()
        super.init(nibName: nil, bundle: nil)
        menuView.popoverVC = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false

        view.addSubview(scrollView)
        view.backgroundColor = .clear
        scrollView.backgroundColor = .clear
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide.snp.edges)
        }

        scrollView.addSubview(menuView)
        menuView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}
