//
//  SheetToolkitFacadeViewController.swift
//  SpaceKit
//
//  Created by Webster on 2019/11/11.
//  工具箱一级页面的基类

import Foundation

class SheetToolkitFacadeViewController: SheetBaseToolkitViewController {

    var tapItem = SheetToolkitTapItem()
    
    lazy var contentView: SheetToolkitPageItemContentView = {
        var view = SheetToolkitPageItemContentView()
        view.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        return view
    }()

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    init() {
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    // 更新数据源抽象方法
    func update(_ tapItem: SheetToolkitTapItem) {
        self.tapItem = tapItem
    }
    
    // 重置状态抽象方法
    func reset() {
        
    }

}
