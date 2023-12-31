//
//  FeedCardStatusComponent.swift
//  LarkFeedBase
//
//  Created by liuxianyu on 2023/5/10.
//

import Foundation
import LarkOpenFeed
import LarkModel
import RustPB
import UniverseDesignColor
import UniverseDesignTag
import SwiftUI

// MARK: - Factory
public class FeedCardStatusFactory: FeedCardBaseComponentFactory {
    // 组件类别
    public var type: FeedCardComponentType {
        return .status
    }
    public init() {}

    public func creatVM(feedPreview: FeedPreview) -> FeedCardBaseComponentVM {
        return FeedCardStatusComponentVM(feedPreview: feedPreview)
    }

    public func creatView() -> FeedCardBaseComponentView {
        return FeedCardStatusComponentView()
    }
}

// MARK: - ViewModel
public protocol FeedCardStatusVM: FeedCardBaseComponentVM, FeedCardStatusVisible {
    var statusData: FeedCardStatusData { get }
}

public enum FeedCardStatusData {
    case desc(FeedCardStatusConf) // 状态描述。不需要倒计时
    case countDownData(FeedCardStatusCountDownData)// 状态描述。需要倒计时

    public static func `default`() -> FeedCardStatusData {
        return .desc(.default())
    }
}

extension FeedStatusLabel.LabelType {
    var color: UDTag.Configuration.ColorScheme {
        switch self {
        case .primary:
            return UDTag.Configuration.ColorScheme.blue
        case .secondary:
            return UDTag.Configuration.ColorScheme.normal
        case .success:
            return UDTag.Configuration.ColorScheme.green
        case .unknownLabelType:
            return UDTag.Configuration.ColorScheme.normal
        @unknown default:
            return UDTag.Configuration.ColorScheme.normal
        }
    }
}

public struct FeedCardStatusConf {
    public var text: String
    public var color: UDTag.Configuration.ColorScheme

    public init(text: String,
                color: UDTag.Configuration.ColorScheme) {
        self.text = text
        self.color = color
    }

    public static func `default`() -> FeedCardStatusConf {
        return .init(text: "", color: .normal)
    }

    func transfrom() -> UDTag.Configuration {
        return UDTag.Configuration.text(text,
                                        tagSize: .mini,
                                        colorScheme: color,
                                        isOpaque: false)
    }
}

public struct FeedCardStatusCountDownData {
    public let startTime: Int // 时间戳，精度为s
    public let endTime: Int // 时间戳，精度为s
    public let advancedTime: Int // 时间间隔，精度为s
    // TODO: open feed v7.3先临时解决状态组件没有及时显示的问题，后续优化实现
    public var isFlag: Bool = false // 是否被标记
    public init?(
         startTime: Int,
         endTime: Int,
         advancedTime: Int) {
        guard (startTime) != 0 && (endTime != 0) else {
            return nil
        }
        self.startTime = startTime
        self.endTime = endTime
        self.advancedTime = advancedTime
    }

    enum CountDownStatus {
        case earlyAdvanceNotice // 超出【提前x分钟开始预告】
        case advanceNotice(Int) // 提前x分钟开始预告
        case ongoing // 进行中
        case end // 已结束

        func buildStatusConf() -> FeedCardStatusConf {
            switch self {
            case .earlyAdvanceNotice:
                return .default()
            case .advanceNotice(let minutes):
                // x分钟后；分钟级别
                let text = BundleI18n.LarkFeedBase.Lark_Event_NumMinLater_Text(minutes)
                return FeedCardStatusConf(text: text, color: .blue)
            case .ongoing:
                // 进行中
                let text = BundleI18n.LarkFeedBase.Lark_Event_EventInProgress_Status
                return FeedCardStatusConf(text: text, color: .green)
            case .end:
                return .default()
            }
        }
    }

    func transfrom() -> FeedCardStatusCountDownData.CountDownStatus {
        let startTime = startTime
        let endTime = endTime
        let advancedTime = advancedTime
        //获取当前时间
        let now = Date()
        //当前时间的时间戳，精度为秒
        let currentTime = Int(now.timeIntervalSince1970)
        if currentTime < startTime {
            // 开始前
            let diff = startTime - currentTime
            if diff <= advancedTime {
              // 距开始<=x分钟，展示x分钟后；需要倒计时
                let seconds: Double = 60.0
                let result = Int(ceil((Double(diff)) / seconds))
                return .advanceNotice(result)
            } else {
                // 距开始大于x分钟，不展示信息；需要倒计时
                return .earlyAdvanceNotice
            }
        } else {
            // 开始后
            if currentTime <= endTime {
                // 进行中；不需要倒计时
                return .ongoing
            } else {
                // 已结束；不需要倒计时
                return .end
            }
        }
    }
}

// MARK: - ViewModel
final class FeedCardStatusComponentVM: FeedCardStatusVM {
    // 组件类别
    var type: FeedCardComponentType {
        return .status
    }

    // VM 数据
    let statusData: FeedCardStatusData

    let isVisible: Bool

    // 在子线程生成view data
    required init(feedPreview: FeedPreview) {
        let statusLabel = feedPreview.uiMeta.statusLabel
        self.statusData = .desc(FeedCardStatusConf(text: statusLabel.text, color: statusLabel.type.color))
        self.isVisible = statusLabel.isValid
    }
}

// MARK: - View
class FeedCardStatusComponentView: FeedCardBaseComponentView {
    // 组件类别
    var type: FeedCardComponentType {
        return .status
    }

    // 提供布局信息，比如：width、height、padding等（cell初始化进行布局时获取）
    var layoutInfo: LarkOpenFeed.FeedCardComponentLayoutInfo? {
        return nil
    }

    private var timer: Timer?
    private var count: Int = 0

    private weak var tagView: UDTag?
    private var statusVM: FeedCardStatusVM?

    func creatView() -> UIView {
        let tagView = UDTag(configuration: FeedCardStatusConf.default().transfrom())
        tagView.setContentHuggingPriority(.required, for: .horizontal)
        tagView.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.tagView = tagView
        return tagView
    }

    func updateView(view: UIView, vm: FeedCardBaseComponentVM) {
        guard let view = view as? UDTag,
              let vm = vm as? FeedCardStatusVM else {
            stopTimer()
            return
        }
        var preCheckVisible = true
        self.statusVM = vm
        // 因为current time的缘故，所以只能从这里处理数据
        let conf: FeedCardStatusConf
        switch vm.statusData {
        case .desc( let statusConf):
            conf = statusConf
            stopTimer()
        case .countDownData(let countDownData):
            let countDownStatus = countDownData.transfrom()
            switch countDownStatus {
            case .earlyAdvanceNotice:
                // 需要进行倒计时
                self.startTimer()
            case .advanceNotice(_): // 分钟级别
                // 需要进行倒计时
                self.startTimer()
            case .ongoing:
                // 停止倒计时
                self.stopTimer()
            case .end:
                // 停止倒计时
                self.stopTimer()
            }
            conf = countDownStatus.buildStatusConf()
            preCheckVisible = !countDownData.isFlag
        }
        if view.text != conf.text {
            let udConf = conf.transfrom()
            view.updateConfiguration(udConf)
            // TODO: 为了解决UDTag size布局更新的问题（内容撑不起来），需要手动调用下UDTag的 [无效 contentsize]函数，触发重新计算size、正确size更新
            view.invalidateIntrinsicContentSize()
        }
        let isVisible = !conf.text.isEmpty && preCheckVisible
        if isVisible != vm.isVisible {
            // 避免重复赋值
            vm.showOrHiddenView(isVisible: isVisible)
            view.isHidden = !isVisible
        }
    }

    func subscribedEventTypes() -> [FeedCardEventType] {
        return [.didEndDisplay]
    }

    func postEvent(type: FeedCardEventType, value: FeedCardEventValue, object: Any) {
        if case .didEndDisplay = type {
            self.stopTimer()
        }
    }

    private func startTimer() {
        guard self.timer == nil else { return }
        // every 1 second
        let timeInterval: TimeInterval = 1
        timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
        self.count += 1
    }

    private func stopTimer() {
        guard self.timer != nil else { return }
        self.timer?.invalidate()
        self.timer = nil
        self.count -= 1
    }

    @objc
    func timerFired() {
        if self.count > 1 {
            FeedBaseContext.log.error("feedlog/feedcard/render/status. count: \(self.count)")
        }
        guard let view = self.tagView, let vm = self.statusVM else { return }
        updateView(view: view, vm: vm)
    }
}
