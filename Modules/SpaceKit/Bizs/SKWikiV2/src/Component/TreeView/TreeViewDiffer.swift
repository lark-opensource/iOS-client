//
//  TreeViewDiffer.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/7/28.
//

import Foundation
import RxDataSources
import SKWorkspace

enum TreeViewTransaction {
    case reload
    case update(changeSets: [Changeset<NodeSection>])
}

struct TreeViewListDiffer {

    private(set) var currentList: [NodeSection]

    init(currentList: [NodeSection] = []) {
        self.currentList = currentList
    }

    mutating func reset(newList: [NodeSection]) {
        currentList = newList
    }

    mutating func handle(newList: [NodeSection]) -> TreeViewTransaction {
        let oldList = currentList
        currentList = newList
        do {
            let differences = try Diff.differencesForSectionedView(initialSections: oldList, finalSections: newList)
            return .update(changeSets: differences)
        } catch {
            return .reload
        }
    }
}
