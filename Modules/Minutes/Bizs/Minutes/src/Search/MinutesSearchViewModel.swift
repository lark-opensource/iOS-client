//
//  MinutesSearchViewModel.swift
//  Minutes
//
//  Created by yangyao on 2021/1/18.
//

import Foundation
import MinutesFoundation
import MinutesNetwork

class MinutesSearchViewModel {
    let result: FindResult
    // pid和sentence的映射
    var pidAndSentenceDict: [String: [Sentence]] = [:]
    // sentence和sentence length的映射，pid sid确定唯一的sentence
    var sentenceContentLenDict: [[String]: NSInteger] = [:]
    // pid和行的映射
    var pidAndIdxDict: [String: NSInteger] = [:]
    // key 是行，value是该行对应所有的ranges数组
    var searchResultDict: [NSInteger: [NSRange]] = [:]
    // 结果数组，拆分到每个词汇 (行，range)
    var searchResults: [(NSInteger, NSRange)] = []
    var timelines: [Timeline] = []

    init(result: FindResult,
         pidAndSentenceDict: [String: [Sentence]],
         sentenceContentLenDict: [[String]: NSInteger],
         pidAndIdxDict: [String: NSInteger]) {
        self.result = result
        self.pidAndSentenceDict = pidAndSentenceDict
        self.sentenceContentLenDict = sentenceContentLenDict
        self.pidAndIdxDict = pidAndIdxDict
        calculateRanges()
    }

    func calculateRanges() {
        var results: [String: [NSRange]] = [:]

        // 根据pid获取paragraph，根据sid获取sentence
        // [pid, sid]唯一确定一个sentence
        for (pid, value) in result.content.subtitles {
            // pid获取sentence数组
            guard let sentencesInParagraph = pidAndSentenceDict[pid] else {
                return
            }
            var ranges: [NSRange] = []
            for sentence in value.sentences {
                let sid = sentence.id
                var beforeLength = 0
                // 找出在当前sentence顺序之前的sentence
                let before = sentencesInParagraph.filter { $0.id < sid }.map { [pid, $0.id] }
                // 算出总长度
                beforeLength += before.reduce(0) { (last, element) -> NSInteger in
                    return last + (sentenceContentLenDict[element] ?? 0)
                }
                // 加上当前sentence的range
                for highlighted in sentence.highlight {
                    ranges.append(NSRange(location: beforeLength + highlighted.offset, length: highlighted.size))
                }
                results[pid] = ranges
            }
        }
        // 一共多少个，每个对应的index
        var array: [(NSInteger, NSRange)] = []
        // pid和index对应数组
        for (pid, ranges) in results {
            if let index = pidAndIdxDict[pid] {
                searchResultDict[index] = ranges
                for range in ranges {
                    array.append((index, range))
                }
            }
        }
        searchResults = array.sorted(by: { $0.0 < $1.0 })

        for t in result.timeline {
            timelines.append(t)
        }
        assert(searchResults.count == timelines.count)
    }
}
