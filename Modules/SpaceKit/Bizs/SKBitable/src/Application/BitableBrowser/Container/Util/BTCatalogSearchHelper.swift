//
//  BTCatalogSearchHelper.swift
//  SKBitable
//
//  Created by zoujie on 2023/9/6.
//  


import Foundation

class BTCatalogSearchHelper {
    class func getSearchResult(datas: [BTCommonDataGroup], searchKey: String? = nil) -> [BTCommonDataGroup] {
        guard let searchKey = searchKey else {
            return datas
        }
        
        var searchResult: [BTCommonDataGroup] = []
        let pinyinKey = BTUtil.transformChineseToPinyin(string: searchKey.lowercased())
        
        datas.forEach { data in
            var searchData = data
            data.items.forEach { item in
                if BTUtil.transformChineseToPinyin(string: item.mainTitle?.text?.lowercased() ?? "").contains(pinyinKey) {
                    // 查找到结果
                    searchData.items = [item]
                    searchResult.append(searchData)
                }
            }
        }
        
        return searchResult
    }
}
