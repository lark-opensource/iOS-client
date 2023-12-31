//
//  TextAndWaveView.swift
//  LarkAudio
//
//  Created by kangkang on 2023/11/14.
//

import LarkUIKit
import Foundation
import LarkContainer
import LarkKeyboardView
import UniverseDesignFont
import UniverseDesignColor

final class TextAndWaveView: UIView {

    enum Cons {
        static let timeLabelSpacing: CGFloat = 12
        static let waveHeight: CGFloat = 28
        static let defaultWaveRightOffset: CGFloat = 55
    }
    weak var keyboardView: LKKeyboardView? {
        didSet {
            textView.keyboardView = keyboardView
        }
    }
    let textView: RecognizeTextView
    let stackView = UIStackView()
    private let waveCenterView = UIView()
    private let waveView = WaveView()
    private let timeLabel = UILabel()
    private let waveBackView = UIView()
    private let waveMaskView = UIView()
    // figma上的颜色是imtoken-message-bg-bubbles-blue，没有给标准Color，颜色在UDColor.registerUDBizColor(UDMessageBizColor())内已经注入，此处可以拿到
    private let backActiveColor = UDColor.getValueByBizToken(token: "imtoken-message-bg-bubbles-blue") ?? UDColor.rgb(0xD1E3FF) & UDColor.rgb(0x133063)
    private let backInactiveColor = UDColor.udtokenReactionBgGreyFloat
    private let recordLengthLimit: TimeInterval
    private var currentTime: TimeInterval = 0
    private var timeTextHasReverse: Bool = false {
        didSet {
            guard timeTextHasReverse != oldValue else { return }
            if timeTextHasReverse {
                let text = BundleI18n.LarkAudio.Lark_IM_AudioMsg_RecordingEndsInNums_Text(10)
                let width = NSString(string: text).boundingRect(
                    with: CGSize(width: CGFloat(MAXFLOAT), height: CGFloat(MAXFLOAT)),
                    options: .usesLineFragmentOrigin, attributes: [.font: UDFont.body2],
                    context: nil).width + Cons.timeLabelSpacing + Cons.timeLabelSpacing
                waveCenterView.snp.updateConstraints { make in
                    make.right.equalToSuperview().offset(-width)
                }
            } else {
                waveCenterView.snp.updateConstraints { make in
                    make.right.equalToSuperview().offset(-Cons.defaultWaveRightOffset)
                }
            }
        }
    }

    var displayState: InputDisplayState = .over {
        didSet {
            // 需要重置属性，此处需要不等于oldValue
            guard displayState != oldValue else { return }
            switch displayState {
            case .voiceAndRecognizing:  // 说话并且识别中
                voiceAndRecognizing()
            case .recognizing:          // 没说话，在识别剩余中
                recognizing()
            case .over:                 // 识别结束
                over()
            }
        }
    }

    init(userResolver: UserResolver, chatName: String, recordLengthLimit: TimeInterval) {
        self.textView = RecognizeTextView(userResolver: userResolver, chatName: chatName)
        self.recordLengthLimit = recordLengthLimit
        super.init(frame: .zero)
        setViews()
    }

    private func setViews() {
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .center
        self.addSubview(stackView)
        let offset = Display.pad ? 0 : 8
        stackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(offset)
            make.right.equalToSuperview().offset(-offset)
        }

        // 为了使用 stackView 的 spacing
        let headerView = UIView()
        stackView.addArrangedSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.height.equalTo(0.1)
        }
        stackView.addArrangedSubview(textView)
        stackView.addArrangedSubview(waveBackView)
        textView.backgroundColor = UDColor.bgBody
        textView.layer.cornerRadius = GestureView.Cons.squareLayer
        textView.layer.masksToBounds = true
        textView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }

        waveBackView.layer.cornerRadius = GestureView.Cons.squareLayer
        waveBackView.layer.masksToBounds = true
        waveBackView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }

        waveBackView.addSubview(waveCenterView)
        waveCenterView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(7)
            make.left.equalToSuperview().offset(1)
            make.bottom.equalToSuperview().offset(-7)
            make.right.equalToSuperview().offset(-Cons.defaultWaveRightOffset)
            make.height.equalTo(Cons.waveHeight)
        }

        waveBackView.addSubview(waveView)
        waveView.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        waveView.snp.makeConstraints { make in
            make.center.equalTo(waveCenterView)
            make.width.equalTo(Cons.waveHeight)
            make.height.equalTo(waveCenterView.snp.width)
        }

        let maskBackView = UIView()
        maskBackView.backgroundColor = UDColor.bgBodyOverlay
        waveBackView.addSubview(maskBackView)
        maskBackView.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
            make.width.equalTo(9)
            make.height.equalTo(Cons.waveHeight)
        }

        waveBackView.addSubview(waveMaskView)
        waveMaskView.snp.makeConstraints { make in
            make.edges.equalTo(maskBackView)
        }

        timeLabel.font = UDFont.body2
        timeLabel.textColor = UDColor.functionInfoContentDefault
        waveBackView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-Cons.timeLabelSpacing)
        }
        displayState = .over
    }

    // 更新音波
    func updateDecibel(decibel: Float) {
        waveView.addDecible(decibel)
    }

    // 更新时间
    func updateTime(_ time: TimeInterval) {
        currentTime = time
        if recordLengthLimit - time <= 10 {
            timeTextHasReverse = true
            timeLabel.text = BundleI18n.LarkAudio.Lark_IM_AudioMsg_RecordingEndsInNums_Text(Int(recordLengthLimit - time))
        } else {
            timeTextHasReverse = false
            timeLabel.text = AudioUtils.timeString(time: time)
        }
    }

    // 更新文字
    func updateText(text: String, finish: Bool, diffIndexSlice: [Int32] = []) {
        textView.updateText(text: text, finish: finish, diffIndexSlice: diffIndexSlice)
    }

    // 更新文字
    func hasReady() {
        textView.hasReady()
    }

    private func voiceAndRecognizing() {
        waveView.reset()
        waveView.start()
        waveView.changeColor(color: UDColor.functionInfoContentDefault)
        timeLabel.textColor = UDColor.functionInfoContentDefault
        timeLabel.text = "0:00"
        textView.inputState = .voiceAndRecognizing
        waveBackView.backgroundColor = backActiveColor
        waveMaskView.backgroundColor = backActiveColor
        currentTime = 0
        timeTextHasReverse = false
    }

    private func recognizing() {
        waveView.stop()
        waveView.changeColor(color: UDColor.textCaption)
        timeLabel.textColor = UDColor.textCaption
        timeTextHasReverse = false
        timeLabel.text = AudioUtils.timeString(time: currentTime)
        textView.inputState = .recognizing
        waveBackView.backgroundColor = backInactiveColor
        waveMaskView.backgroundColor = backInactiveColor
    }

    private func over() {
        timeLabel.textColor = UDColor.textCaption
        timeTextHasReverse = false
        timeLabel.text = AudioUtils.timeString(time: currentTime)
        textView.inputState = .over
        waveBackView.backgroundColor = backInactiveColor
        waveMaskView.backgroundColor = backInactiveColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
