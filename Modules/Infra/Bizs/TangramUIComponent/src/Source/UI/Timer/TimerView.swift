//
//  TimerView.swift
//  UDDemo
//
//  Created by houjihu on 2021/4/9.
//

import Foundation
import UIKit
import SnapKit

/// 计时器，支持倒计时/正计时，最细粒度是秒级
/// 1）正计时规则：显示从「分｜秒」开始，超过一小时显示「时｜分｜秒」，每一间隔最低显示两位
/// 1）倒计时规则：根据传入的总时间决定，超过一小时显示「时｜分｜秒」，否则显示「分｜秒」，每一间隔最低显示两位
public final class TimerView: UIView {
    public static var defaultFont: UIFont { UIFont.ud.body2 }
    /// 文字颜色
    public static var defaultTextColor: UIColor { UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.5) }
    /// 文本水平方向空白间距
    static let textHorizontalMargin = CGFloat(1.0)

    /// 是否是倒计时
    public var countDown: Bool {
        didSet {
            start()
        }
    }

    /// 倒计时开始时间
    public var startTime: Int64 {
        didSet {
            start()
        }
    }

    /// 倒计时结束时间
    public var endTime: Int64? {
        didSet {
            start()
        }
    }

    /// 倒计时是否结束
    public var isEnd: Bool {
        didSet {
            if isEnd {
                updateTime()
            } else {
                start()
            }
        }
    }

    public var font: UIFont {
        didSet {
            timeLabel.font = font
        }
    }

    public var textColor: UIColor = TimerView.defaultTextColor {
        didSet {
            timeLabel.textColor = textColor
        }
    }

    public var textAlignment: NSTextAlignment = .left {
        didSet {
            timeLabel.textAlignment = textAlignment
        }
    }

    /// 显示时间的label
    lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.textColor = textColor
        label.font = self.font
        label.numberOfLines = 1
        return label
    }()

    var timer: Timer?

    // MARK: life cycle
    /// 初始化计时器视图
    /// - Parameters:
    ///   - countDown: 是否是倒计时
    ///   - startTime: 倒计时开始时间
    public init(countDown: Bool = false,
                font: UIFont = TimerView.defaultFont,
                textColor: UIColor = TimerView.defaultTextColor,
                startTime: Int64 = 0,
                endTime: Int64? = nil,
                isEnd: Bool = false,
                textAlignment: NSTextAlignment = .left) {
        self.countDown = countDown
        self.font = font
        self.textColor = textColor
        self.startTime = startTime
        self.endTime = endTime
        self.isEnd = isEnd
        self.textAlignment = textAlignment
        super.init(frame: .zero)
        setupViews()
    }

    /// 根据传入的属性，获取适合显示的视图大小
    /// - Returns: 适合显示的视图大小
    public class func fitSize(size: CGSize, font: UIFont = TimerView.defaultFont) -> CGSize {
        // 最多显示99:99:99，按最大算定宽，否则计时过程中宽度变化会闪动
        let attr = NSAttributedString(string: "99:99:99", attributes: [.font: font])
        let textSize = attr.componentTextSize(for: size, limitedToNumberOfLines: 1)
        return CGSize(width: textSize.width + textHorizontalMargin, height: textSize.height)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        timeLabel.textAlignment = textAlignment
        timeLabel.textColor = textColor
        timeLabel.font = font
        addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        updateTime()
    }

    func updateTime() {
        var duration = computeDuration()
        // 兼容计算出的负值
        duration = max(0, duration)
        self.timeLabel.text = Self.timeString(seconds: duration)
    }

    func computeDuration() -> Int64 {
        var duration: Int64 = 0
        if self.isEnd { // 如果计时结束，则使用endTime计算duration
            self.stop()
            duration = self.countDown ? (self.startTime - (self.endTime ?? 0)) : ((self.endTime ?? 0) - self.startTime)
            return duration
        }
        let current = Int64(CFAbsoluteTimeGetCurrent() + kCFAbsoluteTimeIntervalSince1970)
        if let endTime = endTime, current >= endTime { // 当前时间超过结束时间，则计时结束
            self.stop()
            duration = self.countDown ? (self.startTime - endTime) : (endTime - self.startTime)
            return duration
        }
        // 正常计时
        duration = self.countDown ? (self.startTime - current) : (current - self.startTime)
        return duration
    }

    /// 获取用于显示的时间字符串
    /// 超过一小时显示「时｜分｜秒」，否则显示「分｜秒」，每一间隔最低显示两位
    class func timeString(seconds: Int64) -> String {
        let secondsForOneHour: Int64 = 60 * 60
        let secondsForOneMinute: Int64 = 60
        let calculatedHours = seconds / secondsForOneHour
        let calculatedMinutes = (seconds - calculatedHours * secondsForOneHour) / secondsForOneMinute
        let calculatedSeconds = seconds - calculatedHours * secondsForOneHour - calculatedMinutes * secondsForOneMinute
        let formatString = "%02d"
        let minuteAndSecondString = String(format: formatString, calculatedMinutes) + ":" + String(format: formatString, calculatedSeconds)
        if calculatedHours > 0 {
            return String(format: formatString, calculatedHours) + ":" + minuteAndSecondString
        }
        return minuteAndSecondString
    }

    deinit {
        stop()
    }
}

public extension TimerView {

    // MARK: actions
    /// 开始
    func start() {
        if timer != nil {
            timer?.start()
            return
        }
        timer = Timer(timerInterval: 1, handler: { [weak self] _ in
            self?.updateTime()
        })
        timer?.start()
    }
    /// 暂停
    func pause() {
        timer?.pause()
    }
    /// 停止
    func stop() {
        timer?.stop()
    }
}
