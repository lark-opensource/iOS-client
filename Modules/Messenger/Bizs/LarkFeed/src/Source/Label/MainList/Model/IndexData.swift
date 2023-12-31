//
//  IndexData.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/20.
//

import Foundation

protocol IndexDataInterface {
    var id: Int { get }
    var parentId: Int { get }
}

struct IndexCursor {
    let position: Int64
    let itemId: Int64

    init(position: Int64,
         itemId: Int64 = 0) {
        self.position = position
        self.itemId = itemId
    }
}

struct IndexData: Hashable {
    let id: Int
    let parentId: Int
    let originOrder: Int64
    let version: Int64

    // 顺序关系
    private(set) var childIndexList: [IndexData]
    // 辅助查询：key: id, value: IndexData的index
    private(set) var childIndexMap: [Int: Int]

    private(set) var hasMore: Bool?
    private(set) var nextCursor: IndexCursor?

    init(id: Int,
         parentId: Int,
         originOrder: Int64,
         version: Int64,
         hasMore: Bool? = nil,
         nextCursor: IndexCursor? = nil,
         childIndexList: [IndexData] = [],
         childIndexMap: [Int: Int] = [:]) {
        self.id = id
        self.parentId = parentId
        self.originOrder = originOrder
        self.version = version
        self.hasMore = hasMore
        self.nextCursor = nextCursor
        self.childIndexList = childIndexList
        self.childIndexMap = childIndexMap
    }

    static let rootParentData = 0
    static func `default`() -> IndexData {
        return IndexData(id: rootParentData, parentId: rootParentData, originOrder: Int64(rootParentData), version: Int64(rootParentData))
    }

    mutating func update(childId: Int,
                         originOrder: Int64,
                         version: Int64) {
        var childIndexData: IndexData
        if let oldChildIndexData = self.getChildIndexData(id: childId) {
            childIndexData = IndexData(id: childId,
                                       parentId: id,
                                       originOrder: originOrder,
                                       version: version,
                                       hasMore: oldChildIndexData.hasMore,
                                       nextCursor: oldChildIndexData.nextCursor,
                                       childIndexList: oldChildIndexData.childIndexList,
                                       childIndexMap: oldChildIndexData.childIndexMap)
        } else {
            childIndexData = IndexData(id: childId,
                                       parentId: id,
                                       originOrder: originOrder,
                                       version: version)
        }
        update(childIndexData: childIndexData)
    }

    mutating func update(childIndexData: IndexData) {
        if let index = self.childIndexMap[childIndexData.id] {
            guard index < childIndexList.count else {
                let errorMsg = "index: \(index), current: \(self.description), child: \(childIndexData.description)"
                let info = FeedBaseErrorInfo(type: .error(), errorMsg: errorMsg)
                FeedExceptionTracker.Label.updateChildIndexData(node: .indexOutOfRange, info: info)
                return
            }
            self.childIndexList.replaceSubrange(index..<(index + 1), with: [childIndexData])
        } else {
            self.childIndexList.append(childIndexData)
        }
    }

    mutating func remove(childId: Int) {
        guard let index = self.childIndexMap[childId] else { return }
        remove(childIndex: index)
    }

    mutating func remove(childIndex: Int) {
        guard childIndex < childIndexList.count else { return }
        self.childIndexList.remove(at: childIndex)
        // TODO: 待优化，每次remove操作完后，都需要做一次排序优化（结合下面注释掉的代码）
        sort()
    }

//    mutating func remove(ids: [Int]) {
//        let indexes = ids.compactMap({ self.childIndexMap[$0] })
//        remove(indexes: indexes)
//    }
//
//    mutating func remove(indexes: [Int]) {
//        let indexes = indexes.sorted(by: { $0 > $1 })
//        indexes.forEach({ index in
//            guard index < childIndexList.count else { return }
//            self.childIndexList.remove(at: index)
//        })
//        sort()
//    }

    mutating func update(hasMore: Bool, nextCursor: IndexCursor) {
        self.hasMore = hasMore
        self.nextCursor = nextCursor
    }

    func getChildIndexData(id: Int) -> IndexData? {
        guard let index = self.childIndexMap[id] else { return nil }
        return self.getChildIndexData(index: index)
    }

    func getChildIndexData(index: Int) -> IndexData? {
        guard index < childIndexList.count else { return nil }
        return self.childIndexList[index]
    }

    mutating func sort() {
        self.childIndexList = self.childIndexList.sorted(by: { $0.originOrder > $1.originOrder })
        self.childIndexMap.removeAll()
        for i in 0..<childIndexList.count {
            let child = childIndexList[i]
            self.childIndexMap[child.id] = i
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: IndexData, rhs: IndexData) -> Bool {
        return lhs.id == rhs.id
    }
}

extension IndexData {
    var description: String {
        let info = "id: \(id), parentId: \(parentId), originOrder: \(originOrder), hasMore: \(hasMore), nextPosition: \(nextCursor), "
        let childInfo = "count: \(childIndexList.count), childIds: \(childIndexList.map { $0.id })"
        return info + childInfo
    }
}
