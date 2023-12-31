//
//  SheetFilterDetailViewController.swift
//  SpaceKit
//
//  Created by Webster on 2019/9/26.
//  三级页面基类

import Foundation
import SKCommon
import SKUIKit

protocol SheetFilterDetailDelegate: AnyObject {
    var browserViewBottomDistance: CGFloat { get }
    func requestJsCallBack(identifier: String, value: String, controller: SheetFilterDetailViewController)
    func requestJsCallBack(identifier: String, range value: [Any], controller: SheetFilterDetailViewController, bySearch: Bool?)
    func willBeginTextInput(controller: SheetFilterDetailViewController)
    func willEndTextInput(controller: SheetFilterDetailViewController)
}

class SheetFilterDetailViewController: SheetScrollableToolkitViewController, SheetColumnSwitchViewDelegate {
    //筛选信息
    var filterInfo: SheetFilterInfo = SheetFilterInfo()
    let switchHeight: CGFloat = 56
    weak var delegate: SheetFilterDetailDelegate?
    lazy var switchView: SheetColumnSwitchView = {
        let view = SheetColumnSwitchView()
        view.delegate = self
        return view
    }()
    init(_ filterInfo: SheetFilterInfo) {
        super.init()
        self.filterInfo = filterInfo

        let scrollTopPadding = topPaddingWithHeader + switchHeight
        scrollView.snp.updateConstraints { (make) in
            make.top.equalToSuperview().offset(scrollTopPadding)
        }
        view.addSubview(switchView)
        switchView.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.height.equalTo(switchHeight)
            make.left.equalToSuperview()
            make.top.equalToSuperview().offset(topPaddingWithHeader)
        }
    }

    func updateSwitchView() {
        navigationBar.setTitleText(filterInfo.navigatorTitle)
        switchView.titleLabel.text = filterInfo.colTitle
        switchView.updateIndex(current: filterInfo.colIndex, total: filterInfo.colTotal)
    }

    func update(_ info: SheetFilterInfo) {
        filterInfo = info
        updateSwitchView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func didRequestTo(index: Int, view: SheetColumnSwitchView) {
        delegate?.requestJsCallBack(identifier: SheetFilterInfo.JSIdentifier.range, value: String(index), controller: self)
    }
}
