//
//  HomePersonalSection.swift
//  SKSpace
//
//  Created by majie.7 on 2023/5/28.
//

import Foundation
import RxDataSources
import SKWorkspace

public enum HomeListState {
    case error
    case normal(homeItem: HomeItemContainer)
    case empty
    case loading
}

public enum HomeItemType: Equatable, IdentifiableType {
    case specialItem(title: String)  // 提供特殊交互能力的item
    case item(node: TreeNode)   // 树节点
    case headerRoot(scene: HomeTreeSectionScene, isExpand: Bool, showCreateButton: Bool)  // 根节点
    case loading     // loading节点
    case empty       // 空数据兜底页节点
    case error       // 失败兜底页
    
    public typealias Identity = String
    public var identity: String {
        switch self {
        case .specialItem(let title):
            return title
        case .item(let node):
            return node.diffId.uniqueID
        case let .headerRoot(scene, _, showCreateButton):
            return "headerRoot - \(scene.headerTitle) - \(showCreateButton)"
        case .loading:
            return "loading"
        case .empty:
            return "empty"
        case .error:
            return "error"
        }
    }
}

enum HomeViewTransaction {
    case reload
    case update(state: HomeListState, inserts: [Int], deletes: [Int], updates: [Int], moves: [(from: Int, to: Int)])
}

public struct HomeItemContainer: AnimatableSectionModelType {
    public typealias Item = HomeItemType
    public var identity: String { identifier }
    
    private var identifier: String
    public var items: [HomeItemType]
    
    public init(identifier: String, items: [HomeItemType]) {
        self.identifier = identifier
        self.items = items
    }
    
    public init(original: HomeItemContainer, items: [HomeItemType]) {
        self = original
        self.items = items
    }
    
    public static let `default` = HomeItemContainer(identifier: "", items: [])
}

public struct HomeViewListDiffer {

    private(set) var currentData: HomeItemContainer

    public init(currentData: HomeItemContainer = .default) {
        self.currentData = currentData
    }

    mutating func reset(newData: HomeItemContainer) {
        currentData = newData
    }

    
    mutating func handle(oldData: HomeItemContainer, newData: HomeItemContainer) -> [HomeViewTransaction] {
        do {
            let differences = try Diff.differencesForSectionedView(initialSections: [oldData], finalSections: [newData])
            let result = handle(newData: newData, diffResults: differences)
            return result
        } catch {
            return [.reload]
        }
    }
    
    private func handle(newData: HomeItemContainer, diffResults: [Changeset<HomeItemContainer>]) -> [HomeViewTransaction] {
        var results = [HomeViewTransaction]()
        for diff in diffResults {
            let insert = diff.insertedItems.map(\.itemIndex)
            let delete = diff.deletedItems.map(\.itemIndex)
            let update = diff.updatedItems.map(\.itemIndex)
            let move = diff.movedItems.map { ($0.itemIndex, $1.itemIndex) }
            guard let finalList = diff.finalSections.first?.items else {
                return [.reload]
            }
            let homeItem = HomeItemContainer(original: newData, items: finalList)
            results.append(.update(state: .normal(homeItem: homeItem), inserts: insert, deletes: delete, updates: update, moves: move))
        }
        return results
    }
}

public struct HomeListStateDiffer {
    
    private(set) var currentState: HomeListState
    private var differ: HomeViewListDiffer
    
    init(initialState: HomeListState, differ: HomeViewListDiffer) {
        currentState = initialState
        self.differ = differ
    }
    
    mutating func handle(newState: HomeListState) -> [HomeViewTransaction] {
        let oldState = currentState
        currentState = newState
        switch (oldState, newState) {
        case let (.normal(oldItems), .normal(newItems)):
            let diffResult = differ.handle(oldData: oldItems, newData: newItems)
            return diffResult
        default:
            return [.reload]
        }
    }
    
    mutating func reset(newState: HomeListState) {
        currentState = newState
    }
}
