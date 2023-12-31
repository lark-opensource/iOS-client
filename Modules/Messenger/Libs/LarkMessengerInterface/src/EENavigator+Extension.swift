//
//  EENavigator+Extension.swift
//  LarkMessengerInterface
//
//  Created by CharlieSu on 11/27/19.
//

import UIKit
import Foundation
import EENavigator

public struct PresentParam {
    public let naviParams: NaviParams?
    public let context: [String: Any]
    public let wrap: UINavigationController.Type?
    public let from: UIViewController
    public let prepare: ((UIViewController) -> Void)?
    public let animated: Bool
    public let completion: Handler?

    public init(naviParams: NaviParams? = nil,
                context: [String: Any] = [:],
                wrap: UINavigationController.Type? = nil,
                from: UIViewController,
                prepare: ((UIViewController) -> Void)? = nil,
                animated: Bool = true,
                completion: Handler? = nil) {
        self.naviParams = naviParams
        self.context = context
        self.wrap = wrap
        self.from = from
        self.prepare = prepare
        self.animated = animated
        self.completion = completion
    }
}

public struct PushParam {
    public let naviParams: NaviParams?
    public let context: [String: Any]
    public let from: UIViewController
    public let animated: Bool
    public let completion: Handler?

    public init(naviParams: NaviParams? = nil,
                context: [String: Any] = [:],
                from: UIViewController,
                animated: Bool = true,
                completion: Handler? = nil) {
        self.naviParams = naviParams
        self.context = context
        self.from = from
        self.animated = animated
        self.completion = completion
    }
}

public struct ShowDetailParam {
    public let naviParams: NaviParams?
    public let context: [String: Any]
    public let wrap: UINavigationController.Type?
    public let from: UIViewController
    public let completion: Handler?

    public init(naviParams: NaviParams? = nil,
                context: [String: Any] = [:],
                wrap: UINavigationController.Type? = nil,
                from: UIViewController,
                completion: Handler? = nil) {
        self.naviParams = naviParams
        self.context = context
        self.wrap = wrap
        self.from = from
        self.completion = completion
    }
}

public extension Navigatable {
    func present<T: Body> (body: T, presentParam: PresentParam) {
        present(body: body,
                naviParams: presentParam.naviParams,
                context: presentParam.context,
                wrap: presentParam.wrap,
                from: presentParam.from,
                prepare: presentParam.prepare,
                animated: presentParam.animated,
                completion: presentParam.completion)
    }

    func push<T: Body>(body: T, pushParam: PushParam) {
        push(body: body,
             naviParams: pushParam.naviParams,
             context: pushParam.context,
             from: pushParam.from,
             animated: pushParam.animated,
             completion: pushParam.completion)
    }

    func showDetail<T: Body>(body: T, showDetailParam: ShowDetailParam) {
        self.showDetail(
            body: body,
            context: showDetailParam.context,
            wrap: showDetailParam.wrap,
            from: showDetailParam.from,
            completion: showDetailParam.completion
        )
    }
}

public struct MeetingInfo {
    public let startTime: Int64
    public let endTime: Int64
    public let alertName: String

    public init(startTime: Int64,
                endTime: Int64,
                alertName: String) {
        self.startTime = startTime
        self.endTime = endTime
        self.alertName = alertName
    }
}

public struct CalendarChatMeetingInfo {
    public let meetingInfo: MeetingInfo?
    public let url: URL?

    public init(meetingInfo: MeetingInfo?, url: URL?) {
        self.url = url
        self.meetingInfo = meetingInfo
    }
}
