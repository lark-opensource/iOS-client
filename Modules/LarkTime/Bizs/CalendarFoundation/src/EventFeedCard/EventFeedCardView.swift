//
//  EventFeedCardView.swift
//  CalendarFoundation
//
//  Created by chaishenghua on 2023/8/1.
//

public protocol EventFeedCardView: UIView {
    var identifier: String { get }

    var model: EventFeedCardModel { get set }
}
