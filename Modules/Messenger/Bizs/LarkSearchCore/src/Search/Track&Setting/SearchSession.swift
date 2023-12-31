//
//  SearchSession.swift
//  LarkSearch
//
//  Created by SuPeng on 6/18/19.
//

import Foundation
import EEAtomic
import RxSwift
import LarkMessengerInterface

// TODO: 现在SearchSession跨场景透传比较麻烦，各个子搜索场景也没有带上session..
public final class SearchSession {
    public init() {}
    // TODO: 后续改成按session计数的. 现在先保证唯一性
    private static let requestID = AtomicUIntCell()
    public static var getRequestID: UInt { requestID.increment() + 1 }

    public var sourceOfSearch: SourceOfSearch?

    deinit {
        _seqID.deallocate()
    }

    @AtomicObject public private(set) var session: String = genSession()
    private var _seqID = AtomicUIntCell()
    public var seqID: UInt { _seqID.value }
    /// 每次不同的query，有不同的seqID
    /// FIXME: 有些地方持久化了seqID, 有些地方没有，导致加载更多时有些会变，有些不会变，产生不一致
    public func nextSeqID() -> UInt { _seqID.increment() + 1 }
    /// session + seqID, should get after call nextSeqID
    public func imprID(seqID: UInt) -> String { "\(session)_\(seqID)" }

    public func capture() -> Captured { Captured(session: session, seqID: seqID) }
    public func nextSeq() -> Captured { Captured(session: session, seqID: _seqID.increment() + 1) }

    static func genSession() -> String { "\(Date().timeIntervalSince1970)" }

    public var clickInfo: SearchClickInfo?
    public let newSessionPublisher = PublishSubject<SearchSession>()

    @discardableResult
    public func renewSession() -> String {
        session = Self.genSession()
        _seqID.value = 0

        newSessionPublisher.on(.next(self))
        return session
    }

    /// a captured, immutable seq definition
    public struct Captured {
        public let session: String
        public let seqID: UInt
        public var imprID: String { "\(session)_\(seqID)" }

        public static func mock() -> Captured { return Captured(session: "", seqID: 0) }
        public init(session: String, seqID: UInt) {
            self.session = session
            self.seqID = seqID
        }
    }
}

public struct SearchClickInfo {
    public let clickResultType: String
    public let queryLength: Int
    public let searchLocation: Int
    public let searchPage: String
    public init(clickResultType: String, queryLength: Int, searchLocation: Int, searchPage: String) {
        self.clickResultType = clickResultType
        self.queryLength = queryLength
        self.searchLocation = searchLocation
        self.searchPage = searchPage
    }
}
