//
//  SheetFilterByColorController.swift
//  SpaceKit
//
//  Created by Webster on 2019/9/26.
//

import Foundation
import SKCommon
import SKResource
import SKUIKit

class SheetFilterByColorController: SheetFilterDetailExpandableViewController {

    lazy var tipLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.SKResource.Doc_Sheet_NoColor
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.N500
        return label
    }()

    override var resourceIdentifier: String {
        return BadgedItemIdentifier.filterColor.rawValue
    }

    override init(_ filterInfo: SheetFilterInfo) {
        super.init(filterInfo)
        update(filterInfo)
        refreshTipLabel()
    }

    override func update(_ info: SheetFilterInfo) {
        super.update(info)
        refreshTipLabel()
    }

    override func extraItemDriverList(_ info: SheetFilterInfo) -> [SheetNormalListItemDriver]? {
        let type = info.filterType
        let lists = info.colorFilter?.colorLists?.map { (item) -> SheetNormalListItemDriver in
            let width = view.window?.bounds.size.width ?? view.bounds.size.width
            return SheetNormalListItemDriver(item: item, type: type, referWidth: width)
        }
        return lists
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func canReuseFilterItemView(refresh newInfo: SheetFilterInfo) -> Bool {
        let newInfoListCount = newInfo.colorFilter?.colorLists?.count ?? -1
        let oldInfoListCount = filterInfo.colorFilter?.colorLists?.count ?? 0
        //个数不等,一定要执行强制刷新
        if newInfoListCount != oldInfoListCount { return false }
        guard let newItemsLists = newInfo.colorFilter?.colorLists else { return false }
        var allMatch = true
        for newItem in newItemsLists {
            let hasObj = filterInfo.colorFilter?.colorLists?.contains(where: { $0.identifier == newItem.identifier }) ?? false
            if !hasObj {
                allMatch = false
                break
            }
        }
        return allMatch
    }

    private func refreshTipLabel() {
        let counter = filterInfo.colorFilter?.colorLists?.count ?? 0
        tipLabel.isHidden = counter > 0
        if tipLabel.superview == nil {
            scrollView.addSubview(tipLabel)
            tipLabel.snp.remakeConstraints { (make) in
                make.width.equalToSuperview()
                make.height.equalTo(22)
                make.centerX.centerY.equalToSuperview()
            }
        }
    }
}
