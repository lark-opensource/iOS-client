//
//  MinutesSubtitleData.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/3/3.
//

import Foundation
import LKCommonsLogging

public final class MinutesSubtitleData {

    static let logger = Logger.log(MinutesSubtitleData.self, category: "Minutes")

    let api: MinutesAPI

    let objectToken: String

    let language: Language

    var isSubtitleEmpty: Bool = true

    public var subtitleItems: [OverlaySubtitleItem] = []
    var subtitlesFirst: [Int: String] = [:]
    var subtitlesSecond: [Int: String] = [:]
    var firstTimelines: [Int] = []
    var secondTimelines: [Int] = []

    public init(api: MinutesAPI, objectToken: String, language: Language = .default) {
        self.api = api
        self.objectToken = objectToken
        self.language = language
        loadSubtitles()
    }

    func insertSentence(from: String, to: String, content: String) {
        guard let fromTime = Int(from), let toTime = Int(to) else { return }

        DispatchQueue.main.async {
            let firstTime = self.findLastTime(fromTime, true)
            let secondTime = self.findLastTime(fromTime, false)
            let firstLine = self.subtitlesFirst[firstTime]
            let secondLine = self.subtitlesSecond[secondTime]

            if firstLine?.isEmpty != false {
                self.subtitlesFirst[fromTime] = content
                self.subtitlesFirst[toTime] = ""
                self.firstTimelines.append(contentsOf: [fromTime, toTime])
            } else if secondLine?.isEmpty != false {
                self.subtitlesSecond[fromTime] = content
                self.subtitlesSecond[toTime] = ""
                self.secondTimelines.append(contentsOf: [fromTime, toTime])
            } else {
                self.subtitlesFirst[fromTime] = content
                self.subtitlesFirst[toTime] = ""
                self.firstTimelines.append(contentsOf: [fromTime, toTime])
            }

            self.isSubtitleEmpty = false
        }
    }

    func findLastTime(_ time: Int, _ isFirstLine: Bool) -> Int {
        let timelines = isFirstLine ? firstTimelines : secondTimelines
        let lastTime = timelines.last { $0 <= time }
        return lastTime ?? 0
    }

    func loadSubtitles() {
        subtitleItems.removeAll()
        loadOverlaySubtitle { result in
            switch result {
            case .success(let value):
                self.subtitleItems = value
                Self.logger.info("load mobile sub success.")
                for item in value {
                    self.insertSentence(from: "\(item.startTime)", to: "\(item.stopTime)", content: item.content)
                }
            case .failure(let error):
                Self.logger.warn("load mobile sub failed, try load web vtt...")
                self.loadWebVTT()
            }
        }
    }

    func loadWebVTT() {
        loadWebVTT { result in
            switch result {
            case .success(let value):
                Self.logger.info("load WebVtt success.")
                self.setupSubtitles(from: value)
            case .failure(let error):
                Self.logger.warn("load webvtt failed, \(error) reloading latter.")
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) { [weak self] in
                    self?.loadSubtitles()
                }
            }
        }
    }

    func setupSubtitles(from: String) {
        let lines = from.split(whereSeparator: \.isNewline)
        var index = 0
        while index < lines.count {
            let line = lines[index]
            index += 1
            if let (startTime, endTime) = line.covertTime() {
                let value = lines[index]
                index += 1
                insertSentence(from: "\(startTime.millisecond)", to: "\(endTime.millisecond)", content: String(value))
            }
        }
    }

    /// subtitles's first line data
    ///
    ///  *should call in main thread*
    ///
    /// - Parameter time: current play back time
    /// - Returns: nil for no data.
    public func fistline(_ time: Int) -> String? {
        guard !isSubtitleEmpty else {
            return nil
        }
        let firstTime = findLastTime(time, true)
        return subtitlesFirst[firstTime]
    }

    /// subtitles's second line data
    ///
    ///   * should call in main thread
    ///
    /// - Parameter time: current play back time
    /// - Returns: nil for no data.
    public func secondLine(_ time: Int) -> String? {
        guard !isSubtitleEmpty else {
            return nil
        }
        let secondTime = findLastTime(time, false)
        return subtitlesSecond[secondTime]
    }

    public var isEmpty: Bool {
        return isSubtitleEmpty
    }

    public func loadWebVTT(completionHandler: @escaping (Result<String, Error>) -> Void) {
        let request = FetchWebVTTReqeust(objectToken: objectToken, translateLang: language.code)
        api.sendRequest(request, completionHandler: completionHandler)
    }

    public func loadOverlaySubtitle(completionHandler: @escaping (Result<[OverlaySubtitleItem], Error>) -> Void) {
        let request = FetchMobileOverlaySubtilteRequst(objectToken: objectToken, language: language.code)

        api.sendRequest(request) { result in
            completionHandler(result.map { $0.data.subtitles ?? [] })
        }
    }
}
