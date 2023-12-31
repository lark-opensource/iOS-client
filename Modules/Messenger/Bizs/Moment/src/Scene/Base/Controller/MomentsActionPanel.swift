//
//  MomentsActionPanel.swift
//  Moment
//
//  Created by ByteDance on 2023/1/28.
//

import UIKit
import Foundation
import UniverseDesignActionPanel
import LarkUIKit

class MomentsActionPanel: UDActionPanel {
    var scrollView: AutoScrollableContainer?
    let childViewHeight: CGFloat
    init(childView: UIView, height: CGFloat, backgroundColor: UIColor, safeAreaInsets: UIEdgeInsets) {
        self.childViewHeight = height
        let presentVC = BaseUIViewController()
        presentVC.view.backgroundColor = .clear
        var originY = UIScreen.main.bounds.height - safeAreaInsets.bottom - height
        let minOriginY: CGFloat = 88
        if originY < minOriginY {
            //可以滚动
            originY = minOriginY

            let scrollView = AutoScrollableContainer(contentHeight: height + safeAreaInsets.bottom, childView: childView, childViewHeight: height)
            presentVC.view.addSubview(scrollView)
            scrollView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            scrollView.backgroundColor = backgroundColor
            scrollView.addSubview(childView)
            self.scrollView = scrollView
        } else {
            presentVC.view.addSubview(childView)
            childView.snp.makeConstraints { make in
                make.bottom.equalTo(presentVC.view.safeAreaLayoutGuide.snp.bottom)
                make.left.right.equalToSuperview()
                make.height.equalTo(height)
            }
            let coverView = UIView()
            coverView.backgroundColor = backgroundColor
            presentVC.view.addSubview(coverView)
            coverView.snp.makeConstraints { make in
                make.left.right.equalTo(childView)
                make.bottom.equalToSuperview()
                make.top.equalTo(childView.snp.bottom)
            }
        }
        super.init(customViewController: presentVC,
                   config: UDActionPanelUIConfig(
                    originY: originY,
                    canBeDragged: true,
                    backgroundColor: .clear
                ))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        scrollView?.contentHeight = self.childViewHeight + self.view.safeAreaInsets.bottom
    }
}
