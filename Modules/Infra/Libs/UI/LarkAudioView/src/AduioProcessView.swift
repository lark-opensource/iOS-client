//
//  AduioProcessView.swift
//  LarkChat
//
//  Created by 李晨 on 2019/2/22.
//

import Foundation
import LarkAudioKit
import UIKit

public struct AudioProcessWave {
    public var value: Double
    public var startTime: TimeInterval
    public var duration: TimeInterval
}

public protocol AudioProcessViewProtocol: UIView {
    func update(currentTime: TimeInterval, duration: TimeInterval)
}

public final class AudioProcessView: UIView, AudioProcessViewProtocol {
    public let waves: [AudioProcessWave]
    public var duration: TimeInterval
    public var current: TimeInterval = 0
    private var wrapperView: UIView = UIView()

    private var waveViews: [UIView] = []
    private var timeLabel: UILabel = {
        var label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = UIColor.white
        label.textAlignment = .right
        return label
    }()

    // 取单个数字的最大宽度
    private static var numberMaxWidth: CGFloat = {
        let font = UIFont.systemFont(ofSize: 17)
        return (0...9).map({ (index) -> CGFloat in
            let rect = NSString(string: "\(index)").boundingRect(
                with: CGSize(width: 100, height: CGFloat(MAXFLOAT)),
                options: .usesLineFragmentOrigin,
                attributes: [.font: font],
                context: nil)
            return rect.width
        }).max() ?? 0
    }()

    private static var colonWidth: CGFloat = {
        let font = UIFont.systemFont(ofSize: 17)
        let rect = NSString(string: ":").boundingRect(
            with: CGSize(width: 100, height: CGFloat(MAXFLOAT)),
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil)
        return rect.width
    }()

    public static var maxWidth: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return 320 - 32
        }
        return UIScreen.main.bounds.width - 32
    }
    public static var defaultWaveNumber: Int = Int((AudioProcessView.maxWidth - 78) / 6)

    public static func waves(
        data: Data,
        duration: TimeInterval,
        waveNumber: Int = AudioProcessView.defaultWaveNumber,
        maxSampleDuration: Double = 0.01
        ) -> [AudioProcessWave]? {
        guard let wavFile = WavFile(data: data) else { return nil }
        var waves: [AudioProcessWave] = []
        let waveDuration = duration / TimeInterval(waveNumber)
        let frameLength = wavFile.pcmData.frameLength
        let waveFrameCount = Int(TimeInterval(wavFile.pcmData.data.count / frameLength) / TimeInterval(waveNumber))
        for i in 0..<waveNumber {
            let offset = min(
                waveFrameCount * frameLength,
                Int(Double(wavFile.pcmData.sampleRate) * Double(frameLength) * maxSampleDuration)
            )
            // 取样偏移
            let start = i * waveFrameCount * frameLength
            let subData = Data(wavFile.pcmData.data[start..<start + offset])
            let decibel = Decibel.getDecibel(data: subData, channel: wavFile.pcmData.numChannels, bitsPerSample: wavFile.pcmData.bitsPerSample)
            let wave = AudioProcessWave(value: decibel.avgValue, startTime: Double(i) * waveDuration, duration: waveDuration)
            waves.append(wave)
        }
        return waves
    }

    // 直接传入初始化过的数据
    public init(duration: TimeInterval, waves: [AudioProcessWave]) {
        self.waves = waves
        self.duration = duration
        super.init(frame: CGRect.zero)
        self.setupViews()
    }

    // 通过 data 初始化数据
    public init?(data: Data, duration: TimeInterval, waveNumber: Int = AudioProcessView.defaultWaveNumber) {
        guard let waves = AudioProcessView.waves(data: data, duration: duration, waveNumber: waveNumber) else { return nil }
        self.waves = waves
        self.duration = duration
        super.init(frame: CGRect.zero)
        self.setupViews()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.layer.cornerRadius = 22
        self.layer.masksToBounds = true

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [ // gradient-wathet
            UIColor.ud.W400.cgColor,
            UIColor.ud.colorfulWathet.cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        gradientLayer.frame = CGRect(x: 0, y: 0, width: AudioProcessView.maxWidth, height: 44)
        gradientLayer.locations = [NSNumber(value: 0), NSNumber(value: 1)]
        self.layer.addSublayer(gradientLayer)

        self.addSubview(self.wrapperView)
        wrapperView.snp.makeConstraints { (maker) in
            maker.center.equalToSuperview()
        }

        self.waves.enumerated().forEach { (_, wave) in
            let waveView = UIView()
            waveView.layer.cornerRadius = 1
            wrapperView.addSubview(waveView)
            waveView.snp.makeConstraints({ (maker) in
                maker.width.equalTo(2)
                maker.centerY.equalToSuperview()
                if let last = self.waveViews.last {
                    maker.left.equalTo(last.snp.right).offset(4)
                } else {
                    maker.left.equalToSuperview()
                }
                // 最小显示 45 最大显示 80
                let maxValue: Double = 80
                let minValue: Double = 45
                let value = max(min(wave.value, maxValue), minValue)
                let height = 4 + (value - minValue) * 18 / (maxValue - minValue)
                maker.height.equalTo(height)
            })
            self.waveViews.append(waveView)
        }

        self.timeLabel.text = AudioProcessView.format(time: self.duration)
        self.timeLabel.font = UIFont.systemFont(ofSize: 17)
        self.timeLabel.textColor = UIColor.white
        wrapperView.addSubview(self.timeLabel)
        timeLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.right.equalToSuperview()
            if let last = self.waveViews.last {
                maker.left.equalTo(last.snp.right).offset(8)
            } else {
                maker.left.equalToSuperview()
            }
            maker.width.equalTo(0)
        }

        self.updateWaveViews()
        self.updateTimeView()
    }

    public func update(currentTime: TimeInterval, duration: TimeInterval) {
        self.current = currentTime
        self.timeLabel.text = AudioProcessView.format(time: self.current)
        self.updateWaveViews()
        self.updateTimeView()
    }

    private func updateTimeView() {
        self.timeLabel.snp.updateConstraints { (maker) in
            maker.width.equalTo(AudioProcessView.timeStrWidth(time: self.current))
        }
    }

    private func updateWaveViews() {
        self.waves.enumerated().forEach { (index, wave) in
            if wave.startTime < self.current {
                self.waveViews[index].backgroundColor = UIColor.white
            } else {
                self.waveViews[index].backgroundColor = UIColor.white.withAlphaComponent(0.2)
            }
        }
    }

    private static func format(time: TimeInterval) -> String {
        let second = Int(time) % 60
        let minute = Int(time) / 60
        return "\(minute):\(second >= 10 ? "" : "0")\(second)"
    }

    static func timeStrWidth(time: TimeInterval) -> CGFloat {
        let second = Int(time) % 60
        let minute = Int(time) / 60

        if minute >= 10 {
            return ceil(4 * self.numberMaxWidth + self.colonWidth)
        } else {
            return ceil(3 * self.numberMaxWidth + self.colonWidth)
        }
    }
}
