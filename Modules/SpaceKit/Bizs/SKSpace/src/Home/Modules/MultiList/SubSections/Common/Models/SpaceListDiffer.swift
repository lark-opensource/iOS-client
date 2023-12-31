//
//  SpaceListDiffer.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/9.
//

import Foundation
import RxDataSources
import SKFoundation
import SKCommon

enum SpaceListDiffResult<T> {
    case none(list: [T])
    case reload(list: [T])
    case update(list: [T], inserts: [Int], deletes: [Int], updates: [Int], moves: [(from: Int, to: Int)])
}

enum SpaceListTransaction<T> {
    case updateList(diffResults: [SpaceListDiffResult<T>])
    case displayListAfterLoading
    case displayListFromSpecialState
    case changeSpecialState
}

//class SpaceListPlaceHolderDiffer<T> {
//    func handle(currentList: [T], newList: [T]) -> [SpaceListDiffResult<T>] {
//        [.reload(list: newList)]
//    }
//}

class SpaceListStandardDiffer<T: IdentifiableType & Equatable> {
    func handle(currentList: [T], newList: [T]) -> [SpaceListDiffResult<T>] {
        let initialContainer = SpaceListItemContainer(items: currentList, identity: "item-list")
        let finalContainer = SpaceListItemContainer(items: newList, identity: "item-list")
        do {
            let differents = try Diff.differencesForSectionedView(initialSections: [initialContainer], finalSections: [finalContainer])
            let results = handle(list: newList, diffResults: differents)
            return results
        } catch {
            DocsLogger.debug("space.list.standard.differ --- diff failed with error", error: error)
            return [.reload(list: newList)]
        }
    }

    private func handle(list: [T], diffResults: [Changeset<SpaceListItemContainer<T>>]) -> [SpaceListDiffResult<T>] {
        var results: [SpaceListDiffResult<T>] = []
        for diff in diffResults {
            let insert = diff.insertedItems.map(\.itemIndex)
            let delete = diff.deletedItems.map(\.itemIndex)
            let update = diff.updatedItems.map(\.itemIndex)
            let move = diff.movedItems.map { ($0.itemIndex, $1.itemIndex) }
            guard let finalList = diff.finalSections.first?.items else {
                return [.reload(list: list)]
            }
            results.append(.update(list: finalList, inserts: insert, deletes: delete, updates: update, moves: move))
        }
        return results
    }
}

extension SpaceListItemType: IdentifiableType {
    var identity: String {
        switch self {
        case .gridPlaceHolder:
            return "grid-placeholder"
        case .inlineSectionSeperator:
            return "inline-section-seperator"
        case let .driveUpload(statusItem):
            return statusItem.uniqueID
        case let .spaceItem(item):
            return item.itemID
        }
    }
}

protocol SpaceListItemTypeDiffer {
    typealias Item = SpaceListItemType
    func handle(currentList: [Item], newList: [Item]) -> [SpaceListDiffResult<Item>]
}

private class SpaceListItemTypeStandardDiffer: SpaceListStandardDiffer<SpaceListItemType>, SpaceListItemTypeDiffer {}

private struct SpaceListItemContainer<T: IdentifiableType & Equatable>: AnimatableSectionModelType {
    let items: [T]
    let identity: String

    init(items: [T], identity: String) {
        self.items = items
        self.identity = identity
    }

    init(original: SpaceListItemContainer<T>, items: [T]) {
        identity = original.identity
        self.items = items
    }
}

enum SpaceListDifferFactory {
    static func createListStateDiffer() -> SpaceListStateDiffer {
        let differ = SpaceListItemTypeStandardDiffer()
        return SpaceListStateDiffer(initialState: .loading, differ: differ)
    }
}

class SpaceListStateDiffer {
    typealias State = SpaceListSubSection.ListState
    typealias Item = SpaceListItemType

    private var currentState: State
    private let differ: SpaceListItemTypeDiffer
    init(initialState: State, differ: SpaceListItemTypeDiffer) {
        currentState = initialState
        self.differ = differ
    }

    func handle(newState: State) -> SpaceListTransaction<Item> {
        let oldState = currentState
        currentState = newState
        switch (oldState, newState) {
        case let (.normal(oldItems), .normal(newItems)):
            let diffResults = differ.handle(currentList: oldItems, newList: newItems)
            return .updateList(diffResults: diffResults)
        case (.loading, .normal):
            return .displayListAfterLoading
        case (_, .normal):
            return .displayListFromSpecialState
        default:
            return .changeSpecialState
        }
    }
}
