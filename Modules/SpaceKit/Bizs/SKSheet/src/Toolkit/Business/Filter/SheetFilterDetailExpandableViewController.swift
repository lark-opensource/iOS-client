//
//  SheetFilterDetailExpandableViewController.swift
//  SpaceKit
//
//  Created by Webster on 2019/9/29.
//  可以点击 item 展开输入框的三级页面

import Foundation
import SKCommon
import SKUIKit

class SheetFilterDetailExpandableViewController: SheetFilterDetailViewController {
    var itemDriverList: [SheetNormalListItemDriver]?
    var viewStairs: [SheetSpecialFilterView] = []
    var noneIdentifiers: Set<String> = SheetFilterInfo.JSIdentifier.noneIdentitiers

    override init(_ filterInfo: SheetFilterInfo) {
        super.init(filterInfo)
        displayFilterViewList()
    }

    override func update(_ info: SheetFilterInfo) {
        if canReuseFilterItemView(refresh: info) {
            let newItemLists = extraItemDriverList(info) ?? []
            for newItem in newItemLists {
                let view = viewStairs.first { $0.dataDriver.identifier == newItem.identifier }
                view?.updateText(by: newItem)
            }
            itemDriverList = newItemLists
            layoutFilterItemView()
            refreshContentSize()
            super.update(info)
        } else {
            super.update(info)
            displayFilterViewList()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshContentSize()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func displayFilterViewList() {
        makeFilterItemView()
        attachFilterItemView()
        layoutFilterItemView()
        refreshContentSize()
    }

    //model 转成 protocol， can be override
    func extraItemDriverList(_ info: SheetFilterInfo) -> [SheetNormalListItemDriver]? {
        let type = info.filterType
        let lists = info.colorFilter?.colorLists?.map({ (item) -> SheetNormalListItemDriver in
            let width = view.window?.bounds.size.width ?? view.bounds.size.width
            return SheetNormalListItemDriver(item: item, type: type, referWidth: width)
        })
        return lists
    }

    ///退出编辑，收起键盘 子类实现
    func endTextEditing() {

    }

    ///数据刷新的时候，view是否能够复用，子类实现
    func canReuseFilterItemView(refresh newInfo: SheetFilterInfo) -> Bool {
        return false
    }

    func maxContentHeight() -> CGFloat {
        let safeBottomInset = view.window?.safeAreaInsets.bottom ?? view.safeAreaInsets.bottom
        return filterItemViewHeight() + safeBottomInset
    }

    private func makeFilterItemView() {
        viewStairs.forEach { $0.removeFromSuperview() }
        viewStairs.removeAll()
        itemDriverList = extraItemDriverList(filterInfo)
        let driverList = itemDriverList ?? [SheetNormalListItemDriver]()
        viewStairs = driverList.map({ (driver) -> SheetSpecialFilterView in
            let view = SheetSpecialFilterView(driver)
            return view
        })
    }

    private func attachFilterItemView() {
        viewStairs.forEach { $0.removeFromSuperview() }
        viewStairs.forEach { scrollView.addSubview($0) }
    }

    private func layoutFilterItemView() {
        var previousView: UIView?
        for view in viewStairs {
            view.delegate = self
            let height = view.dataDriver.isExpand ? view.dataDriver.expandHeight : view.dataDriver.normalHeight
            view.snp.remakeConstraints { (make) in
                make.left.equalToSuperview()
                make.width.equalToSuperview()
                make.height.equalTo(height)
                if let topView = previousView {
                    make.top.equalTo(topView.snp.bottom)
                } else {
                    make.top.equalToSuperview()
                }
            }
            previousView = view
        }
    }

    private func filterItemViewHeight() -> CGFloat {
        var height: CGFloat = 0
        itemDriverList?.forEach({ (item) in
            if item.isExpand {
                height += item.expandHeight
            } else {
                height += item.normalHeight
            }
        })
        return height
    }

    private func refreshContentSize() {
        scrollView.contentSize = CGSize(width: view.frame.width, height: maxContentHeight())
    }

}

extension SheetFilterDetailExpandableViewController: SheetSpecialFilterViewDelegate {
    func wantedExpand(hasLayout: Bool, view: SheetSpecialFilterView) {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: { [weak self] in
            let expanedAllViews = self?.viewStairs.filter { $0.dataDriver.isExpand == true && $0 != view }
            expanedAllViews?.forEach {
                $0.show(isExpand: false, layoutNow: false)
                $0.layoutIfNeeded()
            }
            if self?.noneIdentifiers.contains(view.dataDriver.identifier) ?? false {
                view.updateButtonIcon(expand: true)
            } else {
                let noneView = self?.viewStairs.first(where: { return (self?.noneIdentifiers.contains($0.dataDriver.identifier) ?? false) })
                noneView?.show(isExpand: false, layoutNow: false)
                view.show(isExpand: true, layoutNow: false)
            }
            view.layoutIfNeeded()
            self?.scrollView.layoutIfNeeded()
            }, completion: nil)
        refreshContentSize()
        callFrontIfPressNoneView(view)
    }

    func willBeginTextInput(textField: UITextField, view: SheetSpecialFilterView) {
        delegate?.willBeginTextInput(controller: self)
    }

    func willEndTextInput(textField: UITextField, view: SheetSpecialFilterView) {
        delegate?.willEndTextInput(controller: self)
    }

    func requestUpdateColor(value: String, view: SheetSpecialFilterView) {
        delegate?.requestJsCallBack(identifier: view.dataDriver.identifier, range: [value], controller: self, bySearch: nil)
    }

    func requestUpdateSingleText(txt: String, view: SheetSpecialFilterView) {
        delegate?.requestJsCallBack(identifier: view.dataDriver.identifier, range: [txt], controller: self, bySearch: nil)
    }

    func requestUpdateTextRange(beginTxt: String, endTxt: String, view: SheetSpecialFilterView) {
        delegate?.requestJsCallBack(identifier: view.dataDriver.identifier, range: [beginTxt, endTxt], controller: self, bySearch: nil)
    }

    private func callFrontIfPressNoneView(_ view: SheetSpecialFilterView) {
        if noneIdentifiers.contains(view.dataDriver.identifier) {
            delegate?.requestJsCallBack(identifier: view.dataDriver.identifier, value: "", controller: self)
            endTextEditing()
        }
    }
}
