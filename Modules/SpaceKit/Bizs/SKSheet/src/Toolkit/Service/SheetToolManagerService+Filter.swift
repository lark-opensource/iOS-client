//
//  File.swift
//  SpaceKit
//
//  Created by Webster on 2019/9/26.
//B

import Foundation
import SKCommon
import SKBrowser

typealias FilterInfoFinishBlock = (_ current: Int, _ hasNext: Bool, _ infos: [SheetFilterInfo.FilterValueItem]) -> Void

extension SheetToolManagerService {

    func handleFilterInfo(_ params: [String: Any]) {
        guard let data = params["data"] as? [String: Any], data.count > 0 else { return }
        guard let items = data["items"] as? [[String: Any]] else { return }
        guard let callBack = params["callback"] as? String else { return }

        filterJsMethod = callBack
        let title = data["title"] as? String ?? ""
        let sheetId = data["sheetId"] as? String ?? ""
        var colTotal = 0
        var colIndex = 0
        if let rangeInfo = data[SheetFilterInfo.JSIdentifier.range] as? [String: Any] {
            colTotal = rangeInfo["total"] as? Int ?? 0
            colIndex = rangeInfo["index"] as? Int ?? 0
        }
        filterInfos.removeAll()
        parseFilterByColor(extraItem(info: items, identifier: BarButtonIdentifier.cellFilterByColor))
        parseFilterByCondition(extraItem(info: items, identifier: BarButtonIdentifier.cellFilterByCondition))
        parseFilterByValue(extraItem(info: items, identifier: BarButtonIdentifier.cellFilterByValue), index: colIndex, sheetId: sheetId) { [weak self] in
            guard let strongSelf = self else { return }
            for (_, aFilterInfo) in strongSelf.filterInfos {
                aFilterInfo.colTitle = title
                aFilterInfo.colIndex = colIndex
                aFilterInfo.colTotal = colTotal
                aFilterInfo.sheetId = sheetId
            }
            strongSelf.manager.updateFilterInfo(strongSelf.filterInfos)
        }
    }

    private func parseFilterByValue(_ info: [String: Any]?, index: Int, sheetId: String, finish: @escaping () -> Void) {
        guard let realInfo = info else { return }
        let newFilterDetail = SheetFilterInfo(valueInfo: realInfo)
        filterInfos.updateValue(newFilterDetail, forKey: .byValue)

        var maxNumberOfLoad = 1 //最多调用次数
        let size = 1000 //每次拉取1k条数据
        let retryTimes = 5 //重试次数5
        let startIndex = newFilterDetail.valueFilter?.current ?? 0
        if let total = newFilterDetail.valueFilter?.total, total > 0 {
            let ceilPage = (total + size - 1) / size
            maxNumberOfLoad = ceilPage + retryTimes
        }

        var currentLoad = 0
        func loadMoreFilterInfo(current: Int, completed: @escaping FilterInfoFinishBlock) {
            guard currentLoad < maxNumberOfLoad else {
                completed(0, false, [SheetFilterInfo.FilterValueItem]())
                return
            }
            let params: [String: Any] = ["current": current, "size": size, "currentCol": index, "sheetId": sheetId]
            model?.jsEngine.callFunction(DocsJSCallBack.sheetFilterPageFetch, params: params, completion: { (data, _) in
                guard let dataDict = data as? [String: Any] else {
                    completed(0, false, [SheetFilterInfo.FilterValueItem]())
                    return
                }
                let callbackCurrent = dataDict["current"] as? Int ?? 0
                let callbackHasNext = dataDict["hasNext"] as? Bool ?? false
                var callBackList = [SheetFilterInfo.FilterValueItem]()
                if let itemList = dataDict["list"] as? [[String: Any]] {
                    let mappedList = itemList.map({ (item) -> SheetFilterInfo.FilterValueItem in
                        var newItem = SheetFilterInfo.FilterValueItem()
                        newItem.count = item["count"] as? Int ?? 0
                        newItem.selected = item["select"] as? Bool ?? false
                        newItem.value = item["value"] as? String ?? ""
                        return newItem
                    })
                    callBackList.append(contentsOf: mappedList)
                }
                currentLoad += 1
                completed(callbackCurrent, callbackHasNext, callBackList)
            })
        }

        func loopLoadOnePage(index: Int, finish: @escaping () -> Void) {
            loadMoreFilterInfo(current: index) { (newCurrent, hasNext, infos) in
                newFilterDetail.valueFilter?.valueList?.append(contentsOf: infos)
                newFilterDetail.valueFilter?.current = newCurrent
                newFilterDetail.valueFilter?.hasNext = hasNext
                if hasNext {
                    loopLoadOnePage(index: newCurrent, finish: finish)
                } else {
                    let count = newFilterDetail.valueFilter?.valueList?.count ?? 0
                    for i in 0..<count {
                        newFilterDetail.valueFilter?.valueList?[i].index = i
                    }
                    finish()
                }
            }
        }

        loopLoadOnePage(index: startIndex, finish: finish)
    }

    private func parseFilterByColor(_ info: [String: Any]?) {
        guard let realInfo = info else { return }
        let newFilterDetail = SheetFilterInfo(colorInfo: realInfo)
        filterInfos.updateValue(newFilterDetail, forKey: .byColor)
    }

    private func parseFilterByCondition(_ info: [String: Any]?) {
        guard let realInfo = info else { return }
        let newFilterDetail = SheetFilterInfo(contiditonInfo: realInfo)
        filterInfos.updateValue(newFilterDetail, forKey: .byCondition)
    }

    private func extraItem(info: [[String: Any]], identifier: BarButtonIdentifier) -> [String: Any]? {
        let filterValueItem = info.filter {
            let value = $0["id"] as? String ?? ""
            return value == identifier.rawValue
            //return value == "FilterValue"
        }
        return filterValueItem.first
    }

}
