//
//  AudioView.swift
//  LarkChat
//
//  Created by chengzhipeng-bytedance on 2018/3/23.
//

import Foundation
import UIKit
import SnapKit
import RichLabel
import UniverseDesignColor

public final class AudioView: UIView, UIGestureRecognizerDelegate {
    public struct ColorConfig {
        public let panColorConfig: PanColorConfig?
        public let stateColorConfig: StateColorConfig?

        public let background: UIColor
        public let lineBackground: UIColor
        public let processLineBackground: UIColor
        public let timeLabelText: UIColor?
        public let invalidTimeLabelText: UIColor?

        public init(
            panColorConfig: PanColorConfig?,
            stateColorConfig: StateColorConfig?,
            background: UIColor,
            lineBackground: UIColor,
            processLineBackground: UIColor,
            timeLabelText: UIColor?,
            invalidTimeLabelText: UIColor?) {
            self.panColorConfig = panColorConfig
            self.stateColorConfig = stateColorConfig
            self.background = background
            self.lineBackground = lineBackground
            self.processLineBackground = processLineBackground
            self.timeLabelText = timeLabelText
            self.invalidTimeLabelText = invalidTimeLabelText
        }
    }

    public struct PanColorConfig {
        public let background: UIColor
        public let readyBorder: UIColor?
        public let playBorder: UIColor?

        public init(
            background: UIColor,
            readyBorder: UIColor?,
            playBorder: UIColor?) {
            self.background = background
            self.readyBorder = readyBorder
            self.playBorder = playBorder
        }
    }

    public struct StateColorConfig {
        public let background: UIColor?
        public let foreground: UIColor?

        public init(background: UIColor?, foreground: UIColor?) {
            self.background = background
            self.foreground = foreground
        }
    }

    public var newSkin: Bool = false

    public enum Style {
        case light // 背景色为白色
        case dark  // 背景色为灰色
        case blue  // 背景色为蓝色
        case clearLight // 背景色为透明色, 线按照light style 显示
        case clearDark  // 背景色为透明色, 线按照dark style 显示
        case clearBlue  // 背景色为透明色, 线按照dark style 显示
    }

    public enum PanState {
        case start
        case end
        case dragging
    }

    public enum State {
        case ready
        case loading(TimeInterval)
        case pause(TimeInterval)
        case playing(TimeInterval)
        case draging(TimeInterval)
    }

    static public let defaultInset: UIEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

    private var needUpdateLayout: Bool = false
    private var needUpdateTitle: Bool = false

    public var colorConfig: ColorConfig? {
        didSet {
            updateUI(style: style, state: state, isValid: isValid)
        }
    }

    public private(set) var edgeInset: UIEdgeInsets = AudioView.defaultInset {
        didSet {
            if oldValue != self.edgeInset {
                self.needUpdateLayout = true
            }
        }
    }

    public private(set) var isValid: Bool = true {
        didSet {
            self.stateBtn.isValid = self.isValid
        }
    }
    public private(set) var style: Style = .light
    public private(set) var state: State = .ready {
        didSet {
            switch self.state {
            case .ready:
                self.stateBtn.status = .playing
                self.currentTime = self.time
                self.panView.panState = .ready
                self.update(process: 0)
            case .pause(let time):
                self.stateBtn.status = .playing
                self.currentTime = time
                self.panView.panState = .play
                self.update(process: time / self.time)
            case .playing(let time):
                self.stateBtn.status = .stop
                self.currentTime = time
                self.panView.panState = .play
                self.update(process: time / self.time)
            case .draging(let time):
                self.stateBtn.status = .stop
                self.currentTime = time
                self.panView.panState = .draging
                self.update(process: time / self.time)
            case .loading(let time):
                self.stateBtn.status = .loading
                self.currentTime = self.time
                self.panView.panState = .ready
                self.update(process: time / self.time)
            }
            self.timeLabel.text = AudioView.format(time: self.currentTime)
            self.updateTimeWidth()
        }
    }

    public private(set) var key: String = ""

    public private(set) var time: TimeInterval = 0
    public private(set) var currentTime: TimeInterval = 0

    public private(set) var minLineWidth: CGFloat = 0 {
        didSet {
            if oldValue != minLineWidth {
                self.needUpdateLayout = true
            }
        }
    }

    public private(set) var text: String = "" {
        didSet {
            if oldValue != text {
                self.needUpdateTitle = true
                self.needUpdateLayout = true
            }
        }
    }

    public private(set) var isAudioRecognizeFinish: Bool = false {
        didSet {
            if oldValue != isAudioRecognizeFinish {
                self.needUpdateTitle = true
                self.needUpdateLayout = true
            }
        }
    }

    private var loadingView: AudioRecognizeLoadingView?

    static private let audioLabelFont: UIFont = UIFont.systemFont(ofSize: 16)
    public private(set) var textLabel: LKLabel = {
        let textLabel = LKLabel()
        textLabel.numberOfLines = 0
        textLabel.textColor = UIColor.ud.N900
        textLabel.font = AudioView.audioLabelFont
        textLabel.backgroundColor = UIColor.clear
        return textLabel
    }()

    public typealias ProcessViewLayoutBlock = (_ window: UIWindow, _ audioView: AudioView, _ maker: ConstraintMaker) -> Void
    public var processViewLayout: ProcessViewLayoutBlock = { (window, audioView, maker) in
        let processViewHeight: CGFloat = 44
        let inset: CGFloat = 16.5
        let space: CGFloat = 6.5

        let findVCBlock: (UIView) -> UIViewController? = { (view) -> UIViewController? in
            var responder: UIResponder? = view
            while responder != nil {
                responder = responder!.next
                if let viewController = responder as? UIViewController {
                    return viewController
                }
            }
            return nil
        }

        let audioRectInWindow = audioView.convert(audioView.bounds, to: window)

        // process view height
        maker.height.equalTo(processViewHeight)

        // process view horizontal constraint
        if UIDevice.current.userInterfaceIdiom == .pad, let vc = findVCBlock(audioView) {
            let vcRectInWindow = vc.view.convert(vc.view.bounds, to: window)
            maker.left.equalTo(max(audioRectInWindow.left - 40, vcRectInWindow.left + inset))
            maker.width.equalTo(min(AudioProcessView.maxWidth, vc.view.bounds.width - 2 * inset))
        } else {
            maker.left.equalTo(inset)
            maker.right.equalTo(-inset)
        }

        // process view vertical constraint
        if audioRectInWindow.top - processViewHeight - space > 0 {
            maker.top.equalTo(audioRectInWindow.top - processViewHeight - space)
        } else {
            maker.top.equalTo(audioRectInWindow.bottom + space)
        }
    }

    private lazy var timeLabel: UILabel = {
        let time = UILabel()
        time.textColor = UIColor.ud.N600
        time.font = UIFont.systemFont(ofSize: 12)
        time.backgroundColor = UIColor.clear
        time.textAlignment = .right
        return time
    }()

    private lazy var stateBtn: AudioStateView = {
        let stateBtn = AudioStateView()
        stateBtn.backgroundColor = colorConfig?.stateColorConfig?.background ?? UIColor.clear
        stateBtn.clipsToBounds = true
        stateBtn.addTarget(self, action: #selector(clickStateBtn), for: .touchUpInside)
        return stateBtn
    }()

    private lazy var widthLine: UIView = {
        var line = UIView()
        return line
    }()

    private lazy var line: UIView = {
        var line = UIView()
        line.backgroundColor = UIColor.ud.N300
        line.layer.cornerRadius = 0.5
        line.layer.masksToBounds = true
        line.setContentHuggingPriority(.defaultLow, for: .horizontal)
        line.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return line
    }()

    // 以下两个 layout line 用于布局不用于显示
    private var hadInitProcessLayout: Bool = false

    private lazy var layoutLine: UIView = {
        var line = UIView()
        line.setContentHuggingPriority(.defaultLow, for: .horizontal)
        line.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return line
    }()

    private lazy var layoutProcessLine: UIView = {
        var line = UIView()
        line.setContentHuggingPriority(.defaultLow, for: .horizontal)
        line.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return line
    }()

    private lazy var processLine: UIView = {
        var line = UIView()
        line.backgroundColor = UIColor.ud.colorfulWathet
        line.layer.cornerRadius = 0.5
        line.layer.masksToBounds = true
        return line
    }()

    // 处理外界手势冲突
    private lazy var counteractGesture: UILongPressGestureRecognizer = {
        let counteractGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleGesture))
        counteractGesture.minimumPressDuration = 0.05
        counteractGesture.cancelsTouchesInView = false
        counteractGesture.delegate = self
        return counteractGesture
    }()

    private lazy var clickGesture: UITapGestureRecognizer = {
        let clickGesture = UITapGestureRecognizer(target: self, action: #selector(handleClickGesture))
        clickGesture.delegate = self
        return clickGesture
    }()

    private lazy var panView: AudioPanView = {
        let panView = AudioPanView()
        if self.style == .blue || self.style == .clearBlue {
            panView.style = .blue
        }
        panView.addTarget(self, action: #selector(handlePanTouchBegin), for: .touchDown)
        panView.addTarget(self, action: #selector(handlePanTouchEnd), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        panView.addTarget(self, action: #selector(handlePanTouchMove(_:event:)), for: [.touchDragEnter, .touchDragExit, .touchDragInside, .touchDragOutside])
        return panView
    }()

    // 点击状态按钮
    public var clickStateBtnAction: (() -> Void)?

    // 拖动响应 action
    public var panAction: ((_ state: PanState, _ progress: TimeInterval) -> Void)?

    public var showProcessView: Bool = true

    // 取单个数字的最大宽度
    private static var numberMaxWidth: CGFloat = {
        let font = UIFont.systemFont(ofSize: 12)
        return (0...9).map({ (index) -> CGFloat in
            let rect = NSString(string: "\(index)").boundingRect(
                with: CGSize(width: 100, height: CGFloat(MAXFLOAT)),
                options: .usesLineFragmentOrigin,
                attributes: [.font: font],
                context: nil)
            return rect.width
        }).max() ?? 0
    }()

    private static var colonWidth: CGFloat = {
        let font = UIFont.systemFont(ofSize: 12)
        let rect = NSString(string: ":").boundingRect(
            with: CGSize(width: 100, height: CGFloat(MAXFLOAT)),
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil)
        return rect.width
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)

        self.needUpdateLayout = true
        self.needUpdateTitle = true
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        self.backgroundColor = UIColor.white

        self.addSubview(self.widthLine)
        self.addSubview(self.textLabel)
        self.addSubview(self.stateBtn)
        self.addSubview(self.layoutLine)
        self.addSubview(self.layoutProcessLine)
        self.addSubview(self.line)
        self.addSubview(self.processLine)
        self.addSubview(self.timeLabel)
        self.addSubview(self.panView)

        self.addGestureRecognizer(self.counteractGesture)
        self.addGestureRecognizer(self.clickGesture)

        self.updateViewConstraintsIfNeeded()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.cleanProcessView()
    }

    public func set(
        key: String,
        time: TimeInterval,
        state: State,
        text: String,
        style: Style,
        edgeInset: UIEdgeInsets = AudioView.defaultInset,
        minLineWidth: CGFloat = 0,
        isAudioRecognizeFinish: Bool,
        isValid: Bool = true) {
        if self.key != key {
            self.cleanProcessView()
        }
        self.key = key
        self.time = time
        self.text = text
        self.isAudioRecognizeFinish = isAudioRecognizeFinish
        self.updateUI(style: style, state: state, isValid: isValid)
        self.edgeInset = edgeInset
        self.minLineWidth = minLineWidth
        self.updateAudioText()
        self.updateViewConstraintsIfNeeded()
        self.panView.isUserInteractionEnabled = isValid
    }

    private func updateUI(style: Style, state: State, isValid: Bool) {
        self.style = style
        panView.colorConfig = colorConfig?.panColorConfig

        timeLabel.textColor = colorConfig?.timeLabelText ?? UIColor.ud.N900
        processLine.backgroundColor = colorConfig?.processLineBackground ?? UIColor.ud.N700

        switch self.style {
        case .light:
            self.line.backgroundColor = colorConfig?.lineBackground ?? UIColor.ud.N400
            self.panView.readyView.layer.borderColor = (colorConfig?.panColorConfig?.readyBorder ?? UIColor.ud.N300).cgColor
            self.backgroundColor = colorConfig?.background ?? UIColor.white
        case .dark:
            self.line.backgroundColor = colorConfig?.lineBackground ?? UIColor.ud.N400.withAlphaComponent(0.5)
            self.panView.readyView.layer.borderColor = (colorConfig?.panColorConfig?.readyBorder ?? UIColor.ud.N400.withAlphaComponent(0.5)).cgColor
            self.backgroundColor = colorConfig?.background ?? UIColor.ud.N200
        case .blue:
            self.line.backgroundColor = colorConfig?.lineBackground ?? UIColor.ud.B700.withAlphaComponent(0.3)
            self.backgroundColor = colorConfig?.background ?? UIColor.clear
            self.timeLabel.textColor = colorConfig?.timeLabelText ?? UIColor.ud.B700
            self.processLine.backgroundColor = colorConfig?.processLineBackground ?? UIColor.ud.B700
            self.panView.readyView.layer.borderColor = (colorConfig?.panColorConfig?.readyBorder ?? UIColor.ud.B300).cgColor
            self.panView.playView.layer.borderColor = (colorConfig?.panColorConfig?.playBorder ?? UIColor.ud.B300).cgColor
        case .clearLight:
            self.line.backgroundColor = colorConfig?.lineBackground ?? UIColor.ud.N400
            self.panView.readyView.layer.borderColor = (colorConfig?.panColorConfig?.readyBorder ?? UIColor.ud.N300).cgColor
            self.backgroundColor = colorConfig?.background ?? UIColor.clear
        case .clearDark:
            self.line.backgroundColor = colorConfig?.lineBackground ?? UIColor.ud.N400.withAlphaComponent(0.5)
            self.panView.readyView.layer.borderColor = (colorConfig?.panColorConfig?.readyBorder ?? UIColor.ud.N400.withAlphaComponent(0.5)).cgColor
            self.backgroundColor = colorConfig?.background ?? UIColor.clear
        case .clearBlue:
            self.line.backgroundColor = colorConfig?.lineBackground ?? UIColor.ud.B700.withAlphaComponent(0.3)
            self.backgroundColor = colorConfig?.background ?? UIColor.clear
            self.timeLabel.textColor = colorConfig?.timeLabelText ?? UIColor.ud.B700
            self.processLine.backgroundColor = colorConfig?.processLineBackground ?? UIColor.ud.B700
            self.panView.readyView.layer.borderColor = (colorConfig?.panColorConfig?.readyBorder ?? UIColor.ud.B300).cgColor
            self.panView.playView.layer.borderColor = (colorConfig?.panColorConfig?.playBorder ?? UIColor.ud.B300).cgColor
        }
        self.stateBtn.style = self.style
        self.stateBtn.colorConfig = colorConfig?.stateColorConfig

        self.state = isValid ? state : .ready
        self.isValid = isValid
        if !self.isValid {
            if self.style == .blue || self.style == .clearBlue {
                self.timeLabel.textColor = colorConfig?.invalidTimeLabelText ?? UIColor.ud.B300
            } else if style == .dark {
                self.timeLabel.textColor = colorConfig?.invalidTimeLabelText ?? UIColor.ud.N400
            } else {
                self.timeLabel.textColor = colorConfig?.invalidTimeLabelText ?? UIColor.ud.N400
            }
        }
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        switch self.style {
        case .light:
            self.panView.readyView.layer.borderColor = (colorConfig?.panColorConfig?.readyBorder ?? UIColor.ud.N300).cgColor
        case .dark:
            self.panView.readyView.layer.borderColor = (colorConfig?.panColorConfig?.readyBorder ?? UIColor.ud.N400.withAlphaComponent(0.5)).cgColor
        case .blue:
            self.panView.readyView.layer.borderColor = (colorConfig?.panColorConfig?.readyBorder ?? UIColor.ud.B300).cgColor
            self.panView.playView.layer.borderColor = (colorConfig?.panColorConfig?.playBorder ?? UIColor.ud.B300).cgColor
        case .clearLight:
            self.panView.readyView.layer.borderColor = (colorConfig?.panColorConfig?.readyBorder ?? UIColor.ud.N300).cgColor
        case .clearDark:
            self.panView.readyView.layer.borderColor = (colorConfig?.panColorConfig?.readyBorder ?? UIColor.ud.N400.withAlphaComponent(0.5)).cgColor
        case .clearBlue:
            self.panView.readyView.layer.borderColor = (colorConfig?.panColorConfig?.readyBorder ?? UIColor.ud.B300).cgColor
            self.panView.playView.layer.borderColor = (colorConfig?.panColorConfig?.playBorder ?? UIColor.ud.B300).cgColor
        }
    }

    public func updateCurrentState(_ state: State) {
        self.state = state
    }

    public var isDraging: Bool {
        return self.panView.isTouching
    }

    private func updateAudioText() {
        defer {
            // 无论是否刷新文本，都要刷新loading组件动画
            if let loadingView = self.loadingView,
                !self.isAudioRecognizeFinish {
                loadingView.startAnimationIfNeeded()
            }
        }

        if !self.needUpdateTitle { return }
        self.needUpdateTitle = false

        self.textLabel.text = self.text
        if !self.isAudioRecognizeFinish {
            if self.loadingView == nil {
                let loadingView = AudioRecognizeLoadingView(text: "")
                self.loadingView = loadingView
            }
            if let loadingView = self.loadingView {
                loadingView.bounds = loadingView.attachmentBounds
                let attachment = LKAttachment(view: loadingView, verticalAlign: .middle)
                attachment.fontDescent = self.textLabel.font.descender
                attachment.fontAscent = self.textLabel.font.ascender
                self.textLabel.appendAttachment(attachment: attachment)
            }
        }
    }

    public func updateViewConstraintsIfNeeded() {
        if !self.needUpdateLayout { return }
        self.needUpdateLayout = false

        let textIsEmpty = self.text.isEmpty
        self.textLabel.isHidden = textIsEmpty

        if textIsEmpty {
            self.textLabel.snp.removeConstraints()
        } else {
            self.textLabel.snp.remakeConstraints { (maker) in
                maker.left.equalTo(self.edgeInset.left)
                maker.top.equalTo(self.edgeInset.top)
                maker.right.equalTo(-self.edgeInset.right)
            }
        }
        self.stateBtn.snp.remakeConstraints { (maker) in
            maker.width.equalTo(stateBtn.snp.height)
            maker.height.equalTo(20).priority(.high)
            maker.left.equalTo(self.edgeInset.left)
            maker.bottom.equalTo(-self.edgeInset.bottom - 3)
            if textIsEmpty {
                maker.top.equalTo(self.edgeInset.top + 3)
            } else {
                maker.top.equalTo(self.textLabel.snp.bottom).offset(12)
            }
        }

        self.timeLabel.snp.remakeConstraints { (maker) in
            maker.centerY.equalTo(self.stateBtn)
            maker.right.equalTo(-self.edgeInset.right)
            maker.width.equalTo(AudioView.timeStrWidth(time: self.currentTime))
        }

        self.widthLine.snp.remakeConstraints { (maker) in
            maker.left.right.top.equalToSuperview()
            maker.height.equalTo(0)
            maker.width.greaterThanOrEqualTo(self.minLineWidth).priority(.high)
        }

        self.line.snp.remakeConstraints { (maker) in
            maker.centerY.equalTo(self.stateBtn)
            maker.left.equalTo(self.stateBtn.snp.right).offset(6)
            maker.right.equalTo(self.timeLabel.snp.left).offset(-6)
            maker.height.equalTo(1)
        }

        if hadInitProcessLayout { return }
        self.hadInitProcessLayout = true

        self.processLine.snp.remakeConstraints { (maker) in
            maker.left.top.bottom.equalTo(self.line)
            maker.right.equalTo(self.panView.snp.centerX)
        }

        self.layoutLine.snp.remakeConstraints { (maker) in
            maker.left.equalTo(self.line).offset(8)
            maker.right.equalTo(self.line).offset(-8)
            maker.centerY.equalTo(self.line)
            maker.height.equalTo(1)
        }

        self.layoutProcessLine.snp.remakeConstraints { (maker) in
            maker.left.centerY.equalTo(self.layoutLine)
            maker.width.equalTo(self.layoutLine).multipliedBy(0)
            maker.height.equalTo(1)
        }

        self.panView.snp.remakeConstraints { (maker) in
            maker.width.height.equalTo(16)
            maker.centerY.equalTo(self.stateBtn)
            maker.centerX.equalTo(self.layoutProcessLine.snp.right)
        }
    }

    private func cleanProcessView() {
        if self.processView != nil {
            self.processView?.removeFromSuperview()
            self.processView = nil
        }
    }
    public var processViewBlock: ((_ audioKey: String, _ callback: (AudioProcessViewProtocol) -> Void) -> Void)?
    private(set) weak var processView: (AudioProcessViewProtocol)?
    private(set) var fetchingKey: String?
    private func showAudioProcess(currentTime: TimeInterval, show: Bool) {
        if !show {
            fetchingKey = nil
            self.processView?.removeFromSuperview()
            self.processView = nil
            return
        }
        if let processView = self.processView {
            processView.update(currentTime: currentTime, duration: self.time)
            return
        }
        if self.fetchingKey == self.key { return }
        self.fetchingKey = self.key
        let contentKey = self.key

        self.processViewBlock?(contentKey) { [weak self] processView in
            guard let `self` = self,
                self.fetchingKey == contentKey else { return }
            self.fetchingKey = nil
            if let window = self.window {
                self.processView = processView
                processView.update(currentTime: currentTime, duration: self.time)
                window.addSubview(processView)
                processView.snp.makeConstraints({ (maker) in
                    self.processViewLayout(window, self, maker)
                })
            }
        }
    }

    private func updateTimeWidth() {
        self.timeLabel.snp.updateConstraints { (maker) in
            maker.width.equalTo(AudioView.timeStrWidth(time: self.currentTime))
        }
    }

    private func update(process: TimeInterval) {
        let process = min(1, process)
        self.layoutProcessLine.snp.remakeConstraints { (maker) in
            maker.left.centerY.equalTo(self.layoutLine)
            maker.width.equalTo(self.layoutLine).multipliedBy(process)
            maker.height.equalTo(1)
        }
    }

    private func handlePan(_ state: PanState, _ process: TimeInterval) {
        // 让 audio 浮窗根据手势出现隐藏效果更顺滑
        // 根据状态变化的话有可能会卡住
        // 因为在后台播放音乐或者佩戴蓝牙耳机时，音频操作会比较慢
        if self.showProcessView {
            self.showAudioProcess(currentTime: self.time * process, show: state != .end)
        }
        self.panAction?(state, process)
    }

    @objc
    private func handleGesture() {
        // nothing
    }

    @objc
    private func handleClickGesture() {
        self.clickStateBtnAction?()
    }

    @objc
    func handlePanTouchBegin() {
        var process: TimeInterval = TimeInterval((self.panView.center.x - self.layoutLine.frame.left) / self.layoutLine.frame.width)
        process = max(min(process, 1), 0)
        self.handlePan(.start, process)
    }

    @objc
    private func handlePanTouchEnd() {
        var process: TimeInterval = TimeInterval((self.panView.center.x - self.layoutLine.frame.left) / self.layoutLine.frame.width)
        process = max(min(process, 1), 0)
        self.handlePan(.end, process)
    }

    @objc
    func handlePanTouchMove(_ sender: UIButton, event: UIEvent) {
        if let touch = event.allTouches?.first {
            let point = touch.location(in: self.panView)
            let offset = point.x - self.panView.bounds.centerX
            var process: TimeInterval = TimeInterval((self.panView.center.x - self.layoutLine.frame.left + offset) / self.layoutLine.frame.width)
            process = max(min(process, 1), 0)
            self.handlePan(.dragging, process)
        }
    }

    @objc
    private func clickStateBtn() {
        self.clickStateBtnAction?()
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {

        if gestureRecognizer == self.counteractGesture {
            if self.stateBtn.hitTest(touch.location(in: self.stateBtn), with: nil) != nil ||
                self.panView.hitTest(touch.location(in: self.panView), with: nil) != nil {
                return true
            }
        } else if gestureRecognizer == self.clickGesture {
            if self.stateBtn.hitTest(touch.location(in: self.stateBtn), with: nil) == nil &&
                self.panView.hitTest(touch.location(in: self.panView), with: nil) == nil &&
                !self.textLabel.bounds.contains(touch.location(in: self.textLabel)) {
                return true
            }
        }

        return false
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }

    public func gestureRecognizer(_ gestureRetruecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRetruecognizer == self.counteractGesture {
            return true
        }
        return false
    }
}

extension AudioView {
    static func format(time: TimeInterval) -> String {
        let second = Int(time) % 60
        let minute = Int(time) / 60
        return "\(minute):\(second >= 10 ? "" : "0")\(second)"
    }

    static func timeStrWidth(time: TimeInterval) -> CGFloat {
        let second = Int(time) % 60
        let minute = Int(time) / 60

        if minute >= 10 {
            return ceil(4 * self.numberMaxWidth + self.colonWidth)
        } else {
            return ceil(3 * self.numberMaxWidth + self.colonWidth)
        }
    }
}
