//
//  ReactionDetailTableViewModel.swift
//  Calendar
//
//  Created by pluto on 2023/5/24.
//

import UIKit
import Foundation
import RustPB
import LKCommonsLogging

struct CalendarReactoinChatterInfo {
    var name: String
    var avatarKey: String
    var description: String
    var chatterId: String
}

final class ReactionDetailTableViewModel {
    private let logger = Logger.log(ReactionDetailTableViewModel.self, category: "calendar.ReactionDetailTableViewModel")

    let dataSource: [Basic_V1_AttendeeRSVPInfo]
    private(set) var chatters: [CalendarReactoinChatterInfo] = []


    init(data: [Basic_V1_AttendeeRSVPInfo]) {
        logger.info("ReactionDetailTable data count: \(data.count)")
        dataSource = data
        configChatterData()
    }
    
    private func configChatterData() {
        for item in dataSource {
            var chatterInfo: CalendarReactoinChatterInfo = CalendarReactoinChatterInfo(name: item.displayName, avatarKey: item.avatarKey, description: item.description_p.text, chatterId: item.chatterID.description)
            chatters.append(chatterInfo)
        }
    }

    func chatter(at index: Int) -> CalendarReactoinChatterInfo? {
        return chatters[safeIndex: index]
    }
}

