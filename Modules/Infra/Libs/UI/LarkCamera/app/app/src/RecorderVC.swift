//
//  RecorderVC.swift
//  LarkCameraDev
//
//  Created by Saafo on 2023/3/22.
//

import UIKit
import AVFAudio

class RecorderVC: UIViewController, AVAudioRecorderDelegate {
    var audioRecorder: AVAudioRecorder?
    var audioSession: AVAudioSession?
    var cacheURL: URL?
    var recordButton = UIButton()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ud.bgBase
        cacheURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")
        // 设置录音参数
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 24000,//16000,
            AVNumberOfChannelsKey: 1
        ]
        // 获取AVAudioSession单例对象
        let session = AVAudioSession.sharedInstance()
        self.audioSession = session

        // 设置输入设备（其实没有区别）
        print("0x01 \(String(describing: session.preferredInput)), \(String(describing: session.availableInputs))")
        let inputDevices = session.availableInputs
        let desiredInput = inputDevices?.first(where: { $0.portType == .builtInMic })
        do {
            try session.setPreferredInput(desiredInput)
        } catch {
            print("Error setting preferred input: \(error.localizedDescription)")
        }
        print("0x02 \(String(describing: session.preferredInput)), \(String(describing: session.availableInputs))")


        // 创建AVAudioRecorder对象
        do {
            audioRecorder = try AVAudioRecorder(url: cacheURL!, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.delegate = self
        } catch {
            print("❤️ create audio recorder failed: \(error)")
        }

        // Configure button
        recordButton.frame = CGRect(x: 150, y: 600, width: 100, height: 100)
        recordButton.layer.cornerRadius = 32
        recordButton.backgroundColor = .ud.R400
        recordButton.addTarget(self, action: #selector(start(_:)), for: .touchDown)
        recordButton.addTarget(self, action: #selector(stop(_:)), for: .touchUpInside)
        view.addSubview(recordButton)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        do {
            try audioSession?.setCategory(.playAndRecord, mode: .default,
                                          options: [.allowBluetooth, .allowAirPlay, .allowBluetoothA2DP])
            try audioSession?.setActive(true)
        } catch {
            print("❤️ failed to set audio session active: \(error)")
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        do {
            try audioSession?.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("❤️ failed to set audio session inactive: \(error)")
        }
    }

    @objc
    func start(_ sender: UIButton) {
        print("start")
        audioRecorder?.record()
    }

    @objc
    func stop(_ sender: UIButton) {
        print("stop")
        audioRecorder?.stop()
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        guard flag else {
            print("❤️ recorder finish failed")
            return
        }
        print("finish recording, size: \(String(describing: try? Data(contentsOf: cacheURL!).count))")
        // Photo doesn't support wav(lpcm) file, so we share to other apps
        let activityViewController = UIActivityViewController(activityItems: [cacheURL!], applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }
}

