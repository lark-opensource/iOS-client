//
//  HomeSidebarViewData.swift
//  Todo
//
//  Created by wangwanxin on 2023/10/13.
//

import Foundation
import UniverseDesignIcon
import Differentiator
import LarkDocsIcon
import LarkContainer

final class HomeSidebarMetaData {

    // 我负责的+我关注的+全部+我创建的等，key是containerGuid
    private var defaultContainerMetaData = [String: Rust.ContainerMetaData]()
    // 分组, key是sectionGuid
    private var tasklistSections = [String: Rust.TaskListSection]()
    // 分组数据: key是containerGuid
    private var tasklistSectionItems = [String: Rust.TaskListSectionItem]()
    // 分组折叠状态
    private var sectionCollapsed = [String: Bool]()

    private let semaphore: DispatchSemaphore
    init(with res: Rust.TaskCenterResponse) {
        semaphore = DispatchSemaphore(value: 0)
        semaphore.signal()
        makeCacheData(res)
    }

    private func makeCacheData(_ res: Rust.TaskCenterResponse) {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        // meta data
        let metaDatas = res.containers.compactMap { container in
            var metaData = Rust.ContainerMetaData()
            metaData.container = container
            metaData.views = res.views.filter({ $0.containerGuid == container.guid })
            metaData.sections = res.sections.filter({ $0.containerID == container.guid })
            return (container.guid, metaData)
        }
        defaultContainerMetaData = Dictionary(metaDatas, uniquingKeysWith: { $1 })

        // sections
        let sections = res.taskContainerSections.map { section in
            return (section.guid, section)
        }
        tasklistSections = Dictionary(sections, uniquingKeysWith: { $1 })

        // sectionItems
        let items = res.containerSectionItems.map { item in
            return (item.guid, item)
        }
        tasklistSectionItems = Dictionary(items, uniquingKeysWith: { $1 })
    }

    private func makeDefaultContainerMetaData(_ res: Rust.TaskCenterResponse) {
        semaphore.wait()
        defer {
            semaphore.signal()
        }

        let metaDatas = res.containers.compactMap { container in
            var metaData = Rust.ContainerMetaData()
            metaData.container = container
            metaData.views = res.views.filter({ $0.containerGuid == container.guid })
            metaData.sections = res.sections.filter({ $0.containerID == container.guid })
            return (container.guid, metaData)
        }
        defaultContainerMetaData = Dictionary(metaDatas, uniquingKeysWith: { $1 })
    }

    func updateDefaultMetaDataView(_ newView: Rust.TaskView, in containerGuid: String) {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        guard let metaData = defaultContainerMetaData[containerGuid] else {
            return
        }
        defaultContainerMetaData[containerGuid] = Self.replaceView(newView, in: metaData)
    }

    static func replaceView(_ newView: Rust.TaskView, in metaData: Rust.ContainerMetaData) -> Rust.ContainerMetaData {
        var newMetaData = metaData
        var views = newMetaData.views
        if let index = views.firstIndex(where: { $0.guid == newView.guid }) {
            views[index] = newView
        }
        newMetaData.views = views
        return newMetaData
    }

    func updateTasklistSection(_ sections: [Rust.TaskListSection]) {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        guard !sections.isEmpty else { return }
        sections.forEach { newSection in
            if let oldSection = tasklistSections[newSection.guid] {
                if newSection.deleteMilliTime > 0 {
                    // delete
                    tasklistSections.removeValue(forKey: newSection.guid)
                } else if newSection.version >= oldSection.version {
                    // update
                    tasklistSections.updateValue(newSection, forKey: newSection.guid)
                }
            } else {
                // add
                if newSection.deleteMilliTime == 0 {
                    tasklistSections[newSection.guid] = newSection
                }
            }
        }
    }

    func updateTasklistContainer(_ containers: [Rust.TaskContainer]) {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        guard !containers.isEmpty else { return }
        containers.forEach { newContainer in
            if let oldContainerItem = tasklistSectionItems[newContainer.guid] {
                if newContainer.isDeleted {
                    // 删除
                    tasklistSectionItems.removeValue(forKey: newContainer.guid)
                } else if newContainer.version >= oldContainerItem.container.version {
                    // update
                    let oldItem = tasklistSectionItems[newContainer.guid]
                    if var newOldItem = oldItem, newContainer.version >= newOldItem.container.version {
                        newOldItem.container = newContainer
                        tasklistSectionItems.updateValue(newOldItem, forKey: newContainer.guid)
                    }
                }
            } else {
                if !newContainer.isDeleted {
                    var newItem = Rust.TaskListSectionItem()
                    newItem.container = newContainer
                    tasklistSectionItems[newContainer.guid] = newItem
                }
            }
        }
    }

    func updateTasklistSectionItem(_ items: [Rust.TaskListSectionItem]) {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        guard !items.isEmpty else { return }
        items.forEach { newItem in
            if let oldItem = tasklistSectionItems[newItem.guid] {
                var new = newItem
                new.refs = mergeTaskListRefs(newItem.refs, and: oldItem.refs)
                tasklistSectionItems[newItem.guid] = new
            } else {
                // add
                tasklistSectionItems[newItem.guid] = newItem
            }
        }
    }

    private func mergeTaskListRefs(_ newRefs: [Rust.TaskListSectionRef], and oldRefs: [Rust.TaskListSectionRef]) -> [Rust.TaskListSectionRef] {
        var mergedRefs = oldRefs
        newRefs.forEach { newRef in
            if let index = mergedRefs.firstIndex(where: { $0.containerGuid == newRef.containerGuid && $0.sectionGuid == newRef.sectionGuid }) {
                if newRef.version > mergedRefs[index].version {
                    mergedRefs.append(newRef)
                    mergedRefs.remove(at: index)
                }
            } else {
                mergedRefs.append(newRef)
            }
        }
        return mergedRefs
    }

    // 无序的数据
    func getTasklistData() -> ([Rust.TaskListSection]?, [Rust.TaskListSectionItem]?) {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        let validItems = tasklistSectionItems.filter { (_, value) in
            return value.container.isValid
        }
        return (Array(tasklistSections.values), Array(validItems.values))
    }

    func getTaskListItem(_ guid: String) -> Rust.TaskListSectionItem? {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        return tasklistSectionItems[guid]
    }

    func getDefaultMetaData(by key: ContainerKey) -> Rust.ContainerMetaData? {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        return defaultContainerMetaData.values.first(where: { $0.container.key == key.rawValue })
    }

    func getDefaultMetaData(by guid: String) -> Rust.ContainerMetaData? {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        return defaultContainerMetaData[guid]
    }

    func setSection(_ sectionGuid: String, isCollapsed: Bool) {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        sectionCollapsed[sectionGuid] = isCollapsed
    }

    func getCollapsed(_ sectionGuid: String) -> Bool {
        semaphore.wait()
        defer {
            semaphore.signal()
        }
        return sectionCollapsed[sectionGuid] ?? false
    }

}

extension Rust.TaskListSectionItem {
    var guid: String { container.guid }

    func validRef(by sectionGuid: String) -> Rust.TaskListSectionRef? {
        return refs.first(where: { !$0.isDeleted && $0.sectionGuid == sectionGuid &&  $0.containerGuid == guid })
    }
}

struct HomeSidebarSectionData {
    var items = [HomeSidebarItemData]()
    var header = HomeSidebarHeaderData()
    var footer = HomeSidebarFooterData()
}

extension HomeSidebarSectionData: AnimatableSectionModelType {

    typealias Identity = String

    var identity: String { header.identifier }

    init(original: HomeSidebarSectionData, items: [HomeSidebarItemData]) {
        self = original
        self.items = items
    }
}

extension HomeSidebarItemData: DiffableType, Equatable {

    var diffId: String { identifier }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.diffId == rhs.diffId
    }

}

struct HomeSidebarItemData {
    enum AccessoryType {
        case none
        case count(String)
        case icon(archived: UIImage?, more: UIImage)
    }

    enum Category {
        // 快速访问 + 清单。
        enum SubItemType {
            //快速访问
            case simple
            // 非默认分组
            case inSection(ref: Rust.TaskListSectionRef, isLastItem: Bool)
            // 默认分组
            case withoutSection(ref: Rust.TaskListSectionRef)

            var isLastItemInSection: Bool {
                if case .inSection(_, let isLastItem) = self {
                    return isLastItem
                }
                return false
            }
        }

        // 我负责的，我关注的
        case normal

        case subItem(SubItemType)

        static func tailingIcon(_ isArchived: Bool) -> UIImage {
            let type: UDIconType = isArchived ? .massageBoxOutOutlined : .moreOutlined
            let color = isArchived ? UIColor.ud.iconN3 : UIColor.ud.iconN2
            return UDIcon.getIconByKey(
                type,
                iconColor: color,
                size: HomeSidebarItemData.Config.accessoryIconSize)
        }

        var isTaskListItem: Bool {
            if case .subItem(let type) = self {
                switch type {
                case .inSection, .withoutSection: return true
                default: return false
                }
            }
            return false
        } 

        var ref: Rust.TaskListSectionRef? {
            if case .subItem(let type) = self {
                switch type {
                case .simple: return nil
                case .inSection(let ref, _):
                    return ref
                case .withoutSection(let ref):
                    return ref
                }
            }
            return nil
        }
    }

    // 唯一标识
    var identifier: String
    // 类型
    var category: Category = .normal
    // 头部icon
    var leadingIconBuilder: LarkDocsIcon.IconBuilder?

    var userResolver: LarkContainer.UserResolver?

    var isDefaultIcon: Bool = false

    //标题
    var title: String
    // 尾部
    var accessory: AccessoryType?

    var isSelected: Bool = false

    var backgroundColor: UIColor = UIColor.ud.bgBody

    struct Config {
        static let activityGuid = UUID().uuidString
        static let leadingIconSize = CGSize(width: 20, height: 20)
        static let accessoryIconSize = CGSize(width: 16, height: 16)
        static let normalHeight = 48.0
        static let subItemHeight = 44.0
        static let hPadding = 16.0
        static let cornerRadius = 8.0

    }
}

extension HomeSidebarItemData {

    var preferredHeight: CGFloat {
        switch category {
        case .subItem(let type):
            if type.isLastItemInSection {
                return Config.normalHeight
            }
            return  Config.subItemHeight
        default: return Config.normalHeight
        }
    }
    
}

struct HomeSidebarHeaderData {

    enum Category {
        case none
        case savedSearch
        case taskLists
        case section(Rust.TaskListSection)
        case add

        var leadingIcon: UIImage? {
            switch self {
            case .savedSearch, .section: return getLeadingIcon(.expandDownFilled, isSmallSize: true)
            case .taskLists: return getLeadingIcon(.tasklistOutlined, isSmallSize: false)
            case .add: return getLeadingIcon(.addOutlined, isSmallSize: false)
            default: return nil
            }
        }

        var tailingIcon: UIImage? {
            switch self {
            case .section: return getTailingIcon(.moreOutlined, isSmallSize: true)
            case .taskLists: return getTailingIcon(.addOutlined, isSmallSize: false)
            default: return nil
            }
        }

        var hasDividingLine: Bool {
            switch self {
            case .savedSearch, .taskLists: return true
            default: return false
            }
        }

        var isSection: Bool {
            if case .section = self {
                return true
            }
            return false
        }

        var isTaskLists: Bool {
            if case .taskLists = self {
                return true
            }
            return false
        }

        var isAdd: Bool {
            if case .add = self {
                return true
            }
            return false
        }

        private func getLeadingIcon(_ key: UDIconType, isSmallSize: Bool) -> UIImage {
            return UDIcon.getIconByKey(
                key,
                iconColor: UIColor.ud.iconN2,
                size: isSmallSize ? HomeSidebarHeaderData.Config.leadingArrorIconSize : HomeSidebarHeaderData.Config.leadingViewSize)
        }

        private func getTailingIcon(_ key: UDIconType, isSmallSize: Bool) -> UIImage {
            return UDIcon.getIconByKey(
                key,
                iconColor: UIColor.ud.iconN2,
                size: isSmallSize ? HomeSidebarHeaderData.Config.sectionTailingIconSize : HomeSidebarHeaderData.Config.leadingViewSize)
        }
    }

    // 唯一标识
    var identifier: String = UUID().uuidString
    // none的时候header不显示
    var category: Category = .none

    var leadingIcon: UIImage?

    var title: String = ""

    var tailingIcon: UIImage?
    // 选中
    var isSelected: Bool = false
    // 折叠
    var isCollapsed: Bool = false

    struct Config {
        static let leadingViewSize = CGSize(width: 20, height: 20)
        static let tailingViewSize = CGSize(width: 20, height: 20)
        static let sectionTailingIconSize = CGSize(width: 16, height: 16)
        static let leadingArrorIconSize = CGSize(width: 12, height: 12)
        static let dividingLineHeight = 1.0
        static let contentHeight = 48.0
        static let vSpace = 6.0
        static let taskListsGuid = UUID().uuidString
        static let addSectionGuid = UUID().uuidString
    }

}

extension HomeSidebarHeaderData {

    var preferredHeight: CGFloat {
        guard !isHidden else { return .zero }
        if category.hasDividingLine {
            return Config.dividingLineHeight + Config.vSpace + Config.contentHeight
        }
        return Config.contentHeight
    }

    var isHidden: Bool {
        switch category {
        case .none: return true
        case .section(let section): return section.isDefault
        default: return false
        }
    }

    var sectionRawData: Rust.TaskListSection? {
        if case .section(let sectionData) = category {
            return sectionData
        }
        return nil
    }
}

extension HomeSidebarSectionData {

    static var containerKeyToIcon: [String: UIImage] {
        [
            ContainerKey.owned.rawValue: UDIcon.memberOutlined.ud.withTintColor(UIColor.ud.iconN2),
            ContainerKey.followed.rawValue: UDIcon.subscribeAddOutlined.ud.withTintColor(UIColor.ud.iconN2)
        ]
    }

    /// 自定义分组排序规则：category 为section, 按照rank 排序
    static func customSectionSorter(_ left: HomeSidebarSectionData, _ right: HomeSidebarSectionData) -> Bool {
        guard let leftSection = left.header.sectionRawData, let rightSection = right.header.sectionRawData else {
            return false
        }
        return leftSection.rank < rightSection.rank
    }

}

struct HomeSidebarFooterData {

    var preferredHeight: CGFloat {
        if isHidden { return .zero }
        return Config.height
    }

    var isHidden: Bool = false

    struct Config {
        static let height = 6.0
    }
}

extension SideBarItem.CustomCategory {

    var logInfo: String {
        switch self {
        case .none: return "none"
        case .activity: return "activity"
        case .taskLists(let tab, let isArchived):
            return "tap \(tab.rawValue), isArchived \(isArchived)"
        }
    }

    var title: String? {
        switch self {
        case .none: return nil
        case .activity: return I18N.Todo_Updates_Title
        case .taskLists(_, let isArchived):
            return isArchived ? I18N.Todo_TaskListPage_Archived_Option : I18N.Todo_TaskListPage_TaskLists_Title
        }
    }
}
