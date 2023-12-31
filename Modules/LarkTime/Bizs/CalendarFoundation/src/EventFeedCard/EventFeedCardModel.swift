//
//  EventFeedCardCellModel.swift
//  CalendarFoundation
//
//  Created by chaishenghua on 2023/8/1.
//

public enum EventFeedCardType {
    case vc
    case event
}

public protocol EventFeedCardModel {

    var sortTime: Int64 { get }

    var cardID: String { get }

    var cardType: EventFeedCardType { get }
}
