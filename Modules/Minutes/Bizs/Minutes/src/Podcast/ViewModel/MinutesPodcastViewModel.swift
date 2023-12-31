//
//  MinutesPodcastViewModel.swift
//  Minutes
//
//  Created by yangyao on 2021/4/1.
//

import UIKit
import SnapKit
import MinutesFoundation
import MinutesNetwork

class MinutesPodcastViewModel {
    var data: [MinutesPodcastLyricViewModel] = []

    public var minutes: Minutes

    var firstVMStartTime: Int? {
        return data.first?.subtitleItem.startTime
    }

    init(minutes: Minutes) {
        self.minutes = minutes
    }

    private var tasks: [Int: Bool] = [:]

    var subtitleItems: [OverlaySubtitleItem]?

    public var isSupportASR: Bool {
        return minutes.basicInfo?.supportAsr == true
    }

    func configure(containerWidth: CGFloat, subtitleItems: [OverlaySubtitleItem]?) {
        guard let subtitleItems = subtitleItems else { return }

        self.subtitleItems = subtitleItems

        var data: [MinutesPodcastLyricViewModel] = []
        for (pIndex, item) in subtitleItems.enumerated() {
            let vm = MinutesPodcastLyricViewModel(containerWidth: containerWidth, subtitleItem: item, pIndex: pIndex)
            data.append(vm)
        }
        self.data = data
    }

    func getHeight(_ pVM: MinutesPodcastLyricViewModel, _ otherSectionHeight: CGFloat) -> CGFloat {
        var totalHeight: CGFloat = otherSectionHeight
        for (idx, vm) in data.enumerated() where idx < pVM.pIndex {
            totalHeight += vm.cellHeight
        }
        return totalHeight
    }

    func getCenterHeight(_ pVM: MinutesPodcastLyricViewModel, _ otherSectionHeight: CGFloat) -> CGFloat {
        var totalHeight: CGFloat = otherSectionHeight
        for (idx, vm) in data.enumerated() {
            if idx < pVM.pIndex {
                totalHeight += vm.cellHeight
            } else if idx == pVM.pIndex {
                totalHeight += vm.cellHeight / 2.0
                break
            }
        }
        return totalHeight
    }

    public func clearTasks() {
        tasks.removeAll()
    }

    public func checkIsCurrentLyric(_ time: NSInteger?, index: NSInteger? = nil) -> MinutesPodcastLyricViewModel? {
        guard let time = time else { return nil }

        tasks[time] = false
        var matchedVM: MinutesPodcastLyricViewModel?
        for (idx, vm) in data.enumerated() {
//            if tasks[time] != false { return matchedVM }
            let result = vm.checkIsCurrentLyric(time)
            if result == true {
                matchedVM = vm
            }
        }
        if matchedVM != nil {
            return matchedVM
        } else {
            // 找最近的那一个
            var fabsResult: CGFloat?
            for (idx, vm) in data.enumerated() {
//                if tasks[time] != false { return matchedVM }
                vm.setIsCurrentLyric(false)
                let tmp = fabs(CGFloat(vm.subtitleItem.startTime - time))
                if fabsResult == nil {
                    fabsResult = tmp
                    matchedVM = vm
                } else {
                    if let result = fabsResult, tmp < result {
                        fabsResult = tmp
                        matchedVM = vm
                    }
                }
            }
            matchedVM?.setIsCurrentLyric(true)
            return matchedVM
        }
    }

    public func findHighlightedLyric(_ offset: CGFloat, _ otherSectionHeight: CGFloat) -> MinutesPodcastLyricViewModel? {
        var hitVM: MinutesPodcastLyricViewModel?
        var hitIndex: Int?
        var totalHeight: CGFloat = otherSectionHeight
        for (idx, vm) in data.enumerated() {
            totalHeight += vm.cellHeight
            vm.isHitLyricHighlighted = false
            if totalHeight >= offset && hitIndex == nil {
                hitIndex = idx
                hitVM = vm
                vm.isHitLyricHighlighted = true
            }
        }
        return hitVM
    }

    public func resetHighlightedLyric() {
        for vm in data {
            vm.isHitLyricHighlighted = false
        }
    }
}
