//
//  SearchModel.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/7/17.
//

import Foundation
import RustPB

class MailSearchSession {
    private var timeStamp = Date()
    private var sessionID = Int.random(in: 0..<Int.max)
    let uuid = UUID().uuidString
    var session: String {
        return String("\(Int(timeStamp.timeIntervalSince1970) + sessionID)")
    }

    var clientSession: String = ""

    @discardableResult
    func renewClientSession() -> String {
        clientSession = ""
        return clientSession
    }

    @discardableResult
    func renewSession() -> String {
        timeStamp = Date()
        sessionID = Int.random(in: 0..<Int.max)
        return session
    }

    func sessionTimeStamp() -> TimeInterval {
        return timeStamp.timeIntervalSince1970
    }
}

protocol MailSearchHistoryInfo {
    var keyword: String { get }
}
