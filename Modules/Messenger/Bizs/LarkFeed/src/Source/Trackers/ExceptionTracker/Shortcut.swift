//
//  Shortcut.swift
//  LarkFeed
//
//  Created by liuxianyu on 2023/11/14.
//

extension FeedExceptionTracker {
    enum FeedShortcutSubModule: String {
        case tap
        case dataflow
    }

    enum FeedShortcutNode: String {
        case pushDocsController
    }

    struct Shortcut {
        static func tap(node: FeedShortcutNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .tap, node: node, info: info)
        }

        static func dataflow(node: FeedShortcutNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .dataflow, node: node, info: info)
        }

        private static func post(subModule: FeedShortcutSubModule, node: FeedShortcutNode, info: FeedBaseErrorInfo) {
            FeedExceptionTracker.post(moduleName: FeedModuleType.shortcut.rawValue,
                                      subModuleName: subModule.rawValue,
                                      nodeName: node.rawValue,
                                      info: info)
        }
    }
}
