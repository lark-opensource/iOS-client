//
//  V3ListData.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/23.
//

import Foundation
import Differentiator
import RxSwift
import RxCocoa
import LKCommonsLogging

// MARK: - Seaction Header

struct V3ListSectionHeaderData {
    var isFoldHidden: Bool = false
    var isFold: Bool = false
    // title single multi 这三个是互斥的
    var titleInfo: (icon: UIImage?, text: String)?
    var singleUser: (avatar: AvatarSeed, name: String)?
    var multiUsers: AvatarGroupViewData?
    var badgeCount: Int?
    var totalCount: Int?
    var hasMore: Bool = false
    var layoutInfo: V3ListSectionHeaderLayout?
    // 记录原始数据
    var users: [Assignee]?
    var dueTimeType: V3ListTimeGroup.DueTime?
    var startTimeType: V3ListTimeGroup.StartTime?
}

extension V3ListSectionHeaderData {

    func makeLayoutInfo() -> V3ListSectionHeaderLayout {
        var layout = V3ListSectionHeaderLayout()
        typealias Section = ListConfig.Section
        if let titleInfo = titleInfo {
            layout.titleWidth = CGFloat(ceil(titleInfo.text.size(withAttributes: [
                .font: Section.titleFont
            ]).width))
        }
        if let user = singleUser {
            let width = CGFloat(ceil(user.name.size(withAttributes: [
                .font: Section.mainFont
            ]).width))
            layout.userNameWidth = width
            layout.userWidth = Section.userLeftPadding + Section.userSize.width + Section.userSpace + width + Section.userRightPadding
        }
        if let total = totalCount {
            layout.totalCntWidth = CGFloat(ceil(String(total).size(withAttributes: [
                .font: Section.mainFont
            ]).width))
        }
        if let badge = badgeCount {
            layout.badgeWidth = CGFloat(ceil(String(badge).size(withAttributes: [
                .font: Section.badgeFont
            ]).width))
        }
        return layout
    }

}

struct V3ListSectionHeaderLayout {
    // title
    var titleWidth: CGFloat?
    // name
    var userNameWidth: CGFloat?
    // padding + avatar + space + name + right
    var userWidth: CGFloat?
    // total
    var totalCntWidth: CGFloat?
    // badge
    var badgeWidth: CGFloat?
}

extension V3ListSectionHeaderData {

    var preferredHeight: CGFloat {
        return ListConfig.Section.headerHeight
    }

}

// MARK: - Section Footer

struct V3ListSectionFooterData {
    // 是否显示Footer
    var isShow: Bool = false
    // 是否隐藏Footer内容
    var isHidden: Bool { !isShow }
    // 当分组折叠起来的时候，内容不需要展示，space一直要有
    var isFold: Bool = false
}

extension V3ListSectionFooterData {

    var preferredHeight: CGFloat {
        if isHidden || isFold {
            return ListConfig.Section.footerSpaceHeight
        }
        return ListConfig.Section.footerTitleHeight + ListConfig.Section.footerSpaceHeight
    }

}

// MARK: - Section

struct V3ListSectionData {
    var header: V3ListSectionHeaderData?
    var items = [V3ListCellData]()
    var footer = V3ListSectionFooterData()
    // 唯一标识，目前用于排序
    var sectionId: String = String(Utils.RichText.randomId())
    // 是否是自定义分组
    var isCustom: Bool = false
    // 是否是骨架图分组
    var isSkeleton: Bool = false
}

extension V3ListSectionData: AnimatableSectionModelType {

    typealias Identity = String
    typealias Item = V3ListCellData

    var identity: String { sectionId }

    init(original: V3ListSectionData, items: [V3ListCellData]) {
        self = original
        self.items = items
    }
}

extension V3ListSectionData {

    static func safeCheckIndexPath(at indexPath: IndexPath, with sections: [any AnimatableSectionModelType]) -> (section: Int, row: Int)? {
        return Utils.safeCheckIndexPath(at: indexPath, with: sections)
    }

    static func safeCheckSection<T>(in section: Int, with sections: [T]) -> Int? {
        return Utils.safeCheckSection(in: section, with: sections)
    }

    static func safeCheckRows<T>(_ indexPath: IndexPath, from items: [T]) -> Int? {
        return Utils.safeCheckRows(indexPath, from: items)
    }
}

// MARK: - List View Data

struct V3ListViewData {
    // 列表数据
    var data = [V3ListSectionData]()
    // 交互方式
    var transition: ListViewTransition = .reload
    // 刷新结束后的操作
    var afterTransition: ListAfterTransition = .none
    // 当值任务执行时长，一些UI任务执行时候不能被打断
    var duration: Double {
        if transition == .animated {
            return 0.25
        }
        return 0
    }
}

extension V3ListViewData {

    var isEmpty: Bool { data.isEmpty }
}

// MARK: - Queue

final class V3ListQueue {

    enum Scene: String {
    case reorder
    }

    // UI信号
    let rxUIData = BehaviorRelay<V3ListViewData?>(value: nil)
    /// 最新数据
    let rxLatestData = BehaviorRelay<V3ListViewData?>(value: nil)
    // 输出任务queue,本质是数组
    private lazy var outputList: [V3ListViewData] = []
    // log
    private static let logger = Logger.log(V3ListQueue.self, category: "V3List.Queue")

    /// 数据处理queue,本质是串行队列
    private lazy var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "V3TodoListDataQueueQueue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
        return queue
    }()

    var isBusy: Bool { queue.operationCount > 0 || !outputList.isEmpty }

    /// 暂停
    func pauseQueue(_ scene: V3ListQueue.Scene) {
        V3ListQueue.logger.info("pause queue from \(scene), cnt is: \(queue.operationCount) ")
        queue.isSuspended = true
    }

    /// 恢复
    func resumeQueue(_ scene: V3ListQueue.Scene) {
        V3ListQueue.logger.info("resume queue from \(scene), cnt is: \(queue.operationCount)")
        queue.isSuspended = false
        doFirstTask()
    }

    func addTask(_ task: @escaping () -> V3ListViewData?) {
        let t = { [weak self] in
            guard let self = self, let latest = task() else { return }
            self.rxLatestData.accept(latest)
            self.addToOutput(latest)
        }
        queue.addOperation(t)
    }

    private func addToOutput(_ task: V3ListViewData) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.outputList.append(task)
            self.doFirstTask()
        }
    }

    private func doFirstTask() {
        guard let task = outputList.first, !queue.isSuspended else {
            return
        }
        rxUIData.accept(task)
        V3ListQueue.logger.info("did post ui data: \(task.logInfo)")
        if task.duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + task.duration) { [weak self] in
                self?.doNextTask()
            }
        } else {
            doNextTask()
        }
    }

    private func doNextTask() {
        assert(Thread.isMainThread)
        if !outputList.isEmpty {
            outputList.removeFirst()
        }
        doFirstTask()
    }

}
