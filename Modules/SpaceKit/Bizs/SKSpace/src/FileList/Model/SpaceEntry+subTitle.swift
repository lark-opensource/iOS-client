//  Created by weidong fu on 25/11/2017.

import Foundation
import SKCommon
import SKResource
import SKFoundation

private let sortTypeKey = "sortType"
extension SpaceEntry {
    // TODO: 尽量少用，DataModel 改造完成后废弃掉
    var sortType: SortItem.SortType {
        get { return storedExtensionProperty[sortTypeKey] as? SortItem.SortType ?? .updateTime }
        set { updateStoredExtensionProperty(key: sortTypeKey, value: newValue) }
    }
    
    public func makeSubtitle(_ parameter: Any?, isShowCreateTime: Bool = false) -> String? {
        if isShortCut { return  BundleI18n.SKResource.CreationMobile_Wiki_Shortcuts_ShortcutLabel_Placeholder }
        let source = parameter as? FileSource ?? .unknown
        if source == .trash {
            return SpaceEntry.getSubtitleOfTrashFile(author: self.owner, expireTime: expireTime ?? 0)
        }
        if source == .recent {
            /// DM-4228 对于 Drive 上传的文件，判断 openTime 和 createTime，相距 3 秒内显示“上传于 {{createTime}}”，否则显示“最近浏览于 {{openTime}}”
            if type == .file, let open = openTime, let create = createTime, open - create < 3.0 {
                return BundleI18n.SKResource.Doc_List_UploadTime(create.fileSubTitleDateFormatter)
            }
            return recentListSubtitle()
        } else if source == .share && self.isShareRoot {
            /// 与我共享
            return formateSubtitle()
        } else if source == .share && !self.isShareRoot {
            return formateSubtitle()
        } else if source == .manualOffline {
            var subTitle = manuaOfflineListSubtitle()
            if type == .file, fileSize > 0 {
                // 需要显示文件大小
                let sizeString = FileSizeHelper.memoryFormat(fileSize)
                subTitle = sizeString + BundleI18n.SKResource.Doc_Facade_Space + subTitle
            }
            return subTitle
        } else {
            return isShowCreateTime ?
                BundleI18n.SKResource.Doc_List_Create_At((self.createTime ?? 0).fileSubTitleDateFormatter) :
                BundleI18n.SKResource.LarkCCM_NewCM_LastModifiedTime_Description((self.editTime ?? 0).fileSubTitleDateFormatter)
        }
    }

    public func subtitle(listSource: FileSource, sortType: SpaceSortHelper.SortType) -> String {
        if isShortCut { return BundleI18n.SKResource.CreationMobile_Wiki_Shortcuts_ShortcutLabel_Placeholder }
        switch listSource {
        case .recent:
            if type == .file, let open = openTime, let create = createTime, open - create < 3.0 {
                return BundleI18n.SKResource.Doc_List_UploadTime(create.fileSubTitleDateFormatter)
            }
            return subtitleForRecentList(sortType: sortType)
        case .share:
            return subtitle(sortType: sortType)
        case .manualOffline:
            var subTitle = subtitleForManualOfflineList(sortType: sortType)
            if type == .file, fileSize > 0 {
                // 需要显示文件大小
                let sizeString = FileSizeHelper.memoryFormat(fileSize)
                subTitle = sizeString + BundleI18n.SKResource.Doc_Facade_Space + subTitle
            }
            return subTitle
        case .favorites:
            if let favoriteTime {
                return BundleI18n.SKResource.LarkCCM_NewCM_StarredTime_Description(favoriteTime.fileSubTitleDateFormatter)
            } else {
                // 默认用创建时间兜底
                return BundleI18n.SKResource.LarkCCM_NewCM_LastModifiedTime_Description((self.editTime ?? 0).fileSubTitleDateFormatter)
            }
        default:
            if sortType == .createTime {
                return BundleI18n.SKResource.Doc_List_Create_At((self.createTime ?? 0).fileSubTitleDateFormatter)
            } else {
                return BundleI18n.SKResource.LarkCCM_NewCM_LastModifiedTime_Description((self.editTime ?? 0).fileSubTitleDateFormatter)
            }
        }
    }
    
    public func timeTitleBySortType(sortType: SpaceSortHelper.SortType) -> String {
        switch sortType {
        case .updateTime, .lastModifiedTime:
            return (self.editTime ?? 0).fileSubTitleDateFormatter
        case .createTime, .latestCreated:
            return (self.createTime ?? 0).fileSubTitleDateFormatter
        case .lastOpenTime:
            return (self.openTime ?? 0).fileSubTitleDateFormatter
        case .allTime:
            return (self.activityTime ?? 0).fileSubTitleDateFormatter
        case .sharedTime:
            return (self.shareTime ?? 0).fileSubTitleDateFormatter
        case .addFavoriteTime:
            return (self.favoriteTime ?? 0).fileSubTitleDateFormatter
        case .addedManualOfflineTime:
            return (self.addManuOfflineTime ?? 0).fileSubTitleDateFormatter
        default:
            return (self.editTime ?? 0).fileSubTitleDateFormatter
        }
    }

    // MARK: - private
    private static func getSubtitleOfTrashFile(author: String?, expireTime: TimeInterval) -> String {
        let secondsOfADay: Double = 60 * 60 * 24
        let remainingDays = Int(ceil(Double(expireTime) / secondsOfADay))
        let authorStr = BundleI18n.SKResource.Doc_Normal_Owner + " " + (author ?? "")
        let timeStr = BundleI18n.SKResource.Doc_List_RetentionTime + " " + "\(remainingDays)" + BundleI18n.SKResource.Doc_Normal_ExpireTimeUnit
        return authorStr + "  " + timeStr
    }

    private func formateSubtitle() -> String {
        switch sortType {
        case .shareTime:
            return BundleI18n.SKResource.Doc_List_ShareBy((self.owner ?? ""), ((self.shareTime ?? 0).fileSubTitleDateFormatter))
        case .createTime:
            return BundleI18n.SKResource.Doc_List_Create_At((self.createTime ?? 0).fileSubTitleDateFormatter)
        default:  // 默认显示更新时间
            return BundleI18n.SKResource.LarkCCM_NewCM_LastModifiedTime_Description((self.editTime ?? 0).fileSubTitleDateFormatter)
        }
    }

    /// 为了方便修改，各个列表分开吧，代码冗余一点
    private func recentListSubtitle() -> String {
        switch sortType {
        case .latestModifiedTime: // 最近修改
            return BundleI18n.SKResource.LarkCCM_NewCM_LastModifiedTime_Description(getFormattedTimeForRecent(self.myEditTime))
        case .letestCreated: // 最近创建
            return BundleI18n.SKResource.Doc_List_Create_At(getFormattedTimeForRecent(self.createTime))
        case .latestOpenTime: // 最近打开
            return BundleI18n.SKResource.LarkCCM_NewCM_LastVisitedTime_Description(getFormattedTimeForRecent(self.openTime))
        case .allTime: // 全部
            return BundleI18n.SKResource.LarkCCM_NewCM_LastVisitedTime_Description(getFormattedTimeForRecent(self.activityTime))
        default:
            return BundleI18n.SKResource.LarkCCM_NewCM_LastVisitedTime_Description(getFormattedTimeForRecent(self.openTime))
        }
    }

    private func subtitle(sortType: SpaceSortHelper.SortType) -> String {
        switch sortType {
        case .sharedTime:
            return BundleI18n.SKResource.Doc_List_ShareBy((owner ?? ""), ((shareTime ?? 0).fileSubTitleDateFormatter))
        case .createTime:
            return BundleI18n.SKResource.Doc_List_Create_At((createTime ?? 0).fileSubTitleDateFormatter)
        default:  // 默认显示更新时间
            return BundleI18n.SKResource.LarkCCM_NewCM_LastModifiedTime_Description((editTime ?? 0).fileSubTitleDateFormatter)
        }
    }

    private func subtitleForRecentList(sortType: SpaceSortHelper.SortType) -> String {
        switch sortType {
        case .lastModifiedTime: // 最近修改
            return BundleI18n.SKResource.LarkCCM_NewCM_LastModifiedTime_Description(getFormattedTimeForRecent(myEditTime))
        case .latestCreated: // 最近创建
            return BundleI18n.SKResource.Doc_List_Create_At(getFormattedTimeForRecent(createTime))
        case .lastOpenTime: // 最近打开
            return BundleI18n.SKResource.LarkCCM_NewCM_LastVisitedTime_Description(getFormattedTimeForRecent(openTime))
        case .allTime: // 全部
            return BundleI18n.SKResource.LarkCCM_NewCM_LastVisitedTime_Description(getFormattedTimeForRecent(activityTime))
        default:
            return BundleI18n.SKResource.LarkCCM_NewCM_LastVisitedTime_Description(getFormattedTimeForRecent(openTime))
        }
    }

    private func getFormattedTimeForRecent(_ targetTime: TimeInterval?) -> String {
        return getFormattedTime(targetTime, defaultCheck: [openTime, activityTime, myEditTime, createTime])
    }

    private func getFormattedTime(_ targetTime: TimeInterval?, defaultCheck: [TimeInterval?]) -> String {
        var finalTime: TimeInterval = 0
        if let time = targetTime, time > 0 {
            finalTime = time
            return finalTime.fileSubTitleDateFormatter
        }

        let defaultTime = defaultCheck.first(where: { time in
            if let aTime = time, aTime > 0 {
                return true
            }
            return false
        })
        if let time = defaultTime as? TimeInterval {
            finalTime = time
        }
        return finalTime.fileSubTitleDateFormatter

    }

    /// 为了方便修改，各个列表分开吧，代码冗余一点
    private func manuaOfflineListSubtitle() -> String {
        /// DM-4228 对于 Drive 上传的文件，判断 openTime 和 createTime，相距 3 秒内显示“上传于 {{createTime}}”
        if type == .file,
            let open = openTime, open > 0,
            let create = createTime, create > 0,
            open - create < 3.0 {
            return BundleI18n.SKResource.Doc_List_UploadTime(create.fileSubTitleDateFormatter)
        }
        switch sortType {
        case .latestAddManuOffline, .updateTime: // 最近添加
            /// 本来是用addManuOfflineTime的，但是后来，跟产品和安卓那边确认之后，显示editTime，排序用addManuOfflineTime
            return BundleI18n.SKResource.LarkCCM_NewCM_LastModifiedTime_Description((self.editTime ?? 0).fileSubTitleDateFormatter)
        case .latestModifiedTime:
            return BundleI18n.SKResource.LarkCCM_NewCM_LastModifiedTime_Description((self.editTime ?? 0).fileSubTitleDateFormatter)
        case .latestOpenTime:
            return BundleI18n.SKResource.LarkCCM_NewCM_LastVisitedTime_Description((self.openTime ?? 0).fileSubTitleDateFormatter)
        case .letestCreated:
            return BundleI18n.SKResource.Doc_List_Create_At((self.createTime ?? 0).fileSubTitleDateFormatter)
        default:
            return BundleI18n.SKResource.LarkCCM_NewCM_LastVisitedTime_Description((self.openTime ?? 0).fileSubTitleDateFormatter)
        }
    }

    private func subtitleForManualOfflineList(sortType: SpaceSortHelper.SortType) -> String {
        /// DM-4228 对于 Drive 上传的文件，判断 openTime 和 createTime，相距 3 秒内显示“上传于 {{createTime}}”
        if type == .file,
           let open = openTime, open > 0,
           let create = createTime, create > 0,
           open - create < 3.0 {
            return BundleI18n.SKResource.Doc_List_UploadTime(create.fileSubTitleDateFormatter)
        }
        switch sortType {
        case .addedManualOfflineTime, .updateTime: // 最近添加
            /// 本来是用addManuOfflineTime的，但是后来，跟产品和安卓那边确认之后，显示editTime，排序用addManuOfflineTime
            return BundleI18n.SKResource.LarkCCM_NewCM_LastModifiedTime_Description((editTime ?? 0).fileSubTitleDateFormatter)
        case .lastModifiedTime:
            return BundleI18n.SKResource.LarkCCM_NewCM_LastModifiedTime_Description((editTime ?? 0).fileSubTitleDateFormatter)
        case .lastOpenTime:
            return BundleI18n.SKResource.LarkCCM_NewCM_LastVisitedTime_Description((openTime ?? 0).fileSubTitleDateFormatter)
        case .latestCreated:
            return BundleI18n.SKResource.Doc_List_Create_At((createTime ?? 0).fileSubTitleDateFormatter)
        default:
            return BundleI18n.SKResource.LarkCCM_NewCM_LastVisitedTime_Description((openTime ?? 0).fileSubTitleDateFormatter)
        }
    }
}
