//
//  ViewController.swift
//  LarkAudioKitDev
//
//  Created by 李晨 on 2019/11/5.
//

import Foundation
import UIKit
import LarkAudioKit
import AVFoundation

class ViewController: UIViewController, RecordAudioDelegate {

    var audioData: Data?

    let statusView = UIView()

    let statusLabel = UILabel()

    var recordService: AudioRecordManager = AudioRecordManager.sharedInstance
    var playService: AudioPlayMediator = AudioPlayMediator()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(statusView)
        statusView.frame = .init(x: 50, y: 444, width: 44, height: 44)
        statusView.layer.cornerRadius = 22
        statusView.backgroundColor = UIColor.red

        self.view.addSubview(statusLabel)
        statusLabel.frame = .init(x: 150, y: 444, width: 200, height: 44)
        statusLabel.textColor = UIColor.black
        statusLabel.text = "ready"

        let button = UILabel(frame: .init(x: 100, y: 100, width: 100, height: 44))
        button.backgroundColor = UIColor.red
        button.text = "Record"
        button.textColor = .white
        button.isUserInteractionEnabled = true
        self.view.addSubview(button)
        let long = UILongPressGestureRecognizer(target: self, action: #selector(click(ges:)))
        button.addGestureRecognizer(long)

        let button2 = UIButton(frame: .init(x: 100, y: 200, width: 100, height: 44))
        button2.backgroundColor = UIColor.green
        button2.setTitle("Stop", for: .normal)
        self.view.addSubview(button2)
        button2.addTarget(self, action: #selector(click2), for: .touchUpInside)

        let button3 = UIButton(frame: .init(x: 100, y: 300, width: 100, height: 44))
        button3.backgroundColor = UIColor.blue
        button3.setTitle("Play", for: .normal)
        self.view.addSubview(button3)
        button3.addTarget(self, action: #selector(click3), for: .touchUpInside)


        let button4 = UIButton(frame: .init(x: 100, y: 500, width: 100, height: 44))
        button4.backgroundColor = UIColor.blue
        button4.setTitle("震动", for: .normal)
        self.view.addSubview(button4)
        button4.addTarget(self, action: #selector(click4), for: .touchUpInside)
    }

    @objc func click(ges: UIGestureRecognizer) {
        if ges.state != .began {
            return
        }
        self.recordService.delegate = self
        self.recordService.startRecord(useAveragePower: false, impact: true) { result in
            print("--------------- start result \(result)")
        }
    }

    @objc func click2() {
        self.recordService.stopRecord()
    }

    @objc func click3() {
        if let data = self.audioData {
            self.playService.playAudioWith(data: data, key: "123123", play: true)
        }
    }

    static var i = 0
    @objc func click4() {
        if let style = UIImpactFeedbackGenerator.FeedbackStyle(rawValue: Self.i) {
            UIImpactFeedbackGenerator(style: style).impactOccurred()
            print("------------ impact style \(style.rawValue)")
        }
        Self.i += 1
        if Self.i > 4 {
            Self.i = 0
        }
    }

    func audioRecordUpdateMetra(_ metra: Float) {
        print("----- record audioRecordUpdateMetra \(metra)")
    }

    func audioRecordStateChange(state: AudioRecordState) {
        print("----- record audioRecordStateChange \(state) date \(Date().timeIntervalSince1970)")

        switch state {
            case .success(let data, let length):
                print("----- record audioRecordStreamData  \(data) is Wav \(OpusUtil.isWavFormat(data)) length \(length)")
                self.audioData = data
                statusView.backgroundColor = UIColor.red
                statusLabel.text = "ready"
            case .prepare:
                statusView.backgroundColor = UIColor.yellow
                statusLabel.text = "prepare"
            case .start:
                statusView.backgroundColor = UIColor.green
                statusLabel.text = "recording"
            default:
                statusView.backgroundColor = UIColor.red
                statusLabel.text = "ready"
        }
    }

    func audioRecordStreamData(data: Data) {

    }
}
