//
//  V3ListViewModel+Sort.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/29.
//

import Foundation

// MARK: - Sort

extension V3ListViewModel {

    func sortedItems(_ cellDatas: [V3ListCellData], type: FilterTab.SortingCollection?, refs: [String: String]?) -> [V3ListCellData] {
        let beginTime = CFAbsoluteTimeGetCurrent()
        defer {
            V3Home.logger.info("sorted items consume \(CFAbsoluteTimeGetCurrent() - beginTime), count: \(cellDatas.count), type: \(type)")
        }
        guard let type = type else {
            V3Home.assertionFailure()
            return cellDatas
        }
        guard !cellDatas.isEmpty else { return [] }
        return cellDatas
            .sorted(by: { [weak self] (cd0, cd1) in
                guard let self = self else { return true }
                switch type.field {
                case .custom: return customSorter(cd0, cd1, refs: refs)
                case .dueTime: return dueTime(cd0, cd1, self.curTimeContext.timeZone, type.isAscending)
                case .startTime: return startTime(cd0, cd1, self.curTimeContext.timeZone, type.isAscending)
                default: return time(cd0, cd1, type.field, type.isAscending)
                }
            })
    }

    /// 自定义排序
    private func customSorter(_ cd0: V3ListCellData, _ cd1: V3ListCellData, refs: [String: String]?) -> Bool {
        guard let refs = refs else {
            return true
        }
        let ref0 = refs[cd0.todo.guid], ref1 = refs[cd1.todo.guid]
        guard let ref0 = ref0, let ref1 = ref1 else {
            return true
        }
        return ref0 < ref1
    }

    private func startTime(_ cd0: V3ListCellData, _ cd1: V3ListCellData, _ timeZone: TimeZone, _ isAscending: Bool) -> Bool {
        switch (cd0.todo.isStartTimeValid, cd1.todo.isStartTimeValid) {
        case (false, false): return time(cd0, cd1, .createTime, false)
        case (false, true): return false
        case (true, false): return true
        case (true, true):
            let (startTime0, startTime1) = (cd0.todo.startTimeForDisplay(timeZone), cd1.todo.startTimeForDisplay(timeZone))
            if startTime0 == startTime1 {
                return time(cd0, cd1, .createTime, false)
            } else {
                return isAscending ? startTime0 < startTime1 : startTime0 > startTime1
            }
        }
    }

    /// 截止时间比较特殊
    private func dueTime(_ cd0: V3ListCellData, _ cd1: V3ListCellData, _ timeZone: TimeZone, _ isAscending: Bool) -> Bool {
        switch (cd0.todo.isDueTimeValid, cd1.todo.isDueTimeValid) {
        case (false, false): return time(cd0, cd1, .createTime, false)
        case (false, true): return false
        case (true, false): return true
        case (true, true):
            let (dueTime0, dueTime1) = (cd0.todo.dueTimeForDisplay(timeZone), cd1.todo.dueTimeForDisplay(timeZone))
            if dueTime0 == dueTime1 {
                return time(cd0, cd1, .createTime, false)
            } else {
                return isAscending ? dueTime0 < dueTime1 : dueTime0 > dueTime1
            }
        }
    }

    /// 创建时间、完成时间、更新时间
    private func time(_ cd0: V3ListCellData, _ cd1: V3ListCellData, _ type: FilterTab.SortingField, _ isAscending: Bool) -> Bool {
        var cd0T, cd1T: Int64
        switch type {
        case .completeTime:
            (cd0T, cd1T) = (cd0.userCompletedMilliTime, cd1.userCompletedMilliTime)
            if cd0T == cd1T {
                return time(cd0, cd1, .createTime, false)
            } else if cd0T > 0, cd1T > 0 {
                break
            } else {
                // 已完成要在未完成上面
                return cd0T > cd1T
            }
        case .createTime: (cd0T, cd1T) = (cd0.todo.createMilliTime, cd1.todo.createMilliTime)
        case .updateTime:
            (cd0T, cd1T) = (cd0.todo.updateMilliTime, cd1.todo.updateMilliTime)
            // 更新时间相同用创建时间排序
            if cd0T == cd1T {
                return time(cd0, cd1, .createTime, false)
            }
            // 更新时间为0的时候，需要按照创建时间来参与排序
            if cd0T == 0 {
                cd0T = cd0.todo.createMilliTime
            }
            if cd1T == 0 {
                cd1T = cd1.todo.createMilliTime
            }
        default: return true
        }
        if cd0T == cd1T {
            // 如果时间一样，则以 guid 排序，避免完成时间一致的情况下，数据排序不稳定
            return cd0.todo.guid < cd1.todo.guid
        }
        return isAscending ? cd0T < cd1T : cd0T > cd1T
    }
}
