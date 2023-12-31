//
//  SheetScrollableToolkitViewController.swift
//  SpaceKit
//
//  Created by Webster on 2019/9/25.
//  工具箱二级页面的基类

import Foundation
import SKBrowser

class SheetScrollableToolkitViewController: SheetBaseToolkitViewController {

    var itemInfo: ToolBarItemInfo = ToolBarItemInfo(identifier: "")

    lazy var scrollView: UIScrollView = {
        var view = UIScrollView()
        view.backgroundColor = UIColor.ud.bgBody
        view.showsVerticalScrollIndicator = false
        view.delegate = self
        return view
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(navigationBar)
        navigationBar.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.height.equalTo(navigationBarHeight)
            make.top.equalToSuperview().offset(draggableViewHeight)
            make.left.equalToSuperview()
        }

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.left.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalToSuperview().offset(topPaddingWithHeader)
        }

        NSLayoutConstraint.activate([
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SheetScrollableToolkitViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {

    }

}
