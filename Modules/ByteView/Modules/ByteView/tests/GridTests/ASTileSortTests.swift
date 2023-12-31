//
//  ASTileSortTests.swift
//  ByteView-Unit-Tests
//
//  Created by YizhuoChen on 2023/5/5.
//

import XCTest
@testable import ByteView
@testable import ByteViewNetwork
@testable import ByteViewSetting

final class ASTileSortTests: XCTestCase {

    // 影响排序结果的变量: as, focus, displayInfo
    private var sut: ActiveSpeakerGridTileSorter!
    private var context: InMeetGridSortContext!

    override func setUpWithError() throws {
        sut = ActiveSpeakerGridTileSorter(myself: me.user)
        context = InMeetGridSortContext(videoSortConfig: .default,
                                        nonVideoConfig: .default,
                                        activeSpeakerConfig: .default,
                                        isSelfSharingContent: false,
                                        shareSceneType: .none,
                                        isHost: true,
                                        focusID: nil,
                                        isHideSelf: false,
                                        isHideNonVideo: false,
                                        isVoiceMode: false,
                                        isWebinar: false)
        context.displayInfo = GridDisplayInfo(visibleRange: .page(index: 0), displayMode: .gridVideo)
    }

    override func tearDownWithError() throws {
        sut = nil
        context = nil
    }

    func testBasicSort() {
        var allParticipants = (1..<10).map { person(String($0)) }
        var scoreInfos = sortInput(from: allParticipants, context: context)
        // case 1:
        // desc: 首次排序，无任何影响排序结果的变量（例如as、focus、参会人变动等）
        // expected: 将自己放到排序结果的首位，然后其余按照 rank 顺序依次填充
        var result = sut.sort(scoreInfos: scoreInfos, context: context)
        var expected = [me.user.id] + (1..<10).map { String($0) }
        XCTAssertEqual(result.map { $0.id }, expected)

        // case 2:
        // desc: 不在首页的某个人说话
        // expected: 将此人与首页评分最低的人替换，被替换的人重新回到待排序队列，按照 rank 排序
        context.currentActiveSpeaker = allParticipants.last?.user
        scoreInfos = sortInput(from: allParticipants, context: context)
        result = sut.sort(scoreInfos: scoreInfos, context: context)
        expected = [me.user.id, "1", "2", "3", "4", "9",
                    "5", "6", "7", "8"]
        XCTAssertEqual(result.map { $0.id }, expected)

        // case 3:
        // desc: 其他条件不变时，尽量保证首屏和当前屏不变，即使着两屏参会人分数排名已经比其他人低
        // expected: 同上
        allParticipants = [4, 5, 6, 7, 8, 9, 1, 2, 3].map { person(String($0)) }
        scoreInfos = sortInput(from: allParticipants, context: context)
        result = sut.sort(scoreInfos: scoreInfos, context: context)
        XCTAssertEqual(result.map { $0.id }, expected)

        // case 4:
        // desc: 入会或开启摄像头的成为上首屏候选人，关闭摄像头的成为下首屏候选
        // expected: 上首屏候选人如果分数超过首屏最低分，或下首屏候选人分数低于非首屏最高分，则进行首屏变更，被换下首屏的进入待排序队列
        scoreInfos = sortInput(from: allParticipants, context: context, unmuteIndexes: [1], enterIndexes: [2], muteIndexes: [6])
        result = sut.sort(scoreInfos: scoreInfos, context: context)
        expected = [me.user.id, "7", "6", "5", "4", "9",
                    "8", "1", "2", "3"]
        XCTAssertEqual(result.map { $0.id }, expected)
    }

    func testFocus() {
        let allParticipants = (1..<10).map { person(String($0)) }
        var scoreInfos = sortInput(from: allParticipants, context: context)
        // case 1:
        // desc: 首次排序，无任何影响排序结果的变量（例如as、focus、参会人变动等）
        // expected: 将自己放到排序结果的首位，然后其余按照 rank 顺序依次填充
        var result = sut.sort(scoreInfos: scoreInfos, context: context)
        var expected = [me.user.id] + (1..<10).map { String($0) }
        XCTAssertEqual(result.map { $0.id }, expected)

        // case 2:
        // desc: 不在首页的某个参会人成为被聚焦
        // expected: 被聚焦人放到首页第二位，被替换下来的人放到待排队列
        context.focusingParticipantID = allParticipants.last?.user
        scoreInfos = sortInput(from: allParticipants, context: context)
        result = sut.sort(scoreInfos: scoreInfos, context: context)
        expected = [me.user.id, "9", "2", "3", "4", "5",
                    "1", "6", "7", "8"]
        XCTAssertEqual(result.map { $0.id }, expected)

        // case 3:
        // desc: 在首页但不在第二位的参会人被聚焦
        // expected: 被聚焦人放到首页第二位，首页其他位置不变，第二位被替换的人加入待排队列，被聚焦人原来的位置由待排队列中排名最高的人替换
        context.focusingParticipantID = allParticipants[2].user
        scoreInfos = sortInput(from: allParticipants, context: context)
        result = sut.sort(scoreInfos: scoreInfos, context: context)
        expected = [me.user.id, "3", "2", "1", "4", "5",
                    "6", "7", "8", "9"]
        XCTAssertEqual(result.map { $0.id }, expected)

        // case 4:
        // desc: 自己被聚焦
        // expected: 自己依然放到首页第一位，保持不变
        context.focusingParticipantID = me.user
        scoreInfos = sortInput(from: allParticipants, context: context)
        result = sut.sort(scoreInfos: scoreInfos, context: context)
        XCTAssertEqual(result.map { $0.id }, expected)
    }

    func testVisibleRange() {
        let allParticipants = (1..<20).map { person(String($0)) }
        var scoreInfos = sortInput(from: allParticipants, context: context)
        // case 1:
        // desc: 首次排序，无任何影响排序结果的变量（例如as、focus、参会人变动等）
        // expected: 将自己放到排序结果的首位，然后其余按照 rank 顺序依次填充
        var result = sut.sort(scoreInfos: scoreInfos, context: context)
        var expected = [me.user.id] + (1..<20).map { String($0) }
        XCTAssertEqual(result.map { $0.id }, expected)

        var currentPage = 2
        context.displayInfo = GridDisplayInfo(visibleRange: .page(index: currentPage), displayMode: .gridVideo)

        // case 2:
        // desc: 用户切换当前屏到第三页，待排队列分数排名变化时，尽量（指无 AS focus 等影响时）保证首屏和当前屏顺序不变
        // expected: 首页和第三页位置保持变，其余页按照新的 rank 填充
        var reversed = Array(allParticipants.reversed())
        scoreInfos = sortInput(from: reversed, context: context)
        result = sut.sort(scoreInfos: scoreInfos, context: context)
        expected = [me.user.id, "1", "2", "3", "4", "5",
                    "19", "18", "11", "10", "9", "8",
                    "12", "13", "14", "15", "16", "17", // 当前屏
                    "7", "6"]
        XCTAssertEqual(result.map { $0.id }, expected)

        // case 3:
        // desc: 非当前屏非首屏用户成为 AS，将此 AS 放到首页
        // expected: AS 替换掉首页最低分用户，被替换的人加入待排队列
        context.currentActiveSpeaker = allParticipants.last?.user
        scoreInfos = sortInput(from: reversed, context: context)
        result = sut.sort(scoreInfos: scoreInfos, context: context)
        expected = [me.user.id, "19", "2", "3", "4", "5",
                    "18", "11", "10", "9", "8", "7",
                    "12", "13", "14", "15", "16", "17", // 当前屏
                    "6", "1"]
        XCTAssertEqual(result.map { $0.id }, expected)

        // case 4:
        // desc: 当前屏用户成为 AS，保留此 AS 的位置不变
        // expected: 同上一个 case
        context.currentActiveSpeaker = allParticipants[currentPage * 6 + 2].user
        scoreInfos = sortInput(from: reversed, context: context)
        result = sut.sort(scoreInfos: scoreInfos, context: context)
        XCTAssertEqual(result.map { $0.id }, expected)

        // case 5:
        // desc: 用户切换当前屏到第4页，AS 同上
        // expected: AS 被添加到首页，替换掉分数最低的人，其余两屏按照分数排序
        currentPage = 3
        context.displayInfo.visibleRange = .page(index: currentPage)
        scoreInfos = sortInput(from: reversed, context: context)
        result = sut.sort(scoreInfos: scoreInfos, context: context)
        expected = [me.user.id, "19", "15", "3", "4", "5",
                    "18", "17", "16", "14", "13", "12",
                    "11", "10", "9", "8", "7", "2",
                    "6", "1"] // 当前屏
        XCTAssertEqual(result.map { $0.id }, expected)

        // case 6:
        // desc: 当前页是最后一页, 前面离会一人("3")导致当前页不满
        // expected: 当前页往前逐个插入能盛得下的宫格
        reversed.removeAll(where: { $0.user.id == "3" })
        scoreInfos = sortInput(from: reversed, context: context)
        result = sut.sort(scoreInfos: scoreInfos, context: context)
        expected = [me.user.id, "19", "15", "18", "4", "5",
                    "17", "16", "14", "13", "12", "11",
                    "10", "9", "8", "7", "2", "6",
                    "1"] // 当前屏
        XCTAssertEqual(result.map { $0.id }, expected)

        // case 7:
        // desc: 当前页是最后一页，前面离会人数大于当前页宫格数
        // expected: 当前页全部前移，最终排序结果少一页，除了首屏保留以外，其余按照分数排
        reversed.removeAll(where: { $0.user.id == "13" || $0.user.id == "19" })
        scoreInfos = sortInput(from: reversed, context: context)
        result = sut.sort(scoreInfos: scoreInfos, context: context)
        expected = [me.user.id, "17", "15", "18", "4", "5",
                    "16", "14", "12", "11", "10", "9",
                    "8", "7", "6", "2", "1"]
        XCTAssertEqual(result.map { $0.id }, expected)

        // case 8:
        // desc: 当前页的人被聚焦，且首页第二位是 AS
        // expected: 被聚焦人放到首页第二位，AS 替换掉首页最低分，被替换的人加入待排队列
        currentPage = 2
        context.displayInfo.visibleRange = .page(index: currentPage)
        context.focusingParticipantID = allParticipants.first(where: { $0.user.id == "6" })?.user
        context.currentActiveSpeaker = allParticipants.first(where: { $0.user.id == "17" })?.user
        scoreInfos = sortInput(from: reversed, context: context)
        result = sut.sort(scoreInfos: scoreInfos, context: context)
        expected = [me.user.id, "6", "15", "18", "17", "5",
                    "16", "14", "12", "11", "10", "9",
                    "8", "7", "4", "2", "1"]
        XCTAssertEqual(result.map { $0.id }, expected)
    }

    private func sortInput(from participants: [Participant],
                           context: InMeetGridSortContext,
                           unmuteIndexes: Set<Int> = [],
                           enterIndexes: Set<Int> = [],
                           muteIndexes: Set<Int> = []) -> [GridSortInputEntry] {
        let actionForIndex = { (index) -> CandidateAction in
            if unmuteIndexes.contains(index) {
                return .unmuteCamera
            } else if muteIndexes.contains(index) {
                return .muteCamera
            } else if enterIndexes.contains(index) {
                return .enter
            } else {
                return .none
            }
        }
        let res = participants.enumerated().map { index, participant in
            GridSortInputEntry(participant: participant, myself: me.user, asID: context.currentActiveSpeaker, focusedID: context.focusingParticipantID, rank: index, action: actionForIndex(index))
        }
        return res + [GridSortInputEntry(participant: me, myself: me.user, asID: context.currentActiveSpeaker, focusedID: context.focusingParticipantID, rank: participants.count + 1, action: .none)]
    }

    private let me = ParticipantMockData.myself
}
