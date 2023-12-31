//
//  NaviAnimationMasterViewController.swift
//  LarkUIKitDemo
//
//  Created by Supeng on 2021/2/5.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import SnapKit
class NaviAnimationMasterViewController: BaseUIViewController {
    private var edgeNaviAnimation: EdgeNaviAnimator?

    private let label = UILabel()
    private let naviBar = TitleNaviBar(titleString: "MasterVC")

    override func viewDidLoad() {
        super.viewDidLoad()

        isNavigationBarHidden = true
        view.addSubview(naviBar)
        naviBar.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
        }
        let detailItem = TitleNaviBarItem(image: Resources.refreshDrag) { [weak self] _ in
            self?.goToDetail()
        }

        naviBar.rightItems = [detailItem]
        view.backgroundColor = .gray
        label.text = "从右侧边缘左滑，展示下一个详情页"
        view.addSubview(label)
        label.snp.makeConstraints { $0.center.equalToSuperview() }

        edgeNaviAnimation = EdgeNaviAnimator { [weak self] in
            self?.goToDetail()
        }
        edgeNaviAnimation?.addGesture(to: view)

        let back = TitleNaviBarItem(image: UIImage(named: "swipeCell_dealed")?.withRenderingMode(.alwaysTemplate)) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }
        naviBar.leftItems = [back]
    }

    func goToDetail() {
        navigationController?.pushViewController(NaviAnimationDetailViewController(), animated: true)
    }
}

extension NaviAnimationMasterViewController: CustomNaviAnimation {
    var animationProxy: CustomNaviAnimation? {
        edgeNaviAnimation
    }
}

class NaviAnimationDetailViewController: BaseUIViewController {
    private let naviBar = TitleNaviBar(titleString: "DetailVC")

    override func viewDidLoad() {
        super.viewDidLoad()

        isNavigationBarHidden = true
        view.addSubview(naviBar)
        naviBar.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
        }
        naviBar.addBackButton()

        view.backgroundColor = .green
    }
}
