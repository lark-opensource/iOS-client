//
//  RegionProvider.swift
//  LarkAccount
//
//  Created by au on 2022/8/3.
//

import Foundation

struct Region: Codable {

    let code: String
    let name: String
    let geo: String
    let index: String
    
    enum CodingKeys: String, CodingKey {
        case code = "region_code"
        case name = "region_name"
        case geo
        case index = "head_index"
    }
    
    internal init(code: String, name: String, geo: String, index: String) {
        self.code = code
        self.name = name
        self.geo = geo
        self.index = index
    }
}

class RegionProvider {
    
    let regionList: [Region]
    let topRegionList: [Region]
    
    private(set) var indexList = [String]()
    
    internal init(regionList: [Region], topRegionList: [Region]) {
        self.regionList = regionList
        self.topRegionList = topRegionList
        setup()
    }
    
    private func setup() {
        regionList.forEach { region in
            let index = region.index.uppercased()
            if !index.isEmpty && !indexList.contains(index) {
                indexList.append(index)
            }
        }
    }
    
    // 模糊搜索
    func search(_ word: String) -> [Region] {
        let lowerWord = word.lowercased()
        return regionList.filter {
            $0.code.lowercased().contains(lowerWord) || $0.name.lowercased().contains(lowerWord)
        }
    }
}
