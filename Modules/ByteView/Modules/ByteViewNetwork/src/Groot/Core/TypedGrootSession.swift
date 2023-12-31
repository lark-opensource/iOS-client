//
//  TypedGrootSession.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/15.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// use XxxGrootSession.get(_ channel:) to fetch instance
public final class TypedGrootSession<Notifier: GrootCellNotifierProtocol>: GrootSession {
    public typealias CellType = Notifier.CellType

    private init(userId: String, channel: GrootChannel, observer: Notifier.Observer?) {
        let notifier = Notifier(channel: channel)
        self._notifier = notifier
        super.init(userId: userId, channel: channel, cellHandler: notifier)
        if let observer = observer {
            notifier.addObserver(observer)
        }
    }

    private let _notifier: Notifier
    public var notifier: Notifier {
        _notifier
    }

    public static func get(_ channel: GrootChannel, userId: String, observer: Notifier.Observer? = nil) -> Self {
        GrootSessionStorage.get(channel) {
            Self.init(userId: userId, channel: channel, observer: observer)
        }
    }
}

public extension TypedGrootSession where CellType: NetworkEncodable {
    func sendCell(_ cell: CellType, action: GrootCell.Action = .clientReq, completion: ((Result<Void, Error>) -> Void)? = nil) {
        sendCells([cell], action: action, completion: completion)
    }

    func sendCells(_ cells: [CellType], action: GrootCell.Action = .clientReq, sender: ByteviewUser? = nil, completion: ((Result<Void, Error>) -> Void)? = nil) {
        do {
            let grootCells = try cells.map { GrootCell(action: action, payload: try $0.serializedData(), sender: sender) }
            let request = SendGrootCellsRequest(channel: channel, cells: grootCells)
            httpClient.send(request, completion: completion)
        } catch {
            completion?(.failure(error))
        }
    }
}

private class GrootSessionStorage {
    static func get<T: GrootSession>(_ channel: GrootChannel, generator: () -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        if let session = cache[channel]?.value as? T {
            return session
        } else {
            cache = cache.filter({ $0.value.value != nil })
            let session = generator()
            cache[channel] = CacheItem(value: session)
            return session
        }
    }

    private static let lock = NSLock()
    private static var cache: [GrootChannel: CacheItem] = [:]
    private struct CacheItem {
        weak var value: GrootSession?
    }
}
