//
//  Setting.swift
//  LarkFeed
//
//  Created by liuxianyu on 2023/11/14.
//

extension FeedExceptionTracker {
    enum FeedSettingSubModule: String {
        case fg
        case cloudSetting
    }

    enum FeedSettingNode: String {
        case fgToRust
        case getSettingJson
    }

    struct Setting {
        static func fg(node: FeedSettingNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .fg, node: node, info: info)
        }

        static func cloudSetting(node: FeedSettingNode, info: FeedBaseErrorInfo) {
            Self.post(subModule: .cloudSetting, node: node, info: info)
        }

        private static func post(subModule: FeedSettingSubModule, node: FeedSettingNode, info: FeedBaseErrorInfo) {
            FeedExceptionTracker.post(moduleName: FeedModuleType.setting.rawValue,
                                      subModuleName: subModule.rawValue,
                                      nodeName: node.rawValue,
                                      info: info)
        }
    }
}
