import Foundation
import UIKit
import SnapKit
import LarkUIKit
import UniverseDesignColor
import EENavigator
import LarkExtensions
import MinutesFoundation
import LarkContainer

class MinutesTranscriptProgressBar: UIView, UserResolverWrapper {
    let userResolver: LarkContainer.UserResolver

    init(resolver: UserResolver) {
        self.userResolver = resolver
        super.init(frame: .zero)

        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var sliderValueDidChanged: ((CGFloat, CGFloat) -> Void)?
    var currentTimeDidhanged: ((String?) -> Void)?
    var endTimeDidhanged: ((String?) -> Void)?

    let currentTimeLabel: UILabel = UILabel()
    let endTimeLabel: UILabel = UILabel()

    lazy var slider: MinutesSliderView = {
        let sv = MinutesSliderView(resolver: userResolver)
        sv.trackHeight = 2
        sv.thumbRadius = 4.5
        sv.isDynamic = false
        sv.delegate = self
        return sv
    }()
    var videoDuration: Int = 0 {
        didSet {
            slider.videoDuration = videoDuration
            let timeStr = (TimeInterval(videoDuration) / 1000).autoFormat()
            endTimeLabel.text = timeStr
            endTimeDidhanged?(timeStr)
        }
    }
    var chapters: [MinutesChapterInfo] = [] {
        didSet {
            slider.chapters = chapters
        }
    }

    func updateSliderOffset(_ currentTime: Int) {
        let process = CGFloat(currentTime) / CGFloat(videoDuration)

        DispatchQueue.main.async {
            self.slider.setValue(process, animated: false)
            let timeStr =  (TimeInterval(currentTime) / 1000).autoFormat()
            self.currentTimeLabel.text = timeStr
            self.currentTimeDidhanged?(timeStr)
        }
    }

    func setupSubviews() {
        backgroundColor = UIColor.ud.bgFloatOverlay
        addSubview(slider)
        slider.snp.makeConstraints { maker in
            maker.left.equalToSuperview().offset(16)
            maker.right.equalToSuperview().inset(16)
            maker.top.equalToSuperview()
            maker.height.equalTo(46)
        }
        slider.setValue(0.0, animated: false)

        addSubview(currentTimeLabel)
        currentTimeLabel.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        currentTimeLabel.textColor = UIColor.ud.textPlaceholder
        currentTimeLabel.text = "00:00"
        currentTimeLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(self.snp.top).offset(40)
            maker.left.equalToSuperview().offset(16)
        }

        addSubview(endTimeLabel)
        endTimeLabel.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        endTimeLabel.textColor = UIColor.ud.textPlaceholder
        endTimeLabel.text = "--:--"
        endTimeLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(self.snp.top).offset(40)
            maker.right.equalToSuperview().offset(-16)
        }
    }
}

extension MinutesTranscriptProgressBar: MinutesSliderViewDelegate {
    func sliderValueWillChange() {
    }

    func sliderValueDidChanged(_ value: CGFloat) {
        let time = ceil(CGFloat(videoDuration) * value)
        let timeStr =  TimeInterval(time / 1000).autoFormat()
        self.currentTimeLabel.text = timeStr
        currentTimeDidhanged?(timeStr)
        sliderValueDidChanged?(value, time)

    }

    func sliderValueDidEndChanged() {
    }
}
