//
//  MinutesSliderView.swift
//  Minutes
//
//  Created by chenlehui on 2021/11/9.
//

import UIKit
import SnapKit
import LarkUIKit
import UniverseDesignColor
import LarkExtensions
import MinutesFoundation
import UniverseDesignIcon
import EENavigator
import LarkContainer
import AudioToolbox

extension Notification.Name {
    static let didTouchedProgressBar = Notification.Name(rawValue: "minutes.speaker.didTouchedProgressBar")
}

protocol MinutesSliderViewDelegate: AnyObject {
    func sliderValueWillChange()
    func sliderValueDidChanged(_ value: CGFloat)
    func sliderValueDidEndChanged()
}

class MinutesSliderView: UIView {
    var panGesture: UIPanGestureRecognizer?
    var longPressGesture: UILongPressGestureRecognizer?
    var navigationController: UINavigationController? {
        return userResolver.navigator.mainSceneTopMost?.navigationController
    }
    
    weak var delegate: MinutesSliderViewDelegate?

    var trackColor: UIColor = UIColor.ud.lineBorderComponent {
        didSet {
            trackView.backgroundColor = trackColor
        }
    }

    var progressColor: UIColor = UIColor.ud.colorfulBlue {
        didSet {
            progressView.backgroundColor = progressColor
        }
    }

    var thumbColor: UIColor = UIColor.ud.colorfulBlue {
        didSet {
            thumbView.backgroundColor = thumbColor
        }
    }

    var thumbRadius: CGFloat = 6.5 {
        didSet {
            updateThumbView(withRadius: thumbRadius)
        }
    }
    var trackHeight: CGFloat = 3 {
        didSet {
            updateTrackView(withHeight: trackHeight)
        }
    }

    var videoDuration: Int = 0

    var chapterViews: [UIView] = []

    var chapters: [MinutesChapterInfo] = [] {
        didSet {
            configureChapter()
        }
    }

    func configureChapter() {
        chapterViews.forEach { $0.removeFromSuperview() }
        chapterViews.removeAll()

        for (idx, info) in chapters.enumerated() {
            let totalLength = videoDuration
            guard videoDuration != 0 else { return }
            let left: CGFloat = bounds.width * CGFloat(info.startTime) / CGFloat(totalLength)
            let chapterSep = UIView()
            let cWidth = trackHeight
            insertSubview(chapterSep, aboveSubview: progressView)
            chapterSep.backgroundColor = .white

            chapterSep.snp.remakeConstraints { make in
                make.centerX.equalTo(left + CGFloat(cWidth) / 2.0)
                make.centerY.equalToSuperview()
                make.width.equalTo(cWidth)
                make.top.bottom.equalTo(trackView)
            }
            chapterSep.isHidden = idx == 0
            chapterViews.append(chapterSep)
        }
    }
    
    var value: CGFloat = 0 {
        didSet {
            DispatchQueue.main.async {
                self.updateProgress(animated: false)
            }
        }
    }

    var forceThumbShow: Bool = true {
        didSet {
            setThumb(isShow: forceThumbShow)
        }
    }
    var isDynamic = true

    private lazy var trackView: UIView = {
        let v = UIView()
        v.backgroundColor = trackColor
        v.isUserInteractionEnabled = false
        return v
    }()

    private lazy var progressView: UIView = {
        let v = UIView()
        v.backgroundColor = progressColor
        v.isUserInteractionEnabled = false
        return v
    }()

    private lazy var thumbView: UIView =  {
        let v = UIView()
        v.backgroundColor = thumbColor
        v.layer.cornerRadius = thumbRadius
        v.isUserInteractionEnabled = false
        return v
    }()

    private var isStrong = false

    private var workItem: DispatchWorkItem?

    private var thumbCenterX: CGFloat {
        var cx = value * bounds.width
        if cx < thumbRadius {
            cx = thumbRadius
        }
        if cx > bounds.width - thumbRadius {
            cx = bounds.width - thumbRadius
        }
        return cx
    }

    let userResolver: UserResolver
    init(resolver: UserResolver) {
        self.userResolver = resolver
        super.init(frame: .zero)
        backgroundColor = .clear
        addSubview(trackView)
        trackView.snp.makeConstraints { make in
            make.left.right.centerY.equalToSuperview()
            make.height.equalTo(trackHeight)
        }
        addSubview(progressView)
        progressView.snp.makeConstraints { make in
            make.top.left.bottom.equalTo(trackView)
            make.width.equalTo(value * bounds.width)
        }
        addSubview(thumbView)
        thumbView.snp.makeConstraints { make in
            make.size.equalTo(thumbRadius * 2)
            make.centerY.equalToSuperview()
            make.centerX.equalTo(thumbRadius)
        }

        let pan = UIPanGestureRecognizer()
        pan.addTarget(self, action: #selector(panAction))
        pan.delegate = self
        addGestureRecognizer(pan)
        panGesture = pan
        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(tapAction))
        addGestureRecognizer(tap)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressHandle(gesture:)))
        self.addGestureRecognizer(longPress)
        longPressGesture = longPress
    }

    var isLongPress: Bool = false
    @objc private func longPressHandle(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            isLongPress = true
        case .ended, .cancelled, .failed:
            isLongPress = false
        default:
            break
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setValue(_ value: CGFloat, animated: Bool) {
        self.value = value
        DispatchQueue.main.async {
            self.updateProgress(animated: animated)
        }
    }

    func bringThumbToFront() {
        bringSubviewToFront(thumbView)
    }

    func setThumb(isShow: Bool) {
        if forceThumbShow {
            thumbView.isHidden = false
        } else {
            thumbView.isHidden = !isShow
        }
    }

    var leftProgressView: UIView?

    func updateProgress(animated: Bool) {
        let pWidth = value * bounds.width
        progressView.snp.updateConstraints { make in
            make.width.equalTo(pWidth)
        }
        thumbView.snp.updateConstraints { make in
            make.centerX.equalTo(thumbCenterX)
        }

        self.leftProgressView?.removeFromSuperview()
        for (idx, view) in chapterViews.enumerated() {
            let leftProgressView = UIView()
            leftProgressView.backgroundColor = UIColor.ud.staticWhite.withAlphaComponent(0.9)
            leftProgressView.isUserInteractionEnabled = false

            if chapterViews.indices.contains(idx+1) {
                let nextView = chapterViews[idx+1]

                if pWidth > view.frame.minX && pWidth <= nextView.frame.minX {
                    insertSubview(leftProgressView, aboveSubview: progressView)
                    leftProgressView.snp.makeConstraints { make in
                        make.left.equalToSuperview().offset(pWidth)
                        make.top.bottom.equalTo(trackView)
                        make.right.equalTo(nextView.snp.left)
                    }
                    self.leftProgressView = leftProgressView
                    break
                }
            } else if idx == chapterViews.count-1 {
                if pWidth > view.frame.minX {
                    insertSubview(leftProgressView, aboveSubview: progressView)
                    leftProgressView.snp.makeConstraints { make in
                        make.left.equalToSuperview().offset(pWidth)
                        make.top.bottom.equalTo(trackView)
                        make.right.equalTo(self)
                    }
                    self.leftProgressView = leftProgressView
                }
            }
        }


        if animated {
            UIView.animate(withDuration: 0.2) {
                self.layoutIfNeeded()
            }
        }
    }

    private func updateThumbView(withRadius radius: CGFloat) {
        thumbView.layer.cornerRadius = radius
        thumbView.snp.updateConstraints { make in
            make.size.equalTo(radius * 2)
        }
    }

    private func updateTrackView(withHeight height: CGFloat) {
        trackView.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
    }

    private func updateValue(withLocation loc: CGPoint) {
        let width = bounds.width
        var currentValue = loc.x / width
        if currentValue < 0 {
            currentValue = 0
        }
        if currentValue > 1 {
            currentValue = 1
        }
        value = currentValue
        delegate?.sliderValueDidChanged(value)

        let playTime: CGFloat = ceil(CGFloat(videoDuration) * currentValue)

        let max = Int(playTime + 10000)
        let min = Int(playTime - 10000)
        var matchedIndex: Int?

        if let index = chapters.firstIndex(where: { min < $0.stopTime && $0.stopTime < max } ) {
            matchedIndex = index
        }

        if matchedIndex != nil {
            AudioServicesPlaySystemSound(1520)
        }
    }

    private func switchToStrong(_ isStrong: Bool) {
        if isStrong {
            updateThumbView(withRadius: 10)
            updateTrackView(withHeight: 6)
        } else {
            updateThumbView(withRadius: thumbRadius)
            updateTrackView(withHeight: trackHeight)
        }
        self.isStrong = isStrong
    }

    private func delaySwitchToLittle() {
        let workIem = DispatchWorkItem { [weak self] in
            self?.switchToStrong(false)
            self?.setThumb(isShow: false)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: workIem)
        self.workItem = workIem
    }

    private func cancelWorkItem() {
        workItem?.cancel()
    }

    @objc private func tapAction(_ gesture: UITapGestureRecognizer) {
        updateValue(withLocation: gesture.location(in: self))
        if isDynamic {
            cancelWorkItem()
            switchToStrong(true)
            setThumb(isShow: true)
            delaySwitchToLittle()
        }

        NotificationCenter.default.post(name: .didTouchedProgressBar, object: nil)
    }

    @objc private func panAction(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began, .possible:
            delegate?.sliderValueWillChange()
            if isDynamic {
                cancelWorkItem()
                switchToStrong(true)
                setThumb(isShow: true)
            }
        case .ended, .cancelled, .failed:
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
            delegate?.sliderValueDidEndChanged()
            if isDynamic {
                delaySwitchToLittle()
            }
            NotificationCenter.default.post(name: .didTouchedProgressBar, object: nil)
        default:
            break
        }
        updateValue(withLocation: gesture.location(in: self))
    }

}

extension MinutesSliderView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == panGesture {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }

        return true
    }
}
