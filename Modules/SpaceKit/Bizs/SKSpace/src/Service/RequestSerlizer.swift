//
//  RequestSerlizer.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/5/31.
//  

import Foundation
import SwiftyJSON
import SKFoundation
import SKCommon

public final class LocalSortAndFilterUtility {

    public class func sortList(_ list: [SpaceEntry], by sortType: SortItem.SortType, isUp: Bool) -> [SpaceEntry] {
            let sortedList = list.sorted(by: { (first, sec) -> Bool in
                switch sortType {
                case .updateTime:
                    return compare((first.editTime ?? 0), (sec.editTime ?? 0), isUp: isUp)
                case .createTime:
                    return compare((first.createTime ?? 0), (sec.createTime ?? 0), isUp: isUp)
                case .letestCreated:
                    return compare((first.createTime ?? 0), (sec.createTime ?? 0), isUp: false)
                case .owner:
                    return compare((first.owner ?? ""), (sec.owner ?? ""), isUp: isUp)
                case .title:
                    return compare(first.name, (sec.name ?? ""), isUp: isUp)
                case .latestOpenTime:
                    return compare((first.openTime ?? 0), (sec.openTime ?? 0), isUp: isUp)
                case .latestModifiedTime:
                    return compare((first.myEditTime ?? 0), (sec.myEditTime ?? 0), isUp: isUp)
                case .shareTime:
                    return compare((first.shareTime ?? 0), (sec.shareTime ?? 0), isUp: isUp)
                case .allTime:
                    return compare((first.activityTime ?? 0), (sec.activityTime ?? 0), isUp: false)
                case .latestAddManuOffline:
                    return false
                case.addFavoriteTime:
                    return compare((first.favoriteTime ?? 0), (sec.favoriteTime ?? 0), isUp: isUp)
                }
            })
        return sortedList
    }

    class func compare<T: Comparable>(_ first: T, _ sec: T, isUp: Bool) -> Bool {
        let rs = first > sec
        return (isUp ? !rs : rs)
    }
}
