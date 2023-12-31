//
//  TeamEvent.swift
//  LarkFeed
//
//  Created by chaishenghua on 2022/8/30.
//

import Foundation
import ServerPB
import RichLabel
import LarkContainer

final class TeamEventCellModel {
    let event: NSMutableAttributedString
    let time: String
    let date: String
    let links: [LKTextLink]
    let userResolver: LarkContainer.UserResolver
    init(event: NSMutableAttributedString,
         time: String,
         date: String,
         links: [LKTextLink],
         userResolver: UserResolver) {
        self.event = event
        self.time = time
        self.date = date
        self.links = links
        self.userResolver = userResolver
    }
}
