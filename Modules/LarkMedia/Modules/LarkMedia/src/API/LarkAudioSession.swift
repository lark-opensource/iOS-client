//
//  LarkAudioSession.swift
//  LarkMedia
//
//  Created by FakeGourmet on 2023/7/24.
//

import Foundation
import AVFAudio
import LKCommonsLogging

public class LarkAudioSession: NSObject {

    public static let shared = LarkAudioSession()

    static let logger = Logger.log(LarkAudioSession.self, category: "LarkMedia.LarkAudioSession")
    var logger: Log { Self.logger }

    var avAudioSession: AVAudioSession { AVAudioSession.sharedInstance() }

    @RwAtomic
    var _currentRoute: AVAudioSessionRouteDescription?
    @RwAtomic
    var _category: AVAudioSession.Category?
    @RwAtomic
    var _categoryOptions: AVAudioSession.CategoryOptions?
    @RwAtomic
    var _mode: AVAudioSession.Mode?
    @RwAtomic
    var _routeSharingPolicy: AVAudioSession.RouteSharingPolicy?

    private override init() {
        super.init()
    }
}

public extension LarkAudioSession {
    @objc
    var currentRoute: AVAudioSessionRouteDescription { _currentRoute ?? avAudioSession.currentRoute }

    @objc
    var category: AVAudioSession.Category { _category ?? avAudioSession.category }

    @objc
    var mode: AVAudioSession.Mode { _mode ?? avAudioSession.mode }

    @objc
    var categoryOptions: AVAudioSession.CategoryOptions { _categoryOptions ?? avAudioSession.categoryOptions }

    @objc
    var routeSharingPolicy: AVAudioSession.RouteSharingPolicy { _routeSharingPolicy ?? avAudioSession.routeSharingPolicy }
}

public extension LarkAudioSession {

    func setCategory(_ category: AVAudioSession.Category,
                     file: String = #fileID, function: String = #function, line: Int = #line) throws {
        logger.debug("setCategory: \(category)", file: file, function: function, line: line)
        try avAudioSession.setCategory(category)
    }

    func setCategory(_ category: AVAudioSession.Category, options: AVAudioSession.CategoryOptions = [],
                     file: String = #fileID, function: String = #function, line: Int = #line) throws {
        logger.debug("setCategory: \(category) options: \(options)", file: file, function: function, line: line)
        try avAudioSession.setCategory(category, options: options)
    }

    func setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions = [],
                     file: String = #fileID, function: String = #function, line: Int = #line) throws {
        logger.debug("setCategory: \(category) mode: \(mode) options: \(options)", file: file, function: function, line: line)
        try avAudioSession.setCategory(category, mode: mode, options: options)
    }

    func setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, policy: AVAudioSession.RouteSharingPolicy, options: AVAudioSession.CategoryOptions = [],
                     file: String = #fileID, function: String = #function, line: Int = #line) throws {
        logger.debug("setCategory: \(category) mode: \(mode) policy: \(policy) options: \(options)", file: file, function: function, line: line)
        try avAudioSession.setCategory(category, mode: mode, policy: policy, options: options)
    }

    func setMode(_ mode: AVAudioSession.Mode,
                 file: String = #fileID, function: String = #function, line: Int = #line) throws {
        logger.debug("setMode: \(mode)", file: file, function: function, line: line)
        try avAudioSession.setMode(mode)
    }

    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions = [],
                   file: String = #fileID, function: String = #function, line: Int = #line) throws {
        logger.debug("setActive: \(active) options: \(options)", file: file, function: function, line: line)
        try avAudioSession.setActive(active, options: options)
    }

    func overrideOutputAudioPort(_ portOverride: AVAudioSession.PortOverride,
                                 file: String = #fileID, function: String = #function, line: Int = #line) throws {
        logger.debug("overrideOutputAudioPort: \(portOverride)", file: file, function: function, line: line)
        try avAudioSession.overrideOutputAudioPort(portOverride)
    }

    @available(iOS 13.0, *)
    func setAllowHapticsAndSystemSoundsDuringRecording(_ inValue: Bool,
                                                       file: String = #fileID, function: String = #function, line: Int = #line) throws {
        logger.debug("setAllowHapticsAndSystemSoundsDuringRecording: \(inValue)", file: file, function: function, line: line)
        try avAudioSession.setAllowHapticsAndSystemSoundsDuringRecording(inValue)
    }

    func setPreferredInput(_ inPort: AVAudioSessionPortDescription?,
                           file: String = #fileID, function: String = #function, line: Int = #line) throws {
        logger.debug("setPreferredInput: \(String(describing: inPort))", file: file, function: function, line: line)
        try avAudioSession.setPreferredInput(inPort)
    }

    func setInputGain(_ gain: Float,
                      file: String = #fileID, function: String = #function, line: Int = #line) throws {
        logger.debug("setInputGain: \(gain)", file: file, function: function, line: line)
        try avAudioSession.setInputGain(gain)
    }

    func setInputDataSource(_ dataSource: AVAudioSessionDataSourceDescription?,
                            file: String = #fileID, function: String = #function, line: Int = #line) throws {
        logger.debug("setInputDataSource: \(String(describing: dataSource))", file: file, function: function, line: line)
        try avAudioSession.setInputDataSource(dataSource)
    }

    func setOutputDataSource(_ dataSource: AVAudioSessionDataSourceDescription?,
                             file: String = #fileID, function: String = #function, line: Int = #line) throws {
        Self.logger.debug("setOutputDataSource: \(String(describing: dataSource))", file: file, function: function, line: line)
        try avAudioSession.setOutputDataSource(dataSource)
    }

    func setPreferredSampleRate(_ sampleRate: Double,
                                file: String = #fileID, function: String = #function, line: Int = #line) throws {
        logger.debug("setPreferredSampleRate: \(sampleRate)", file: file, function: function, line: line)
        try avAudioSession.setPreferredSampleRate(sampleRate)
    }

    func setAggregatedIOPreference(_ inIOType: AVAudioSession.IOType,
                                   file: String = #fileID, function: String = #function, line: Int = #line) throws {
        logger.debug("setAggregatedIOPreference: \(inIOType)", file: file, function: function, line: line)
        try avAudioSession.setAggregatedIOPreference(inIOType)
    }

    @available(iOS 15.0, *)
    func setSupportsMultichannelContent(_ inValue: Bool,
                                        file: String = #fileID, function: String = #function, line: Int = #line) throws {
        logger.debug("setSupportsMultichannelContent: \(inValue)", file: file, function: function, line: line)
        try avAudioSession.setSupportsMultichannelContent(inValue)
    }

    func setPreferredInputNumberOfChannels(_ count: Int,
                                           file: String = #fileID, function: String = #function, line: Int = #line) throws {
        logger.debug("setPreferredInputNumberOfChannels: \(count)", file: file, function: function, line: line)
        try avAudioSession.setPreferredInputNumberOfChannels(count)
    }

    func setPreferredOutputNumberOfChannels(_ count: Int,
                                            file: String = #fileID, function: String = #function, line: Int = #line) throws {
        logger.debug("setPreferredOutputNumberOfChannels: \(count)", file: file, function: function, line: line)
        try avAudioSession.setPreferredOutputNumberOfChannels(count)
    }
}

public extension LarkAudioSession {
    func requestRecordPermission(_ response: @escaping (Bool) -> Void,
                                 file: String = #fileID, function: String = #function, line: Int = #line) {
        logger.debug("requestRecordPermission", file: file, function: function, line: line)
#if swift(>=5.9)
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission(completionHandler: response)
            return
        }
#endif
        avAudioSession.requestRecordPermission(response)
    }
}
