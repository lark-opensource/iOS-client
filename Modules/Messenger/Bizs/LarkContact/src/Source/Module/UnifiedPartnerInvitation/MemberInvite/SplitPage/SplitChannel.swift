//
//  SplitChannel.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/1/1.
//

import UIKit
import Foundation

enum ChannelFlag {
    case directed
    case wechat
    case nonDirectedQRCode
    case nonDirectedLink
    case larkInvite
    case addressbookImport
    case teamCode
    case unknown
}

struct SplitChannel {
    let title: String
    let icon: UIImage
    let secondTitle: String
    let channelFlag: ChannelFlag

    init(_ icon: UIImage,
         _ title: String,
         _ secondTitle: String = "",
         _ channelFlag: ChannelFlag) {
        self.icon = icon
        self.title = title
        self.secondTitle = secondTitle
        self.channelFlag = channelFlag
    }
}
