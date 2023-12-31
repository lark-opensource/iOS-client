//
//  Utils.swift
//  Todo
//
//  Created by 张威 on 2020/11/19.
//

import LarkUIKit
import LarkSetting
import LarkDowngrade
import Differentiator

struct Utils { }

extension Utils {

    static func getJson<T>(source: T) -> String? where T: Encodable {
        var result: String?
        do {
            let data = try JSONEncoder().encode(source)
            result = String(data: data, encoding: .utf8)!
        } catch {
            Detail.logger.info("getJson failed \(error)")
        }
        return result
    }

}

extension Utils {
    struct ConfigKeys {
        static let helpCenter = "help_key_todo"
    }
    struct KVKey {
        static let guideInChat = "guide_in_chat_displayed"

        static let sendToChat = "task_detail_send_to_chat"

        static let tasklistViewInCenter = "center_task_list_key"
    }
}

extension Utils {
    struct List {
        // 列表中一个屏幕的item的数量
        static let oneSceenItemCnt: Int = Display.pad ? 20 : 10
        /// 分页数据拉取数量：初始拉取 50，loadMore 每次追加 20
        static let fetchCount = (initial: 30, loadMore: 20)
    }
    struct Pop {
        static let preferredContentWidth: CGFloat = 250
    }

    struct Logger {
        static let limmit = 50
    }
}

extension Utils {
    struct Applink {
        /// https://bytedance.feishu.cn/wiki/wikcnWUM6b8Or3fg6ZOhVrKmARb
        static func taskListApplink(with containerID: String) -> String? {
            guard !containerID.isEmpty else { return nil }
            let settings = DomainSettingManager.shared.currentSetting
            guard let host = settings["applink"]?.first else {
                return nil
            }
            return "https://\(host)/client/todo/task_list?guid=\(containerID)"
        }
    }
}

extension Utils {

    struct DeviceStatus {
        // 是否是低端机
        var isLowDevice: Bool {
            var isLowDevice = false
            // 这是一个同步方法
            LarkDowngradeService.shared.Downgrade(
                key: "todoTabData",
                indexes:[.lowDevice]) { _ in
                    //低端机的一些处理
                    isLowDevice = true
                } doNormal: { _ in
                    isLowDevice = false
                }
            return isLowDevice
        }
    }

    static func safeCheckIndexPath(at indexPath: IndexPath, with sections: [any AnimatableSectionModelType]) -> (section: Int, row: Int)? {
        guard let section = Self.safeCheckSection(in: indexPath.section, with: sections) else { return nil }
        guard !sections[section].items.isEmpty else {
            return nil
        }
        let row = indexPath.row
        guard row >= 0 && row < sections[section].items.count else {
            return nil
        }
        return (section, row)
    }

    static func safeCheckSection<T>(in section: Int, with sections: [T]) -> Int? {
        guard !sections.isEmpty else { return nil }
        guard section >= 0 && section < sections.count else {
            return nil
        }
        return section
    }

    static func safeCheckRows<T>(_ indexPath: IndexPath, from items: [T]) -> Int? {
        guard !items.isEmpty else { return nil }
        let row = indexPath.row
        guard row >= 0 && row < items.count else { return nil }
        return row
    }
}
