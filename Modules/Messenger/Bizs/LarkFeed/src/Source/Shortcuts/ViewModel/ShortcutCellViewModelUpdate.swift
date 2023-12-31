//
//  ShortcutViewModelUpdate.swift
//  LarkFeed
//
//  Created by bitingzhu on 2020/7/10.
//

import Foundation
import LKCommonsLogging

/// 置顶数据更新容器
final class ShortcutViewModelUpdate {
    /// 数据刷新方式
    enum DataReloadMode {
        /// 全量刷新
        case full
        /// 部分刷新
        case diffing(commandGenerator: CommandGenerator)
        /// 跳过刷新
        case skipped
    }

    /// 视图刷新命令
    enum ViewReloadCommand {
        /// 全量刷新
        case full
        /// 部分刷新
        case partial(changeset: Changeset)
        /// 无操作 （起名为none，if case 的时候会被编译器以为是系统的.none）
        case skipped

        /// 在没有更改时裁剪刷新命令
        func trimmed() -> ViewReloadCommand {
            switch self {
            case let .partial(changeset):
                // changeset中的操作为空则返回空刷新命令
                if changeset.reload.isEmpty && changeset.insert.isEmpty && changeset.delete.isEmpty {
                    FeedContext.log.info("feedlog/shortcut/dataflow/diff/trimmed/skip. .partial trimmed to .none (no change detected)")
                    return .skipped
                }
                return self
            default:
                return self
            }
        }
    }

    /// 快照差异容器
    struct Changeset {
        let reload: [IndexPath]
        let insert: [IndexPath]
        let delete: [IndexPath]

        /// 约束diff的最大下标
        func withUpperBound(_ maxIndex: Int) -> Changeset {
            Changeset(
                reload: reload.filter { $0.item < maxIndex },
                insert: insert.filter { $0.item < maxIndex },
                delete: delete.filter { $0.item < maxIndex }
            )
        }
    }
    /// 数据刷新命令生成器类型：传入可选数据参数、生成刷新命令
    typealias CommandGenerator = (
        _ formerSnapshot: [ShortcutCellViewModel]?,
        _ formerVisibleCount: Int?,
        _ currentVisibleCount: Int?
        ) -> ViewReloadCommand

    /// 数据快照
    let snapshot: [ShortcutCellViewModel]
    /// 预期的collectionView reload方式
    private let dataReloadMode: DataReloadMode
    /// 最终生成的具体刷新命令, 默认为空, 外部需通过调用generateReloadCommand来生成刷新方式所对应的刷新命令
    private(set) var viewReloadCommand: ViewReloadCommand?

    /// 私有初始化
    private init(snapshot: [ShortcutCellViewModel], dataReloadMode: DataReloadMode) {
        self.snapshot = snapshot
        self.dataReloadMode = dataReloadMode
    }

    /// 创建全量刷新的容器
    static func full(_ snapshot: [ShortcutCellViewModel]) -> ShortcutViewModelUpdate {
        ShortcutViewModelUpdate(snapshot: snapshot, dataReloadMode: .full)
    }

    /// 创建包含最新快照但不触发刷新的容器
    static func skipped(_ snapshot: [ShortcutCellViewModel]) -> ShortcutViewModelUpdate {
        ShortcutViewModelUpdate(snapshot: snapshot, dataReloadMode: .skipped)
    }

    /// 创建自动计算diff的容器
    static func autoDiffing(_ currentSnapshot: [ShortcutCellViewModel]) -> ShortcutViewModelUpdate {
        ShortcutViewModelUpdate(snapshot: currentSnapshot,
             dataReloadMode: .diffing(commandGenerator: { Self.computeReloadCommandByDiffing(formerSnapshot: $0,
                                                                                         formerVisibleCount: $1,
                                                                                         currentSnapshot: currentSnapshot,
                                                                                         currentVisibleCount: $2) }))
    }

    /// 创建手动指定changeset的容器
    static func manualDiffing(snapshot: [ShortcutCellViewModel], changeset: Changeset) -> ShortcutViewModelUpdate {
        ShortcutViewModelUpdate(snapshot: snapshot, dataReloadMode: .diffing(commandGenerator: { _, formerVisibleCount, currentVisibleCount in
            guard let formerVisibleCount = formerVisibleCount,
                let currentVisibleCount = currentVisibleCount else { return .full }
            return ViewReloadCommand.partial(changeset: changeset.withUpperBound(max(formerVisibleCount, currentVisibleCount))).trimmed()
        }))
    }

    /// 初始化空容器
    static func empty() -> ShortcutViewModelUpdate {
        ShortcutViewModelUpdate(snapshot: [], dataReloadMode: .skipped)
    }

    /// 计算diff
    private static func computeReloadCommandByDiffing(formerSnapshot: [ShortcutCellViewModel]?,
                                                      formerVisibleCount: Int?,
                                                      currentSnapshot: [ShortcutCellViewModel],
                                                      currentVisibleCount: Int?) -> ViewReloadCommand {
        // 若无法获取之前的快照，则进行全量刷新
        guard let formerSnapshot = formerSnapshot,
            let formerVisibleCount = formerVisibleCount,
            let currentVisibleCount = currentVisibleCount else {
            FeedContext.log.info("feedlog/shortcut/dataflow/diff/auto/precheck/full. data not sufficient")
            return .full
        }

        var reloadSet: [Int] = []
        var insertSet: [Int] = []
        var deleteSet: [Int] = []

        // 重合区间diff计算
        // Naive Method
        let commonVisibleCount = min(formerVisibleCount, currentVisibleCount)
        for i in 0..<commonVisibleCount {
            if !ShortcutCellViewModel.isEquivalentTo(lhs: formerSnapshot[i], rhs: currentSnapshot[i]) {
                reloadSet.append(i)
            }
        }

        // 尾部区间diff计算
        if formerVisibleCount > currentVisibleCount {
            deleteSet.append(contentsOf: commonVisibleCount..<formerVisibleCount)
        } else if formerVisibleCount < currentVisibleCount {
            insertSet.append(contentsOf: commonVisibleCount..<currentVisibleCount)
        }

        FeedContext.log.info("feedlog/shortcut/dataflow/diff/audo/preResult/partial. reload count: \(reloadSet.count), insert count: \(insertSet.count), delete count: \(deleteSet.count)")
        return ViewReloadCommand.partial(changeset: Changeset(
                reload: convertIntToIndexPath(reloadSet),
                insert: convertIntToIndexPath(insertSet),
                delete: convertIntToIndexPath(deleteSet)
            )).trimmed()
    }

    /// 将Int数组转为IndexPath数组
    static func convertIntToIndexPath(_ ints: [Int]) -> [IndexPath] {
        ints.map { IndexPath(item: $0, section: 0) }
    }

    /// 根据刷新模式和具体数据生成具体刷新命令
    func generateReloadCommand(formerSnapshot: [ShortcutCellViewModel]? = nil,
                              formerVisibleCount: Int? = nil,
                              currentVisibleCount: Int? = nil) {
        switch dataReloadMode {
        case .full:
            viewReloadCommand = .full
        case .skipped:
            viewReloadCommand = ViewReloadCommand.skipped
        case let .diffing(commandGenerator):
            viewReloadCommand = commandGenerator(formerSnapshot, formerVisibleCount, currentVisibleCount)
        }
    }

    /// 指定空刷新命令
    func setEmptyReloadCommand() {
        viewReloadCommand = ViewReloadCommand.skipped
    }
}
