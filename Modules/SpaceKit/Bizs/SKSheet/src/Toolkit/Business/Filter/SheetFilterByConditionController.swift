//
//  SheetFilterByConditionController
//  SpaceKit
//
//  Created by Webster on 2019/9/26.
//

import Foundation
import SKCommon
import SKUIKit
import SKFoundation

class SheetFilterByConditionController: SheetFilterDetailExpandableViewController {
    //键盘监听
    private var kbListener = Keyboard()
    //当前键盘的位置
    var keyboardRect: CGRect?

    override var resourceIdentifier: String {
        return BadgedItemIdentifier.filterCondition.rawValue
    }

    override init(_ filterInfo: SheetFilterInfo) {
        super.init(filterInfo)
        update(filterInfo)
        view.bringSubviewToFront(navigationBar)
        kbListener.listenWillEvents { [weak self] (options) in
            if options.event == .willHide {
                self?.keyboardRect = nil
                self?.scrollView.snp.updateConstraints({ (make) in
                    make.bottom.equalToSuperview()
                })
            } else {
                let bottomPadding = self?.delegate?.browserViewBottomDistance ?? 0
                let padding = options.endFrame.height - bottomPadding
                self?.keyboardRect = options.endFrame
                self?.scrollView.snp.updateConstraints({ (make) in
                    make.bottom.equalToSuperview().offset(-padding)
                })
                self?.scrollView.layoutIfNeeded()
                self?.view.layoutIfNeeded()
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_100) {
                    self?.scrollHitItemFloatKeyboard()
                }
            }
        }
    }

    override func extraItemDriverList(_ info: SheetFilterInfo) -> [SheetNormalListItemDriver]? {
        let type = info.filterType
        let lists = info.conditionFilter?.conditionLists?.map({ (item) -> SheetNormalListItemDriver in
            let width = view.window?.bounds.size.width ?? view.bounds.size.width
            return SheetNormalListItemDriver(item: item, type: type, referWidth: width)
        })
        return lists
    }

    override func canReuseFilterItemView(refresh newInfo: SheetFilterInfo) -> Bool {
        let newInfoListCount = newInfo.conditionFilter?.conditionLists?.count ?? -1
        let oldInfoListCount = filterInfo.conditionFilter?.conditionLists?.count ?? 0
        //个数不等,一定要执行强制刷新
        if newInfoListCount != oldInfoListCount { return false }
        guard let newItemsLists = newInfo.conditionFilter?.conditionLists else { return false }
        var allMatch = true
        for newItem in newItemsLists {
            let hasObj = filterInfo.conditionFilter?.conditionLists?.contains(where: { $0.identifier == newItem.identifier }) ?? false
            if !hasObj {
                allMatch = false
                break
            }
        }
        return allMatch
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func endTextEditing() {
        for view in viewStairs {
            view.beginTextField?.endEditing(true)
            view.endTextField?.endEditing(true)
            if view.dataDriver.isExpand {
                view.reportFinishEdit()
            }
        }
    }

    override func didRequestTo(index: Int, view: SheetColumnSwitchView) {
        endTextEditing()
        scrollView.setContentOffset(CGPoint.zero, animated: false)
        super.didRequestTo(index: index, view: view)
    }
}

extension SheetFilterByConditionController {

    private func selectedItemYOffset() -> CGFloat {
        var height: CGFloat = 0
        if let lists = itemDriverList {
            for item in lists {
                if item.isExpand {
                    height += item.expandHeight
                    break
                } else {
                    height += item.normalHeight
                }
            }
        }
        return height
    }

    private func scrollHitItemFloatKeyboard() {
        let yOffset = selectedItemYOffset() - scrollView.frame.height
        if yOffset > 0 {
            scrollView.setContentOffset(CGPoint(x: 0, y: yOffset), animated: false)
        }
    }
}
