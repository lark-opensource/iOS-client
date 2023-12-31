//
//  CaretView.swift
//  LarkAudio
//
//  Created by kangkang on 2023/10/31.
//

import Foundation
import UniverseDesignColor

// 光标View
final class CaretView: UIView {
    let blinkDuration = 0.5
    let blinkFadeDuration = 0.2
    var timer: Timer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 1
        self.backgroundColor = .systemBlue
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if self.window != nil {
            startBlinks()
        } else {
            stopBlinks()
        }
    }

    func startBlinks() {
        timer?.invalidate()
        let t = Timer(timeInterval: blinkDuration, target: self, selector: #selector(doBlink), userInfo: nil, repeats: true)
        RunLoop.current.add(t, forMode: .common)
        self.timer = t
    }

    @objc
    func doBlink() {
        UIView.animate(withDuration: blinkFadeDuration, delay: 0, options: .curveEaseInOut, animations: {
            if self.alpha == 1 {
                self.alpha = 0
            } else {
                self.alpha = 1
            }
        })
    }

    func stopBlinks() {
        timer?.invalidate()
        self.alpha = 0
    }
}
