//
//  DiffUtils.swift
//  ByteView
//
//  Created by liujianlong on 2021/6/20.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

enum DiffUtils {
    struct BatchUpdate {
        var deletions: [Int]
        var moves: [(from: Int, to: Int)]
        var insertions: [Int]

        var isEmpty: Bool {
            deletions.isEmpty && moves.isEmpty && insertions.isEmpty
        }
    }

    class OPNode {
        var val: Int
        var prev: OPNode?
        init(val: Int, prev: OPNode?) {
            self.val = val
            self.prev = prev
        }

        static let emptyNode = OPNode(val: 0, prev: nil)

        static func initialize(pointer: UnsafeMutablePointer<OPNode>, val: Int, prev: OPNode?) -> OPNode {
            pointer.initialize(to: emptyNode)
            pointer.pointee.val = val
            pointer.pointee.prev = prev
            return pointer.pointee
        }
    }

    static func computeNDDiff<ItemType: Hashable>(origin: [ItemType], target: [ItemType], maxDepth: Int?) -> (deleted: [Int], inserted: [Int])? {
        let maxD = maxDepth != nil ? min(maxDepth!, target.count + origin.count) : target.count + origin.count
        let vOffset = maxD
        var vArray: [Int] = Array(repeating: 0, count: maxD + maxD + 1)
        if origin.isEmpty, target.isEmpty {
            return ([], [])
        }

        vArray[1] = 0

        var operationNodes: [Int: OPNode] = [:]

        for d in 0 ... maxD {
            let from = d > target.count ? -(d - 2) : -d
            let to = d > origin.count ? (d - 2) : d
            for k in stride(from: from, through: to, by: 2) {
                var x: Int
                var y: Int
                if k == from || k != to && vArray[k - 1 + vOffset] < vArray[k + 1 + vOffset] {
                    x = vArray[k + 1 + vOffset]

                    operationNodes[k] = OPNode(val: x - k, prev: operationNodes[k + 1])
                } else {
                    x = vArray[k - 1 + vOffset] + 1

                    operationNodes[k] = OPNode(val: -x, prev: operationNodes[k - 1])
                }
                y = x - k
                while x < origin.count, y < target.count, origin[x] == target[y] {
                    x += 1
                    y += 1
                }
                vArray[k + vOffset] = x
                if x == origin.count, y == target.count {
                    return deriveDeletedInserted(operationNodes: operationNodes[k]!)
                }
            }
        }
        return nil
    }


    private static func deriveDeletedInserted(operationNodes: OPNode) -> (deleted: [Int], inserted: [Int]) {
        var deleted: [Int] = []
        var inserted: [Int] = []
        var curNode: OPNode?
        curNode = operationNodes
        while curNode != nil {
            let op = curNode!.val
            if op > 0 {
                inserted.append(op - 1)
            } else if op < 0 {
                deleted.append(-op - 1)
            }
            curNode = curNode!.prev
        }
        return (deleted.reversed(), inserted.reversed())
    }

    static func computeDiff<ItemType: Hashable>(origin: [ItemType], target: [ItemType]) -> (deleted: [Int], inserted: [Int]) {
        var costs = Array(repeating: Array(repeating: 0, count: origin.count + 1), count: target.count + 1)
        for j in 0 ... origin.count {
            costs[0][j] = j
        }
        if !target.isEmpty {
            for i in 1 ... target.count {
                costs[i][0] = i
                if origin.isEmpty {
                    continue
                }
                for j in 1 ... origin.count {
                    if origin[j - 1] == target[i - 1] {
                        costs[i][j] = min(costs[i - 1][j - 1], costs[i][j - 1] + 1, costs[i - 1][j] + 1)
                    } else {
                        costs[i][j] = min(costs[i][j - 1] + 1, costs[i - 1][j] + 1)
                    }
                }
            }
        }

        var deletedIndices: [Int] = []
        var insertIndices: [Int] = []
        var row = target.count
        var col = origin.count
        while col > 0, row > 0 {
            if costs[row][col] == costs[row - 1][col] + 1 {
                // insert
                insertIndices.append(row - 1)
                row -= 1
            } else if costs[row][col] == costs[row][col - 1] + 1 {
                // delete
                deletedIndices.append(col - 1)
                col -= 1
            } else {
                assert(target[row - 1] == origin[col - 1])
                row -= 1
                col -= 1
            }
        }
        while col > 0 {
            deletedIndices.append(col - 1)
            col -= 1
        }

        while row > 0 {
            insertIndices.append(row - 1)
            row -= 1
        }
        return (deletedIndices.reversed(), insertIndices.reversed())
    }

    static func computeBatchAction<ItemType: Hashable>(origin: [ItemType],
                                                       target: [ItemType],
                                                       maxChangeCnt: Int) -> BatchUpdate? {
        let originItemsSet = Set(origin)
        let targetItemsSet = Set(target)
        let originIndexMap = Dictionary(uniqueKeysWithValues: origin.enumerated().map { ($0.element, $0.offset) })
        let targetIndexMap = Dictionary(uniqueKeysWithValues: target.enumerated().map { ($0.element, $0.offset) })

        let deleteActions = origin.enumerated().filter { !targetItemsSet.contains($0.element) }
        var moveActions: [(Int, Int)] = []
        let insertActions = target.enumerated().filter { !originItemsSet.contains($0.element) }

        let afterDeleteItems = origin.filter(targetItemsSet.contains(_:))
        let targetBeforeInsert = target.filter(originItemsSet.contains(_:))
        guard let (movedIndices, _) = computeNDDiff(origin: afterDeleteItems,
                                                    target: targetBeforeInsert,
                                                    maxDepth: maxChangeCnt)
        else {
            return nil
        }
        for idx in movedIndices {
            let item = afterDeleteItems[idx]
            moveActions.append((originIndexMap[item]!, targetIndexMap[item]!))
        }
        //        for i in 0..<targetBeforeInsert.count {
        //            if targetBeforeInsert[i] != afterDeleteItems[i] {
        //                let item = targetBeforeInsert[i]
        //                moveActions.append((originIndexMap[item]!, targetIndexMap[item]!))
        //                let idx = afterDeleteItems.firstIndex(of: item)!
        //                afterDeleteItems.remove(at: idx)
        //                afterDeleteItems.insert(item, at: i)
        //            }
        //        }

        let batchUpdate = BatchUpdate(deletions: deleteActions.map(\.offset),
                                      moves: moveActions,
                                      insertions: insertActions.map(\.offset))
        return batchUpdate
    }
}
