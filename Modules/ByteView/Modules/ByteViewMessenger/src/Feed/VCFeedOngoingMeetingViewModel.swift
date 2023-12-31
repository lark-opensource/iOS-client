//
//  VCFeedOngoingMeetingViewModel.swift
//  ByteViewMessenger
//
//  Created by lutingting on 2022/9/20.
//

import Foundation
import ByteViewNetwork
import ByteViewCommon
import RxSwift
import RxCocoa
import LarkOpenFeed
import LarkContainer

class VCFeedOngoingMeetingViewModel: VCNoticeGrootCellObserver, GrootSessionDelegate {
    static let logger = Logger.getLogger("FeedOngoing")

    private var isGrootChannelOpened: Bool = false
    private let grootChannelQueue: DispatchQueue = DispatchQueue(label: "ByteViewMessenger.GrootChannel")
    private var deletedEvents: [String] = []
    private var grootSession: GrootSession?
    var dataCommand: PublishRelay<EventDataCommand>

    @RwAtomic
    private(set) var items: [String: EventItem] = [:]

    private let userResolver: UserResolver
    private var httpClient: HttpClient? { try? userResolver.resolve(assert: HttpClient.self) }

    init(userResolver: UserResolver, dataCommand: PublishRelay<EventDataCommand>) {
        self.dataCommand = dataCommand
        self.userResolver = userResolver
        self.loadGenericTypes()
        fetchData()
    }

    deinit {
        self.isGrootChannelOpened = false
    }

    private func loadGenericTypes() {
        // 初始化泛型缓存，否则可能和VcMeetingAdapter的类型初始化存在多线程竞争
        // https://t.wtturl.cn/URHSB4o/
        let testObj: Any = NSObject()
        _ = testObj as? VCNoticeGrootSession
    }

    private func fetchData() {
        httpClient?.getResponse(GetVcImNoticeInfoRequest(), options: .retry(3, owner: self)) { [weak self] result in
            guard let self = self else { return }
            self.grootChannelQueue.async {
                switch result {
                case .success(let content):
                    let lastIdItems = Array(self.items.keys)
                    self.items = self.getItemsByInfos(content.imNoticeInfos)
                    self.openGrootChannel(downVersion: content.downVersion)
                    if !self.items.isEmpty {
                        let currentIdItems = Array(self.items.keys)
                        let shouldDeleteItems = lastIdItems.filter { !currentIdItems.contains($0) }
                        self.appendDeletedEvents(with: shouldDeleteItems)
                        self.dataCommand.accept(.remove(shouldDeleteItems))
                        self.dataCommand.accept(.insertOrUpdate(self.items))
                    } else {
                        self.appendDeletedEvents(with: lastIdItems)
                        self.dataCommand.accept(.remove(lastIdItems))
                    }
                case .failure(let error):
                    Self.logger.error("VCFeedOngoingMeetingViewModel fetch data error: \(error)")
                }
            }
        }
    }

    private func openGrootChannel(downVersion: Int32) {
        self.grootChannelQueue.async { [weak self] in
            guard let self = self else { return }
            let userId = self.userResolver.userID
            let channel = GrootChannel(id: userId, type: .vcNoticeChannel)
            if self.grootSession == nil {
                self.grootSession = VCNoticeGrootSession.get(channel, userId: userId, observer: self)
                self.grootSession?.delegate = self
            }
            self.grootSession?.open(version: Int64(downVersion)) { r in
                Self.logger.info("openGrootChannel status: \(r)")
                switch r {
                case .success:
                    self.isGrootChannelOpened = true
                case .failure:
                    self.isGrootChannelOpened = false
                }
            }
        }
    }

    func didReceiveVCNoticeGrootCells(_ cells: [VCNoticeGrootCell], for channel: GrootChannel) {
        Self.logger.info("didReceiveVCNoticeGrootCells cells: \(cells), channel: \(channel)")
        self.grootChannelQueue.async { [weak self] in
            guard let self = self else { return }
            var updateItems: [String: EventItem] = [:]
            var removedEvents: [String] = []
            cells.forEach { cell in
                let meetingId = cell.upsertImNoticeInfo.meetingId
                if !meetingId.isEmpty, !self.deletedEvents.contains(meetingId) {
                    let vm = VCFeedOngoingMeetingCellViewModel(userResolver: self.userResolver, vcInfo: cell.upsertImNoticeInfo, delegate: self)
                    updateItems[meetingId] = vm
                    removedEvents.removeAll { $0 == meetingId }
                    self.items[meetingId] = vm
                }
                if let dismissNoticeMeetingId = cell.dismissNoticeMeetingId, !dismissNoticeMeetingId.isEmpty, !self.deletedEvents.contains(dismissNoticeMeetingId) {
                    removedEvents.append(dismissNoticeMeetingId)
                    updateItems.removeValue(forKey: dismissNoticeMeetingId)
                    self.items.removeValue(forKey: dismissNoticeMeetingId)
                }
            }
            if !updateItems.isEmpty {
                self.dataCommand.accept(.insertOrUpdate(updateItems))
            }
            if !removedEvents.isEmpty {
                self.dataCommand.accept(.remove(removedEvents))
            }
        }
    }

    func sessionDidChangeStatus(session: GrootSession, oldValue: GrootChannelStatus) {
        Self.logger.info("sessionDidChangeStatus session status: \(session.status)")
        if session.status == .closed {
            self.grootChannelQueue.async { [weak self] in
                self?.grootSession = nil
                self?.isGrootChannelOpened = false
                self?.fetchData()
            }
        }
    }

    func removeAll() {
        let ids = Array(self.items.keys)
        self.dataCommand.accept(.remove(ids))
        self.appendDeletedEvents(with: ids)
        self.items = [:]
        Self.logger.info("removeAll ids: \(ids)")
        httpClient?.send(SetVcImNoticeInfoCloseRequest(meetingIds: ids))
    }

    func remove(items: [EventItem]) {
        var ids: [String] = []
        items.forEach { item in
            ids.append(item.id)
            self.items.removeValue(forKey: item.id)
        }
        self.dataCommand.accept(.remove(ids))
        self.appendDeletedEvents(with: ids)
        Self.logger.info("remove ids: \(ids)")
        httpClient?.send(SetVcImNoticeInfoCloseRequest(meetingIds: ids))
    }

    private func appendDeletedEvents(with items: [String]) {
        self.grootChannelQueue.async { [weak self] in
            guard let self = self else { return }
            self.deletedEvents += items
        }
    }

    private func getItemsByInfos(_ infos: [IMNoticeInfo]) -> [String: EventItem] {
        var items: [String: EventItem] = [:]
        infos.forEach { info in
            guard !deletedEvents.contains(info.meetingId) else { return }
            if !info.meetingId.isEmpty {
                items[info.meetingId] = VCFeedOngoingMeetingCellViewModel(userResolver: userResolver, vcInfo: info, delegate: self)
            }
        }
        return items
    }
}

extension VCFeedOngoingMeetingViewModel: VCFeedOngoingMeetingCellViewModelDelegate {
    func needUpdateFeedOngoingMeetingCell(_ item: VCFeedOngoingMeetingCellViewModel) {
        guard self.items[item.id] != nil else { return }
        Self.logger.info("need update FeedOngoingMeetingCell for \(item.id)")
        self.dataCommand.accept(.insertOrUpdate([item.id: item]))
    }
}
