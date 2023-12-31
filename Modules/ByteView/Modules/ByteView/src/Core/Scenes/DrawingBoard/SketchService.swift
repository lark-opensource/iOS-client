//
//  SketchService.swift
//  ByteView
//
//  Created by 刘建龙 on 2019/11/29.
//

import Foundation
import RxSwift
import RxRelay
import ByteViewNetwork

// 按照开启标注流程，对应每个阶段顺序往下执行。
enum SketchStatus: Equatable {
    case none
    case requestStarting
    case requestStartSuccess(canOtherSketch: Bool)
    case requestStartFailed
    case fetching
    case fetchSuccess(version: Int32, currentStep: Int32, units: [SketchDataUnit])
    case fetchFailed
    case opening
    case openFailed
    case connecting
    case connected
}

extension SketchDataUnit.ShapeType {
    var briefDescription: String {
        switch self {
        case .arrow:
            return "arrow"
        case .comet:
            return "commet"
        case .line:
            return "line"
        case .oval:
            return "oval"
        case .pencil:
            return "pencil"
        case .rectangle:
            return "rectangle"
        case .text:
            return "text"
        @unknown default:
            return "unknown-\(self.rawValue)"
        }
    }
}

extension SketchOperationUnit {
    var briefDescription: String {
        switch self.cmd {
        case .remove:
            return "remove, \(self.removeData.removeType) \(self.removeData.ids)"
        case .update, .add:
            return "\(self.cmd) \(self.sketchUnits.map({ ($0.shapeType.briefDescription, $0.shapeID, $0.user.deviceID) }))"
        @unknown default:
            return "\(self.cmd)"
        }
    }
}

enum ByteViewSketch {
    static var logger = Logger.sketch
}

protocol SketchServiceDelegate: AnyObject {
    func receiveGrootCell(cells: [SketchGrootCell])
    func sketchStatusDidChange(currentStatus: SketchStatus, preStatus: SketchStatus)
    func showOtherCannotSketchTip()
}

// 标注流程：
// 主动开启：首先调用SketchStartRequest，然后FetchAllSketchDataRequest，最后openGrootChannel
// 被动开启：首先调用FetchAllSketchDataRequest，然后openGrootChannel
// 如果处于开启中状态，后续重新开启的动作将被跳过
// 一旦开启成功过，endSketch之前，后续就不需要再次开启
class SketchService: GrootSessionDelegate, SketchGrootCellObserver {

    private let meeting: InMeetMeeting
    private let shareScreenID: String

    private var httpClient: HttpClient { meeting.httpClient }
    weak var delegate: SketchServiceDelegate?
    var currentStatus: SketchStatus = .none {
        didSet {
            guard oldValue != currentStatus else { return }
            self.sketchStatusChanged(oldStatus: oldValue, newStatus: currentStatus)
        }
    }
    private var grootSession: SketchGrootSession?
    var isActive: Bool = false

    init(meeting: InMeetMeeting, shareScreenID: String) {
        self.meeting = meeting
        self.shareScreenID = shareScreenID
    }

    func startSketch(isActive: Bool) {
        // 上一次开启失败或者未开启过，需要重新开启。
        let isNeedRestart = [.none, .requestStartFailed, .fetchFailed, .openFailed].contains(currentStatus)
        ByteViewSketch.logger.info("start sketch, isActive: \(isActive), isNeedRestart: \(isNeedRestart)")
        // 主动开启和被动开启,流程不相同
        if isNeedRestart {
            self.isActive = isActive
            if isActive {
                requestToStartSketch()
            } else {
                fetchAllSketchData(isActive: isActive)
            }
        } else {
            // 如果正在打开标注的过程中，接收到被动开启动作，忽略赋值
            if isActive {
                self.isActive = isActive
            }
            // 等待上次的结果，直接跳过本次。
        }
    }

    // 向服务端请求发起标注，主动发起才需要
    private func requestToStartSketch() {
        let httpClient = self.httpClient
        ByteViewSketch.logger.info("requestToStartSketch shareScreenID: \(shareScreenID)")
        let preStatus = self.currentStatus
        delegate?.sketchStatusDidChange(currentStatus: .requestStarting, preStatus: preStatus)
        currentStatus = .requestStarting
        let request = SketchStartRequest(meetingId: meeting.meetingId, shareScreenId: shareScreenID, breakoutRoomId: meeting.setting.breakoutRoomId)
        httpClient.getResponse(request) { [weak self] result in
            guard let self = self else { return }
            let preStatus = self.currentStatus
            switch result {
            case .success(let response):
                ByteViewSketch.logger.info("requestToStartSketch(shareScreenID:\(self.shareScreenID)), canOtherSketch: \(response.canOtherSketch) succeed!")
                let newStatus: SketchStatus = .requestStartSuccess(canOtherSketch: response.canOtherSketch)
                self.delegate?.sketchStatusDidChange(currentStatus: newStatus, preStatus: preStatus)
                self.currentStatus = newStatus
            case .failure(let error):
                ByteViewSketch.logger.error("requestToStartSketch(shareScreenID:\(self.shareScreenID)), failed \(error)!")
                self.delegate?.sketchStatusDidChange(currentStatus: .requestStartFailed, preStatus: preStatus)
                self.currentStatus = .requestStartFailed
            }
        }
    }

    // 拉取远端最新数据
    private func fetchAllSketchData(isActive: Bool) {
        ByteViewSketch.logger.info("fetchAllSketchData shareScreenID: \(shareScreenID), isActive: \(isActive)")
        let preStatus = currentStatus
        delegate?.sketchStatusDidChange(currentStatus: .fetching, preStatus: preStatus)
        currentStatus = .fetching
        let request = FetchAllSketchDataRequest(shareScreenId: shareScreenID)
        self.httpClient.getResponse(request) { [weak self] result in
            guard let self = self else { return }
            let preStatus = self.currentStatus
            switch result {
            case .success(let response):
                let units = response.sketchUnits.sorted(by: { $0.currentStep < $1.currentStep })
                ByteViewSketch.logger.info("fetchAllSketchData: version:\(response.version), unitsCount:\(units.count), currentStep:\(response.currentStep)")
                let newStatus: SketchStatus = .fetchSuccess(version: response.version, currentStep: response.currentStep, units: units)
                self.delegate?.sketchStatusDidChange(currentStatus: newStatus, preStatus: preStatus)
                self.currentStatus = newStatus
            case .failure:
                ByteViewSketch.logger.error("fetchAllSketchData shareScreenID: \(self.shareScreenID), failed: \(VCError.fetchAllSketchDataFailed)")
                self.delegate?.sketchStatusDidChange(currentStatus: .fetchFailed, preStatus: preStatus)
                self.currentStatus = .fetchFailed
            }
        }
    }

    // 开启groot，注意，如果open返回的status为close，rust会重试，不代表打开失败，视为正在打开中，等状态状态更新
    private func openSketchChannel(version: Int32) {
        ByteViewSketch.logger.info("openingGrootChannel id: \(shareScreenID)")
        let preStatus = currentStatus
        currentStatus = .opening
        delegate?.sketchStatusDidChange(currentStatus: currentStatus, preStatus: preStatus)
        self.grootSession = .get(GrootChannel(id: shareScreenID, type: .sketch), userId: self.meeting.userId)
        self.grootSession?.delegate = self
        self.grootSession?.notifier.addObserver(self)
        self.grootSession?.open(version: Int64(version)) { [weak self] result in
            guard let self = self else { return }
            let preStatus = self.currentStatus
            switch result {
            case .success(let status):
                let sketchStatus = Self.mapChannelStatus(status)
                let newStatus: SketchStatus
                if sketchStatus == .openFailed {
                    newStatus = .openFailed
                } else if sketchStatus == .connecting {
                    newStatus = .connecting
                } else if sketchStatus == .connected {
                    newStatus = .connected
                } else {
                    newStatus = .openFailed
                }
                self.delegate?.sketchStatusDidChange(currentStatus: newStatus, preStatus: preStatus)
                self.currentStatus = newStatus
                ByteViewSketch.logger.info("openingGrootChannel success id: \(self.shareScreenID), status: \(status), currentStatus: \(self.currentStatus)")
            case .failure(let error):
                ByteViewSketch.logger.info("openingGrootChannel error id: \(self.shareScreenID), error: \(error)")
                self.delegate?.sketchStatusDidChange(currentStatus: .openFailed, preStatus: preStatus)
                self.currentStatus = .openFailed
            }
        }
    }

    private func sketchStatusChanged(oldStatus: SketchStatus, newStatus: SketchStatus) {
        switch (oldStatus, newStatus) {
        // 主动开启标注，请求开启成功后，自动进入拉去数据阶段
        case (.requestStarting, .requestStartSuccess(canOtherSketch: let canOtherSketch)):
            if !canOtherSketch {
                self.delegate?.showOtherCannotSketchTip()
            }
            self.fetchAllSketchData(isActive: true)
        // 拉去数据成功后，自动进入开启groot流程
        case (.fetching, .fetchSuccess(version: let version, currentStep: _, units: _)):
            self.openSketchChannel(version: version)
        default:
            break
        }
    }

    func sessionDidChangeStatus(session: GrootSession, oldValue: GrootChannelStatus) {
        ByteViewSketch.logger.info("sketch groot status changed, currentStatus = \(currentStatus), sessionStatus: \(session.status)")
        // groot状态恢复。（rust返回close，内部会不断充实，groot状态可能得到更新）
        if currentStatus == .connecting, session.status == .connected {
            let preStatus = currentStatus
            currentStatus = .connected
            delegate?.sketchStatusDidChange(currentStatus: currentStatus, preStatus: preStatus)
        }
    }

    func didReceiveSketchGrootCells(_ cells: [SketchGrootCell], for channel: GrootChannel) {
        delegate?.receiveGrootCell(cells: cells)
    }

    func didReceiveSketchGrootCells(_ cells: [SketchGrootCell], sender: [ByteviewUser?], for channel: GrootChannel) {
        let minCount = min(cells.count, sender.count)
        guard minCount > 0 else { return }
        var newCells: [SketchGrootCell] = []
        for i in 0..<minCount {
            // 过滤掉自己的数据
            if let user = sender[i], user == meeting.account {
                continue
            } else {
                newCells.append(cells[i])
            }
        }
        delegate?.receiveGrootCell(cells: newCells)
    }

    func send(units: [SketchOperationUnit]) {
        for unit in units {
            ByteViewSketch.logger.info("send unit: \(unit.briefDescription)")
        }
        let cells = [SketchGrootCell(meetingID: meeting.meetingId, units: units)]
        if let session = self.grootSession {
            session.sendCells(cells, sender: meeting.account)
        } else {
            ByteViewSketch.logger.warn("send units when grootSession is nil")
            SketchGrootSession.get(GrootChannel(id: shareScreenID, type: .sketch), userId: meeting.userId).sendCells(cells, sender: meeting.account)
        }
    }

    private static func mapChannelStatus(_ channelStatus: GrootChannelStatus) -> SketchStatus {
        ByteViewSketch.logger.info("groot channel status: \(channelStatus)")
        switch channelStatus {
        case .connecting:
            return .connecting
        case .closed:
            return .connecting
        case .connected:
            return .connected
        case .willBeClosed:
            return .connected
        default:
            return .openFailed
        }
    }
}
