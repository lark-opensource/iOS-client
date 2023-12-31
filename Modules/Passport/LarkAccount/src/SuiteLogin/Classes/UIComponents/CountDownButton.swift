//
//  CountDownButton.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2020/8/5.
//

import UIKit

class CountDownButton: NextButton {

    private var countNumber: uint
    private let maxCountDownNumber: uint
    private let templateTitle: (String) -> String
    private let normalTitle: String
    private var countDownOver: (() -> Void)?
    private var timer: Timer?

    init(style: Style = .roundedRectWhiteWithGrayOutline,
         maxCountDownNumber: uint = 60,
         initCount: uint? = nil,
         normalTitle: String,
         templateTitle: @escaping (String) -> String,
         countDownOver: (() -> Void)?) {
        self.templateTitle = templateTitle
        self.normalTitle = normalTitle
        self.maxCountDownNumber = maxCountDownNumber
        self.countNumber = initCount ?? maxCountDownNumber
        self.countDownOver = countDownOver
        super.init(title: normalTitle, style: style)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startCountDown(withCount count: uint? = nil) {
        stopCountDown()
        if let count = count {
            countNumber = count
        }
        update()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (_) in
            guard let self = self else { return }
            self.countNumber -= 1
            self.update()
        })
    }

    func stopCountDown() {
        timer?.invalidate()
        timer = nil
    }

    private func update() {
        if countNumber > 0 {
            isEnabled = false
            setTitle(templateTitle("\(countNumber)"), for: .disabled)
        } else {
            stopCountDown()
            countNumber = maxCountDownNumber
            isEnabled = true
            setTitle(normalTitle, for: .normal)
            countDownOver?()
        }
    }

    deinit {
        stopCountDown()
    }
}
