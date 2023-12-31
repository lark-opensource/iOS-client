// longweiwei

import Foundation
import Homeric

extension MailTracker {

    // 默认Tea平台会上报、若还需要上报到Slardar 需添加到shouldReportToSlardar函数case中
    public func eventPlatform(_ event: String) -> Platform {
        return Platform(tea: shouldReportToTea(event),
                        slardar: shouldReportToSlardar(event))
    }
    /// 内部数据上报 Tea
    func shouldReportToTea(_ event: String) -> Bool {
        return event == "mail_test_statistics" ? false : true
    }

    /// 对外数据上报 Slardar
    func shouldReportToSlardar(_ event: String) -> Bool {
        if event == "mail_test_statistics" || event == Homeric.EMAIL_EDIT {
            return false
        } else {
            return true
        }
    }

}

public struct Platform {
    public var tea: Bool
    public var slardar: Bool
}
