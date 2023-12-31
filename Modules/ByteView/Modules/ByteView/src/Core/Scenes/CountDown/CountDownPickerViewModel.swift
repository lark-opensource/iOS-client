//
//  CountDownPickerViewModel.swift
//  ByteView
//
//  Created by wulv on 2022/4/19.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker

enum CountDownPickTime: Equatable {
    case hour(Int)
    case minute(Int)
}

extension CountDownPickTime {

    static let invalidHour: CountDownPickTime = .hour(-1)
    static let invalidMinute: CountDownPickTime = .minute(-1)

    // ---- 没有记忆值时，取默认值 -----
    static let defaultHour: Int = 0
    static let defaultMinute: Int = 5
    // ---- 延长时间默认值 ------
    static let defaultProlongHour: Int = 0
    static let defaultProlongMinute: Int = 1

    var value: Int {
        switch self {
        case .hour(let h):
            return h
        case .minute(let m):
            return m
        }
    }

    var isInvalid: Bool {
        switch self {
        case .hour:
            return self == Self.invalidHour
        case .minute:
            return self == Self.invalidMinute
        }
    }

    var isProlongDefault: Bool {
        switch self {
        case .hour:
            return value == Self.defaultProlongHour
        case .minute:
            return value == Self.defaultProlongMinute
        }
    }

    func isLocalSave(db: CountDownDatabase) -> Bool {
        let lastMinute = db.lastSetMinute
        switch self {
        case .hour:
            if lastMinute > 0 {
                return value == lastMinute / 60
            } else {
                return value == Self.defaultHour
            }
        case .minute:
            if lastMinute > 0 {
                return value == lastMinute % 60
            } else {
                return value == Self.defaultMinute
            }
        }
    }

    func toSeconds() -> Int64 {
        switch self {
        case .hour(let h):
            return Int64(h * 60 * 60)
        case .minute(let m):
            return Int64(m * 60)
        }
    }

    func toMinutes() -> Int {
        switch self {
        case .hour(let h):
            return h * 60
        case .minute(let m):
            return m
        }
    }
}

struct PickerCellModel {
    let title: NSAttributedString
    let time: CountDownPickTime

    init(time: CountDownPickTime) {
        self.time = time

        var text: String = ""
        if !time.isInvalid {
            switch time {
            case .hour(let h):
                text = "\(h) " + I18n.View_G_HourUnit
            case .minute(let m):
                text = "\(m) " + I18n.View_G_MinuteUnit
            }
        }
        self.title = NSAttributedString(string: text, config: .h4, textColor: UIColor.ud.textTitle)
    }

    var isProlongDefaultTime: Bool {
        time.isProlongDefault
    }

    func isLocalSaveTime(db: CountDownDatabase) -> Bool {
        time.isLocalSave(db: db)
    }
}

typealias PickerTimeColumn = [PickerCellModel]

class CountDownPickerViewModel {

    enum Orientation {
        case portrait
        case landscape

        var placeholdCount: Int {
            switch self {
            case .portrait: return 3
            case .landscape: return 2
            }
        }
    }
    var orientation: Orientation = .portrait {
        didSet {
            if oldValue != orientation {
                resetDatasource()
            }
        }
    }

    enum PageSource {
        case more
        case reset
        case prolong
    }
    var pageSource: PageSource = .more

    var style: CountDownPickerViewController.Style = .start

    let meeting: InMeetMeeting
    let manager: CountDownManager
    lazy var db = CountDownDatabase(storage: meeting.storage)
    init(meeting: InMeetMeeting, manager: CountDownManager, orientation: Orientation = .portrait) {
        self.meeting = meeting
        self.manager = manager
        self.orientation = orientation
        resetDatasource()
    }

    private(set) var pickerDataSource: [PickerTimeColumn] = []

    /// 各列选中的时间模型，初始值为defaultTime
    private(set) lazy var selectTime: [CountDownPickTime] = {
        let useLocalSave: Bool = style == .start
        return pickerDataSource.compactMap {
            $0.first(where: { cellM in
                useLocalSave ? cellM.isLocalSaveTime(db: db) : cellM.isProlongDefaultTime
            })?.time
        }
    }()

    /// 是否启用结束提示音
    private(set) lazy var enableAudio: Bool = {
        let local = db.isEndAudioEnabled
        if local == 1 {
            // 上次设过开
            return true
        } else if local == -1 {
            // 上次设过关
            return false
        } else {
            // 未设
            return true
        }
    }()

    /// 剩余时间提醒值
    lazy var remindTime: CountDownRemindPickTime? = {
        let last = db.lastRemindMinute
        if last > 0 {
            // 上次设过某个值
            return .minute(last)
        } else if last == -1 {
            // 上次设成“无”
            return  CountDownRemindPickTime.firstMinute
            // 上次未设，使用默认值
        } else {
            return .minute(CountDownRemindPickerViewModel.defaultMinute)
        }
    }()

    private func resetDatasource() {
        // disable-lint: magic number
        var hours = (0...23).map { PickerCellModel(time: CountDownPickTime.hour($0)) }
        var minutes = (0...59).map { PickerCellModel(time: CountDownPickTime.minute($0)) }
        // enable-lint: magic number
        [CountDownPickTime](repeatElement(CountDownPickTime.invalidHour, count: orientation.placeholdCount)).forEach {
            let placeholderHour = PickerCellModel(time: $0)
            hours.insert(placeholderHour, at: 0)
            hours.append(placeholderHour)
        }
        [CountDownPickTime](repeatElement(CountDownPickTime.invalidMinute, count: orientation.placeholdCount)).forEach {
            let placeholderMinute = PickerCellModel(time: $0)
            minutes.insert(placeholderMinute, at: 0)
            minutes.append(placeholderMinute)
        }
        pickerDataSource = [hours, minutes]
    }

    func updateEnableAudio(_ enable: Bool) {
        enableAudio = enable
    }

    func updateSelectTime(column: Int, row: Int) {
        let index = realIndex(row)
        guard let models = pickerDataSource[safeAccess: column], let model = models[safeAccess: index] else {
            Logger.countDown.debug("incorrect select column: \(column), row: \(row)")
            return
        }
        selectTime[column] = model.time
    }

    func enabled(column: Int, row: Int) -> Bool {
        guard let models = pickerDataSource[safeAccess: column], let model = models[safeAccess: row] else {
            Logger.countDown.debug("invalid column: \(column), row: \(row)")
            return false
        }

        var notAllZero = false
        for (i, t) in selectTime.enumerated() {
            let time = i == column ? model.time : t
            if time.isInvalid {
                return false
            }
            if time.value != 0 {
                notAllZero = true
                break
            }
        }
        return notAllZero
    }

    func start() {
        var remindTimes: [Int64] = []
        if let minute = remindTime?.value {
            remindTimes = [Int64(minute * 60)]
            db.lastRemindMinute = minute
        } else {
            db.lastRemindMinute = -1
        }
        let duration = selectDuration()
        let playEndAudio = enableAudio
        let source = pageSource
        manager.requestStart(with: duration * 1000, remindersInSeconds: remindTimes, playEndAudio: playEndAudio) { success in
            var params: TrackParams = [.click: "begin",
                                       .from_source: source,
                                       "countdown_time": duration / 60, // 埋点单位：分
                                       "is_default": 0,
                                       "is_check_audio": playEndAudio,
                                       "is_fail": !success,
                                       "is_check_remind_countdown": remindTimes.isEmpty ? 0 : 1]
            if let seconds = remindTimes.first {
                params["remind_countdown_time"] = seconds / 60
            }
            VCTracker.post(name: .vc_countdown_setup_click, params: params)
        }
        db.lastSetMinute = Int(duration / Int64(60))
        db.isEndAudioEnabled = playEndAudio ? 1 : -1
    }

    func prolong() {
        let duration = selectDuration()
        VCTracker.post(name: .vc_countdown_click,
                       params: [.click: "prolong", "sub_click_type": "customize", "prolong_time": duration / 60]) // 埋点单位: 分
        manager.requestProlong(with: duration * 1000)
    }

    /// 选择的时长(分）
    func selectMinute() -> Int {
        var sum: Int = 0
        selectTime.forEach {
            sum += $0.toMinutes()
        }
        return sum
    }
}

extension CountDownPickerViewModel {

    /// picker回调的index是可选范围的row，需加上占位得到真实的index
    func realIndex(_ row: Int) -> Int {
        return row + orientation.placeholdCount
    }

    /// 选择的时长(秒）
    private func selectDuration() -> Int64 {
        var sum: Int64 = 0
        selectTime.forEach {
            sum += $0.toSeconds()
        }
        return sum
    }
}
