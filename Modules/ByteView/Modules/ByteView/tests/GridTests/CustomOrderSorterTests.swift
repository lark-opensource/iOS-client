//
//  CustomOrderSorterTests.swift
//  ByteView-Unit-Tests
//
//  Created by YizhuoChen on 2023/5/9.
//

import XCTest
@testable import ByteView
@testable import ByteViewNetwork
@testable import ByteViewSetting

final class CustomOrderSorterTests: XCTestCase {

    // 自定义排序默认不会记录每次排序结果，但在业务中会由上层使用者结合用户操作和服务端推送来保存自定义顺序，
    // 因此测试用例中需要频繁调用 context.updateCurrentSortResult 来更新排序结果，模拟连续的顺序更新操作
    private var sut: CustomOrderGridSorter!
    private var context: InMeetGridSortContext!

    override func setUpWithError() throws {
        sut = CustomOrderGridSorter(myself: ParticipantMockData.myself.user)
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
        changeDisplayMode(.singleRowVideo)

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

        // case 5: 用户正在拖动过程中，忽略一切变化，无需重排
        context.markDirty()
        context.isGridDragging = true
        XCTAssertEqual(sut.sort(participants: input, with: context), .unchanged)
    }

    func testManuallyReorder() {
        changeDisplayMode(.singleRowVideo)

        // 输入：自己，参会人1，参会人2，room3
        let me: Participant = ParticipantMockData.myself
        let input = [me, person("1"), person("2"), room("3")]
        context.updateCurrentSortResult(input.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) })

        // case 1: 拖动最后一个宫格，移动到第二位
        context.reorderAction = .move(from: 3, to: 1)
        var result = sut.sort(participants: input, with: context)
        var expectedOutput = sortResult(basedOn: input, customOrder: [0, 3, 1, 2])
        var expected: SortResult = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
        context.updateCurrentSortResult(expectedOutput)

        // case 2: invalid input
        context.reorderAction = .move(from: 4, to: 2)
        result = sut.sort(participants: input, with: context)
        XCTAssertEqual(result, expected)
        context.reorderAction = .move(from: 2, to: 7)
        result = sut.sort(participants: input, with: context)
        XCTAssertEqual(result, expected)

        // case 3: 通过选择直接替换第一个宫格和第三个宫格
        context.reorderAction = .swap(i: 0, j: 2)
        result = sut.sort(participants: input, with: context)
        expectedOutput = sortResult(basedOn: input, customOrder: [1, 3, 0, 2])
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
        context.updateCurrentSortResult(expectedOutput)

        // case 4: invalid input
        context.reorderAction = .swap(i: 4, j: 2)
        result = sut.sort(participants: input, with: context)
        XCTAssertEqual(result, expected)
        context.reorderAction = .swap(i: 2, j: 7)
        result = sut.sort(participants: input, with: context)
        XCTAssertEqual(result, expected)
    }

    func testFilterParticipants() {
        changeDisplayMode(.singleRowVideo)

        // 输入：自己（开摄像头），参会人1，参会人2（开摄像头），room3
        let me: Participant = ParticipantMockData.myself
        var input = [me, person("1"), person("2"), room("3")]
        input[2].settings.isCameraMuted = false
        input[0].settings.isCameraMuted = false
        let initialOutput = input.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) }
        context.updateCurrentSortResult(initialOutput)

        // case 1: 仅开启隐藏自己，最终输出结果不包含自己
        prepare(context, hideSelf: true, hideNonVideo: false, voiceMode: false)
        var result = sut.sort(participants: input, with: context)
        var expectedOutput = sortResult(basedOn: input, customOrder: [1, 2, 3])
        var expected: SortResult = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
        // 记录此次排序结果
        context.updateCurrentSortResult(expectedOutput)

        // case 2: 恢复隐藏自己，自己显示在最后一位
        prepare(context, hideSelf: false, hideNonVideo: false, voiceMode: false)
        result = sut.sort(participants: input, with: context)
        expectedOutput = sortResult(basedOn: input, customOrder: [1, 2, 3, 0])
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)

        // 重置排序结果
        context.updateCurrentSortResult(initialOutput)

        // case 3: 仅开启隐藏非视频参会者，输出不包括关闭摄像头的人
        prepare(context, hideSelf: false, hideNonVideo: true, voiceMode: false)
        result = sut.sort(participants: input, with: context)
        expectedOutput = sortResult(basedOn: input, customOrder: [0, 2])
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
        // 记录此次排序结果
        context.updateCurrentSortResult(expectedOutput)

        // case 4: 恢复隐藏非视频参会者，之前被隐藏的被放置在后面，顺序不定义
        prepare(context, hideSelf: false, hideNonVideo: false, voiceMode: false)
        result = sut.sort(participants: input, with: context)
        if case .sorted(let res) = result {
            XCTAssertEqual(expectedOutput, Array(res[0..<expectedOutput.count]))
            XCTAssertEqual(res.count, input.count)
            var left: [Int] = []
            for i in expectedOutput.count..<res.count {
                if case .participant(let p) = res[safeAccess: i]?.type {
                    left.append(Int(p.user.id) ?? -1)
                } else {
                    XCTFail("Sort result must all be participants")
                }
            }
            XCTAssertEqual(left.sorted(), [1, 3])
        } else {
            XCTFail("Sort result must be .sorted(result)")
        }

        // 重置排序结果
        context.updateCurrentSortResult(initialOutput)

        // case 5: 仅开启隐藏非视频参会者，所有人都关闭摄像头，此时兜底显示一个 AS 宫格
        prepare(context, hideSelf: false, hideNonVideo: true, voiceMode: false)
        input[0].settings.isCameraMuted = true
        input[2].settings.isCameraMuted = true
        result = sut.sort(participants: input, with: context)
        expected = .sorted([GridSortOutputEntry(type: .activeSpeaker, strategy: .normal)])
        XCTAssertEqual(result, expected)

        // case 5: 自己和参会人2开启摄像头，同时开启隐藏自己和隐藏非视频，此时只保留除自己以外开摄像头的人
        input[0].settings.isCameraMuted = false
        input[2].settings.isCameraMuted = false
        prepare(context, hideSelf: true, hideNonVideo: true, voiceMode: false)
        result = sut.sort(participants: input, with: context)
        expectedOutput = sortResult(basedOn: input, customOrder: [2])
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)

        // case 6: 语音模式，开启隐藏非视频，不开启隐藏自己，自己和参会人2开摄像头，只保留自己
        prepare(context, hideSelf: false, hideNonVideo: true, voiceMode: true)
        result = sut.sort(participants: input, with: context)
        expectedOutput = sortResult(basedOn: input, customOrder: [0])
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)

        // case 7: 语音模式，开启隐藏非视频，不开启隐藏自己，只有参会人2开摄像头，预期保留一个 AS 宫格
        input[0].settings.isCameraMuted = true
        prepare(context, hideSelf: false, hideNonVideo: true, voiceMode: true)
        result = sut.sort(participants: input, with: context)
        expected = .sorted([GridSortOutputEntry(type: .activeSpeaker, strategy: .normal)])
        XCTAssertEqual(result, expected)

        // case 8: 语音模式，开启隐藏非视频，开启隐藏自己，自己开摄像头，预期兜底展示 AS 宫格
        prepare(context, hideSelf: true, hideNonVideo: true, voiceMode: true)
        result = sut.sort(participants: input, with: context)
        expected = .sorted([GridSortOutputEntry(type: .activeSpeaker, strategy: .normal)])
        XCTAssertEqual(result, expected)
    }

    func testASAndShare() {
        changeDisplayMode(.singleRowVideo)
        context.isPhone = false
        context.isNewLayoutEnabled = false

        context.markDirty()
        // 输入：自己，参会人1，参会人2，room3
        let me: Participant = ParticipantMockData.myself
        var input = [me, person("1"), person("2"), room("3")]
        let initialOutput = input.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) }
        context.updateCurrentSortResult(initialOutput)

        // ========== 共享宫格 ==========

        // case 1: 开启共享，默认共享宫格在第二位
        changeShareGridEnabled(true)
        context.shareSceneType = .magicShare
        var result = sut.sort(participants: input, with: context)
        var expectedOutput = input.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) }
        expectedOutput.insert(GridSortOutputEntry(type: .share, strategy: .normal), at: 1)
        var expected: SortResult = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
        context.updateCurrentSortResult(expectedOutput)

        // case 2: 用户操作可以正常使 share 宫格位置变化
        context.reorderAction = .move(from: 4, to: 1)
        result = sut.sort(participants: input, with: context)
        expectedOutput = sortResult(basedOn: input, customOrder: [0, 3, 1, 2])
        expectedOutput.insert(GridSortOutputEntry(type: .share, strategy: .normal), at: 2)
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
        context.updateCurrentSortResult(expectedOutput)

        // case 3: 此时通过切换视图导致 share 宫格不可见，去掉共享宫格，但是保留共享宫额的位置
        context.reorderAction = .none
        changeShareGridEnabled(false)
        result = sut.sort(participants: input, with: context)
        expectedOutput = sortResult(basedOn: input, customOrder: [0, 3, 1, 2])
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
        context.updateCurrentSortResult(expectedOutput)

        // case 4: 下次回到宫格视图时，共享宫格依然在原来的位置
        changeShareGridEnabled(true)
        result = sut.sort(participants: input, with: context)
        expectedOutput = sortResult(basedOn: input, customOrder: [0, 3, 1, 2])
        expectedOutput.insert(GridSortOutputEntry(type: .share, strategy: .normal), at: 2)
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
        context.updateCurrentSortResult(expectedOutput)

        // case 5: 切换视图，去掉共享宫格，然后通过用户操作导致现有宫格位置发生变化
        // 5.1 切换视图去掉共享宫格
        changeShareGridEnabled(false)
        _ = sut.sort(participants: input, with: context)
        expectedOutput = sortResult(basedOn: input, customOrder: [0, 3, 1, 2])
        context.updateCurrentSortResult(expectedOutput)
        // 5.2 用户手动拖动宫格
        context.reorderAction = .move(from: 2, to: 0)
        _ = sut.sort(participants: input, with: context)
        expectedOutput = sortResult(basedOn: input, customOrder: [1, 0, 3, 2])
        context.updateCurrentSortResult(expectedOutput)
        // 5.3 切换视图，添加共享宫格
        changeShareGridEnabled(true)
        context.reorderAction = .none
        result = sut.sort(participants: input, with: context)
        expectedOutput.insert(GridSortOutputEntry(type: .share, strategy: .normal), at: 2)
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
        context.updateCurrentSortResult(expectedOutput)

        // case 6: 切换共享类型至自己共享屏幕，取消共享宫格，并重置共享宫格的位置
        changeShareGridEnabled(false)
        context.shareSceneType = .selfSharingScreen
        result = sut.sort(participants: input, with: context)
        _ = expectedOutput.remove(at: 2)
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
        context.updateCurrentSortResult(expectedOutput)

        // case 7: 此时开启共享文档，共享宫格恢复为第一位
        changeShareGridEnabled(true)
        context.shareSceneType = .magicShare
        result = sut.sort(participants: input, with: context)
        expectedOutput.insert(GridSortOutputEntry(type: .share, strategy: .normal), at: 1)
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)

        // ========== AS 宫格 ==========

        // 重置为初始状态
        context.updateCurrentSortResult(initialOutput)
        changeShareGridEnabled(false)

        // case 8: 当所有人都被隐藏时，兜底展示一个 AS 宫格
        context.isHideNonVideo = true
        context.shareSceneType = .none
        result = sut.sort(participants: input, with: context)
        expectedOutput = [GridSortOutputEntry(type: .activeSpeaker, strategy: .normal)]
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
        context.updateCurrentSortResult(expectedOutput)

        // case 9: 有人开启摄像头，只展示开摄像头的用户
        input[1].settings.isCameraMuted = false
        result = sut.sort(participants: input, with: context)
        expectedOutput = sortResult(basedOn: input, customOrder: [1])
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
        // 不应用此次结果

        // ========== AS 宫格 + 共享宫格 ==========

        // case 10: 兜底显示 AS 时，如果有人开启共享，在后面添加共享宫格
        changeShareGridEnabled(true)
        input[1].settings.isCameraMuted = true
        context.shareSceneType = .magicShare
        result = sut.sort(participants: input, with: context)
        expectedOutput = [GridSortOutputEntry(type: .activeSpeaker, strategy: .normal), GridSortOutputEntry(type: .share, strategy: .normal)]
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
        context.updateCurrentSortResult(expectedOutput)

        // case 11: 此时用户通过拖动宫格改变 AS 和共享宫格的位置，记录共享宫格的位置
        context.reorderAction = .swap(i: 0, j: 1)
        result = sut.sort(participants: input, with: context)
        expectedOutput.swapAt(0, 1)
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
        context.updateCurrentSortResult(expectedOutput)

        // case 12: 有人开启摄像头，兜底宫格消失，新展示的宫格放到最后
        input[1].settings.isCameraMuted = false
        context.reorderAction = .none
        result = sut.sort(participants: input, with: context)
        expectedOutput = sortResult(basedOn: input, customOrder: [1])
        expectedOutput.insert(GridSortOutputEntry(type: .share, strategy: .normal), at: 0)
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
        context.updateCurrentSortResult(expectedOutput)

        // case 13: 此人关闭摄像头，兜底宫格重新展示，此时展示在共享宫格之后
        input[1].settings.isCameraMuted = true
        result = sut.sort(participants: input, with: context)
        expectedOutput = [GridSortOutputEntry(type: .share, strategy: .normal), GridSortOutputEntry(type: .activeSpeaker, strategy: .normal)]
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)

        // ========== Phone 上的自定义顺序+共享宫格 ==========
        // 重置 sorter 内部状态为初始状态
        changeShareGridEnabled(false)
        context.isPhone = true
        context.isNewLayoutEnabled = true
        context.isHideNonVideo = false
        context.shareSceneType = .none
        _ = sut.sort(participants: input, with: context)
        context.updateCurrentSortResult(initialOutput)

        // case 14: phone 上共享宫格默认出现在第一格
        changeShareGridEnabled(true)
        context.shareSceneType = .magicShare
        result = sut.sort(participants: input, with: context)
        expectedOutput = sortResult(basedOn: input, customOrder: [0, 1, 2, 3])
        expectedOutput.insert(GridSortOutputEntry(type: .share, strategy: .normal), at: 0)
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
    }

    func testCustomOrderOnPhone() {
        changeDisplayMode(.gridVideo)
        context.isPhone = true

        context.markDirty()
        // 输入：自己，参会人1，参会人2，room3, room4, 参会人5
        let me: Participant = ParticipantMockData.myself
        let input = [me, person("1"), person("2"), room("3"), room("4"), person("5")]
        let initialOutput = input.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) }
        context.updateCurrentSortResult(initialOutput)

        // case 1: 自定义顺序排完后，按照 phone 1:1 layout 优化需求对结果进行整理，确保 room 宫格显示正确
        let result = sut.sort(participants: input, with: context)
        let expectOutput = sortResult(basedOn: input, customOrder: [0, 1, 2, 5, 3, 4])
        XCTAssertEqual(result, .sorted(expectOutput))
    }

    func testHideSelfAndShareWithSingleParticipant() {
        // case: 会中单人开启共享后，宫格视图中开启隐藏自己
        // expected: 只显示共享宫格
        context.isPhone = false
        context.isNewLayoutEnabled = false
        changeDisplayMode(.gridVideo)
        changeShareGridEnabled(true)
        context.shareSceneType = .magicShare

        // 输入：自己，参会人1
        let me: Participant = ParticipantMockData.myself
        var input = [me, person("1")]
        let initialOutput = input.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) }
        context.updateCurrentSortResult(initialOutput)

        // case 1: 初始状态，共享为开启，会中两人，此时共享宫格展示在第二位
        var result = sut.sort(participants: input, with: context)
        var expectedOutput = initialOutput
        expectedOutput.insert(GridSortOutputEntry(type: .share, strategy: .normal), at: 1)
        var expected: SortResult = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
        context.updateCurrentSortResult(expectedOutput)

        // case 2: 参会人1离会，开启隐藏自己，预期只展示共享宫格
        context.isHideSelf = true
        input.remove(at: 1)
        result = sut.sort(participants: input, with: context)
        expectedOutput = [GridSortOutputEntry(type: .share, strategy: .normal)]
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
    }

    // todo: 测试同步顺序场景下的呼叫中用户
    func testCallingCustomOrder() {
        changeDisplayMode(.singleRowVideo)
        context.markDirty()

        // 输入：自己，参会人1，参会人2，room3
        let me: Participant = ParticipantMockData.myself
        var input = [me, person("1"), person("2"), room("3")]
        let initialOutput = input.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) }
        context.updateCurrentSortResult(initialOutput)

        var person4 = callingPerson("4")
        person4.joinTime = 4
        var person5 = callingPerson("5")
        person5.joinTime = 5
        input.append(person4)
        input.append(person5)
        var result = sut.sort(participants: input, with: context)
        var expectedOutput = sortResult(basedOn: input, customOrder: [0, 1, 2, 3, 4, 5])
        var expected: SortResult = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
        context.updateCurrentSortResult(expectedOutput)

        context.reorderAction = .move(from: 4, to: 0)
        result = sut.sort(participants: input, with: context)
        expectedOutput = sortResult(basedOn: input, customOrder: [4, 0, 1, 2, 3, 5])
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
        context.updateCurrentSortResult(expectedOutput)
        context.reorderAction = .none

        // bug: 拖拽呼叫中用户到某个位置，然后被呼叫用户入会，此时应该保持该用户位置不变
        input[4] = person("4")
        result = sut.sort(participants: input, with: context)
        expectedOutput = sortResult(basedOn: input, customOrder: [4, 0, 1, 2, 3, 5])
        expected = .sorted(expectedOutput)
        XCTAssertEqual(result, expected)
    }

    // MARK: - Utils

    private func prepare(_ context: InMeetGridSortContext, hideSelf: Bool, hideNonVideo: Bool, voiceMode: Bool) {
        context.isHideSelf = hideSelf
        context.isHideNonVideo = hideNonVideo
        context.isVoiceMode = voiceMode
    }

    private func sortResult(basedOn input: [Participant], customOrder: [Int]) -> [GridSortOutputEntry] {
        customOrder.compactMap { input[safeAccess: $0] }.map { GridSortOutputEntry(type: .participant($0), strategy: .normal) }
    }

    private func changeDisplayMode(_ mode: InMeetGridViewModel.ContentDisplayMode) {
        context.displayInfo = GridDisplayInfo(visibleRange: .range(start: 0, end: 4, pageSize: 4), displayMode: mode)
        context.markClean()
    }

    private func changeShareGridEnabled(_ isEnabled: Bool) {
        context.shareGridEnabled = isEnabled
        context.markDirty()
    }
}
