//
//  TeamEventModel.swift
//  LarkTeam
//
//  Created by chaishenghua on 2022/9/2.
//

import Foundation

final class TeamEventModel {
    var list: [TeamEventCellModel]
    let title: String

    init(title: String) {
        self.list = [TeamEventCellModel]()
        self.title = title
    }
}
