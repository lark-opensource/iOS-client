//
//  MeetingPrecheckable.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/7/5.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import ByteViewMeeting

typealias PrecheckHandler = (Result<Void, Error>) -> Void

protocol MeetingPrecheckable: AnyObject {
    var nextChecker: MeetingPrecheckable? { get set }
    var description: String { get }

    @discardableResult
    func setNext(_ checker: MeetingPrecheckable) -> MeetingPrecheckable
    func check(_ context: MeetingPrecheckContext, completion: @escaping PrecheckHandler)
}

extension MeetingPrecheckable {
    var description: String { String(describing: type(of: self)) }
}

extension MeetingPrecheckable {
    func setNext(_ checker: MeetingPrecheckable) -> MeetingPrecheckable {
        nextChecker = checker
        return checker
    }

    func checkNextIfNeeded(_ context: MeetingPrecheckContext, completion: @escaping PrecheckHandler) {
        Logger.precheck.info("\(description) precheck success")
        if let checker = nextChecker {
            checker.check(context, completion: completion)
        } else {
            completion(.success(()))
        }
    }
}
