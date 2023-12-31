//
//  WADetailDebugController+Config.swift
//  WebAppContainer
//
//  Created by majie.7 on 2023/12/4.
//

import Foundation


class WADetailDebugItemDataProvider {
    
    init() {}
    
    func configDataSource() -> [(String, [WADebugCellItem])] {
        // section: item
        var dataSource: [(String, [WADebugCellItem])] = []
        
        
        //pkg section 离线包相关debug
        let pkgDebugSectionItems: [WADebugCellItem] = [.updatePkgVersion]
        dataSource.append(("离线包调试相关", pkgDebugSectionItems))
        
        // 其他类型的debug项
        
        return dataSource
    }
    
}
