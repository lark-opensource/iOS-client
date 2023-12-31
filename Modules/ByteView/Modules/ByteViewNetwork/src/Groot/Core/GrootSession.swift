//
//  GrootSession.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/15.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon

public protocol GrootCellHandler: AnyObject {
    func processGrootCells(_ cells: [GrootCell])
}

public protocol GrootSessionDelegate: AnyObject {
    func sessionDidChangeStatus(session: GrootSession, oldValue: GrootChannelStatus)
}

public class GrootSession {
    public let channel: GrootChannel
    public var channelId: String { channel.id }
    @RwAtomic
    public private(set) var status: GrootChannelStatus = .unknown
    @RwAtomic
    public private(set) var isOpen: Bool = false
    public private(set) var isInOpeningProcess: Bool = false
    public weak var delegate: GrootSessionDelegate?

    @RwAtomic
    private var lastVersion: Int64?

    private weak var cellHandler: GrootCellHandler?
    let userId: String
    let httpClient: HttpClient
    public init(userId: String, channel: GrootChannel, cellHandler: GrootCellHandler) {
        self.userId = userId
        self.httpClient = HttpClient(userId: userId)
        self.channel = channel
        self.cellHandler = cellHandler
        Push.grootCells.inUser(userId).addObserver(self) { [weak self] in
            self?.didReceiveGrootCells($0)
        }
        Push.grootChannelStatus.inUser(userId).addObserver(self) { [weak self] in
            self?.didReceiveGrootChannelStatus($0)
        }
        Logger.groot.info("init GrootSession(\(channel))")
    }

    deinit {
        closeIfNeeded()
        Logger.groot.info("deinit GrootSession(\(channel))")
    }

    public func open(version: Int64?, useUpVersionFromSource: Bool = false, completion: ((Result<GrootChannelStatus, Error>) -> Void)? = nil) {
        if isOpen {
            if let version = version, self.lastVersion != version {
                _close { [weak self] _ in
                    if let self = self {
                        self._open(version: version, useUpVersionFromSource: useUpVersionFromSource, completion: completion)
                    } else {
                        completion?(.success(.closed))
                    }
                }
            } else {
                completion?(.success(status))
            }
        } else {
            _open(version: version, useUpVersionFromSource: useUpVersionFromSource, completion: completion)
        }
    }

    public func update(version: Int64, useUpVersionFromSource: Bool = false, completion: ((Result<GrootChannelStatus, Error>) -> Void)? = nil) {
        // 如果正在开启过程中，则先跳过
        guard !isInOpeningProcess else { return }
        if isOpen {
            _update(version: version, completion: completion)
        } else {
            _open(version: version, useUpVersionFromSource: useUpVersionFromSource, completion: completion)
        }
    }

    public func sendCells(_ cells: [GrootCell], action: GrootCell.Action = .clientReq) {
        let request = SendGrootCellsRequest(channel: channel, cells: cells)
        httpClient.send(request)
    }

    private func closeIfNeeded() {
        if isOpen || isInOpeningProcess {
            isOpen = false
            isInOpeningProcess = false
            self._close(completion: nil)
        }
    }

    private func _open(version: Int64?, useUpVersionFromSource: Bool = false, completion: ((Result<GrootChannelStatus, Error>) -> Void)? = nil) {
        let channel = self.channel
        let request = OpenGrootChannelRequest(channel: channel, initDownVersion: version, useUpVersionFromSource: useUpVersionFromSource)
        isInOpeningProcess = true
        httpClient.getResponse(request, options: .retry(3, owner: self)) { [weak self] result in
            switch result {
            case .success(let resp):
                let status = resp.status.status
                Logger.groot.info("open groot channel success: status = \(status), channel = \(channel), version = \(version)")
                self?.isOpen = true
                self?.isInOpeningProcess = false
                self?.lastVersion = version
                self?.handleStatus(status)
                completion?(.success(status))
            case .failure(let error):
                self?.isInOpeningProcess = false
                Logger.groot.error("open groot channel failed: error = \(error), channel = \(channel)")
                completion?(.failure(error))
            }
        }
    }

    private func _update(version: Int64, completion: ((Result<GrootChannelStatus, Error>) -> Void)?) {
        let channel = self.channel
        let request = UpdateGrootChannelRequest(channel: channel, downVersion: version)
        httpClient.getResponse(request, options: .retry(3, owner: self)) { [weak self] result in
            switch result {
            case .success(let resp):
                let status = resp.status.status
                Logger.groot.info("update groot channel success: status = \(status), channel = \(channel), version = \(version)")
                self?.isOpen = true
                self?.lastVersion = version
                self?.handleStatus(status)
                completion?(.success(status))
            case .failure(let error):
                Logger.groot.error("update groot channel failed: error = \(error), channel = \(channel)")
                completion?(.failure(error))
            }
        }
    }

    private func _close(completion: ((Result<Void, Error>) -> Void)?) {
        let channel = self.channel
        let request = CloseGrootChannelRequest(channel: channel)
        httpClient.send(request) { result in
            switch result {
            case .success:
                Logger.groot.info("close groot channel success: channel = \(channel)")
            case .failure(let error):
                Logger.groot.error("close groot channel failed: error = \(error), channel = \(channel)")
            }
            completion?(result)
        }
    }

    private func handleStatus(_ status: GrootChannelStatus) {
        let oldValue = self.status
        self.status = status
        if !isOpen { return }
        switch status {
        case .willBeClosed:
            let request = SendGrootCellsRequest(channel: channel, cells: [])
            httpClient.send(request)
        case .closed:
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(10)) { [weak self] in
                if let self = self, self.isOpen {
                    self._open(version: nil, completion: nil)
                }
            }
        default:
            break
        }
        if oldValue != self.status {
            delegate?.sessionDidChangeStatus(session: self, oldValue: oldValue)
        }
    }

    private func didReceiveGrootCells(_ message: PushGrootCells) {
        if self.channel == message.channel, !message.cells.isEmpty {
            cellHandler?.processGrootCells(message.cells)
        }
    }

    private func didReceiveGrootChannelStatus(_ message: PushGrootChannelStatus) {
        if self.channel == message.channel {
            handleStatus(message.status)
        }
    }
}

extension Logger {
    static let groot = getLogger("groot")
}
