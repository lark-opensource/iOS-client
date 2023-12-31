//
//  ASSortTests.swift
//  ByteView-Unit-Tests
//
//  Created by YizhuoChen on 2023/5/8.
//

import XCTest
@testable import ByteView
@testable import ByteViewNetwork
@testable import ByteViewSetting

final class ASSortTests: XCTestCase {

    private var sut: ActiveSpeakerGridSorter!
    private var context: InMeetGridSortContext!

    override func setUpWithError() throws {
        sut = ActiveSpeakerGridSorter(myself: ParticipantMockData.myself.user)
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
                                        isWebinar: false
        )
        // 默认在 phone 环境下进行测试。大部分测试内容与被测设备无关，少数相关的会在测试时根据需要改变此值。
        context.isPhone = true
        context.isNewLayoutEnabled = true
    }

    override func tearDownWithError() throws {
        sut = nil
        context = nil
    }

    func testSortPrecheck() {
        context.displayInfo = GridDisplayInfo(visibleRange: .page(index: 0), displayMode: .gridVideo)
        context.markClean()

        // case 1: 没有任何变更，无需重排
        let me: Participant = ParticipantMockData.myself
        var input = [me, person("1"), person("2"), room("3")]
        for i in 0..<input.count {
            input[i].joinTime = Int64(i)
        }
        XCTAssertEqual(sut.sort(participants: input, with: context), .unchanged)

        // case 2: 通过 mark dirty 强制刷新，返回排序结果
        context.markDirty()
        var result = sut.sort(participants: input, with: context)
        var expected: SortResult = .sorted(input.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) })
        XCTAssertEqual(result, expected)

        // case 3: context 内变量赋值，但是没有产生变更，不会记录 changedType，因此无需重排
        context.markClean()
        context.isHideSelf = false
        XCTAssertEqual(sut.sort(participants: input, with: context), .unchanged)

        // case 4: context 内变量赋值，且在 sorter 的 observedChanges，需要重排
        context.isHideSelf = true
        result = sut.sort(participants: input, with: context)
        expected = .sorted(input.filter { $0.user != me.user }.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) })
        XCTAssertEqual(result, expected)

        // case 5: 只有存在焦点视频时，自己主持人或共享人身份变更触发重排，否者这两者变更无需重排
        context.markClean()
        context.selfIsHost = false
        XCTAssertEqual(sut.sort(participants: input, with: context), .unchanged)

        context.isHideSelf = false
        context.focusingParticipantID = me.user
        context.markClean()
        context.selfIsHost = true
        result = sut.sort(participants: input, with: context)
        // expect: 0 2 1 3，原因：a. 尽量保留当前屏的规定，2、3预期不变位置 b. 3 是 room 用户，normalize 后会到当前页的最后
        input.swapAt(1, 2)
        expected = .sorted(input.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) })
        XCTAssertEqual(result, expected)
    }

    func testFilterParticipants() {
        context.displayInfo = GridDisplayInfo(visibleRange: .page(index: 0), displayMode: .gridVideo)
        context.markClean()

        // 输入：自己（开摄像头），参会人1，参会人2（开摄像头），room3
        let me: Participant = ParticipantMockData.myself
        var input = [me, person("1"), person("2"), room("3")]
        for i in 0..<input.count {
            input[i].status = .onTheCall
            input[i].joinTime = Int64(i)
            input[i].settings.isCameraMuted = true
        }
        input[2].settings.isCameraMuted = false
        input[0].settings.isCameraMuted = false

        // ========== 焦点视频 ==========

        // case 1: 非主持人主共享，当开启焦点视频时，排序只输出焦点视频
        prepare(context, host: false, sharer: false, hideSelf: false, hideNonVideo: false, voiceMode: false, focus: input[2].user)
        var result = sut.sort(participants: input, with: context)
        var expected: SortResult = .sorted([GridSortOutputEntry(type: .participant(input[2]), strategy: .normal)])
        XCTAssertEqual(result, expected)

        // case 2: 自己是主持人，当开启焦点视频时，输出全部结果，焦点视频在第二位
        prepare(context, host: true, sharer: false, hideSelf: false, hideNonVideo: false, voiceMode: false, focus: input[2].user)
        result = sut.sort(participants: input, with: context)
        var expectedParticipants = input
        expectedParticipants.swapAt(1, 2)
        expected = .sorted(expectedParticipants.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) })
        XCTAssertEqual(result, expected)

        // case 3: 自己是主共享，同上
        prepare(context, host: false, sharer: true, hideSelf: false, hideNonVideo: false, voiceMode: false, focus: input[2].user)
        result = sut.sort(participants: input, with: context)
        XCTAssertEqual(result, expected)

        // ========== 隐藏自己 ==========

        // case 4: 仅开启隐藏自己，最终输出结果不包含自己
        prepare(context, host: true, sharer: false, hideSelf: true, hideNonVideo: false, voiceMode: false, focus: nil)
        result = sut.sort(participants: input, with: context)
        expectedParticipants.removeAll(where: { $0.user == me.user })
        expected = .sorted(expectedParticipants.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) })
        XCTAssertEqual(result, expected)

        // ========== 隐藏非视频 ==========

        // case 5: 仅开启隐藏非视频参会者，没人说话，最终输出结果只包含开摄像头的参会者
        prepare(context, host: true, sharer: false, hideSelf: false, hideNonVideo: true, voiceMode: false, focus: nil)
        result = sut.sort(participants: input, with: context)
        expectedParticipants = [me, input[2]]
        expected = .sorted(expectedParticipants.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) })
        XCTAssertEqual(result, expected)

        // case 6: 仅开启隐藏非视频参会者，没人说话，自己为主持人或主共享，有焦点视频，则焦点视频同样保留
        prepare(context, host: true, sharer: false, hideSelf: false, hideNonVideo: true, voiceMode: false, focus: input[1].user)
        result = sut.sort(participants: input, with: context)
        expectedParticipants = [me, input[1], input[2]]
        expected = .sorted(expectedParticipants.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) })
        XCTAssertEqual(result, expected)

        // case 7: 仅开启隐藏非视频参会者，所有人都关闭摄像头，自己是主持人或主共享，有焦点视频，此时同样保留焦点视频
        input[2].settings.isCameraMuted = true
        input[0].settings.isCameraMuted = true
        result = sut.sort(participants: input, with: context)
        expectedParticipants = [input[1]]
        expected = .sorted(expectedParticipants.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) })
        XCTAssertEqual(result, expected)

        // case 8: 仅开启隐藏非视频参会者，所有人都关闭摄像头，没有焦点视频此时兜底显示一个 AS 宫格
        prepare(context, host: true, sharer: false, hideSelf: false, hideNonVideo: true, voiceMode: false, focus: nil)
        result = sut.sort(participants: input, with: context)
        expected = .sorted([GridSortOutputEntry(type: .activeSpeaker, strategy: .normal)])
        XCTAssertEqual(result, expected)

        // case 9: 自己和参会人2开启摄像头，同时开启隐藏自己和隐藏非视频，此时只保留除自己以外开摄像头的人
        input[0].settings.isCameraMuted = false
        input[2].settings.isCameraMuted = false
        prepare(context, host: true, sharer: false, hideSelf: true, hideNonVideo: true, voiceMode: false, focus: nil)
        result = sut.sort(participants: input, with: context)
        expectedParticipants = [input[2]]
        expected = .sorted(expectedParticipants.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) })
        XCTAssertEqual(result, expected)

        // case 10: 语音模式，开启隐藏非视频，不开启隐藏自己，无焦点视频，自己开摄像头，无临时上屏，则只保留自己
        prepare(context, host: true, sharer: false, hideSelf: false, hideNonVideo: true, voiceMode: true, focus: nil)
        result = sut.sort(participants: input, with: context)
        expectedParticipants = [me]
        expected = .sorted(expectedParticipants.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) })
        XCTAssertEqual(result, expected)

        // case 11: 语音模式，开启隐藏非视频，不开启隐藏自己，有焦点视频，自己开摄像头，无临时上屏，则保留自己和焦点视频
        prepare(context, host: true, sharer: false, hideSelf: false, hideNonVideo: true, voiceMode: true, focus: input[1].user)
        result = sut.sort(participants: input, with: context)
        expectedParticipants = [me, input[1]]
        expected = .sorted(expectedParticipants.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) })
        XCTAssertEqual(result, expected)

        // case 12: 语音模式，开启隐藏非视频，开启隐藏自己，有焦点视频，自己开摄像头，无临时上屏，预期仅保留焦点视频
        prepare(context, host: true, sharer: false, hideSelf: true, hideNonVideo: true, voiceMode: true, focus: input[1].user)
        result = sut.sort(participants: input, with: context)
        expectedParticipants = [input[1]]
        expected = .sorted(expectedParticipants.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) })
        XCTAssertEqual(result, expected)

        // case 13: 语音模式，开启隐藏非视频，开启隐藏自己，无焦点视频，自己开摄像头，预期兜底展示 AS 宫格
        prepare(context, host: true, sharer: false, hideSelf: true, hideNonVideo: true, voiceMode: true, focus: nil)
        result = sut.sort(participants: input, with: context)
        expected = .sorted([GridSortOutputEntry(type: .activeSpeaker, strategy: .normal)])
        XCTAssertEqual(result, expected)

        // case 14: 语音模式，开启隐藏非视频，不开启隐藏自己，无焦点视频，自己关摄像头，预期兜底展示 AS 宫格
        prepare(context, host: true, sharer: false, hideSelf: false, hideNonVideo: true, voiceMode: true, focus: nil)
        input[0].settings.isCameraMuted = true
        result = sut.sort(participants: input, with: context)
        expected = .sorted([GridSortOutputEntry(type: .activeSpeaker, strategy: .normal)])
        XCTAssertEqual(result, expected)

        // case 15: 语音模式，开启隐藏非视频，不开启隐藏自己，有焦点视频，自己关摄像头，无临时上屏，预期仅保留焦点视频
        prepare(context, host: true, sharer: false, hideSelf: false, hideNonVideo: true, voiceMode: true, focus: input[1].user)
        result = sut.sort(participants: input, with: context)
        expectedParticipants = [input[1]]
        expected = .sorted(expectedParticipants.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) })
        XCTAssertEqual(result, expected)

        // ========== 隐藏非视频参会者+临时上屏逻辑 ==========

        // room3 5秒前开始说话，1秒前说话完，接下来的排序结果预期包含 room3，即使 room3 没有开启摄像头
        let now = Date().timeIntervalSinceReferenceDate
        let start = now - 5
        let end = now - 1
        let speakingTime = ActiveSpeakerSpeakingTime(start: start, end: end)
        let mockASInfo = ActiveSpeakerInfo(rtcUid: RtcUID(input[3].user.deviceId), pid: input[3].user, speakingTimes: [speakingTime], isSpeaking: true)
        context.asInfos = [mockASInfo]
        let period = TimeInterval(context.nonVideoConfig.period / 1000)
        let expectedStrategy: GridSortEntryStrategy = .temporary(end + period)
        input[0].settings.isCameraMuted = false
        input[1].settings.isCameraMuted = true
        input[2].settings.isCameraMuted = false
        input[3].settings.isCameraMuted = true

        // case 16: 仅开启隐藏非视频，无焦点视频，自己开摄像头，有临时上屏，预期保留开摄像头的人和临时上屏的人
        prepare(context, host: true, sharer: false, hideSelf: false, hideNonVideo: true, voiceMode: false, focus: nil)
        result = sut.sort(participants: input, with: context)
        var expectedOutputs = [me, input[2]].map { GridSortOutputEntry(type: .participant($0), strategy: .normal) }
        expectedOutputs.append(GridSortOutputEntry(type: .participant(input[3]), strategy: expectedStrategy))
        expected = .sorted(expectedOutputs)
        XCTAssertEqual(result, expected)

        // case 17: 仅开启隐藏非视频，自己为主持人或主共享，有焦点视频，预期保留开摄像头的人、焦点视频和临时上屏
        prepare(context, host: true, sharer: false, hideSelf: false, hideNonVideo: true, voiceMode: false, focus: input[1].user)
        result = sut.sort(participants: input, with: context)
        expectedOutputs = [me, input[1], input[2]].map { GridSortOutputEntry(type: .participant($0), strategy: .normal) }
        expectedOutputs.append(GridSortOutputEntry(type: .participant(input[3]), strategy: expectedStrategy))
        expected = .sorted(expectedOutputs)
        XCTAssertEqual(result, expected)

        // case 18: 仅开启隐藏非视频，所有人都关闭摄像头，自己是主持人或主共享，有焦点视频，此时同样保留焦点视频
        input[2].settings.isCameraMuted = true
        input[0].settings.isCameraMuted = true
        result = sut.sort(participants: input, with: context)
        expectedOutputs = [input[1]].map { GridSortOutputEntry(type: .participant($0), strategy: .normal) }
        expectedOutputs.append(GridSortOutputEntry(type: .participant(input[3]), strategy: expectedStrategy))
        expected = .sorted(expectedOutputs)
        XCTAssertEqual(result, expected)

        // case 19: 仅开启隐藏非视频，所有人都关闭摄像头，没有焦点视频，此时兜底显示一个 AS 宫格
        prepare(context, host: true, sharer: false, hideSelf: false, hideNonVideo: true, voiceMode: false, focus: nil)
        result = sut.sort(participants: input, with: context)
        expected = .sorted([GridSortOutputEntry(type: .activeSpeaker, strategy: .normal)])
        XCTAssertEqual(result, expected)

        // case 20: 自己和参会人2开启摄像头，同时开启隐藏自己和隐藏非视频，此时只保留除自己以外开摄像头的人和临时上屏
        input[0].settings.isCameraMuted = false
        input[2].settings.isCameraMuted = false
        prepare(context, host: true, sharer: false, hideSelf: true, hideNonVideo: true, voiceMode: false, focus: nil)
        result = sut.sort(participants: input, with: context)
        expectedOutputs = [input[2]].map { GridSortOutputEntry(type: .participant($0), strategy: .normal) }
        expectedOutputs.append(GridSortOutputEntry(type: .participant(input[3]), strategy: expectedStrategy))
        expected = .sorted(expectedOutputs)
        XCTAssertEqual(result, expected)

        // case 21: 语音模式，开启隐藏非视频，不开启隐藏自己，无焦点视频，自己开摄像头，有临时上屏，则保留自己和临时上屏
        prepare(context, host: true, sharer: false, hideSelf: false, hideNonVideo: true, voiceMode: true, focus: nil)
        result = sut.sort(participants: input, with: context)
        expectedOutputs = [me].map { GridSortOutputEntry(type: .participant($0), strategy: .normal) }
        expectedOutputs.append(GridSortOutputEntry(type: .participant(input[3]), strategy: expectedStrategy))
        expected = .sorted(expectedOutputs)
        XCTAssertEqual(result, expected)

        // case 22: 语音模式，开启隐藏非视频，不开启隐藏自己，有焦点视频，自己开摄像头，有临时上屏，则保留自己、焦点视频和临时上屏
        prepare(context, host: true, sharer: false, hideSelf: false, hideNonVideo: true, voiceMode: true, focus: input[1].user)
        result = sut.sort(participants: input, with: context)
        expectedOutputs = [me, input[1]].map { GridSortOutputEntry(type: .participant($0), strategy: .normal) }
        expectedOutputs.append(GridSortOutputEntry(type: .participant(input[3]), strategy: expectedStrategy))
        expected = .sorted(expectedOutputs)
        XCTAssertEqual(result, expected)

        // case 12: 语音模式，开启隐藏非视频，开启隐藏自己，有焦点视频，自己开摄像头，有临时上屏，预期保留焦点视频和临时上屏
        prepare(context, host: true, sharer: false, hideSelf: true, hideNonVideo: true, voiceMode: true, focus: input[1].user)
        result = sut.sort(participants: input, with: context)
        expectedOutputs = [input[1]].map { GridSortOutputEntry(type: .participant($0), strategy: .normal) }
        expectedOutputs.append(GridSortOutputEntry(type: .participant(input[3]), strategy: expectedStrategy))
        expected = .sorted(expectedOutputs)
        XCTAssertEqual(result, expected)

        // case 13: 语音模式，开启隐藏非视频，开启隐藏自己，无焦点视频，自己开摄像头，预期兜底展示 AS 宫格
        prepare(context, host: true, sharer: false, hideSelf: true, hideNonVideo: true, voiceMode: true, focus: nil)
        result = sut.sort(participants: input, with: context)
        expected = .sorted([GridSortOutputEntry(type: .activeSpeaker, strategy: .normal)])
        XCTAssertEqual(result, expected)

        // case 14: 语音模式，开启隐藏非视频，不开启隐藏自己，无焦点视频，自己关摄像头，预期兜底展示 AS 宫格
        prepare(context, host: true, sharer: false, hideSelf: false, hideNonVideo: true, voiceMode: true, focus: nil)
        input[0].settings.isCameraMuted = true
        result = sut.sort(participants: input, with: context)
        expected = .sorted([GridSortOutputEntry(type: .activeSpeaker, strategy: .normal)])
        XCTAssertEqual(result, expected)

        // case 15: 语音模式，开启隐藏非视频，不开启隐藏自己，有焦点视频，自己关摄像头，有临时上屏，预期保留焦点视频和临时上屏
        prepare(context, host: true, sharer: false, hideSelf: false, hideNonVideo: true, voiceMode: true, focus: input[1].user)
        result = sut.sort(participants: input, with: context)
        expectedOutputs = [input[1]].map { GridSortOutputEntry(type: .participant($0), strategy: .normal) }
        expectedOutputs.append(GridSortOutputEntry(type: .participant(input[3]), strategy: expectedStrategy))
        expected = .sorted(expectedOutputs)
        XCTAssertEqual(result, expected)
    }

    func testMarkActionAndScoreSort() {
        context.displayInfo = GridDisplayInfo(visibleRange: .range(start: 0, end: 4, pageSize: 4), displayMode: .singleRowVideo)
        context.markDirty()

        // 输入：自己，参会人1，参会人2，参会人3，room4
        let me: Participant = ParticipantMockData.myself

        var input = [me, newPerson(1), newPerson(2), newPerson(3), newRoom(4)]
        input[0].status = .onTheCall
        input[0].joinTime = 0

        // case 1: 首次排序，每个参会者都是 .enter，计算得分相同，按照入会时间排序
        var result = sut.sort(participants: input, with: context)
        var expected: SortResult = .sorted(input.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) })
        XCTAssertEqual(result, expected)

        // case 2: 参会人5首次入会，行为为 enter，成为上屏候选人，打开摄像头，计算分数超过首屏所有人，替换首屏最低分
        var person5 = newPerson(5)
        person5.settings.isCameraMuted = false
        input.append(person5)
        result = sut.sort(participants: input, with: context)
        var expectedParticipants = [input[0], input[1], input[2], input[5], input[3], input[4]]
        expected = .sorted(expectedParticipants.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) })
        XCTAssertEqual(result, expected)

        // case 3: room4 说话，AS 得分提高，从第二屏拿到首屏
        let now = Date().timeIntervalSinceReferenceDate
        let start = now - 5
        let end = now - 1
        let speakingTime = ActiveSpeakerSpeakingTime(start: start, end: end)
        let mockASInfo = ActiveSpeakerInfo(rtcUid: RtcUID(input[4].user.deviceId), pid: input[4].user, speakingTimes: [speakingTime], isSpeaking: true)
        context.asInfos = [mockASInfo]
        context.currentActiveSpeaker = input[4].user

        result = sut.sort(participants: input, with: context)
        expectedParticipants = [input[0], input[1], input[4], input[5], input[2], input[3]]
        expected = .sorted(expectedParticipants.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) })
        XCTAssertEqual(result, expected)

        // case 4: 首页参会人1关闭摄像头，成为下首屏候选，指定参会人3的分数比1高，预期3上首屏，替换1
        input[1].settings.isCameraMuted = false
        _ = sut.sort(participants: input, with: context)

        input[3].joinTime = 0
        input[1].settings.isCameraMuted = true
        result = sut.sort(participants: input, with: context)
        expectedParticipants = [input[0], input[3], input[4], input[5], input[1], input[2]]
        expected = .sorted(expectedParticipants.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) })
        XCTAssertEqual(result, expected)

        // case 5: 一组全新的参会人，得分均为0，其中参会人10状态是 calling，将10放到最后
        input = [me, newPerson(10), newPerson(11), newPerson(12)]
        input[1].status = .calling
        result = sut.sort(participants: input, with: context)
        expectedParticipants = input
        let person10 = expectedParticipants.remove(at: 1)
        expectedParticipants.append(person10)
        expected = .sorted(expectedParticipants.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) })
        XCTAssertEqual(result, expected)
    }

    func testShareAndASOnPhone() {
        context.isPhone = true
        // 手机在横屏时使用 .singleRowVideo
        context.displayInfo = GridDisplayInfo(visibleRange: .range(start: 0, end: 4, pageSize: 4), displayMode: .singleRowVideo)
        context.markDirty()

        // 输入：自己，参会人1，参会人2，参会人3，room4
        let me: Participant = ParticipantMockData.myself

        var input = [me, newPerson(1), newPerson(2), newPerson(3), newRoom(4)]
        input[0].status = .onTheCall
        input[0].joinTime = 0
        input[0].settings.isCameraMuted = true

        // case 1: 首次排序，按照入会时间排序
        var result = sut.sort(participants: input, with: context)
        var expectedOutput = input.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) }
        var expected: SortResult = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
        context.updateCurrentSortResult(expectedOutput)
        context.markClean()

        // case 2: 开启共享，手机横屏时共享宫格在首位
        context.shareGridEnabled = true
        result = sut.sort(participants: input, with: context)
        expectedOutput = [GridSortOutputEntry(type: .share, strategy: .normal)] + expectedOutput
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
        context.markClean()

        // case 3: 开启隐藏自己、隐藏非视频，会中无人开摄像头，兜底显示 AS 宫格，共享宫格仍在首位
        context.isHideSelf = true
        context.isHideNonVideo = true
        result = sut.sort(participants: input, with: context)
        expectedOutput = [GridSortOutputEntry(type: .share, strategy: .normal), GridSortOutputEntry(type: .activeSpeaker, strategy: .normal)]
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
    }

    func testShareAndASOnPad() {
        context.isPhone = false
        context.isNewLayoutEnabled = false
        // 判断使用哪个 sorter 时会结合是否是 phone 以及 displayMode 决定，
        // 为了保证测试时模拟 pad 的环境，这里 displayMode 设置为 singleRowVideo 强制使用 RectSorter
        context.displayInfo = GridDisplayInfo(visibleRange: .range(start: 0, end: 4, pageSize: 4), displayMode: .singleRowVideo)
        context.markDirty()

        // 输入：自己，参会人1，参会人2，参会人3，room4
        let me: Participant = ParticipantMockData.myself

        var input = [me, newPerson(1), newPerson(2), newPerson(3), newRoom(4)]
        input[0].status = .onTheCall
        input[0].joinTime = 0
        input[0].settings.isCameraMuted = true

        // case 1: 首次排序，按照入会时间排序
        var result = sut.sort(participants: input, with: context)
        var expectedOutput = input.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) }
        var expected: SortResult = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
        context.updateCurrentSortResult(expectedOutput)
        context.markClean()

        // case 2: 开启共享，iPad 默认共享宫格在第二位（自己后面）
        context.shareGridEnabled = true
        result = sut.sort(participants: input, with: context)
        expectedOutput.insert(GridSortOutputEntry(type: .share, strategy: .normal), at: 1)
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
        context.markClean()

        // case 3: 开启隐藏自己、隐藏非视频，会中无人开摄像头，兜底显示 AS 宫格，此时共享宫格在首位
        context.isHideSelf = true
        context.isHideNonVideo = true
        result = sut.sort(participants: input, with: context)
        expectedOutput = [GridSortOutputEntry(type: .share, strategy: .normal), GridSortOutputEntry(type: .activeSpeaker, strategy: .normal)]
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
        context.updateCurrentSortResult(expectedOutput)

        context.shareGridEnabled = false
        context.markClean()

        // case 4: 插入共享宫格以后，AS 宫格被挤出首屏，此时交换 AS 宫格与首页最后一格
        // 4.1 初始化排序，首页最后一位是 AS
        context.isHideSelf = false
        context.isHideNonVideo = false
        result = sut.sort(participants: input, with: context)
        expectedOutput = input.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) }
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
        context.updateCurrentSortResult(expectedOutput)
        // 4.2 让首页最后一位是 AS，开启共享，此时需要保证插入共享宫格后，AS 宫格依然在首页
        context.currentActiveSpeaker = input[3].user
        context.shareGridEnabled = true
        result = sut.sort(participants: input, with: context)
        expectedOutput = [input[0], input[1], input[3], input[2], input[4]].map { GridSortOutputEntry(type: .participant($0), strategy: .normal) }
        expectedOutput.insert(GridSortOutputEntry(type: .share, strategy: .normal), at: 1)
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
    }

    // bug: iPad 会中一人开启共享，开启隐藏自己，展示了兜底 AS
    func testHideSelfAndShareWithSingleParticipant() {
        // case: 会中单人开启共享后，宫格视图中开启隐藏自己
        // expected: 只显示共享宫格
        context.displayInfo = GridDisplayInfo(visibleRange: .range(start: 0, end: 4, pageSize: 4), displayMode: .gridVideo)
        context.markClean()

        context.isPhone = false
        context.isNewLayoutEnabled = false
        context.shareGridEnabled = true
        context.isHideSelf = true
        let input = [ParticipantMockData.myself]
        let result = sut.sort(participants: input, with: context)
        let expected: SortResult = .sorted([GridSortOutputEntry(type: .share, strategy: .normal)])
        XCTAssertEqual(result, expected)
    }

    // MARK: - Utils

    private func prepare(_ context: InMeetGridSortContext, host: Bool, sharer: Bool, hideSelf: Bool, hideNonVideo: Bool, voiceMode: Bool, focus: ByteviewUser?) {
        context.selfIsHost = host
        context.selfSharing = sharer
        context.isHideSelf = hideSelf
        context.isHideNonVideo = hideNonVideo
        context.isVoiceMode = voiceMode
        context.focusingParticipantID = focus
    }

    private func newPerson(_ id: Int) -> Participant {
        var p = person("\(id)")
        p.settings.isCameraMuted = true
        p.joinTime = Int64(id)
        p.status = .onTheCall
        return p
    }

    private func newRoom(_ id: Int) -> Participant {
        var r = room("\(id)")
        r.settings.isCameraMuted = true
        r.joinTime = Int64(id)
        r.status = .onTheCall
        return r
    }
}
