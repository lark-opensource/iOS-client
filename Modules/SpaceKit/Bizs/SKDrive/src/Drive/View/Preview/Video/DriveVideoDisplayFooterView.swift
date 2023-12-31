//longweiwei

import UIKit
import LarkUIKit
import SKCommon
import UniverseDesignColor
import UniverseDesignIcon
import SKFoundation

class DriveVideoDisplayFooterView: UIView {
    let playButton = DriveVideoTapButton(type: .custom) // 播放、暂停按钮
    let moreButton = UIButton(type: .custom) // 切换分辨率
    let muteButton = DriveVideoTapButton(type: .custom) // 静音
    let startTimeLabel = UILabel.lu.labelWith(fontSize: 14, textColor: UDColor.primaryOnPrimaryFill, text: "00:00")
    let endTimeLabel = UILabel.lu.labelWith(fontSize: 14, textColor: UDColor.primaryOnPrimaryFill, text: "00:00")
    let slashLabel = UILabel.lu.labelWith(fontSize: 14, textColor: UDColor.primaryOnPrimaryFill, text: "/")
    let rightContainer = UIStackView()
    var needHideMoreButton: Bool = false
    // 卡片模式，显示放大按钮
    lazy var magnifyButton: DriveVideoTapButton = {
        let btn = DriveVideoTapButton(type: .custom)
        btn.isHidden = true
        btn.setImage(UDIcon.magnifyOutlined.ud.withTintColor(UDColor.primaryOnPrimaryFill), for: .normal)
        return btn
    }()
    
    let slider = DriveVideoSlider(frame: .zero)
    
    private var displayMode: DrivePreviewMode = .normal

    var resolution: String = "" {
        didSet {
            moreButton.setTitle(resolution, for: .normal)
        }
    }
    
    var inMutedMode: Bool = false {
        didSet {
            let muteButtonImage = inMutedMode
                ? UDIcon.speakerMuteFilled.ud.withTintColor(UDColor.primaryOnPrimaryFill)
                :UDIcon.speakerFilled.ud.withTintColor(UDColor.primaryOnPrimaryFill)
            muteButton.setImage(muteButtonImage, for: .normal)
        }
    }
    
    // MARK: - intercept pop gesture
    weak var previousGestureDelegate: UIGestureRecognizerDelegate?
    var interactivePopGestureRecognizer: UIGestureRecognizer?
    
    let edgeInsetValue: CGFloat = 16

    override init(frame: CGRect) {
        super.init(frame: frame)
        // 进度条
        self.addSubview(slider)
        self.slider.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.height.equalTo(24)
            make.left.equalToSuperview().offset(edgeInsetValue)
            make.right.equalToSuperview().offset(-edgeInsetValue)
        }
        
        playButton.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        playButton.setImage(UDIcon.playFilled.ud.withTintColor(UDColor.primaryOnPrimaryFill), for: .normal)
        playButton.setImage(UDIcon.pauseLivestreamOutlined.ud.withTintColor(UDColor.primaryOnPrimaryFill), for: .selected)
        configForIPadPointer(button: playButton)
        self.addSubview(playButton)
        playButton.snp.makeConstraints { (make) in
            make.top.equalTo(slider.snp.bottom).offset(10.0)
            make.left.equalTo(edgeInsetValue)
            make.height.width.equalTo(18)
        }

        startTimeLabel.textAlignment = .left
        startTimeLabel.minimumScaleFactor = 6
        self.addSubview(startTimeLabel)
        startTimeLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(playButton)
            make.left.equalTo(playButton.snp.right).offset(16)
            make.height.equalTo(22)
        }
        
        slashLabel.textAlignment = .center
        self.addSubview(slashLabel)
        slashLabel.snp.makeConstraints { make in
            make.centerY.equalTo(playButton)
            make.left.equalTo(startTimeLabel.snp.right)
            make.width.equalTo(9.0)
            make.height.equalTo(22)
        }

        endTimeLabel.textAlignment = .right
        endTimeLabel.minimumScaleFactor = 6
        self.addSubview(endTimeLabel)
        endTimeLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(playButton)
            make.left.equalTo(slashLabel.snp.right)
            make.height.equalTo(22)
        }

        rightContainer.axis = .horizontal
        rightContainer.alignment = .center
        rightContainer.spacing = 18
        self.addSubview(rightContainer)
        rightContainer.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-edgeInsetValue)
            make.centerY.equalTo(playButton)
            make.height.equalTo(22)
        }
        
        muteButton.setImage(UDIcon.speakerFilled.ud.withTintColor(UDColor.primaryOnPrimaryFill), for: .normal)
        muteButton.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        configForIPadPointer(button: muteButton)
        rightContainer.addArrangedSubview(muteButton)
        muteButton.snp.makeConstraints { make in
            make.height.width.equalTo(18)
        }
        
        moreButton.setTitle("", for: .normal)
        moreButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        configForIPadPointer(button: moreButton)
        rightContainer.addArrangedSubview(moreButton)
        moreButton.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(34)
        }
        
        // 卡片模式下
        self.addSubview(magnifyButton)
        magnifyButton.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        configForIPadPointer(button: magnifyButton)
        magnifyButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(playButton)
            make.right.equalToSuperview().offset(-10)
            make.height.width.equalTo(18)
        }
        
        let tap = UITapGestureRecognizer()
        self.addGestureRecognizer(tap)

        let pan = UIPanGestureRecognizer()
        self.addGestureRecognizer(pan)

        let longPress = UILongPressGestureRecognizer()
        self.addGestureRecognizer(longPress)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        DocsLogger.driveInfo("DriveVideoDisplayFooterView deinit")
    }
    
    func hideMoreButton() {
        needHideMoreButton = true
        moreButton.isHidden = true
    }
    
    func setupUI(displayMode: DrivePreviewMode) {
        guard self.displayMode != displayMode else { return }
        self.displayMode = displayMode
        if displayMode == .card {
            setupCardMode()
        } else {
            setupNormalMode()
        }
    }
    
    func setupCardMode() {
        moreButton.isHidden = true
        muteButton.isHidden = false
        playButton.isHidden = false
        startTimeLabel.isHidden = false
        endTimeLabel.isHidden = false
        slashLabel.isHidden = false
        slider.isHidden = false
        magnifyButton.isHidden = false
        
        rightContainer.snp.updateConstraints { make in
            make.right.equalToSuperview().offset(-48)
        }
    }
    
    func setupNormalMode() {
        moreButton.isHidden = needHideMoreButton
        muteButton.isHidden = false
        playButton.isHidden = false
        startTimeLabel.isHidden = false
        endTimeLabel.isHidden = false
        slashLabel.isHidden = false
        slider.isHidden = false
        magnifyButton.isHidden = true
        
        rightContainer.snp.updateConstraints { make in
            make.right.equalToSuperview().offset(-edgeInsetValue)
        }
    }
    
    func resetCardMode() { // 初始化或者播放完毕需要重置 UI 状态
        moreButton.isHidden = true
        muteButton.isHidden = true
        playButton.isHidden = true
        startTimeLabel.isHidden = true
        endTimeLabel.isHidden = true
        slashLabel.isHidden = true
        slider.isHidden = true
        magnifyButton.isHidden = true
    }
    
    private func configForIPadPointer(button: UIButton) {
        if #available(iOS 13.4, *) {
            button.isPointerInteractionEnabled = true
            button.pointerStyleProvider = { button, proposedEffect, proposedShape in
                var rect = button.bounds.insetBy(dx: -12, dy: -10)
                rect = button.convert(rect, to: proposedEffect.preview.target.container)
                return UIPointerStyle(effect: proposedEffect, shape: .roundedRect(rect))
            }
        } else {
            // Fallback on earlier versions
        }

    }
}

extension DriveVideoDisplayFooterView: UIGestureRecognizerDelegate {
    // 避免进度条拖动和侧滑手势冲突
    func startInterceptPopGesture(gesture: UIGestureRecognizer?) {
        if gesture?.delegate !== self {
            previousGestureDelegate = gesture?.delegate
            gesture?.delegate = self
            self.interactivePopGestureRecognizer = gesture
            DocsLogger.driveInfo("DisplayFooterView -- add naviPopGestureDelegate previousGestureDelegate")
        }
    }

    func stopInterceptPopGesture() {
        interactivePopGestureRecognizer?.delegate = previousGestureDelegate
        DocsLogger.driveInfo("DisplayFooterView -- remove naviPopGestureDelegate previousGestureDelegate's nil is \(previousGestureDelegate == nil)")
        interactivePopGestureRecognizer = nil
        previousGestureDelegate = nil
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.view == self && !self.isHidden {
            return false
        }
        return true
    }
}

extension Double {
    var timeIntervalToString: String {
        if self.isNaN || self.isInfinite {
            return "00:00"
        }
        // 注意前置检查，Double 转 Int 遇到 NaN 和 Infinite 情况会崩溃
        let interval = Int(self)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 3600)
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
