//
//  AudioWaveView.swift
//  LarkAudio
//
//  Created by kangkang on 2023/10/9.
//

import LarkUIKit
import Foundation
import UniverseDesignColor

class RecordAnimationView: UIView {

    enum DisplayState {
        case unpressed
        case pressing
        case cancel
    }

    private let cancelOffset: CGFloat = -60
    // 此处增加 textView 是因为有个奇怪的 bug
    // 在ipad上，当tableView不断向前滑动时，会被FocusIfNeeded卡住几十毫秒，造成tableView滑动一卡一卡的，当添加一个textView后就不会卡顿。
    // 猜测是因为iPad需要Focus一个输入框，才能在按下 Tab 键后快速弹起键盘聚焦。
    // tableview出现时会挡住chat的输入框，并且在window上覆盖一个透明的蒙层（防止其他手势），使得 Focus 一直在寻找
    // 如果把这里的 textView 设置为不可交互或者再盖一个UIView，还是会卡顿，所以系统这里会判断“输入框是否addSubView”+“是否能看到”+“是否可交互”。
    // 这里为了让输入框视觉上不可见，设置的足够小并为透明。因为并且在 BeginEdit 时返回 false，这样在按下时，间接性达到了不可交互
    private let textView = UITextView()
    private let timeLabel = UILabel()
    private let cancelLabel = UILabel()
    private let tipLabel = UILabel()
    private let waveView = WaveView(frame: .zero)
    private let trashLottie = TrashLottieView()
    private lazy var waveMaskView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBodyOverlay
        view.alpha = 0
        return view
    }()
    let feedbackGenerator: UIImpactFeedbackGenerator = {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.prepare()
        return feedbackGenerator
    }()

    var readyToCancel: Bool = false {
        didSet {
            guard readyToCancel != oldValue, displayState != .unpressed else { return }
            if readyToCancel {
                trashLottie.activated()
                feedbackGenerator.impactOccurred()
            } else {
                trashLottie.idle()
            }
        }
    }

    private(set) var displayState: DisplayState = .cancel {
        didSet {
            if displayState == oldValue, (displayState == .pressing || displayState == .cancel) { return }
            switch displayState {
            case .unpressed:
                timeLabel.isHidden = true
                timeLabel.text = "0:00"
                cancelLabel.isHidden = true
                tipLabel.isHidden = true
                readyToCancel = false
                trashLottie.isHidden = true
                if trashLottie.superview != nil {
                    trashLottie.snp.remakeConstraints { make in
                        make.centerX.equalToSuperview()
                        make.bottom.equalToSuperview().offset(-30)
                        make.width.height.equalTo(60)
                    }
                }
                waveMaskView.alpha = 0
                waveView.isHidden = true
                waveView.reset()
            case .pressing:
                timeLabel.isHidden = false
                cancelLabel.isHidden = true
                tipLabel.isHidden = false
                readyToCancel = false
                trashLottie.isHidden = false
                waveView.isHidden = false
                waveView.start()
            case .cancel:
                timeLabel.isHidden = true
                cancelLabel.isHidden = false
                tipLabel.isHidden = true
                readyToCancel = true
                trashLottie.isHidden = false
                waveView.isHidden = true
            }
        }
    }

    init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgBodyOverlay
        self.addSubview(waveView)
        self.addSubview(waveMaskView)
        self.addSubview(trashLottie)
        self.addSubview(timeLabel)
        self.addSubview(cancelLabel)
        self.addSubview(tipLabel)
        if Display.pad {
            self.addSubview(textView)
        }
        setupView()
    }

    private func setupView() {
        timeLabel.text = "0:00"
        timeLabel.textColor = UIColor.ud.textCaption
        timeLabel.font = UIFont.systemFont(ofSize: 14)
        timeLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(10)
        }

        cancelLabel.textColor = UIColor.ud.R500
        cancelLabel.text = BundleI18n.LarkAudio.Lark_IM_Audio_ReleaseToCancel_Text
        cancelLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(10)
        }
        cancelLabel.isHidden = true

        if Display.pad {
            textView.delegate = self
            textView.backgroundColor = .clear
            textView.snp.makeConstraints { make in
                make.left.top.equalToSuperview()
                make.width.height.equalTo(3)
            }
        }

        waveView.snp.makeConstraints { make in
            make.height.equalTo(waveMaskView.snp.width)
            make.width.equalTo(28)
            make.center.equalTo(waveMaskView)
        }
        waveView.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)

        waveMaskView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(timeLabel.snp.bottom)
            make.bottom.equalToSuperview().offset(-90)
        }

        trashLottie.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-30)
            make.width.height.equalTo(60)
        }
        trashLottie.isHidden = false

        tipLabel.textColor = UDColor.textCaption
        tipLabel.text = BundleI18n.LarkAudio.Lark_Chat_RecordAudiotips
        tipLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        tipLabel.font = UIFont.systemFont(ofSize: 14)

        displayState = .unpressed
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil {
            displayState = .unpressed
        } else {
            displayState = .pressing
        }
    }

    func updateTime(str: String) {
        timeLabel.text = str
    }

    func updatePoint(point: CGPoint) {
        if point.y < cancelOffset {
            displayState = .cancel
        } else {
            displayState = .pressing
        }
        moveTrash(point: point)
    }

    func updateDecible(decible: Float) {
        waveView.addDecible(decible)
    }

    func stopPress(comple: @escaping () -> Void) {
        if readyToCancel {
            trashLottie.end { [weak self] in
                self?.displayState = .unpressed
                comple()
            }
        } else {
            displayState = .unpressed
            comple()
        }
    }

    private func moveTrash(point: CGPoint) {
        if point.y >= 0 {
            trashLottie.snp.remakeConstraints { make in
                make.width.height.equalTo(60)
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().offset(-30)
            }
        } else if point.y > cancelOffset {
            trashLottie.snp.remakeConstraints { make in
                make.width.height.equalTo(-point.y / 2 + 60)
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().offset(-30 + point.y / 2)
            }
            waveMaskView.alpha = -point.y / 60
        } else {
            trashLottie.snp.remakeConstraints { make in
                make.width.height.equalTo(90)
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().offset(-60)
            }
            waveMaskView.alpha = 1
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension RecordAnimationView: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return false
    }
}
