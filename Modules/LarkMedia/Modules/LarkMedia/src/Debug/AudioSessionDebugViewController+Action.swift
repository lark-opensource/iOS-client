//
//  AudioSessionDebugViewController+Action.swift
//  LarkMedia
//
//  Created by fakegourmet on 2023/3/8.
//

import Foundation
import AVFAudio

// - MARK: Main
extension AudioSessionDebugViewController {
    var mainSection: AudioDebugSectionModel {
        AudioDebugSectionModel(sectionTitle: "Main", cellModels: [
            AudioDebugSubtitleCellModelGetter(title: "Category", value: AVAudioSession.sharedInstance().category.rawValue),
            AudioDebugSubtitleCellModelGetter(title: "Mode", value: AVAudioSession.sharedInstance().mode.rawValue),
            AudioDebugSubtitleCellModelGetter(title: "CategoryOptions", value: AVAudioSession.sharedInstance().categoryOptions.description),
            AudioDebugSubtitleCellModelGetter(title: "RouteSharingPolicy", value: "\(AVAudioSession.sharedInstance().routeSharingPolicy)"),
            AudioDebugSubtitleCellModelGetter(title: "RecordPermission", value: "\(AVAudioSession.sharedInstance().recordPermission)"),
            AudioDebugSubtitleCellModelGetter(title: "IsOtherAudioPlaying", value: "\(AVAudioSession.sharedInstance().isOtherAudioPlaying)"),
            AudioDebugSubtitleCellModelGetter(title: "SecondaryAudioShouldBeSilencedHint", value: "\(AVAudioSession.sharedInstance().secondaryAudioShouldBeSilencedHint)"),
            AudioDebugSubtitleCellModelGetter(title: "CurrentRoute", value: "\(AVAudioSession.sharedInstance().currentRoute)"),
            AudioDebugSubtitleCellModelGetter(title: "PreferredInput", value: "\(String(describing: AVAudioSession.sharedInstance().preferredInput))")
        ])
    }
}

// - MARK: Status
extension AudioSessionDebugViewController {
    var statusSection: AudioDebugSectionModel {
        var cellModels = [
            AudioDebugSubtitleCellModelGetter(title: "PreferredSampleRate", value: "\(AVAudioSession.sharedInstance().preferredSampleRate)"),
            AudioDebugSubtitleCellModelGetter(title: "SampleRate", value: "\(AVAudioSession.sharedInstance().sampleRate)"),
            AudioDebugSubtitleCellModelGetter(title: "PreferredIOBufferDuration", value: "\(AVAudioSession.sharedInstance().preferredIOBufferDuration)"),
            AudioDebugSubtitleCellModelGetter(title: "IOBufferDuration", value: "\(AVAudioSession.sharedInstance().ioBufferDuration)"),
            AudioDebugSubtitleCellModelGetter(title: "PreferredInputNumberOfChannels", value: "\(AVAudioSession.sharedInstance().preferredInputNumberOfChannels)"),
            AudioDebugSubtitleCellModelGetter(title: "InputNumberOfChannels", value: "\(AVAudioSession.sharedInstance().inputNumberOfChannels)"),
            AudioDebugSubtitleCellModelGetter(title: "MaximumInputNumberOfChannels", value: "\(AVAudioSession.sharedInstance().maximumInputNumberOfChannels)"),
            AudioDebugSubtitleCellModelGetter(title: "PreferredOutputNumberOfChannels", value: "\(AVAudioSession.sharedInstance().preferredOutputNumberOfChannels)"),
            AudioDebugSubtitleCellModelGetter(title: "OutputNumberOfChannels", value: "\(AVAudioSession.sharedInstance().outputNumberOfChannels)"),
            AudioDebugSubtitleCellModelGetter(title: "MaximumOutputNumberOfChannels", value: "\(AVAudioSession.sharedInstance().maximumOutputNumberOfChannels)"),
            AudioDebugSubtitleCellModelGetter(title: "InputGain", value: "\(AVAudioSession.sharedInstance().inputGain)"),
            AudioDebugSubtitleCellModelGetter(title: "IsInputGainSettable", value: "\(AVAudioSession.sharedInstance().isInputGainSettable)"),
            AudioDebugSubtitleCellModelGetter(title: "IsInputAvailable", value: "\(AVAudioSession.sharedInstance().isInputAvailable)"),
            AudioDebugSubtitleCellModelGetter(title: "InputDataSource", value: "\(String(describing: AVAudioSession.sharedInstance().inputDataSource))"),
            AudioDebugSubtitleCellModelGetter(title: "OutputDataSource", value: "\(String(describing: AVAudioSession.sharedInstance().outputDataSource))"),
            AudioDebugSubtitleCellModelGetter(title: "InputDataSources", value: "\(String(describing: AVAudioSession.sharedInstance().inputDataSources))"),
            AudioDebugSubtitleCellModelGetter(title: "OutputDataSources", value: "\(String(describing: AVAudioSession.sharedInstance().outputDataSources))"),
            AudioDebugSubtitleCellModelGetter(title: "OutputVolume", value: "\(AVAudioSession.sharedInstance().outputVolume)"),
            AudioDebugSubtitleCellModelGetter(title: "InputLatency", value: "\(AVAudioSession.sharedInstance().inputLatency)"),
            AudioDebugSubtitleCellModelGetter(title: "OutputLatency", value: "\(AVAudioSession.sharedInstance().outputLatency)"),
            AudioDebugSubtitleCellModelGetter(title: "AvailableInputs", value: "\(String(describing: AVAudioSession.sharedInstance().availableInputs))"),
            AudioDebugSubtitleCellModelGetter(title: "AvailableCategories", value: "\(AVAudioSession.sharedInstance().availableCategories)"),
            AudioDebugSubtitleCellModelGetter(title: "AvailableModes", value: "\(AVAudioSession.sharedInstance().availableModes)"),
        ]
        if #available(iOS 13.0, *) {
            cellModels.append(AudioDebugSubtitleCellModelGetter(title: "AllowHapticsAndSystemSoundsDuringRecording", value: "\(AVAudioSession.sharedInstance().allowHapticsAndSystemSoundsDuringRecording)"))
            cellModels.append(AudioDebugSubtitleCellModelGetter(title: "PromptStyle", value: "\(AVAudioSession.sharedInstance().promptStyle)"))
        }
        if #available(iOS 14.0, *) {
            cellModels.append(AudioDebugSubtitleCellModelGetter(title: "PreferredInputOrientation", value: "\(AVAudioSession.sharedInstance().preferredInputOrientation)"))
            cellModels.append(AudioDebugSubtitleCellModelGetter(title: "InputOrientation", value: "\(AVAudioSession.sharedInstance().inputOrientation)"))
        }
        #if compiler(>=5.4)
        if #available(iOS 14.5, *) {
            cellModels.append(AudioDebugSubtitleCellModelGetter(title: "PrefersNoInterruptionsFromSystemAlerts", value: "\(AVAudioSession.sharedInstance().prefersNoInterruptionsFromSystemAlerts)"))
        }
        #endif
        #if compiler(>=5.5)
        if #available(iOS 15.0, *) {
            cellModels.append(AudioDebugSubtitleCellModelGetter(title: "SupportsMultichannelContent", value: "\(AVAudioSession.sharedInstance().supportsMultichannelContent)"))
        }
        #endif
        return AudioDebugSectionModel(sectionTitle: "Status", cellModels: cellModels)
    }
}

// - MARK: Settings
extension AudioSessionDebugViewController {

    var settingsSection: AudioDebugSectionModel {
        AudioDebugSectionModel(sectionTitle: "Settings", cellModels: [
            AudioDebugSingleSelCellModelGetter(title: "Category", value: SingleSelItem(
                AudioSessionDebugViewController.curSelCategory(),
                AVAudioSession.sharedInstance().availableCategories.map { $0.rawValue })
            ),
            AudioDebugSingleSelCellModelGetter(title: "Mode", value: SingleSelItem(
                AudioSessionDebugViewController.curSelMode(),
                AVAudioSession.sharedInstance().availableModes.map { $0.rawValue })
            ),
            AudioDebugMultiSelCellModelGetter(title: "Category Options", value: MultiSelItem(
                    AudioSessionDebugViewController.curSelCategoryOpts().split(separator: "|").map { String($0) },
                    AVAudioSession.CategoryOptions.knownOptions.map { $0.description }
               )
            )
        ])
    }

    var actionSection: AudioDebugSectionModel {
        AudioDebugSectionModel(sectionTitle: "Action", cellModels: [
            AudioDebugButtonCellModelGetter(title: "Update Category", value: {
                let category = AVAudioSession.Category(rawValue: AudioSessionDebugViewController.curSelCategory())
                let mode = AVAudioSession.Mode(rawValue: AudioSessionDebugViewController.curSelMode())
                let categoryOpts = AVAudioSession.CategoryOptions.buildOptions(AudioSessionDebugViewController.curSelCategoryOpts())
                try? AVAudioSession.sharedInstance().setCategory(category, mode: mode, options: categoryOpts)
            }),
            AudioDebugButtonCellModelGetter(title: "Active With Notify", value: {
                try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            }),
            AudioDebugButtonCellModelGetter(title: "Active Without Notify", value: {
                try? AVAudioSession.sharedInstance().setActive(true)
            }),
            AudioDebugButtonCellModelGetter(title: "Deactive With Notify", value: {
                try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            }),
            AudioDebugButtonCellModelGetter(title: "Deactive Without Notify", value: {
                try? AVAudioSession.sharedInstance().setActive(false)
            }),
            AudioDebugButtonCellModelGetter(title: "Override Speaker", value: {
                try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
            }),
            AudioDebugButtonCellModelGetter(title: "Override None", value: {
                try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
            }),
            AudioDebugButtonCellModelGetter(title: "Set Preferred Input", value: { [weak self] in
                guard let self = self else { return }
                guard let inputs = AVAudioSession.sharedInstance().availableInputs else {
                    return
                }
                let alertController = UIAlertController()
                for input in inputs {
                    alertController.addAction(UIAlertAction(title: input.description,
                                                            style: .default,
                                                            handler: { _ in
                                                                try? AVAudioSession.sharedInstance().setPreferredInput(input)
                    }))
                }
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }),
            AudioDebugButtonCellModelGetter(title: "Set Preferred SampleRate", value: { [weak self] in
                guard let self = self else { return }
                let alertController = UIAlertController(title: "Set Preferred SampleRate", message: "", preferredStyle: .alert)
                alertController.addTextField()
                alertController.addAction(UIAlertAction(title: "Set", style: .default, handler: { [weak alertController] _ in
                    if let text = alertController?.textFields?.first?.text,
                       let sampleRate = Double(text) {
                        try? AVAudioSession.sharedInstance().setPreferredSampleRate(sampleRate)
                    }
                }))
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }),
            AudioDebugButtonCellModelGetter(title: "Set Preferred IOBufferDuration", value: { [weak self] in
                guard let self = self else { return }
                let alertController = UIAlertController(title: "Set Preferred IOBufferDuration", message: "", preferredStyle: .alert)
                alertController.addTextField()
                alertController.addAction(UIAlertAction(title: "Set", style: .default, handler: { [weak alertController] _ in
                    if let text = alertController?.textFields?.first?.text,
                       let ioBufferDuration = Double(text) {
                        try? AVAudioSession.sharedInstance().setPreferredIOBufferDuration(ioBufferDuration)
                    }
                }))
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }),
            AudioDebugButtonCellModelGetter(title: "Set Microphone Mute", value: { [weak self] in
                guard let self = self else { return }
                let alertController = UIAlertController(title: "Set Microphone Mute", message: "", preferredStyle: .alert)
                alertController.addTextField()
                alertController.addAction(UIAlertAction(title: "Set", style: .default, handler: { [weak alertController] _ in
                    if let text = alertController?.textFields?.first?.text,
                       let mute = Int(text) {
                        LarkMediaManager.shared.tryLock(scene: .vcMeeting) { result in
                            if case .success(let resource) = result {
                                _ = resource.microphone.requestMute(mute > 0 ? true : false)
                            }
                        }
                    }
                }))
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }),
        ])
    }
}

// - MARK: AudioUnit
extension AudioSessionDebugViewController {
    var auStatusSection: AudioDebugSectionModel {
        AudioDebugSectionModel(sectionTitle: "Status", cellModels: [
            AudioDebugSingleSelActionCellModelGetter(title: "engine", value: SingleSelActionItem(
                value: "",
                options: engineKeys,
                action: nil
            )),
            AudioDebugSingleSelActionCellModelGetter(title: "player", value: SingleSelActionItem(
                value: "",
                options: playerKeys,
                action: nil
            )),
            AudioDebugSingleSelActionCellModelGetter(title: "mixer", value: SingleSelActionItem(
                value: "",
                options: mixerKeys,
                action: nil
            )),
            AudioDebugSubtitleCellModelGetter(title: "AudioUnit", value: audioUnitDesc)
        ])
    }

    var auActionSection: AudioDebugSectionModel {
        AudioDebugSectionModel(sectionTitle: "Action", cellModels: [
            AudioDebugButtonCellModelGetter(title: "Set Audio URL", value: { [weak self] in
                guard let self = self else { return }
                let alertController = UIAlertController(title: "Set Audio URL", message: "", preferredStyle: .alert)
                alertController.addTextField { textfield in
                    textfield.text = ""
                }
                alertController.addAction(UIAlertAction(title: "Set", style: .default, handler: { [weak alertController] _ in
                    if let text = alertController?.textFields?.first?.text {
                        if text.isEmpty {
                            self.audioEngine.addFile()
                        } else {
                            self.audioEngine.addFile(url: URL(string: text))
                        }
                    }
                }))
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }),
            AudioDebugButtonCellModelGetter(title: "Add Player Node", value: { [weak self] in
                self?.audioEngine.addPlayer()
            }),
            AudioDebugButtonCellModelGetter(title: "Remove Player Node", value: { [weak self] in
                self?.audioEngine.removePlayer()
            }),
            AudioDebugButtonCellModelGetter(title: "Add Recorder Node", value: { [weak self] in
                self?.audioEngine.addRecorder()
            }),
            AudioDebugButtonCellModelGetter(title: "Remove Recorder Node", value: { [weak self] in
                self?.audioEngine.removeRecorder()
            }),
            AudioDebugButtonCellModelGetter(title: "Start Engine", value: { [weak self] in
                self?.audioEngine.startEngine()
            }),
            AudioDebugButtonCellModelGetter(title: "Stop Engine", value: { [weak self] in
                self?.audioEngine.stopEngine()
            }),
            AudioDebugButtonCellModelGetter(title: "Start Player", value: { [weak self] in
                self?.audioEngine.startPlayer()
            }),
            AudioDebugButtonCellModelGetter(title: "Pause Player", value: { [weak self] in
                self?.audioEngine.pausePlayer()
            }),
            AudioDebugButtonCellModelGetter(title: "Stop Player", value: { [weak self] in
                self?.audioEngine.stopPlayer()
            }),
            AudioDebugButtonCellModelGetter(title: "toggle VPIO", value: { [weak self] in
                let enabled: Bool = self?.audioEngine.isVPIO ?? false
                self?.audioEngine.setVPIO(enabled: !enabled)
            }),
            AudioDebugButtonCellModelGetter(title: "Audio Unit Property", value: { [weak self] in
                let alertController = UIAlertController(title: "Set AudioUnit", message: "", preferredStyle: .alert)
                alertController.addTextField { textfield in
                    textfield.placeholder = "propertyID"
                }
                alertController.addTextField { textfield in
                    textfield.text = "\(kAudioUnitScope_Global)"
                    textfield.placeholder = "scopeID"
                }
                alertController.addTextField { textfield in
                    textfield.text = "0"
                    textfield.placeholder = "elementID"
                }
                alertController.addTextField { textfield in
                    textfield.text = "0"
                    textfield.placeholder = "data"
                }
                alertController.addTextField { textfield in
                    textfield.text = "0"
                    textfield.placeholder = "isInput"
                }
                alertController.addAction(UIAlertAction(title: "Get", style: .default, handler: { [weak alertController] _ in
                    if let text1 = alertController?.textFields?[0].text,
                       let propertyID = AudioUnitPropertyID(text1),
                       let text2 = alertController?.textFields?[1].text,
                       let scopeID = AudioUnitScope(text2),
                       let text3 = alertController?.textFields?[2].text,
                       let elementID = AudioUnitScope(text3) {
                        let isInput = (alertController?.textFields?[4].text == "0")
                        var result: String?
                        if isInput {
                            result = self?.audioEngine.getInputAudioUnit(id: propertyID, scope: scopeID, element: elementID)
                        } else {
                            result = self?.audioEngine.getOutputAudioUnit(id: propertyID, scope: scopeID, element: elementID)
                        }
                        self?.audioUnitDesc = result ?? ""
                        self?.tableView.reloadData()
                    }
                }))
                alertController.addAction(UIAlertAction(title: "Set", style: .default, handler: { [weak alertController] _ in
                    if let text1 = alertController?.textFields?[0].text,
                       let propertyID = AudioUnitPropertyID(text1),
                       let text2 = alertController?.textFields?[1].text,
                       let scopeID = AudioUnitScope(text2),
                       let text3 = alertController?.textFields?[2].text,
                       let elementID = AudioUnitScope(text3),
                       let text4 = alertController?.textFields?[3].text,
                       var data = UInt32(text4) {
                        let isInput = (alertController?.textFields?[4].text == "0")
                        if isInput {
                            self?.audioEngine.setInputAudioUnit(id: propertyID, scope: scopeID, element: elementID, data: &data, size: UInt32(MemoryLayout<UInt32>.size))

                        } else {
                            self?.audioEngine.setOutputAudioUnit(id: propertyID, scope: scopeID, element: elementID, data: &data, size: UInt32(MemoryLayout<UInt32>.size))
                        }
                    }
                }))
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self?.present(alertController, animated: true, completion: nil)
            }),
        ])
    }
}

extension AudioSessionDebugViewController {
    static func getPropertyList(_ cls: AnyClass?) -> [String] {
        var count: UInt32 = 0
        guard let list = class_copyPropertyList(cls, &count) else {
            return []
        }
        var result: [String] = []
        for i in 0..<Int(count) {
            let p = list[i]
            let cname = property_getName(p)
            guard let name = String(utf8String: cname) else {
                continue
            }
            result.append(name)
        }
        free(list)
        return result
    }
}

fileprivate extension AVAudioInputNode {
    open override var description: String {
        if #available(iOS 13.0, *) {
            return """
            \(super.description)
            vpio: \(isVoiceProcessingEnabled)
            bypassed: \(isVoiceProcessingBypassed)
            agc: \(isVoiceProcessingAGCEnabled)
            inputMuted: \(isVoiceProcessingInputMuted)
            """
        } else {
            return super.description
        }
    }
}

fileprivate extension AVAudioIONode {
    open override var description: String {
        if #available(iOS 13.0, *) {
            return """
            \(super.description)
            vpio: \(isVoiceProcessingEnabled)
            presentationLatency: \(presentationLatency)
            """
        } else {
            return super.description
        }
    }
}

fileprivate extension AVAudioNode {
    open override var description: String {
        """
        \(super.description)
        inputName0: \(String(describing: name(forInputBus: 0)))
        inputFormat0: \(inputFormat(forBus: 0))
        outputName0: \(String(describing: name(forOutputBus: 0)))
        outputFormat0: \(outputFormat(forBus: 0))
        numberOfInputs: \(numberOfInputs)
        numberOfOutputs: \(numberOfOutputs)
        lastRenderTime: \(String(describing: lastRenderTime))
        latency: \(latency)
        outputPresentationLatency: \(outputPresentationLatency)
        """
    }
}

fileprivate extension AVAudioMixerNode {
    open override var description: String {
        """
        \(super.description)
        outputVolume: \(outputVolume)
        nextAvailableInputBus: \(nextAvailableInputBus)
        """
    }
}
