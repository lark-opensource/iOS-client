//
//  NoticeInterceptor.swift
//  ByteView
//
//  Created by eesh-macmini-automation on 2023/3/15.
//

import Foundation

protocol MeetingNoticeInterceptorListener: AnyObject {

    typealias Intercepted = Bool

    /// - Returns: 是否打断通用处理逻辑
    func didReceiveToast(extra: [String: String]) -> Intercepted
}

extension MeetingNoticeInterceptorListener {
    func didReceiveToast(extra: [String: String]) -> Intercepted { true }
}

final class MeetingNoticeInterceptor {

    private let listeners = Listeners<MeetingNoticeInterceptorListener>()
    func addListener(_ listener: MeetingNoticeInterceptorListener) {
        listeners.addListener(listener)
    }

    func removeListener(_ listener: MeetingNoticeInterceptorListener) {
        listeners.removeListener(listener)
    }

    func checkIfInterceptToast(extra: [String: String]) -> Bool {
        var result = false
        listeners.forEach {
            result = result || $0.didReceiveToast(extra: extra)
        }
        return result
    }
}
