//
//  UserNickNameItem.swift
//  Moment
//
//  Created by liluobin on 2021/5/23.
//

import UIKit
import Foundation
final class UserNickNameItem {
    let data: RawData.AnonymousNickname
    let width: CGFloat
    var selected = false
    init(data: RawData.AnonymousNickname) {
        self.data = data
        self.width = MomentsDataConverter.widthForString(data.nickname, font: UIFont.systemFont(ofSize: 14))
    }
}
