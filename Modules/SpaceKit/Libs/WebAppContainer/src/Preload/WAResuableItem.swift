//
//  WAResuableItem.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/12/4.
//

import Foundation

protocol WAResuableItem: AnyObject, Hashable {
    
    var usedCount: Int { get  set }
    
    var inPool: Bool { get set }
    
    var appName: String { get }
    
    var canResue: Bool { get }
}

extension WAResuableItem {
    func increaseUseCount() {
        usedCount += 1
    }
}
