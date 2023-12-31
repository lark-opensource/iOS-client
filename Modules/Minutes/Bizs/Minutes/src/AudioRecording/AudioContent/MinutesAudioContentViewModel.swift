//
//  MinutesAudioContentViewModel.swift
//  Minutes
//
//  Created by yangyao on 2021/3/11.
//

import UIKit
import MinutesFoundation
import MinutesNetwork

class MinutesAudioContentViewModel {
    var data: [MinutesParagraphViewModel] = []
    var allWordsTimes: [[String]] = []

    public var minutes: Minutes

    public var isPullRefreshing = false

    public var endPullRefreshCallBack: (() -> Void)?
    var isInTranslationMode: Bool = false
    var lastSentenceFinal: Bool = false

    var trackSid: Double = 0.0

    init(minutes: Minutes) {
        self.minutes = minutes
    }

    deinit {
        minutes.data.paragraphUpdateBlock = nil
        minutes.translateData?.paragraphUpdateBlock = nil
    }

    lazy var tracker: MinutesTracker = {
        return MinutesTracker(minutes: minutes)
    }()

    var paragraphs: [Paragraph]?

    var onDataUpdated: (() -> Void)?

    var containerWidth: CGFloat = 0

    
    var isInCCMfg: Bool {
        minutes.info.basicInfo?.isInCCMfg == true
    }
    
    func calculate(containerWidth: CGFloat, paragraphs: [Paragraph]?, lastSentenceFinal: Bool, commentsInfo: [String: ParagraphCommentsInfo]?, highlightedCommentId: String?, isInTranslationMode: Bool, complete: ([MinutesParagraphViewModel]) -> Void) {
        guard let paragraphs = paragraphs else { return }

        var data: [MinutesParagraphViewModel] = []

        for (pIndex, p) in paragraphs.enumerated() {

            let vm = MinutesParagraphViewModel(containerWidth: containerWidth,
                                               paragraph: p,
                                               pIndex: pIndex,
                                               pidAndSentenceDict: [:],
                                               highlightedCommentId: highlightedCommentId,
                                               isRecording: true,
                                               isLastParagraph: pIndex == paragraphs.count - 1,
                                               lastSentenceFinal: lastSentenceFinal, ccmComments: [],
                                               isInCCMfg: isInCCMfg)
            vm.commentsInfo = commentsInfo?[p.id]
            vm.isInTranslationMode = isInTranslationMode
            data.append(vm)
        }
        complete(data)
    }
    
    func setParagraphUpdater() {
        if isInTranslationMode {
            minutes.translateData?.paragraphUpdateBlock = { [weak self] pid, sentence in
                self?.updateParagraphs(pid, sentence)
            }
        } else {
            minutes.data.paragraphUpdateBlock = { [weak self] pid, sentence in
                self?.updateParagraphs(pid, sentence)
            }
        }
    }

    func updateParagraphs(_ pid: String, _ sentence:  Sentence, onDataUpdated: (() -> Void)? = nil) {
        if let sid = Double(sentence.id), trackSid < sid {
            trackSid = sid
            let recordingTime = Double(MinutesAudioRecorder.shared.recordingTime)
            if let startTime = Double(sentence.startTime) {
                let latency = ceil(recordingTime * 1000) - startTime
                if latency >= 0 {
                    self.tracker.tracker(name: .minutesDev, params: ["action_name": "audio_record_asr_latency", "latency": latency, "pid": pid, "sid": sentence.id, "minutes_token": minutes.objectToken, "minutes_type": "audio_record", "audio_codec_type": MinutesAudioRecorder.shared.codecType])
                }
            }
        }

        var data = minutes.data
        if isInTranslationMode {
            data = minutes.translateData ?? minutes.data
        }

        self.paragraphs = data.subtitles

        if let pIndex = data.subtitles.firstIndex(where: { $0.id == pid }) {
            let p = data.subtitles[pIndex]
            let vm = MinutesParagraphViewModel(containerWidth: containerWidth,
                                               paragraph: p,
                                               pIndex: pIndex,
                                               pidAndSentenceDict: [:],
                                               highlightedCommentId: nil,
                                               isRecording: true,
                                               isLastParagraph: false,
                                               lastSentenceFinal: true, ccmComments: [],
                                               isInCCMfg: isInCCMfg)
            DispatchQueue.main.async {
                if let index = self.data.firstIndex(where: { $0.paragraph.id == pid }) {
                    self.data[index] = vm
                } else {
                    self.data.append(vm)
                }

                self.data.last?.lastSentenceFinal = data.lastSentenceFinal
                self.data.last?.isLastParagraph = true
                self.onDataUpdated?()
            }
            
            MinutesLogger.record.assertWarn(data.subtitles.count == self.data.count, "update paragraph error: count is not equal.")
        } else {
            MinutesLogger.record.warn("update paragraph failed: can't find subtitle data")
        }

    }

}

extension MinutesAudioContentViewModel {
    func updateFullTextRange(_ index: NSInteger) {
        for (idx, pVM) in data.enumerated() {
            pVM.fullTextRanges = idx == index ? NSRange(location: 0, length: pVM.paragraphContent.count) : nil
        }
    }

    func search(with info: (NSInteger, NSRange)) {
        let index = info.0
        let range = info.1
        for (idx, vm) in data.enumerated() {
            if idx == index {
                vm.specifiedRange = range
            } else {
                vm.specifiedRange = nil
            }
        }
    }
}
