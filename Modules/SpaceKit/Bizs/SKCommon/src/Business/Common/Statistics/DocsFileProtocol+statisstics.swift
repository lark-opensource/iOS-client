//  Created by weidong fu on 25/11/2017.

import Foundation
import SKFoundation

extension SpaceEntry {
    public func makeStatisticsParams() -> [String: Any] {
        let fileType: String = type.name
        var createUID: String?
        var isOwner: String?
        var createTime: TimeInterval?
        var createDate: String?
        var dateFromCreate: TimeInterval?

        createUID = self.createUid
        if let selfUID = User.current.info?.userID, self.createUid == selfUID {
            isOwner = "true"
        } else {
            isOwner = "false"
        }

        createTime = self.addTime
        let date = Date(timeIntervalSince1970: self.addTime ?? 0)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        createDate = formatter.string(from: date)
        let seconds: TimeInterval = Date().timeIntervalSince1970 - (self.addTime ?? 0)
        dateFromCreate = seconds / (60 * 60 * 24)

        var params: [String: Any] = ["file_type": fileType as Any,
                                     "file_id": DocsTracker.encrypt(id: objToken) as Any,
                                     "create_uid": ((createUID != nil) ? DocsTracker.encrypt(id: createUID!) : "") as Any,
                                     "is_owner": (isOwner ?? "") as Any,
                                     "create_time": (String(createTime ?? 0)) as Any,
                                     "create_date": (createDate ?? "") as Any,
                                     "from_create_date": (String(dateFromCreate ?? 0)) as Any]

        if self.type == .file, let subType = self.fileType {
            params["sub_type"] = subType
        }

        if let source = FileListStatistics.source {
            params["source"] = source.rawValue
        }

        return params
    }

    public func openDateIdentify() -> String {
        guard let interval = self.openTime else {
            return "earlier"
        }
        let date = Date(timeIntervalSince1970: interval)
        if Calendar.current.isDateInToday(date) {
            return "today"
        }
        if Calendar.current.isDateInYesterday(date) {
            return "yesterday"
        }
        return "earlier"
    }

}
