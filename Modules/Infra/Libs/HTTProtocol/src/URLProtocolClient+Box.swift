//
//  RustHttpURLProtocolClient.swift
//  LarkRustClient
//
//  Created by SolaWing on 2018/12/14.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation

public class URLProtocolForwardClient: NSObject, URLProtocolClient {
    public struct Event {
        public weak var sender: URLProtocol?
        public var data: Kind
        public enum Kind {
            case redirect(newRequest: URLRequest, response: URLResponse)
            case cached(CachedURLResponse)
            case receive(response: URLResponse, policy: URLCache.StoragePolicy)
            case data(Data)
            case finish
            case error(Error)
            case challenge(URLAuthenticationChallenge)
            case cancel(challenge: URLAuthenticationChallenge)
            public var isFinishEvent: Bool {
                switch self {
                case .finish, .error, .cached: return true
                default: return false
                }
            }
        }
    }
    public typealias OnEvent = (URLProtocolForwardClient, Event) -> Void
    /// if change this, should on same thread with URLProtocol callback.
    public var onEvent: OnEvent?
    public init(onEvent: OnEvent?) {
        self.onEvent = onEvent
    }

    // MARK: URLProtocolClient
    public func urlProtocol(_ protocol: URLProtocol, wasRedirectedTo request: URLRequest, redirectResponse: URLResponse) { // swiftlint:disable:this line_length
        self.onEvent?(self, Event(sender: `protocol`, data: .redirect(newRequest: request, response: redirectResponse)))
    }
    public func urlProtocol(_ protocol: URLProtocol, cachedResponseIsValid cachedResponse: CachedURLResponse) {
        self.onEvent?(self, Event(sender: `protocol`, data: .cached(cachedResponse)))
    }
    public func urlProtocol(_ protocol: URLProtocol, didReceive response: URLResponse, cacheStoragePolicy policy: URLCache.StoragePolicy) { // swiftlint:disable:this line_length
        self.onEvent?(self, Event(sender: `protocol`, data: .receive(response: response, policy: policy)))
    }
    public func urlProtocol(_ protocol: URLProtocol, didLoad data: Data) {
        self.onEvent?(self, Event(sender: `protocol`, data: .data(data)))
    }
    public func urlProtocolDidFinishLoading(_ protocol: URLProtocol) {
        self.onEvent?(self, Event(sender: `protocol`, data: .finish))
    }
    public func urlProtocol(_ protocol: URLProtocol, didFailWithError error: Error) {
        self.onEvent?(self, Event(sender: `protocol`, data: .error(error)))
    }
    public func urlProtocol(_ protocol: URLProtocol, didReceive challenge: URLAuthenticationChallenge) {
        self.onEvent?(self, Event(sender: `protocol`, data: .challenge(challenge)))
    }
    public func urlProtocol(_ protocol: URLProtocol, didCancel challenge: URLAuthenticationChallenge) {
        self.onEvent?(self, Event(sender: `protocol`, data: .cancel(challenge: challenge)))
    }
}

public final class URLProtocolRecordClient: URLProtocolForwardClient {
    public var historyRecord: [Event] = []
    public func forwardRecords(to client: URLProtocolClient, from protocol: URLProtocol? = nil) {
        for v in historyRecord {
            client.receive(event: v, from: `protocol`)
        }
    }
    public override init(onEvent: OnEvent?) {
        super.init {
            ($0 as? URLProtocolRecordClient)?.historyRecord.append($1)
            onEvent?($0, $1)
        }
    }
}

extension URLProtocolClient {
    /// forward event to URLProtocolClient
    public func receive(event: URLProtocolForwardClient.Event, from protocol: URLProtocol? = nil) {
        guard let `protocol` = `protocol` ?? event.sender else { return }
        switch event.data {
        case let .cancel(challenge: challenge):
            self.urlProtocol(`protocol`, didCancel: challenge)
        case .redirect(let newRequest, let response):
            self.urlProtocol(`protocol`, wasRedirectedTo: newRequest, redirectResponse: response)
        case .cached(let response):
            self.urlProtocol(`protocol`, cachedResponseIsValid: response)
        case .receive(let response, let policy):
            self.urlProtocol(`protocol`, didReceive: response, cacheStoragePolicy: policy)
        case .data(let data):
            self.urlProtocol(`protocol`, didLoad: data)
        case .finish:
            self.urlProtocolDidFinishLoading(`protocol`)
        case .error(let error):
            self.urlProtocol(`protocol`, didFailWithError: error)
        case .challenge(let challenge):
            self.urlProtocol(`protocol`, didReceive: challenge)
        }
    }
}
