//
//  InMeetStatusItem.swift
//  ByteView
//
//  Created by chenyizhuo on 2023/3/16.
//

import UIKit

enum InMeetStatusType {
    case lock
    case record
    case transcribe
    case interpreter
    case live
    case interviewRecord
    case countDown

    static let needOmitStates: [InMeetStatusType] = [.lock, .record, .transcribe, .interpreter, .live, .interviewRecord]
    static let allStates: [InMeetStatusType] = [.lock, .record, .transcribe, .interpreter, .live, .interviewRecord, .countDown]
}

class InMeetStatusThumbnailItem {
    let type: InMeetStatusType
    var title: String
    var icon: UIImage?
    var data: Any?

    init(type: InMeetStatusType, title: String, icon: UIImage?, data: Any?) {
        self.type = type
        self.title = title
        self.icon = icon
        self.data = data
    }
}

class InMeetStatusItem {
    let type: InMeetStatusType
    var title: String
    var icon: UIImage?
    var desc: String?
    var clickAction: (() -> Void)?
    var actions: [Action] = []
    var data: Any?

    init(type: InMeetStatusType, title: String, desc: String?, icon: UIImage?) {
        self.type = type
        self.title = title
        self.desc = desc
        self.icon = icon
    }

    struct Action {
        let title: String
        let action: (@escaping (() -> Void)) -> Void
    }
}
