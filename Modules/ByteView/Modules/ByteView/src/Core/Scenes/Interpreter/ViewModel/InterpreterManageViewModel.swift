//
//  InterpreterManageViewModel.swift
//  ByteView
//
//  Created by Tobb Huang on 2020/10/20.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxDataSources
import RxSwift
import RxRelay
import Action
import RxCocoa
import ByteViewNetwork
import ByteViewUI
import ByteViewSetting

final class InterpreterManageViewModel: InMeetDataListener, MeetingSettingListener, InMeetParticipantListener {
    private let disposeBag = DisposeBag()

    static let maxChannelInfosCount: Int = 10

    let meeting: InMeetMeeting
    var reservedUsers: [ByteviewUser] = []

    /// 预设传译员
    @RwAtomic
    private var presetInterpreters: [InterpretationChannelInfo] = []
    /// 会中传译员
    @RwAtomic
    private var onlineInterpreters: [InterpretationChannelInfo] = []
    /// 修改的数据
    @RwAtomic
    private var modifiedInterpreters: [InterpretationChannelInfo] = []
    /// 新增的数据
    @RwAtomic
    private var addedInterpreters: [InterpretationChannelInfo] = []

    private let allInterpretersRelay: BehaviorRelay<[InterpretationChannelInfo]> = BehaviorRelay(value: [])
    var allInterpreters: Observable<[InterpreterSectionModel]> {
        return allInterpretersRelay.map { [InterpreterSectionModel(items: $0)] }.asObservable()
    }

    let isMeetingOpenInterpretation: Bool
    weak var hostVC: UIViewController?
    var httpClient: HttpClient { meeting.httpClient }

    init(meeting: InMeetMeeting) {
        self.meeting = meeting
        self.isMeetingOpenInterpretation = meeting.setting.isMeetingOpenInterpretation
        meeting.data.addListener(self)
        meeting.participant.addListener(self)
        meeting.setting.addListener(self, for: .hasHostAuthority)
        if !isMeetingOpenInterpretation {
            requestOfflineInterpreters()
        }
    }

    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        checkHostFeature()
    }

    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput) {
        let participants = output.newData.nonRingingDict.filter { $0.value.settings.interpreterSetting != nil }.map(\.value)
        if isMeetingOpenInterpretation, !participants.isEmpty {
            updateOnlineInterpreters(participants)
        } else if participants.isEmpty {
            didUpdateOnlineInterpreters([])
        } else {
            updateAllInterpreters()
        }
        updateModifiedAndAddedInfos()
    }

    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        if let preInterpreters = inMeetingInfo.interpretationSetting?.interpreterSettings, !preInterpreters.isEmpty {
            let preIds = preInterpreters.map { $0.user.id }
            httpClient.getResponse(GetChattersRequest(chatterIds: preIds)) { [weak self] r in
                guard let self = self else { return }
                if let users = r.value?.chatters {
                    var infos: [InterpretationChannelInfo] = []
                    for preInterpreter in preInterpreters {
                        if let user = users.first(where: { $0.id == preInterpreter.user.id }),
                           let setting = preInterpreter.interpreterSetting {
                            var info = InterpretationChannelInfo(user: preInterpreter.user, avatarInfo: user.avatarInfo,
                                                                 displayName: user.displayName,
                                                                 interpreterSetting: setting)
                            info.joined = false
                            infos.append(info)
                        }
                    }
                    if self.presetInterpreters != infos {
                        self.presetInterpreters = infos
                        self.updateAllInterpreters()
                    }
                }
            }
            updateModifiedAndAddedInfos()
        }
    }

    private var isLostHostFeature = false
    private func checkHostFeature() {
        if !isLostHostFeature, !meeting.setting.hasHostAuthority {
            isLostHostFeature = true
            dismiss()
        }
    }

    private func dismiss() {
        Util.runInMainThread { [weak self] in
            self?.hostVC?.presentingViewController?.dismiss(animated: true, completion: nil)
            self?.hostVC = nil
        }
    }

    private var onlineRequestKey = ""
    private func updateOnlineInterpreters(_ participants: [Participant]) {
        let key = UUID().uuidString
        onlineRequestKey = key
        let participantService = meeting.httpClient.participantService
        participantService.participantInfo(pids: participants, meetingId: meeting.meetingId) { [weak self] (aps) in
            guard let self = self, self.onlineRequestKey == key else { return }
            var infos: [InterpretationChannelInfo] = []
            for (p, ap) in zip(participants, aps) {
                let nickName: String = p.settings.nickname
                if let setting = p.settings.interpreterSetting {
                    let info = InterpretationChannelInfo(user: p.user, avatarInfo: ap.avatarInfo,
                                                         displayName: nickName.isEmpty ? ap.name : nickName,
                                                         interpreterSetting: setting)
                    infos.append(info)
                }
            }
            self.didUpdateOnlineInterpreters(infos)
        }
    }

    private func didUpdateOnlineInterpreters(_ current: [InterpretationChannelInfo]) {
        let previous = self.onlineInterpreters
        if current.isEmpty, previous.isEmpty { return }
        self.onlineInterpreters = current
        let currentIds = current.compactMap { $0.localIdentifier }
        // 此时离会的传译员
        let leaveInfos = previous.filter { !currentIds.contains($0.localIdentifier) }
        let modifiedInfos = self.modifiedInterpreters
        var removedIdentifiers: [String] = []
        var newAddedInfos: [InterpretationChannelInfo] = []
        for leaveInfo in leaveInfos {
            // 搜索离会传译员是否有对应的修改
            if let info = modifiedInfos.first(where: { $0.localIdentifier == leaveInfo.localIdentifier }) {
                // 如有，则删除该修改
                removedIdentifiers.append(info.localIdentifier)
                // 若该“修改”更新了participant且没有remove，则将其转为新增数据
                if info.user != nil && !info.willBeRemoved {
                    let newAdded = self.combine(originInfo: leaveInfo, modifiedInfo: info)
                    newAddedInfos.append(newAdded)
                }
            }
        }

        if !removedIdentifiers.isEmpty {
            let newModifiedInfos: [InterpretationChannelInfo] = modifiedInfos
                .filter { !removedIdentifiers.contains($0.localIdentifier) }
            self.modifyInterpreters(newModifiedInfos, isUpdateAll: false)
        }

        if !newAddedInfos.isEmpty {
            var newValues = self.addedInterpreters
            newValues.append(contentsOf: newAddedInfos)
            self.addInterpreters(newValues, isUpdateAll: false)
        }
        updateAllInterpreters()
    }

    private func requestOfflineInterpreters() {
        let preInterpreters = meeting.data.inMeetingInfo?.interpretationSetting?.interpreterSettings ?? []
        let participants = meeting.participant.currentRoom.all.filter { p in
            return p.settings.interpreterSetting != nil && !preInterpreters.contains(where: { $0.user == p.user })
        }
        let participantService = meeting.httpClient.participantService
        participantService.participantInfo(pids: participants, meetingId: meeting.meetingId) { [weak self] (aps) in
            var infos: [InterpretationChannelInfo] = []
            for (p, ap) in zip(participants, aps) {
                if let interpreterSetting = p.settings.interpreterSetting {
                    let nickName: String = p.settings.nickname
                    var setting = InterpreterSetting()
                    setting.firstLanguage = interpreterSetting.firstLanguage
                    setting.secondLanguage = interpreterSetting.secondLanguage
                    setting.interpreterSetTime = interpreterSetting.interpreterSetTime
                    let info = InterpretationChannelInfo(user: p.user,
                                                         avatarInfo: ap.avatarInfo,
                                                         displayName: nickName.isEmpty ? ap.name : nickName,
                                                         interpreterSetting: setting)
                    infos.append(info)
                }
            }
            Util.runInMainThread { [weak self] in
                if infos.isEmpty, preInterpreters.isEmpty {
                    self?.addInterpreterAction.execute()
                } else {
                    self?.addInterpreters(infos)
                    self?.reservedUsers = infos.compactMap { $0.user }
                }
            }
        }
    }

    private func addInterpreters(_ infos: [InterpretationChannelInfo], isUpdateAll: Bool = true) {
        self.addedInterpreters = infos
        if isUpdateAll {
            updateAllInterpreters()
        } else {
            updateStartButton()
            updateSaveButton()
        }
    }

    private func modifyInterpreters(_ infos: [InterpretationChannelInfo], isUpdateAll: Bool = true) {
        self.modifiedInterpreters = infos
        if isUpdateAll {
            updateAllInterpreters()
        } else {
            updateStartButton()
            updateSaveButton()
        }
    }

    /// 合并三个数据，组成用于展示的数据流
    private func updateAllInterpreters() {
        var preInfos = self.presetInterpreters
        var onlineInfos = self.onlineInterpreters
        let modifiedInfos = self.modifiedInterpreters
        let addedInfos = self.addedInterpreters

        meeting.participant.currentRoom.nonRingingDict.forEach { (_, onTheCallP) in
            // 会中设置的传译员仍在会中
            if let preInfo = preInfos.first(where: { onTheCallP.participantId.identifier == $0.user?.participantId.identifier }) {
                if !onlineInfos.contains(where: { $0.user?.participantId.identifier == preInfo.user?.participantId.identifier }) {
                    // 添加到会中传译员数组里
                    let info = InterpretationChannelInfo(user: onTheCallP.user, avatarInfo: preInfo.avatarInfo, displayName: preInfo.displayName, interpreterSetting: preInfo.interpreterSetting)
                    onlineInfos.append(info)
                }
                // 从未入会数组中移除
                preInfos.removeAll(where: { onTheCallP.participantId.identifier == $0.user?.participantId.identifier })
                // 会前设置的传译员已入会
            } else if let preInfo = preInfos.first(where: { onTheCallP.user.id == $0.user?.id }), preInfo.user?.deviceId == "0" { // 各端约定，会前预设译员did为0
                if !onlineInfos.contains(where: { $0.user?.id == preInfo.user?.id }) {
                    // 添加到会中传译员数组里
                    let info = InterpretationChannelInfo(user: onTheCallP.user, avatarInfo: preInfo.avatarInfo, displayName: preInfo.displayName, interpreterSetting: preInfo.interpreterSetting)
                    onlineInfos.append(info)
                }
                // 从未入会数组中移除
                preInfos.removeAll(where: { onTheCallP.user.id == $0.user?.id && $0.user?.deviceId == "0" })
            }
        }

        // 原始数据根据添加时间排序
        onlineInfos.sort { (lhs, rhs) -> Bool in
            lhs.interpreterSetting.interpreterSetTime < rhs.interpreterSetting.interpreterSetTime
        }

        preInfos.sort { (lhs, rhs) -> Bool in
            lhs.interpreterSetting.interpreterSetTime < rhs.interpreterSetting.interpreterSetTime
        }

        var infos: [InterpretationChannelInfo] = onlineInfos + preInfos
        // 对原始数据应用更新
        for modifiedInfo in modifiedInfos {
            if let index = infos.firstIndex(where: { $0.localIdentifier == modifiedInfo.localIdentifier }) {
                infos[index] = self.combine(originInfo: infos[index], modifiedInfo: modifiedInfo)
            }
        }
        // 移除被删除的数据
        infos.removeAll(where: { $0.willBeRemoved })
        // 将新添加数据插入数组尾部
        infos.append(contentsOf: addedInfos)
        // 添加序号
        if !infos.isEmpty {
            for i in 0...(infos.count - 1) {
                infos[i].interpreterIndex = i
            }
        }
        // 整体倒序，新添加的展示在最上面
        infos.reverse()
        allInterpretersRelay.accept(infos)
        updateStartButton()
        updateSaveButton()
    }

    /// 监听参会人变化，清理无效的modifiedInfo、addedInfo
    private func updateModifiedAndAddedInfos() {
        let presetIds = meeting.data.inMeetingInfo?.interpretationSetting?.interpreterSettings.map { $0.user.id } ?? []
        var modifiedInfos = self.modifiedInterpreters
        let addedInfos = self.addedInterpreters

        var flag = false
        for i in 0..<modifiedInfos.count {
            if let modifiedUser = modifiedInfos[i].user,
               !meeting.participant.contains(user: modifiedUser),
                !presetIds.contains(modifiedUser.id) {
                // 删除对应的online interpreter
                modifiedInfos[i].willBeRemoved = true
                flag = true
            }
        }
        if flag {
            self.modifyInterpreters(modifiedInfos)
        }

        var newAddedInfos: [InterpretationChannelInfo] = []
        for info in addedInfos {
            if info.user == nil {
                newAddedInfos.append(info)
            } else if let addedPID = info.user?.participantId,
                      (meeting.participant.find(user: addedPID.pid) != nil || presetIds.contains(addedPID.id)) {
                newAddedInfos.append(info)
            }
        }
        if newAddedInfos.count < addedInfos.count {
            self.addInterpreters(newAddedInfos)
        }
    }

    private func updateStartButton() {
        // 存在尚未编辑完成的新增
        if addedInterpreters.contains(where: { !$0.isFull }) {
            startButtonEnabledRelay.accept(false)
        } else if !allInterpretersRelay.value.contains(where: { $0.joined }) {
            // 全部未入会，无法开启
            startButtonEnabledRelay.accept(false)
        } else {
            startButtonEnabledRelay.accept(true)
        }
    }

    private func updateSaveButton() {
        // 删除了所有传译员
        // 无修改/新增
        // 存在尚未编辑完成的新增
        // 全部未入会
        if allInterpretersRelay.value.isEmpty
            || (modifiedInterpreters.isEmpty && addedInterpreters.isEmpty)
            || addedInterpreters.contains(where: { !$0.isFull })
            || !allInterpretersRelay.value.contains(where: { $0.joined }) {
            saveButtonEnabledRelay.accept(false)
        } else {
            saveButtonEnabledRelay.accept(true)
        }
    }

    private let startButtonEnabledRelay = BehaviorRelay(value: false)
    private(set) lazy var startButtonEnabled: Driver<Bool> = startButtonEnabledRelay.asDriver()

    private let saveButtonEnabledRelay = BehaviorRelay(value: false)
    private(set) lazy var saveButtonEnabled: Driver<Bool> = saveButtonEnabledRelay.asDriver()

    var addInterpreterAction: CocoaAction {
        return CocoaAction(workFactory: { [weak self] _ in
            guard let self = self else {
                return .empty()
            }
            // 数量达到上限
            guard self.allInterpretersRelay.value.count < Self.maxChannelInfosCount else {
                Toast.show(I18n.View_G_InterpretersCapacityReached)
                return .empty()
            }
            var currentAddedInfos: [InterpretationChannelInfo] = self.addedInterpreters

            var setting: InterpreterSetting = InterpreterSetting()
            // "* 1000" => 防止快速点击"添加"导致interpreterSetTime一致
            setting.interpreterSetTime = Int64(Date().timeIntervalSince1970 * 1000)
            let newInfo = InterpretationChannelInfo(interpreterSetting: setting)
            currentAddedInfos.append(newInfo)
            self.addInterpreters(currentAddedInfos)
            return .empty()
        })
    }

    func removeInterpreter(info: InterpretationChannelInfo) {
        // 先从addedInterpreters里找
        var addedInfos = self.addedInterpreters
        if let index = addedInfos.firstIndex(where: { $0.localIdentifier == info.localIdentifier }) {
            addedInfos.remove(at: index)
            addInterpreters(addedInfos)
            return
        }

        // 再从modifiedInterpreters（已有修改）中找，找不到则新建修改
        var modifiedInfos = self.modifiedInterpreters
        if let index = modifiedInfos.firstIndex(where: { $0.localIdentifier == info.localIdentifier }) {
            modifiedInfos[index].willBeRemoved = true
        } else {
            var newInfo = info
            newInfo.willBeRemoved = true
            modifiedInfos.append(newInfo)
        }
        modifyInterpreters(modifiedInfos)
    }

    var startInterpretationAction: CocoaAction {
        return CocoaAction(workFactory: { [weak self] _ in
            guard let self = self else {
                return .empty()
            }
            let addedInfos = self.allInterpretersRelay.value
            var setInterpreters: [SetInterpreter] = []
            for info in addedInfos {
                if let setInterpreter = info.convertToSetInterpreter() {
                    setInterpreters.append(setInterpreter)
                }
            }
            // 未被添加为传译员的reserved participants需要手动delete
            self.reservedUsers.forEach { u in
                if addedInfos.firstIndex(where: { $0.user?.identifier == u.identifier }) == nil {
                    setInterpreters.append(.init(user: u, interpreterSetting: nil, isDeleteInterpreter: true))
                }
            }

            let setting = InterpretationSetting(isOpenInterpretation: true, interpreterSettings: setInterpreters)
            self.updateInterpretationSetting(setting)
            InterpreterTrack.startInterpretation()
            InterpreterTrackV2.trackClickStartInterpreter()
            self.dismiss()
            Logger.interpretation.info("Interpretation management: open")
            return .empty()
        })
    }

    var stopInterpretationAction: CocoaAction {
        return CocoaAction(workFactory: { [weak self] _ in
            guard let self = self else {
                return .empty()
            }
            let setting = InterpretationSetting(isOpenInterpretation: false, interpreterSettings: [])
            self.updateInterpretationSetting(setting)
            self.dismiss()
            Logger.interpretation.info("Interpretation management: close")
            return .empty()
        })
    }

    var saveChangesAction: CocoaAction {
        return CocoaAction(workFactory: { [weak self] _ in
            guard let self = self else {
                return .empty()
            }
            var allSetInterpreters: [SetInterpreter] = []
            // 处理modifiedInfo
            allSetInterpreters.append(contentsOf: self.createModificationSetInterpreters())
            // 添加新增数据
            let addedInfos = self.addedInterpreters
            for info in addedInfos {
                if let setInterpreter = info.convertToSetInterpreter() {
                    allSetInterpreters.append(setInterpreter)
                }
            }
            // 带上不变的数据
            let nonChanged = self.allInterpretersRelay.value.filter { non in
                let containInModified = self.modifiedInterpreters.contains(where: { $0.localIdentifier == non.localIdentifier })
                let containInAdded = self.addedInterpreters.contains(where: { $0.localIdentifier == non.localIdentifier })
                return !containInModified && !containInAdded
            }
            for info in nonChanged {
                if let setInterpreter = info.convertToSetInterpreter() {
                    allSetInterpreters.append(setInterpreter)
                }
            }

            let setting = InterpretationSetting(isOpenInterpretation: true, interpreterSettings: allSetInterpreters)
            self.updateInterpretationSetting(setting)
            self.dismiss()
            Logger.interpretation.info("Interpretation management: save")
            return .empty()
        })
    }

    func selectInterpreter(info: InterpretationChannelInfo) {
        var selected = allInterpretersRelay.value.map { $0.user?.identifier }
        var selectedPreIds = allInterpretersRelay.value.filter { !$0.joined }.map { $0.user?.id }
        let isContainCurrent = allInterpretersRelay.value.contains { (channelInfo) -> Bool in
            return (channelInfo.user == info.user) && (info.user != nil)
        }
        if isContainCurrent {
            selected = selected.filter { ($0 != info.user?.identifier) && ($0 != nil) }
            selectedPreIds = selectedPreIds.filter { ($0 != info.user?.id) && ($0 != nil) }
        }

        var preInterpreters = meeting.data.inMeetingInfo?.interpretationSetting?.interpreterSettings ?? []
        preInterpreters.sort(by: { $0.interpreterSetting?.interpreterSetTime ?? 0 < $1.interpreterSetting?.interpreterSetTime ?? 0 })

        let vm = ParticipantSearchViewModel(meeting: meeting,
                                            title: I18n.View_G_AddInterpreter,
                                            fromSource: .interpreter)
        vm.preInterpreters = preInterpreters
        vm.selectedClosure = { [weak self] result in
            guard let self = self, let displayName = result.name, let avatarInfo = result.avatarInfo else { return }

            let onlineInfos = self.onlineInterpreters
            var modifiedInfos = self.modifiedInterpreters
            var addedInfos = self.addedInterpreters
            let preSetInterpreters = self.presetInterpreters
            let user: ByteviewUser

            switch result.type {
            case .inMeet(let participant):
                user = participant.user
                let isInterperter = selected.contains(participant.identifier)
                let isPSTNorSIP = [.pstnUser, .sipUser, .h323User].contains(participant.type)
                let isGuest = participant.isLarkGuest
                let wrongVersion = !participant.capabilities.becomeInterpreter
                if isInterperter {
                    Toast.show(I18n.View_G_AlreadyInterpreter)
                    return
                } else if participant.meetingRole == .webinarAttendee {
                    Toast.show(I18n.View_G_AttendeeNoInterpreter)
                    return
                } else if isPSTNorSIP || isGuest || wrongVersion {
                    Toast.show(I18n.View_G_UserVersionNoInterpretation)
                    return
                }
            case .idle(let selectedUser):
                user = selectedUser
                let isInterperter = selectedPreIds.contains(selectedUser.id)
                if isInterperter {
                    Toast.show(I18n.View_G_AlreadyInterpreter)
                    return
                }
            }

            result.searchVC.dismiss(animated: true)

            // 先在已有的修改中搜索，若搜索成功则叠加修改
            if let index = modifiedInfos.firstIndex(where: { $0.localIdentifier == info.localIdentifier }) {
                modifiedInfos[index].updateUser(user, avatarInfo: avatarInfo, displayName: displayName)
                // 判断该修改是否仍有效，若无效（比如改了两次又改回去了），则移除
                if let info = self.checkModifiedInfo(modifiedInfo: modifiedInfos[index]) {
                    modifiedInfos[index] = info
                } else {
                    modifiedInfos.remove(at: index)
                }
                self.modifyInterpreters(modifiedInfos)
            } else if let onlineInfo = onlineInfos.first(where: { $0.localIdentifier == info.localIdentifier }) {
                // 在原始数据中搜索，若搜索成功则新建修改
                var newModifiedInfo = InterpretationChannelInfo(interpreterSetting: InterpreterSetting())
                newModifiedInfo.interpreterSetting.interpreterSetTime = onlineInfo.interpreterSetting.interpreterSetTime
                newModifiedInfo.updateUser(user, avatarInfo: avatarInfo, displayName: displayName)
                // 判断该修改是否仍有效
                if let checkModifiedInfo = self.checkModifiedInfo(modifiedInfo: newModifiedInfo) {
                    modifiedInfos.append(checkModifiedInfo)
                    self.modifyInterpreters(modifiedInfos)
                }
            } else if let index = addedInfos.firstIndex(where: { $0.localIdentifier == info.localIdentifier }) {
                // 在新增数据中搜索，若搜索成功则叠加修改
                addedInfos[index].updateUser(user, avatarInfo: avatarInfo, displayName: displayName)
                self.addInterpreters(addedInfos)
            } else if let presetInfo = preSetInterpreters.first(where: { $0.localIdentifier == info.localIdentifier }) {
                // 搜索预设传译员
                var newModifiedInfo = InterpretationChannelInfo(interpreterSetting: InterpreterSetting())
                newModifiedInfo.joined = self.meeting.participant.contains(user: user, in: .global)
                newModifiedInfo.interpreterSetting.interpreterSetTime = presetInfo.interpreterSetting.interpreterSetTime
                newModifiedInfo.updateUser(user, avatarInfo: avatarInfo, displayName: displayName)
                // 判断该修改是否仍有效
                if let checkModifiedInfo = self.checkModifiedInfo(modifiedInfo: newModifiedInfo) {
                    modifiedInfos.append(checkModifiedInfo)
                    self.modifyInterpreters(modifiedInfos)
                }
            }
        }
        meeting.router.presentDynamicModal(ParticipantSearchViewController(viewModel: vm),
                                          regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                          compactConfig: .init(presentationStyle: .pageSheet, needNavigation: true))
    }

    func selectLanguage(info: InterpretationChannelInfo, isFirstLang: Bool) {
        let lang: LanguageType = isFirstLang ? info.interpreterSetting.secondLanguage :
                                               info.interpreterSetting.firstLanguage
        let viewModel = InterpreterLanguageViewModel(selectedLanguage: lang, httpClient: httpClient, supportLanguages: meeting.setting.meetingSupportInterpretationLanguage) { [weak self] lang in
            // select the language
            guard let self = self else { return }
            let onlineInfos = self.onlineInterpreters
            var modifiedInfos = self.modifiedInterpreters
            var addedInfos = self.addedInterpreters
            let preSetInterpreters = self.presetInterpreters
            // 先在已有的修改中搜索，若搜索成功则叠加修改
            if let index = modifiedInfos.firstIndex(where: { $0.localIdentifier == info.localIdentifier }) {
                modifiedInfos[index].updateLanguageType(language: lang, isFirstLang: isFirstLang)
                // 判断该修改是否仍有效，若无效（比如改了两次又改回去了），则移除
                if let info = self.checkModifiedInfo(modifiedInfo: modifiedInfos[index]) {
                    modifiedInfos[index] = info
                } else {
                    modifiedInfos.remove(at: index)
                }
                self.modifyInterpreters(modifiedInfos)
            } else if let onlineInfo = onlineInfos.first(where: { $0.localIdentifier == info.localIdentifier }) {
                // 在原始数据中搜索，若搜索成功则新建修改
                var newModifiedInfo = InterpretationChannelInfo(interpreterSetting: InterpreterSetting())
                newModifiedInfo.interpreterSetting.interpreterSetTime = onlineInfo.interpreterSetting.interpreterSetTime
                newModifiedInfo.updateLanguageType(language: lang, isFirstLang: isFirstLang)
                // 判断该修改是否仍有效
                if let checkModifiedInfo = self.checkModifiedInfo(modifiedInfo: newModifiedInfo) {
                    modifiedInfos.append(checkModifiedInfo)
                    self.modifyInterpreters(modifiedInfos)
                }
            } else if let index = addedInfos.firstIndex(where: { $0.localIdentifier == info.localIdentifier }) {
                // 在新增数据中搜索，若搜索成功则叠加修改
                addedInfos[index].updateLanguageType(language: lang, isFirstLang: isFirstLang)
                self.addInterpreters(addedInfos)
            } else if let presetInfo = preSetInterpreters.first(where: { $0.localIdentifier == info.localIdentifier }) {
                // 搜索预设传译员
                var newModifiedInfo = InterpretationChannelInfo(interpreterSetting: InterpreterSetting())
                newModifiedInfo.interpreterSetting.interpreterSetTime = presetInfo.interpreterSetting.interpreterSetTime
                newModifiedInfo.updateLanguageType(language: lang, isFirstLang: isFirstLang)
                // 判断该修改是否仍有效
                if let canModifiedInfo = self.checkModifiedInfo(modifiedInfo: newModifiedInfo) {
                    modifiedInfos.append(canModifiedInfo)
                    self.modifyInterpreters(modifiedInfos)
                }
            }
        }
        let viewController = InterpreterLanguageViewController(viewModel: viewModel)
        let vc = NavigationController(rootViewController: viewController)
        vc.modalPresentationStyle = .formSheet
        meeting.router.present(vc)
    }

    private func combine(originInfo: InterpretationChannelInfo,
                         modifiedInfo: InterpretationChannelInfo) -> InterpretationChannelInfo {
        guard originInfo.localIdentifier == modifiedInfo.localIdentifier else { return originInfo }

        var newInfo: InterpretationChannelInfo = originInfo

        // 如果该修改为“删除”，则合并时无需改动其它字段
        newInfo.willBeRemoved = modifiedInfo.willBeRemoved
        if newInfo.willBeRemoved {
            return newInfo
        }

        if let u = modifiedInfo.user {
            newInfo.user = u
            newInfo.avatarInfo = modifiedInfo.avatarInfo
            newInfo.displayName = modifiedInfo.displayName
            newInfo.joined = modifiedInfo.joined
        }

        let firstModifiedLang = modifiedInfo.interpreterSetting.firstLanguage
        if !firstModifiedLang.isEmpty {
            newInfo.interpreterSetting.firstLanguage = firstModifiedLang
        }

        let secondModifiedLang = modifiedInfo.interpreterSetting.secondLanguage
        if !secondModifiedLang.isEmpty {
            newInfo.interpreterSetting.secondLanguage = secondModifiedLang
        }

        return newInfo
    }

    private func updateInterpretationSetting(_ setting: InterpretationSetting) {
        var request = HostManageRequest(action: .setInterpretationAction, meetingId: meeting.meetingId)
        request.interpretationSetting = setting
        httpClient.send(request)
    }

    private func checkModifiedInfo(modifiedInfo: InterpretationChannelInfo) -> InterpretationChannelInfo? {
        // 找到对应的onlineInfo
        let findInfos = onlineInterpreters + presetInterpreters
        guard let findInfo = findInfos.first(where: { $0.localIdentifier == modifiedInfo.localIdentifier }) else {
            return nil
        }
        // 撤销modifiedInfo中与原始数据一致的字段
        var checkedInfo = modifiedInfo
        if let u = checkedInfo.user, u.identifier == findInfo.user?.identifier {
            checkedInfo.user = nil
        }
        if checkedInfo.interpreterSetting.sameAs(setting: findInfo.interpreterSetting) {
            checkedInfo.interpreterSetting = InterpreterSetting()
        }
        if checkedInfo.isEmpty {
            return nil
        }
        return checkedInfo
    }

    private func createModificationSetInterpreters() -> [SetInterpreter] {
        var allSetInterpreters: [SetInterpreter] = []
        let modifiedInfos = self.modifiedInterpreters
        let addedInfos = self.addedInterpreters
        var allInfos: [InterpretationChannelInfo] = presetInterpreters
        allInfos.append(contentsOf: onlineInterpreters)
        for modifiedInfo in modifiedInfos {
            if let info = allInfos.first(where: { $0.localIdentifier == modifiedInfo.localIdentifier }) {
                // 如果修改了传译员（参会人），则首先删除原传译员
                if modifiedInfo.user != nil && !modifiedInfo.willBeRemoved {
                    var newOriginInfo = info
                    newOriginInfo.willBeRemoved = true
                    if let setInterpreter = newOriginInfo.convertToSetInterpreter() {
                        allSetInterpreters.append(setInterpreter)
                    }
                }
                // 接着合并原始数据和修改数据
                let setInterpreter = self.combine(originInfo: info, modifiedInfo: modifiedInfo).convertToSetInterpreter()
                if let setInterpreter = setInterpreter {
                    allSetInterpreters.append(setInterpreter)
                }
            }
        }
        // 若被删除的传译员同时出现在新增数据中，则撤销删除
        return allSetInterpreters.filter { (setInterpreter) -> Bool in
            let addedIds = addedInfos.compactMap { $0.user?.identifier }
            return !(setInterpreter.isDeleteInterpreter && addedIds.contains(setInterpreter.user.identifier))
        }
    }
}
