//
//  BTHoldDataProvider.swift
//  SKBitable
//
//  Created by yinyuan on 2023/11/7.
//

import Foundation

class BTHoldDataProvider {
    private var linkFieldData: [String: [String: String]] = [:]
    
    private var dynamicOptionsFieldData: [String: [String: BTOptionModel]] = [:]
    
    private var linkDataProviders: [String: BTLinkTableDataProvider] = [:]
    
    func setLinkFieldData(filedId: String, recordTitles: [String: String]) {
        var curRecordTitles = linkFieldData[filedId] ?? [:]
        curRecordTitles.merge(other: recordTitles)
        linkFieldData[filedId] = curRecordTitles
    }
    
    func getLinkFieldData(filedId: String) -> [String: String] {
        return linkFieldData[filedId] ?? [:]
    }
    
    func setDynamicOptionsFieldData(filedId: String, data: [String: BTOptionModel]) {
        var curData = dynamicOptionsFieldData[filedId] ?? [:]
        curData.merge(other: data)
        dynamicOptionsFieldData[filedId] = curData
    }
    
    func getDynamicOptionsFieldData(filedId: String) -> [String: BTOptionModel] {
        return dynamicOptionsFieldData[filedId] ?? [:]
    }
    
    func getLinkDataProvider(baseToken: String, tableID: String, filedId: String) -> BTLinkTableDataProvider {
        let key = "\(baseToken)-\(tableID)-\(filedId)"
        let result = linkDataProviders[key] ?? BTLinkTableDataProvider(baseToken: baseToken, tableID: tableID, fieldID: filedId)
        linkDataProviders[key] = result
        return result
    }
}
