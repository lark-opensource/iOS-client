//
//  OperationDialogVideoControlView.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/8/25.
//

import Foundation
import UniverseDesignFont

final class OperationDialogVideoControlView: UIView {
    enum Action {
        case play(value: Bool)
        case mute(value: Bool)
        case seek(value: Float)
    }

    // MARK: - public properties

    var actionHandler: ((OperationDialogVideoControlView, Action) -> Void)?

    // MARK: - private properties

    private enum Const {
        static let maskH: CGFloat = 60
    }

    private var topMaskLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint(x: 0.5, y: 0.0)
        layer.endPoint = CGPoint(x: 0.5, y: 1.0)
        return layer
    }()

    private var botMaskLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint(x: 0.5, y: 1.0)
        layer.endPoint = CGPoint(x: 0.5, y: 0.0)
        return layer
    }()

    private var progressBar: ProgressBar = {
        let bar = ProgressBar()
        bar.addTarget(self, action: #selector(onSliderValueChange(_:)), for: .valueChanged)
        return bar
    }()

    private var playBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(Resources.icon_player_play_solid, for: .normal)
        btn.setImage(Resources.icon_player_pause_outlined, for: .selected)
        btn.addTarget(self, action: #selector(onPlayBtnClick(_:)), for: .touchUpInside)
        return btn
    }()

    private var timerLabel: UILabel = {
        let vi = UILabel()
        vi.textColor = UIColor.ud.primaryOnPrimaryFill
        vi.font = UDFont.body2
        vi.setContentHuggingPriority(.required, for: .horizontal)
        vi.text = "--:-- / --:--"
        return vi
    }()

    private var volumeBtn: UIButton = {
        let vi = UIButton(type: .custom)
        vi.setImage(Resources.icon_player_speaker_enable_filled, for: .normal)
        vi.setImage(Resources.icon_player_speaker_mute_filled, for: .selected)
        vi.addTarget(self, action: #selector(onMuteBtnClick(_:)), for: .touchUpInside)
        return vi
    }()

    // MARK: - life cycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        subviewsInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let vw = bounds.size.width
        let vh = bounds.size.height
        topMaskLayer.frame = CGRect(x: 0, y: 0, width: vw, height: Const.maskH)
        botMaskLayer.frame = CGRect(x: 0, y: vh - Const.maskH, width: vw, height: Const.maskH)
    }

    // MARK: - public

    func updateProgress(current: TimeInterval, buffer: TimeInterval, total: TimeInterval) {
        if current < 0 || buffer < 0 || total <= 0 {
            return
        }
        progressBar.bufferProgress = CGFloat(buffer / total)
        progressBar.fillProgress = CGFloat(current / total)
        let currentStr = self.formatStringFromTimeInterval(current)
        let totalStr = self.formatStringFromTimeInterval(total)
        timerLabel.text = "\(currentStr) / \(totalStr)"
    }

    func updatePlayingStatus(_ playing: Bool) {
        playBtn.isSelected = playing
    }

    func updateMuteStatus(_ muted: Bool) {
        volumeBtn.isSelected = muted
    }

    func disableSeek(_ disable: Bool) {
        progressBar.isUserInteractionEnabled = !disable
    }

    // MARK: - private

    private func formatStringFromTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        if hours > 0 {
            return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
        }
        return String(format: "%02i:%02i", minutes, seconds)
    }

    @objc
    private func onPlayBtnClick(_ sender: UIButton) {
        actionHandler?(self, .play(value: !sender.isSelected))
    }

    @objc
    private func onMuteBtnClick(_ sender: UIButton) {
        actionHandler?(self, .mute(value: !sender.isSelected))
    }

    @objc
    private func onSliderValueChange(_ sender: ProgressBar) {
        actionHandler?(self, .seek(value: Float(sender.fillProgress)))
    }

    private func subviewsInit() {
        layer.addSublayer(topMaskLayer)
        layer.addSublayer(botMaskLayer)

        topMaskLayer.ud.setColors([UIColor.ud.staticBlack.withAlphaComponent(0.5), UIColor.clear])
        botMaskLayer.ud.setColors([UIColor.ud.staticBlack.withAlphaComponent(0.5), UIColor.clear])

        addSubview(progressBar)
        progressBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(12)
            make.height.equalTo(24)
            make.bottom.equalTo(-36)
        }

        addSubview(playBtn)
        playBtn.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.left.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }

        addSubview(timerLabel)
        timerLabel.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.centerY.equalTo(playBtn)
            make.left.equalTo(playBtn.snp.right).offset(12)
        }

        addSubview(volumeBtn)
        volumeBtn.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.centerY.equalTo(playBtn)
            make.right.equalToSuperview().offset(-12)
        }
    }
}

private final class ProgressBar: UIControl {

    // MARK: - const

    private enum Const {
        static let DraggableMinSize: CGFloat = 44.0
    }

    // MARK: - public properties

    /// 进度条高度
    var barHeight: CGFloat = 4.0 {
        didSet {
            setNeedsLayout()
        }
    }

    /// 指示器半径
    var indicatorRadius: CGFloat = 5.0 {
        didSet {
            setNeedsLayout()
        }
    }

    /// 轨道颜色
    var trackColor: UIColor = UIColor.ud.iconN2.alwaysLight

    /// 缓冲条颜色
    var bufferColor: UIColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.5)

    /// 进度条颜色
    var fillColor: UIColor = UIColor.ud.primaryContentDefault

    /// 指示器颜色
    var indicatorColor: UIColor = UIColor.ud.primaryOnPrimaryFill

    /// 缓冲条进度，0.0 ~ 1.0
    var bufferProgress: CGFloat {
        get {
            bufferProgress_
        }
        set {
            bufferProgress_ = min(max(0.0, newValue), 1.0)
        }
    }

    /// 指示器进度，0.0 ~ 1.0
    var fillProgress: CGFloat {
        get {
            innerFillProgress
        }
        set {
            if isDragingIndicator {
                return
            }
            innerFillProgress = newValue
        }
    }

    // MARK: - private properties

    /// 缓冲进度存储属性 变量命名不要带下划线
    // swiftlint:disable identifier_name
    private var bufferProgress_: CGFloat = 0 {
        didSet {
            bufferBar.frame.size.width = bounds.size.width * bufferProgress_
        }
    }

    /// 指示器进度存储属性，除了 innerFillProgress 内部，其它位置应避免访问
    private var fillProgress_: CGFloat = 0 {
        didSet {
            fillBar.frame = CGRect(
                x: fillBar.frame.origin.x,
                y: fillBar.frame.origin.y,
                width: bounds.size.width * fillProgress_,
                height: fillBar.frame.height
            )
            indicator.frame = CGRect(
                x: (bounds.width - 2 * indicatorRadius) * fillProgress_,
                y: indicator.frame.origin.y,
                width: indicator.frame.width,
                height: indicator.frame.height
            )
        }
    }
    // swiftlint:enable identifier_name

    /// 内部使用的 FillProgress
    private var innerFillProgress: CGFloat {
        get {
            fillProgress_
        }
        set {
            fillProgress_ = min(max(0.0, newValue), 1.0)
        }
    }

    private let trackBar = CALayer()

    private let bufferBar = CALayer()

    private let fillBar = CALayer()

    private let indicator = CALayer()

    private var dragStartPosition = CGPoint.zero

    private var isDragingIndicator = false

    // MARK: - life cycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        subviewsInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - override

    override func layoutSubviews() {
        super.layoutSubviews()

        let barX: CGFloat = 0
        let barY: CGFloat = (bounds.size.height - barHeight) * 0.5
        let barW: CGFloat = bounds.size.width
        let barH: CGFloat = barHeight

        trackBar.frame = CGRect(x: barX, y: barY, width: barW, height: barH)
        trackBar.cornerRadius = barHeight * 0.5

        bufferBar.frame = CGRect(x: barX, y: barY, width: barW * bufferProgress, height: barH)
        bufferBar.cornerRadius = barHeight * 0.5

        fillBar.frame = CGRect(x: barX, y: barY, width: barW * innerFillProgress, height: barH)
        fillBar.cornerRadius = barHeight * 0.5

        let indicatorX = (barW - 2 * indicatorRadius) * innerFillProgress
        let indicatorY = (bounds.size.height - indicatorRadius * 2) * 0.5
        let indicatorW = indicatorRadius * 2
        let indicatorH = indicatorRadius * 2
        indicator.frame = CGRect(x: indicatorX, y: indicatorY, width: indicatorW, height: indicatorH)
        indicator.cornerRadius = indicatorRadius
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        dragStartPosition = touch.location(in: self)

        var activeFrame = indicator.frame
        let minSideLen = min(activeFrame.width, activeFrame.height)
        if minSideLen < Const.DraggableMinSize {
            activeFrame = CGRect(
                x: activeFrame.origin.x - (Const.DraggableMinSize - minSideLen) * 0.5,
                y: activeFrame.origin.y - (Const.DraggableMinSize - minSideLen) * 0.5,
                width: activeFrame.size.width + (Const.DraggableMinSize - minSideLen),
                height: activeFrame.size.width + (Const.DraggableMinSize - minSideLen)
            )
        }

        if activeFrame.contains(dragStartPosition) {
            isDragingIndicator = true
            return true
        }
        return false
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)

        let deltaX = location.x - dragStartPosition.x
        let deltaValue = deltaX / bounds.width

        dragStartPosition = location

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        innerFillProgress += deltaValue

        CATransaction.commit()

        // sendActions(for: .valueChanged)
        return true
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        isDragingIndicator = false
        sendActions(for: .valueChanged)
    }

    // MARK: - private

    private func subviewsInit() {
        layer.addSublayer(trackBar)
        layer.addSublayer(bufferBar)
        layer.addSublayer(fillBar)
        layer.addSublayer(indicator)

        trackBar.ud.setBackgroundColor(trackColor)
        trackBar.masksToBounds = true

        bufferBar.ud.setBackgroundColor(bufferColor)
        bufferBar.masksToBounds = true

        fillBar.ud.setBackgroundColor(fillColor)
        fillBar.masksToBounds = true

        indicator.ud.setBackgroundColor(indicatorColor)
        indicator.masksToBounds = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        addGestureRecognizer(tap)
    }

    @objc
    private func onTap(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: self)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        innerFillProgress = (point.x / bounds.width)
        CATransaction.commit()
        sendActions(for: .valueChanged)
    }
}
