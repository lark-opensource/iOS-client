//
//  TrashLottie.swift
//  LarkAudio
//
//  Created by kangkang on 2023/9/21.
//

import Lottie
import Foundation
import LKCommonsLogging

final class TrashLottieView: UIView {
    enum DisplayState {
        case idling
        case idled
        case ending
        case ended
        case activated
        case activating
    }
    var displayState: DisplayState = .idled {
        didSet {
            TrashLottieView.logger.info("trash lottie display state: \(displayState)")
        }
    }
    lazy var animationView: LOTAnimationView = {
        let path = BundleConfig.LarkAudioBundle.path(forResource: "trash_animation", ofType: "json")
        let view = LOTAnimationView(filePath: path ?? "")
        view.backgroundColor = UIColor.clear
        return view
    }()
    var timer: Timer?
    static let logger = Logger.log(TrashLottieView.self, category: "TrashLottieView")

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(animationView)
        animationView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        animationView.contentMode = .scaleAspectFit
    }

    @objc
    func shakyTrask() {
        animationView.play(fromFrame: 22, toFrame: 60)
    }

    // 垃圾桶展开
    func activated() {
        TrashLottieView.logger.info("trash lottie start activated")
        displayState = .activating
        animationView.play(fromFrame: 0, toFrame: 22) { [weak self] _ in
            self?.displayState = .activated
        }
        animationView.animationSpeed = 1
        timer = Timer(timeInterval: 3, target: self, selector: #selector(shakyTrask), userInfo: nil, repeats: true)
        if let timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    // 垃圾桶收起
    func idle() {
        TrashLottieView.logger.info("trash lottie start idle")
        timer?.invalidate()
        timer = nil
        // 需要让动画固定在22帧。
        // bad case: 执行activated()，动画还没调用completion时，调用idle()。
        // 现象: idle动画执行到一半时activated的completion返回，会让idle动画暂停不继续播放
        animationView.setProgressWithFrame(22)
        animationView.animationSpeed = 1.5
        displayState = .idling
        animationView.play(fromFrame: 22, toFrame: 0) { [weak self] _ in
            self?.displayState = .idled
        }
    }

    // 垃圾桶结束
    func end(completion: @escaping () -> Void) {
        TrashLottieView.logger.info("trash lottie start end")
        self.animationView.setProgressWithFrame(60)
        timer?.invalidate()
        timer = nil
        displayState = .ending
        animationView.play(fromFrame: 60, toFrame: 92) { [weak self] _ in
            self?.displayState = .ended
            completion()
            self?.animationView.setProgressWithFrame(0)
        }
        animationView.animationSpeed = 1
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
