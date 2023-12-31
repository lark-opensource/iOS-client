//
//  InMeetGridSortContext.swift
//  ByteView
//
//  Created by chenyizhuo on 2023/1/31.
//

import Foundation
import ByteViewCommon
import ByteViewSetting

enum GridSortTrigger: Int {
    case participants
    case activeSpeaker
    case focus
    case hideSelf
    case hideNonVideo
    case voiceMode
    case displayInfo
    // 最好替换为 role 枚举
    case selfIsHost
    case selfSharing
    case shareSceneType
    case shareGridEnabled
    case reorder
    case isGridDragging
    case isGridOrderSyncing
}

enum GridReorderAction: Equatable {
    case none
    case swap(i: Int, j: Int)
    case move(from: Int, to: Int)
}

/// 会中宫格排序上下文，能够记录变化值的类型，线程安全
class InMeetGridSortContext {
    private let lock = RwLock()

    private var _allParticipants: [ByteviewUser: InMeetGridCellViewModel] = [:]
    var allParticipants: [ByteviewUser: InMeetGridCellViewModel] {
        get {
            lock.withRead { _allParticipants }
        }
        set {
            lock.withWrite {
                _allParticipants = newValue
                _changedTypes.insert(.participants)
            }
        }
    }

    private var _asInfos: [ActiveSpeakerInfo] = []
    var asInfos: [ActiveSpeakerInfo] {
        get {
            lock.withRead { _asInfos }
        }
        set {
            lock.withWrite {
                _asInfos = newValue
                _changedTypes.insert(.activeSpeaker)
            }
        }
    }

    private var _currentActiveSpeaker: ByteviewUser?
    var currentActiveSpeaker: ByteviewUser? {
        get {
            lock.withRead { _currentActiveSpeaker }
        }
        set {
            lock.withWrite {
                if _currentActiveSpeaker != newValue {
                    _currentActiveSpeaker = newValue
                    _changedTypes.insert(.activeSpeaker)
                }
            }
        }
    }

    private var _focusingParticipantID: ByteviewUser?
    var focusingParticipantID: ByteviewUser? {
        get {
            lock.withRead { _focusingParticipantID }
        }
        set {
            lock.withWrite {
                if _focusingParticipantID != newValue {
                    _focusingParticipantID = newValue
                    _changedTypes.insert(.focus)
                }
            }
        }
    }

    private var _isHideSelf = false
    var isHideSelf: Bool {
        get {
            lock.withRead { _isHideSelf }
        }
        set {
            lock.withWrite {
                if _isHideSelf != newValue {
                    _isHideSelf = newValue
                    _changedTypes.insert(.hideSelf)
                }
            }
        }
    }

    private var _isHideNonVideo = false
    var isHideNonVideo: Bool {
        get {
            lock.withRead { _isHideNonVideo }
        }
        set {
            lock.withWrite {
                if _isHideNonVideo != newValue {
                    _isHideNonVideo = newValue
                    _changedTypes.insert(.hideNonVideo)
                }
            }
        }
    }

    private var _isVoiceMode = false
    var isVoiceMode: Bool {
        get {
            lock.withRead { _isVoiceMode }
        }
        set {
            lock.withWrite {
                if _isVoiceMode != newValue {
                    _isVoiceMode = newValue
                    _changedTypes.insert(.voiceMode)
                }
            }
        }
    }

    private var _displayInfo = GridDisplayInfo(visibleRange: .page(index: 0), displayMode: .gridVideo)
    var displayInfo: GridDisplayInfo {
        get {
            lock.withRead { _displayInfo }
        }
        set {
            lock.withWrite {
                let isDisplayModeChanged = _displayInfo.displayMode != newValue.displayMode
                let isVisibleRangeChanged: Bool
                switch (_displayInfo.visibleRange, newValue.visibleRange) {
                case (.page, .range): isVisibleRangeChanged = true
                case (.range, .page): isVisibleRangeChanged = true
                default: isVisibleRangeChanged = false
                }
                // 永远更新 displayMode 和 visibleRange
                _displayInfo = newValue
                // 只有 displayMode 和 visibleRange 的类型更新时对外通知， 变化不影响宫格重排
                if isDisplayModeChanged || isVisibleRangeChanged {
                    _changedTypes.insert(.displayInfo)
                }
            }
        }
    }

    private var _selfIsHost = false
    var selfIsHost: Bool {
        get {
            lock.withRead { _selfIsHost }
        }
        set {
            lock.withWrite {
                if _selfIsHost != newValue {
                    _selfIsHost = newValue
                    _changedTypes.insert(.selfIsHost)
                }
            }
        }
    }

    private var _selfSharing = false
    var selfSharing: Bool {
        get {
            lock.withRead { _selfSharing }
        }
        set {
            lock.withWrite {
                if _selfSharing != newValue {
                    _selfSharing = newValue
                    _changedTypes.insert(.selfSharing)
                }
            }
        }
    }

    private var _shareGridEnabled = false
    var shareGridEnabled: Bool {
        get {
            lock.withRead { _shareGridEnabled }
        }
        set {
            lock.withWrite {
                if _shareGridEnabled != newValue {
                    _shareGridEnabled = newValue
                    _changedTypes.insert(.shareGridEnabled)
                }
            }
        }
    }

    private var _shareSceneType: InMeetShareSceneType = .none
    var shareSceneType: InMeetShareSceneType {
        get {
            lock.withRead { _shareSceneType }
        }
        set {
            lock.withWrite {
                if _shareSceneType != newValue {
                    _shareSceneType = newValue
                    _changedTypes.insert(.shareSceneType)
                }
            }
        }
    }

    private var _reorderAction: GridReorderAction = .none
    var reorderAction: GridReorderAction {
        get {
            lock.withRead { _reorderAction }
        }
        set {
            lock.withWrite {
                if _reorderAction != newValue {
                    _reorderAction = newValue
                    _changedTypes.insert(.reorder)
                }
            }
        }
    }

    private var _isGridDragging = false
    var isGridDragging: Bool {
        get {
            lock.withRead { _isGridDragging }
        }
        set {
            lock.withWrite {
                if _isGridDragging != newValue {
                    _isGridDragging = newValue
                    _changedTypes.insert(.isGridDragging)
                }
            }
        }
    }

    private var _isGridOrderSyncing = false
    var isGridOrderSyncing: Bool {
        get {
            lock.withRead { _isGridOrderSyncing }
        }
        set {
            lock.withWrite {
                if _isGridOrderSyncing != newValue {
                    _isGridOrderSyncing = newValue
                    _changedTypes.insert(.isGridOrderSyncing)
                }
            }
        }
    }

    // 为了方便单元测试
    var isPhone = Display.phone
    var isNewLayoutEnabled = InMeetFlowComponent.isNewLayoutEnabled

    private var _changedTypes: Set<GridSortTrigger> = []
    var changedTypes: Set<GridSortTrigger> {
        lock.withRead { _changedTypes }
    }

    private var _currentSortResult: [GridSortOutputEntry] = []
    var currentSortResult: [GridSortOutputEntry] {
        lock.withRead { _currentSortResult }
    }

    private var _orderFromServer: [GridSortOutputEntry] = []
    var orderFromServer: [GridSortOutputEntry] {
        lock.withRead { _orderFromServer }
    }

    private var _isDirty = false
    var isDirty: Bool {
        lock.withRead { _isDirty }
    }

    let videoSortConfig: VideoSortConfig
    let nonVideoConfig: HideNonVideoConfig
    let activeSpeakerConfig: ActiveSpeakerConfig
    let isWebinar: Bool

    init(videoSortConfig: VideoSortConfig,
         nonVideoConfig: HideNonVideoConfig,
         activeSpeakerConfig: ActiveSpeakerConfig,
         isSelfSharingContent: Bool,
         shareSceneType: InMeetShareSceneType,
         isHost: Bool,
         focusID: ByteviewUser?,
         isHideSelf: Bool,
         isHideNonVideo: Bool,
         isVoiceMode: Bool,
         isWebinar: Bool
    ) {
        self.videoSortConfig = videoSortConfig
        self.nonVideoConfig = nonVideoConfig
        self.activeSpeakerConfig = activeSpeakerConfig
        self.isWebinar = isWebinar
        _selfSharing = isSelfSharingContent
        _shareSceneType = shareSceneType
        _selfIsHost = isHost
        _focusingParticipantID = focusID
        _isHideSelf = isHideSelf
        _isHideNonVideo = isHideNonVideo
    }

    private init(other: InMeetGridSortContext) {
        self.videoSortConfig = other.videoSortConfig
        self.nonVideoConfig = other.nonVideoConfig
        self.activeSpeakerConfig = other.activeSpeakerConfig
        self.isWebinar = other.isWebinar
        other.lock.withWrite {
            _allParticipants = other._allParticipants
            _currentActiveSpeaker = other._currentActiveSpeaker
            _asInfos = other._asInfos
            _focusingParticipantID = other._focusingParticipantID
            _isVoiceMode = other._isVoiceMode
            _isHideSelf = other._isHideSelf
            _isHideNonVideo = other._isHideNonVideo
            _displayInfo = other._displayInfo
            _selfIsHost = other._selfIsHost
            _selfSharing = other._selfSharing
            _shareSceneType = other._shareSceneType
            _shareGridEnabled = other._shareGridEnabled
            _reorderAction = other._reorderAction
            _changedTypes = other._changedTypes
            _currentSortResult = other._currentSortResult
            _orderFromServer = other._orderFromServer
            _isDirty = other._isDirty
            _isGridDragging = other._isGridDragging
            _isGridOrderSyncing = other._isGridOrderSyncing
        }
    }

    func markDirty() {
        lock.withWrite {
            _isDirty = true
        }
    }

    func markClean() {
        lock.withWrite {
            _reorderAction = .none
            _changedTypes.removeAll()
            _isDirty = false
        }
    }

    func updateCurrentSortResult(_ result: [GridSortOutputEntry]) {
        lock.withWrite {
            _currentSortResult = result
        }
    }

    func updateOrderFromServer(_ order: [GridSortOutputEntry]) {
        lock.withWrite {
            _orderFromServer = order
        }
    }

    var snapshot: InMeetGridSortContext {
        InMeetGridSortContext(other: self)
    }
}

extension InMeetGridSortContext: CustomStringConvertible {
    var description: String {
        lock.withRead {
            let desc = [
                "allParticipants.count: \(_allParticipants.count)",
                "asInfos.count: \(_asInfos.count)",
                "currentAS: \(_currentActiveSpeaker)",
                "focusID: \(_focusingParticipantID)",
                "hideSelf: \(_isHideSelf)",
                "hideNonVideo: \(_isHideNonVideo)",
                "voiceMode: \(_isVoiceMode)",
                "displayInfo: \(_displayInfo)",
                "shareGridEnabled: \(_shareGridEnabled)",
                "shareType: \(_shareSceneType)",
                "selfSharing: \(_selfSharing)",
                "selfIsHost: \(_selfIsHost)",
                "reorderAction: \(_reorderAction)",
                "isGridDragging: \(_isGridDragging)",
                "isGridOrderSyncing: \(_isGridOrderSyncing)"
            ].joined(separator: ", ")
            return "InMeetGridSortContext(\(desc))"
        }
    }
}
