//
//  ActiveSpeakerGridSorter.swift
//  ByteView
//
//  Created by chenyizhuo on 2023/1/31.
//

import Foundation
import ByteViewSetting
import ByteViewNetwork

class ActiveSpeakerGridSorter: GridSorter {
    // 上一次参与排序的参会人，用于当前轮次排序前标记当前轮次每个参会人的动作
    @RwAtomic
    private var lastParticipants: [Participant] = []

    private lazy var tileSorter = ActiveSpeakerGridTileSorter(myself: myself)
    private lazy var rectSorter = ActiveSpeakerGridRectSorter(myself: myself)

    private let myself: ByteviewUser

    init(myself: ByteviewUser) {
        self.myself = myself
    }

    // MARK: - Public

    func sort(participants: [Participant], with context: InMeetGridSortContext) -> SortResult {
        // 1. 检查无需重排或快速排序的路径
        if let shortPathResult = handleShortPath(context: context) {
            return shortPathResult
        }

        // === 排序 pipeline begin ===

        // 2. 过滤符合条件的参会人，处理部分参会人临时上屏逻辑
        let participantMap = filterParticipants(participants, context: context)
        let filtered = participantMap.values.map { $0.participant }
        // 3. 标记每个待排序参会人的行为，这些行为会影响排序时参会人上下首屏行为
        let actionInfos = markActionInfos(newParticipants: filtered)
        // 4. 计算每个参会人的 AS 分数
        let scoreSortResult = scoreSort(newParticipants: filtered, actionInfos: actionInfos, context: context)
        // 5. 对参会人排序
        let gridSortResult = gridSort(newScoreSortResult: scoreSortResult, context: context)
        let sortedParticipants = gridSortResult.compactMap { (item: ByteviewUser) -> GridSortOutputEntry? in
            guard let p = participantMap[item] else { return nil }
            return GridSortOutputEntry(type: .participant(p.participant), strategy: p.strategy)
        }
        // 6. 结合共享宫格和兜底逻辑处理
        let finalResult = handleShareAndAS(sortedParticipants, context: context)

        // === 排序 pipeline end ===

        // 7. 排序完成后的状态更新
        lastParticipants = filtered

        return .sorted(finalResult)
    }

    // MARK: - Private

    private var observedChanges: Set<GridSortTrigger> {
        [.participants, .activeSpeaker, .focus,
            .hideSelf, .hideNonVideo, .voiceMode,
            .displayInfo, .shareGridEnabled,
            .shareSceneType, .selfIsHost, .selfSharing]
    }

    private func handleShortPath(context: InMeetGridSortContext) -> SortResult? {
        // 强制刷新时，走完整的排序 pipeline
        if context.isDirty {
            return nil
        }

        // 检查排序是否可以被跳过
        if canSortBeSkipped(context: context) {
            return .unchanged
        }

        // 对于共享宫格显示与否、displayMode 的变更是同步操作，直接基于上次的排序结果对共享和兜底宫格操作，无需走排序全路径
        if !context.changedTypes.isDisjoint(with: [.shareGridEnabled, .displayInfo]) {
            let lastSortResult = context.currentSortResult.filter {
                if case .participant = $0.type {
                    return true
                } else {
                    return false
                }
            }
            let quickSortResult = handleShareAndAS(lastSortResult, context: context)
            return .sorted(quickSortResult)
        }

        return nil
    }

    private func canSortBeSkipped(context: InMeetGridSortContext) -> Bool {
        let changedTypes = context.changedTypes
        if changedTypes.isDisjoint(with: observedChanges) {
            return true
        }

        // 如果是自身主持人身份、共享变更，则只有存在焦点视频时需要重排
        if !changedTypes.isDisjoint(with: [.selfSharing, .selfIsHost]) && changedTypes.subtracting([.selfIsHost, .selfSharing]).isEmpty {
            return context.focusingParticipantID == nil
        }

        return false
    }

    /// 预处理会中参会人，过滤出实际需要参与排序的参会人，以及这些参会人排序结果的展示策略
    private func filterParticipants(_ participants: [Participant], context: InMeetGridSortContext) -> [ByteviewUser: GridSortParticipant] {
        // 焦点视频最高优
        let focusID = context.focusingParticipantID
        if let id = focusID,
            let participant = participants.first(where: { $0.user == id }),
           // 本人是主持人或主共享时，展示所有宫格，但是将 focus 宫格前置
            !context.selfIsHost && !context.selfSharing {
            return [id: GridSortParticipant(participant: participant, strategy: .normal)]
        }

        let participantMap = Dictionary(participants.map { ($0.user, $0) }) { $1 }
        var result: [ByteviewUser: GridSortParticipant] = [:]
        var newParticipants = participants

        if context.isHideSelf {
            newParticipants.removeAll(where: { $0.user == myself })
        }

        if context.isHideNonVideo {
            let period = TimeInterval(context.nonVideoConfig.period / 1000)
            let now = Date().timeIntervalSinceReferenceDate

            for info in context.asInfos {
                if let participant = participantMap[info.pid],
                  participant.settings.isCameraMutedOrUnavailable,
                  let lastestSpeakingTime = info.speakingTimes.last,
                  lastestSpeakingTime.isSpeaking(in: period, now: now) {
                  let dismissTime = (lastestSpeakingTime.end ?? now) + period
                    result[info.pid] = GridSortParticipant(participant: participant, strategy: .temporary(dismissTime))
                }
            }

            if context.isVoiceMode {
                var isSelfCameraMuted = true
                if let me = participants.first(withUser: myself), !me.settings.isCameraMutedOrUnavailable {
                    isSelfCameraMuted = false
                }
                if (isSelfCameraMuted || context.isHideSelf) && focusID == nil {
                    // 语音模式下，如果自己关闭摄像头，或者隐藏自己开启（此时即使自己开摄像头也需要被过滤），且会中不存在焦点视频，则兜底展示一个 AS 视图
                    newParticipants.removeAll()
                } else {
                    // 如果自己开启摄像头，语音模式下其他参会人均视为关闭摄像头，保留 X 秒内说过话的参会人；如果会中有焦点视频，焦点视频同样保留
                    newParticipants.removeAll(where: {
                        if $0.user == myself {
                            return isSelfCameraMuted && myself != focusID && result[myself] == nil
                        } else {
                            return $0.user != focusID && result[$0.user] == nil
                        }
                    })
                }
            } else if newParticipants.first(where: { !$0.settings.isCameraMutedOrUnavailable || $0.user == focusID }) == nil {
                // 如果所有人都关闭摄像头，且会中没有焦点视频，则兜底展示一个 AS 视图
                newParticipants.removeAll()
            } else {
                // 如果有人开摄像头，则保留 X 秒内说过话的参会人；如果会中有焦点视频，焦点视频同样保留
                newParticipants.removeAll(where: { $0.settings.isCameraMutedOrUnavailable && $0.user != focusID && result[$0.user] == nil })
            }
        }

        if newParticipants.isEmpty {
            // 所有插入都被过滤掉的情况下，不启用临时上屏逻辑，兜底显示一个 AS
            result.removeAll()
        }
        for participant in newParticipants where result[participant.user] == nil {
            result[participant.user] = GridSortParticipant(participant: participant, strategy: .normal)
        }

        return result
    }

    // 参会人变化驱动宫格流刷新，构造排序数组并标记新入会参会人、刚开摄像头参会人
    private func markActionInfos(newParticipants: [Participant]) -> [ByteviewUser: CandidateAction] {
        let lastCameraMap = Dictionary(lastParticipants.map { ($0.user, $0.isCameraOn) }) { $1 }
        let actionPairs = newParticipants.map {
            let action: CandidateAction
            if let lastCameraOn = lastCameraMap[$0.user] {
                // 如果该用户之前也在会中
                let currentCameraOn = $0.isCameraOn
                if currentCameraOn != lastCameraOn {
                    // 跟上次排序相比，摄像头状态发生变化
                    action = currentCameraOn ? .unmuteCamera : .muteCamera
                } else {
                    action = .none
                }
            } else {
                // 用户上次排序时不在会中，所以是新用户入会
                action = .enter
            }
            return ($0.user, action)
        }
        return Dictionary(actionPairs) { $1 }
    }

    // 计算所有参会人得分，并降序排名
    private func scoreSort(newParticipants: [Participant],
                           actionInfos: [ByteviewUser: CandidateAction],
                           context: InMeetGridSortContext) -> [GridSortInputEntry] {
        // 计算 AS 得分
        let scoresMap = calActiveSpeakerScores(newParticipants: newParticipants, asQueue: context.asInfos, videoSortConfig: context.videoSortConfig)
        // 根据 AS 得分对参会人进行排序
        return newParticipants.sorted { lhs, rhs -> Bool in
            let lhsScore = scoresMap[lhs.user] ?? 0
            let rhsScore = scoresMap[rhs.user] ?? 0
            if lhsScore != rhsScore {
                // 得分不同，则根据得分排序
                return lhsScore > rhsScore
            } else {
                // 得分相同，则按状态排序
                if lhs.status != rhs.status {
                    return lhs.status == .onTheCall
                } else if lhs.joinTime != rhs.joinTime {
                    return lhs.joinTime < rhs.joinTime
                } else {
                    return lhs.user.hashValue < rhs.user.hashValue
                }
            }
        }
        .enumerated()
        .map({ index, participant in
            GridSortInputEntry(participant: participant,
                               myself: myself,
                               asID: context.currentActiveSpeaker,
                               focusedID: context.focusingParticipantID,
                               rank: index,
                               action: actionInfos[participant.user] ?? .none)
        })
    }

    // https://bytedance.feishu.cn/docs/doccnck3X48148XzpKfEUTTTfNe "排序得分"
    private func calActiveSpeakerScores(newParticipants: [Participant],
                                        asQueue: [ActiveSpeakerInfo],
                                        videoSortConfig: VideoSortConfig) -> [ByteviewUser: Float] {
        let maxIndex = Int(videoSortConfig.maxIndex)
        let timeScope = Int(videoSortConfig.timeScope)
        let cameraFactor = videoSortConfig.factorCamera

        // 最终排序得分 = AS 时长得分 + 历史 AS 得分 + 摄像头得分
        var scores: [ByteviewUser: Float] = [:]
        // AS 得分 = AS 时长得分 + 历史 AS 得分
        for (index, info) in asQueue.enumerated() {
            let seconds = info.speakingSeconds(in: timeScope)
            // AS 时长得分
            var score: Float = Float(seconds) * videoSortConfig.factorAS
            // 历史 AS 得分
            if index < maxIndex {
                score += Float((maxIndex - index)) * videoSortConfig.factorIndex
            }
            scores[info.pid] = score
        }
        // 摄像头得分
        for participant in newParticipants.filter({ $0.isCameraOn }) {
            scores[participant.user] = (scores[participant.user] ?? 0) + cameraFactor
        }
        return scores
    }

    private func shouldUseTileSort(_ context: InMeetGridSortContext) -> Bool {
        context.isNewLayoutEnabled && context.displayInfo.displayMode == .gridVideo && !context.isWebinar
    }

    // 根据新一轮的 AS 得分排名、当前轮次的宫格排序结果，计算新一轮的宫格排序结果
    private func gridSort(newScoreSortResult: [GridSortInputEntry],
                          context: InMeetGridSortContext) -> [ByteviewUser] {
        if shouldUseTileSort(context) {
            return tileSorter.sort(scoreInfos: newScoreSortResult, context: context)
        } else {
            return rectSorter.sort(scoreInfos: newScoreSortResult, context: context)
        }
    }

    private func handleShareAndAS(_ sortResult: [GridSortOutputEntry], context: InMeetGridSortContext) -> [GridSortOutputEntry] {
        var result = sortResult
        let isEmpty = sortResult.isEmpty
        // 隐藏非视频开启时，参会人全部被隐藏时兜底显示 AS 宫格
        if isEmpty && context.isHideNonVideo {
            result.append(.activeSpeaker)
        }
        if context.shareGridEnabled, case .range(_, _, let pageSize) = context.displayInfo.visibleRange {
            if context.isPhone {
                result.insert(.share, at: 0)
            } else {
                let range = (pageSize - 1)...pageSize
                let beforeInsert = result.firstIndex {
                    if case .participant(let p) = $0.type {
                        return p.user == context.currentActiveSpeaker
                    } else {
                        return false
                    }
                }
                // 兜底情况下共享宫格放在 AS 宫格前面，否则一律显示在所有宫格的第二位
                result.insert(.share, at: isEmpty ? 0 : 1)
                // 此时 AS 可能被挤出首屏，如果发生这种情况，将 AS 与前一位参会人替换，保证插入共享宫格后，AS 位置不变
                if beforeInsert == pageSize - 1 {
                    result.replaceSubrange(range, with: result[range].reversed())
                }
            }
        }
        if result.isEmpty && context.displayInfo.displayMode == .gridVideo {
            // 如果排序的最终输出结果是空，宫格视图兜底展示 AS，防止宫格流展示空数据
            result.append(.activeSpeaker)
        }
        return result
    }
}

private extension Participant {
    var isCameraOn: Bool {
        status == .onTheCall && !settings.isCameraMutedOrUnavailable
    }
}
