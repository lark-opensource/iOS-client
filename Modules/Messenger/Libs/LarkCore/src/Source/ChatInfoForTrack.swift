//
//  ChatInfoForTrack.swift
//  LarkCore
//
//  Created by zc09v on 2020/12/9.
//
import Foundation
import LarkModel

public extension Chat {
    var chatInfoForTrack: [String: Any] {
        var params: [String: Any] = ["group_id": self.id]
        params["type"] = self.type == .p2P ? "p2p_chat" : "group_chat"
        params["mode"] = self.isPublic ? "public" : "private"
        var categories: [String] = []
        if self.isDepartment {
            categories.append("department")
        }
        if self.isOncall {
            categories.append("on_call")
        }
        if self.isCustomerService {
            categories.append("customer_service")
        }
        if self.isMeeting {
            categories.append("meeting")
        }
        if self.isTenant {
            categories.append("all_staff")
        }
        if self.isCrossTenant {
            categories.append("external")
        } else {
            categories.append("internal")
        }
        if self.chatMode == .threadV2 {
            categories.append("circle")
        }
        let category = categories.reduce("") { (result, category) -> String in
            return result + (result.isEmpty ? "\(category)" : ",\(category)")
        }
        params["category"] = category
        return params
    }
}
