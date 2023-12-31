//
//  OpenBGAudioView.swift
//  OPPlugin
//
//  Created by zhysan on 2022/5/19.
//

import UIKit
import ByteWebImage
import EENavigator
import FigmaKit
import SnapKit
import OPPluginManagerAdapter
import UniverseDesignColor


private extension TimeInterval {
    var fullHMSStr: String {
        let hours = Int(self) / 3600
        let minutes = Int(self) / 60 % 60
        let seconds = Int(self) % 60
        return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
    }
}

protocol OpenBGAudioControllerDelegate: AnyObject {
    func viewController(_ vc: OpenBGAudioController, onPlay: Bool)
    func viewControllerClose(_ vc: OpenBGAudioController, byCloseBtn: Bool)
    func viewControllerOnDetail(_ vc: OpenBGAudioController)
    func viewControllerRequestTimeInfo(_ vc: OpenBGAudioController) -> (current: TimeInterval, total: TimeInterval)
}

final class OpenBGAudioController: UIViewController {
    
    // MARK: - public
    
    weak var delegate: OpenBGAudioControllerDelegate?
    
    /// 更新播放时间进度
    /// - Parameters:
    ///   - current: 当前播放时间戳，单位：秒
    ///   - total: 资源总时长，单位：秒
    func updateTimeInfo(current: TimeInterval, total: TimeInterval) {
        mediaView.timeLabel.text = current.fullHMSStr + " / " + total.fullHMSStr
    }
    
    /// 更新媒体资源信息
    /// - Parameters:
    ///   - title: 标题
    ///   - iconLink: 图标
    func updateMediaInfo(title: String?, icon: UIImage?) {
        DispatchQueue.main.async { [weak self] in
            self?.mediaView.titleLabel.text = title
            self?.mediaView.iconView.image = icon
        }
    }
    
    /// 更新播放状态
    /// - Parameter playing: 是否在播放中
    func updatePlayingState(_ playing: Bool) {
        DispatchQueue.main.async { [weak self] in
            // 播放中，则展示「暂停」图标，反之展示「播放」
            self?.mediaView.playButton.isSelected = playing
        }
    }
    
    // MARK: - private vars
    
    private let blurBgView: VisualBlurView = {
        let vi = VisualBlurView()
        vi.blurRadius = 60
        vi.fillOpacity = 0.2
        vi.fillColor = UIColor.ud.primaryOnPrimaryFill
        return vi
    }()
    
    struct Const {
        static var shadowColor: UIColor {
            UIColor.ud.textTitle
        }
    }
    
    private let mediaView: OpenBGMediaControllerView = {
        let vi = OpenBGMediaControllerView(frame: .zero)
        vi.layer.cornerRadius = 6.0
        vi.layer.dropShadow(
            color: Const.shadowColor,
            alpha: 0.1, x: 0, y: 4, blur: 8, spread: 0
        )
        return vi
    }()
    
    private var timeUpdateTimer: Timer? = nil
    
    // MARK: - lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        subviewsInit()
        gestureInit()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        startTimeUpdateTimer()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        stopTimeUpdateTimer()
    }
    
    override func didMove(toParent parent: UIViewController?) {
        if parent == nil {
            // 非关闭按钮触发的 close（如左滑手势关闭）
            delegate?.viewControllerClose(self, byCloseBtn: false)
        }
    }
    
    // MARK: - private
    
    private func startTimeUpdateTimer() {
        let timer = Timer.bdp_scheduledRepeatedTimer(withInterval: 1.0 / 3, target: self) { [weak self] _ in
            guard let self = self else { return }
            self.fetchTimeInfo()
        }
        RunLoop.main.add(timer, forMode: .common)
        timeUpdateTimer = timer
    }
    
    private func stopTimeUpdateTimer() {
        timeUpdateTimer?.invalidate()
        timeUpdateTimer = nil
    }
    
    @objc
    private func fetchTimeInfo() {
        guard let info = delegate?.viewControllerRequestTimeInfo(self) else {
            return
        }
        updateTimeInfo(current: info.current, total: info.total)
    }
    
    // MARK: - actions
    
    @objc
    private func onPlay(_ sender: UIButton) {
        delegate?.viewController(self, onPlay: !sender.isSelected)
    }
    
    @objc
    private func onClose(_ sender: UIButton) {
        delegate?.viewControllerClose(self, byCloseBtn: true)
    }
    
    @objc
    private func onHidden(_ sender: UITapGestureRecognizer) {
        delegate?.viewControllerClose(self, byCloseBtn: false)
    }
    
    @objc
    private func onDetail(_ sender: UITapGestureRecognizer) {
        delegate?.viewControllerOnDetail(self)
    }
    
    // MARK: - init
    
    private func gestureInit() {
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(onHidden(_:)))
        view.addGestureRecognizer(tap1)
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(onDetail(_:)))
        mediaView.isUserInteractionEnabled = true
        mediaView.addGestureRecognizer(tap2)

    }
    
    private func subviewsInit() {
        view.backgroundColor = .clear
        
        view.addSubview(blurBgView)
        view.addSubview(mediaView)
        
        mediaView.playButton.addTarget(self, action: #selector(onPlay(_:)), for: .touchUpInside)
        mediaView.closeButton.addTarget(self, action: #selector(onClose(_:)), for: .touchUpInside)
        
        updateTimeInfo(current: 0, total: 0)
        
        blurBgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        mediaView.snp.makeConstraints { make in
            make.height.equalTo(72)
            make.left.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }
}
