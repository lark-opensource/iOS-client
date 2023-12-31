//
//  Array+Ext.swift
//  SKFoundation
//
//  Created by lijuyou on 2022/11/14.
//  


import Foundation
extension Array {
    
    public func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
    
    public func safe(index: Int) -> Element? {
        guard self.count > index, index >= 0 else {
            return nil
        }
        return self[index]
    }
    
    public func uniqued<E: Hashable>(by filter: ((Element) -> E)) -> [Element] {
        var set = Set<E>()
        var values = [Element]()
        forEach {
            let key = filter($0)
            if set.insert(key).inserted {
                values.append($0)
            }
        }
        return values
    }
    
}
