//
//  DetailDependentListViewModel.swift
//  Todo
//
//  Created by wangwanxin on 2023/7/17.
//

import Foundation
import LarkContainer

final class DetailDependentListViewModel: UserResolverWrapper {
    let userResolver: LarkContainer.UserResolver
    let originalTodos: [Rust.Todo]
    let canEdit: Bool
    let type: Rust.TaskDependent.TypeEnum

    var cellDatas: [DetailDependentListCellData] = []
    var onListUpdate: (() -> Void)?
    var title: String {
        if type == .prev {
            return I18N.Todo_Tasks_BlockedBy_Title
        }
        return I18N.Todo_Tasks_Blocking_Title
    }

    @ScopedInjectedLazy var completeService: CompleteService?
    @ScopedInjectedLazy var timeService: TimeService?
    @ScopedInjectedLazy var richContentService: RichContentService?

    // 时间格式化上下文
    private var curTimeContext: TimeContext {
        return TimeContext(
            currentTime: Int64(Date().timeIntervalSince1970),
            timeZone: timeService?.rxTimeZone.value ?? .current,
            is12HourStyle: timeService?.rx12HourStyle.value ?? false
        )
    }

    init(resolver: UserResolver, dependents: [Rust.Todo], type: Rust.TaskDependent.TypeEnum, canEdit: Bool) {
        self.userResolver = resolver
        self.originalTodos = dependents
        self.canEdit = canEdit
        self.type = type
        self.cellDatas = self.makeListCellData(dependents)
    }


    private func makeListCellData(_ todos: [Rust.Todo]) -> [DetailDependentListCellData] {
        let timeContext = curTimeContext
        return todos
            .map { todo in
                let completeState = completeService?.state(for: todo) ?? .outsider(isCompleted: false)
                var cellData = DetailDependentListCellData(with: todo, completeState: completeState)
                var contentData = V3ListContentData(
                    todo: todo,
                    isTaskEditableInContainer: false,
                    completeState: (completeState, true),
                    richContentService: richContentService,
                    timeContext: timeContext
                )
                // 这种场景不需要显示extensionInfo
                contentData.extensionInfo = nil
                cellData.contentType = .content(data: contentData)
                cellData.showRemoveBtn = canEdit
                return cellData
            }
    }

    func safeCheckRows(_ indexPath: IndexPath) -> Int? {
        return V3ListSectionData.safeCheckRows(indexPath, from: cellDatas)
    }

    func removeItem(at indexPath: IndexPath) -> String? {
        guard let row = safeCheckRows(indexPath) else {
            return nil
        }
        V3Home.logger.info("did remove item at \(row)")
        let removedGuid = cellDatas[row].todo.guid
        cellDatas.remove(at: row)
        onListUpdate?()
        return removedGuid
    }

    func itemGuid(at indexPath: IndexPath) -> String? {
        guard let row = safeCheckRows(indexPath) else {
            return nil
        }
        return cellDatas[row].todo.guid
    }
}
