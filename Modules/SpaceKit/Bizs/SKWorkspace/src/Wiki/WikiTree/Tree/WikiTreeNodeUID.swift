//
//  WikiTreeNodeUID.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2022/8/8.
//

import Foundation

public struct WikiTreeNodeUID {
    // 当前节点的 wiki token
    public let wikiToken: String
    // 当前节点所在的 section
    public let section: TreeNodeRootSection
    // 当前节点所经过的 shortcut token paths
    // 格式为 -Token1-Token2-Token3
    public let shortcutPath: String

    public let uniqueID: String

    // TODO: 是否需要记录 isShortcut
    public init(wikiToken: String, section: TreeNodeRootSection, shortcutPath: String) {
        self.wikiToken = wikiToken
        self.section = section
        self.shortcutPath = shortcutPath
        uniqueID = Self.generateUID(wikiToken: wikiToken, section: section, shortcutPath: shortcutPath)
    }

    public func extend(childToken: String, currentIsShortcut: Bool) -> WikiTreeNodeUID {
        var nextShortcutPath = shortcutPath
        if currentIsShortcut {
            nextShortcutPath += "-\(wikiToken)"
        }
        return WikiTreeNodeUID(wikiToken: childToken, section: section, shortcutPath: nextShortcutPath)
    }

    public static func generateUID(wikiToken: String, section: TreeNodeRootSection, shortcutPath: String) -> String {
        "\(wikiToken)-\(section.rawValue)\(shortcutPath)"
    }
}

extension WikiTreeNodeUID: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uniqueID)
    }
}

extension WikiTreeNodeUID: Equatable {
    public static func == (lhs: WikiTreeNodeUID, rhs: WikiTreeNodeUID) -> Bool {
        lhs.uniqueID == rhs.uniqueID
    }
}

extension WikiTreeNodeUID {
    static let empty: WikiTreeNodeUID = WikiTreeNodeUID(wikiToken: "", section: .mainRoot, shortcutPath: "")
}
