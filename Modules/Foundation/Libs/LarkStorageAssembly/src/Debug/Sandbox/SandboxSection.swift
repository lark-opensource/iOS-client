//
//  SandboxSection.swift
//  LarkStorageAssembly
//
//  Created by 李昊哲 on 2022/11/21.
//

#if !LARK_NO_DEBUG
import Foundation
import LarkStorage

struct SandboxItem: TitledItem, Hashable {
    var domain: String
    var roots: [RootPathType.Normal]

    var title: String {
        get { domain }
        set { domain = newValue }
    }

    func hash(into hasher: inout Hasher) {
        domain.hash(into: &hasher)
    }
}

struct SandboxSection: TitledSectionType {
    typealias Item = SandboxItem

    let space: String
    var items: [Item]

    let isCurrentUser: Bool
    var title: String { space }

    init(space: String, items: [Item]) {
        self.space = space
        self.items = items
        self.isCurrentUser = checkCurrentUser(space: space)
    }
}

extension SandboxSection {
    init(original: SandboxSection, items: [Item]) {
        self = original
        self.items = items
    }
}
#endif
