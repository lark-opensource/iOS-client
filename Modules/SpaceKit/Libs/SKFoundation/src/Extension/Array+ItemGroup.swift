//
//  Array+ItemGroup.swift
//  SKFoundation
//
//  Created by zoujie on 2021/12/9.
//  


import Foundation

public protocol GroupableItem {
    var groupId: String { get }
}

extension Array where Element: GroupableItem {
    public func aggregateByGroupID() -> [[GroupableItem]] {
        var tuples: [(String, GroupableItem)] = []
        self.forEach { item in
            tuples.append((item.groupId, item))
        }

        let aggregatedResult = tuples.reduce([]) { (partialResult, newTuple) -> [[GroupableItem]] in
            let (groupID, newInfo) = newTuple
            if partialResult.isEmpty { // 最开始进来时要新建 [[GroupableItem]]
                return [[newInfo]]
            } else {
                var hasFound = false
                // 对 partialResult 中每一个 [GroupableItem] 遍历
                var aggregated = partialResult.map { (infos) -> [GroupableItem] in
                    if let info = infos.first, info.groupId == groupID { // 如果发现了一样的 groupID，则尾插
                        hasFound = true
                        var augmentedInfos = infos
                        augmentedInfos.append(newInfo)
                        return augmentedInfos
                    } else { // 否则返回原来的元素
                        return infos
                    }
                }
                if !hasFound { // 如果没有，新建一个 [GroupableItem]
                    aggregated.append([newInfo])
                }
                return aggregated
            }
        }
        return aggregatedResult
    }
}
