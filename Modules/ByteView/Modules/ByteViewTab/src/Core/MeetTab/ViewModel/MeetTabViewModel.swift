//
//  MeetTabViewModel.swift
//  ByteView
//
//  Created by ford on 2019/11/4.
//

import Foundation
import RxSwift
import RxCocoa
import Reachability
import ByteViewCommon
import ByteViewNetwork

protocol TabDataObserver {
    func didChangeNetStatus(status: MeetTabViewModel.NetworkStatus)
    func didReceiveUserGrootCell(cells: [TabUserGrootCell])
    func didReceiveMeetingGrootCell(meetingID: String, cells: [TabMeetingGrootCell])
}

extension TabDataObserver {
    func didChangeNetStatus(status: MeetTabViewModel.NetworkStatus) {}
    func didReceiveUserGrootCell(cells: [TabUserGrootCell]) {}
    func didReceiveMeetingGrootCell(meetingID: String, cells: [TabMeetingGrootCell]) {}
}

class MeetTabViewModel {
    static let logger = Logger.tab

    enum NetworkStatus {
        case good
        case lost
        case weak
    }

    var listGrootObservable: Observable<[TabListGrootCell]> { listGrootSubject.asObservable() }

    @RwAtomic
    private var grootChannelOpened: [GrootChannel: GrootSession] = [:]
    private let grootChannelQueue: DispatchQueue = DispatchQueue(label: "ByteViewTab.GrootChannel")

    let listGrootSubject = PublishSubject<[TabListGrootCell]>()

    private lazy var reach: Reachability = Reachability()!
    private var dispatchWorkItem: DispatchWorkItem?

    @RwAtomic
    private var netStatus: NetworkStatus = .good
    private let observers = Listeners<TabDataObserver>()

    let dependency: TabDependency

    lazy var httpClient = dependency.httpClient
    lazy var router = dependency.router
    lazy var account = dependency.accountInfo
    lazy var setting = dependency.setting
    var userId: String { account.userId }
    let fg: TabFeatureGating

    var currentMeeting: TabMeeting? { dependency.currentMeeting }

    init(dependency: TabDependency) {
        self.dependency = dependency
        self.fg = TabFeatureGating(dependency: dependency)
        startMonitor()
    }

    func addObserver(_ observer: TabDataObserver) {
        observers.addListener(observer)
        observer.didChangeNetStatus(status: netStatus)
    }

    func removeObserver(_ observer: TabDataObserver) {
        observers.removeListener(observer)
    }

    private func startMonitor() {
        try? reach.startNotifier()
        let reachBlock: (Reachability) -> Void = { [weak self] reachability in
            self?.notifyNetStatus(reachability.isReachable ? .good : .lost)
        }
        reach.whenReachable = reachBlock
        reach.whenUnreachable = reachBlock
        notifyNetStatus(reach.isReachable ? .good : .lost)

        TabPush.dynamicNetStatus.inUser(userId).addObserver(self) { [weak self] in
            self?.didGetDynamicNetStatus($0.netStatus)
        }
    }
}

extension MeetTabViewModel {

    func didGetDynamicNetStatus(_ status: DynamicNetStatus) {
        if status != .weak {
            dispatchWorkItem?.cancel()
            dispatchWorkItem = nil
        } else {
            let workItem = DispatchWorkItem(block: { [weak self] in
                self?.notifyNetStatus(.weak)
            })
            dispatchWorkItem = workItem
            // nolint-next-line: magic number
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(70), execute: workItem)
        }
        if status == .offline || status == .netUnavailable {
            notifyNetStatus(.lost)
        } else {
            notifyNetStatus(.good)
        }
    }

    private func notifyNetStatus(_ status: NetworkStatus) {
        guard status != netStatus else { return }
        netStatus = status
        observers.forEach {
            $0.didChangeNetStatus(status: status)
        }
    }
}

extension MeetTabViewModel: TabListGrootCellObserver, TabMeetingGrootCellObserver, TabUserGrootCellObserver {
    func openGrootChannel(type: GrootChannelType, channelID: String?, downVersion: Int32) {
        grootChannelQueue.async { [weak self] in
            guard let self = self else { return }
            let channel = self.channel(type: type, channelID: channelID)
            if self.grootChannelOpened.keys.contains(channel) {
                return
            }
            let session: GrootSession
            let version: Int64?
            switch type {
            case .vcTabUserChannel:
                session = TabUserGrootSession.get(channel, userId: self.userId, observer: self)
                version = nil
            case .vcTabMeetingChannel:
                session = TabMeetingGrootSession.get(channel, userId: self.userId, observer: self)
                version = Int64(downVersion)
            case .vcTabListChannel:
                session = TabListGrootSession.get(channel, userId: self.userId, observer: self)
                version = Int64(downVersion)
            default:
                return
            }
            session.open(version: version) { [weak self] r in
                switch r {
                case .success:
                    self?.grootChannelOpened[channel] = session
                case .failure:
                    self?.grootChannelOpened.removeValue(forKey: channel)
                }
            }
        }
    }

    func closeGrootChannel(type: GrootChannelType, channelID: String? = nil) {
        grootChannelQueue.async { [weak self] in
            guard let self = self else { return }
            self.grootChannelOpened.removeValue(forKey: self.channel(type: type, channelID: channelID))
        }
    }

    private func channel(type: GrootChannelType, channelID: String?) -> GrootChannel {
        GrootChannel(id: channelID ?? type.channelID(userId: self.userId), type: type)
    }

    func didReceiveTabListGrootCells(_ cells: [TabListGrootCell], for channel: GrootChannel) {
        let payloads = cells.map { cell -> TabListGrootCell in
            var item = cell
            item.insertTopItems = cell.insertTopItems.filter({ MeetTabListViewModel.compareVersion($0.showVersion, "5.21.0") <= 0 })
            item.updateItems = cell.updateItems.filter({ MeetTabListViewModel.compareVersion($0.showVersion, "5.21.0") <= 0 })
            item.calInsertTopItems = cell.calInsertTopItems.filter({ MeetTabListViewModel.compareVersion($0.showVersion, "5.21.0") <= 0 })
            item.calUpdateItems = cell.calUpdateItems.filter({ MeetTabListViewModel.compareVersion($0.showVersion, "5.21.0") <= 0 })
            item.enterpriseInsertTopItems = cell.enterpriseInsertTopItems.filter({ MeetTabListViewModel.compareVersion($0.showVersion, "5.21.0") <= 0 })
            item.enterpriseUpdateItems = cell.enterpriseUpdateItems.filter({ MeetTabListViewModel.compareVersion($0.showVersion, "5.21.0") <= 0 })
            return item
        }
        Self.logger.info("receive tab list push with insertIds: \(payloads.map { $0.insertTopItems.map { $0.historyID } }), updateIds: \(payloads.map { $0.updateItems.map { $0.historyID } }), deleteIds: \(payloads.map { $0.deletedHistoryIds })")
        listGrootSubject.onNext(payloads)
    }

    func didReceiveTabUserGrootCells(_ cells: [TabUserGrootCell], for channel: GrootChannel) {
        Self.logger.info("Receive meeting detail user channel push with payloads: \(cells), channel id: \(channel.id)")
        observers.forEach {
            $0.didReceiveUserGrootCell(cells: cells)
        }
    }

    func didReceiveTabMeetingGrootCells(_ cells: [TabMeetingGrootCell], for channel: GrootChannel) {
        Self.logger.info("Receive meeting detail push with meetingID: \(channel.id), payloads: \(cells)")
        observers.forEach {
            $0.didReceiveMeetingGrootCell(meetingID: channel.id, cells: cells)
        }
    }
}

extension GrootChannelType {
    func channelID(userId: String) -> String {
        if self == .vcTabUserChannel {
            return userId
        } else if self == .vcTabListChannel {
            return "\(userId)_\(TimeZone.current.identifier)"
        } else {
            return ""
        }
    }
}

enum SncToken: String {
    case keypadCopyNumber = "LARK-PSDA-enterprise_keypad_copy_number"
    case keypadPasteNumber = "LARK-PSDA-enterprise_keypad_paste_number"
    case tabListMeetingId = "LARK-PSDA-tab_list_copy_meeting_id"
    case tabListUpcomingMeetingId = "LARK-PSDA-tab_list_copy_upcoming_meeting_id"
    case tabPageMeetingContent = "LARK-PSDA-tab_page_copy_meeting_content"
}

enum GuideKey: String, CaseIterable {
    case tabList = "vc_tab_recentmeetings_onboarding"
    case clickQuickShareMinute = "View_G_ClickQuickShareMinute_Onboarding"
}

extension MeetTabViewModel {
    @discardableResult
    func setPasteboardText(_ message: String, token: SncToken, shouldImmunity: Bool = false) -> Bool {
        dependency.setPasteboardText(message, token: token.rawValue, shouldImmunity: shouldImmunity)
    }

    func getPasteboardText(token: SncToken) -> String? {
        dependency.getPasteboardText(token: token.rawValue)
    }

    /// guide key 需要由 PM 申请
    func shouldShowGuide(_ key: GuideKey) -> Bool {
        dependency.shouldShowGuide(key: key.rawValue)
    }

    /// guide key 需要由 PM 申请
    func didShowGuide(_ key: GuideKey) {
        dependency.didShowGuide(key: key.rawValue)
    }
}
