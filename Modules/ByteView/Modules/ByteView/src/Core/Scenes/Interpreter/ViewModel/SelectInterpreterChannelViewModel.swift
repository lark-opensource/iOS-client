//
//  SelectInterpreterChannelViewModel.swift
//  ByteView
//
//  Created by wulv on 2020/10/22.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import Action
import RxCocoa
import ByteViewSetting
import ByteViewNetwork

final class SelectInterpreterChannelViewModel: InMeetDataListener, MeetingSettingListener {

    static let logger = Logger.interpretation

    // MARK: Observables & Observers
    let interpretation: InMeetInterpreterViewModel
    let meeting: InMeetMeeting
    weak var hostVC: UIViewController?
    private let manageInterpreterHiddenRelay = BehaviorRelay(value: false)

    private var selectedChannel: LanguageType {
        interpretation.selectedChannel
    }

    var isMuteOriginChannel: Bool {
        interpretation.isOriginChannelMuted
    }

    private let channelsRelay = BehaviorRelay<[InterpreterChannelCellSectionModel]>(value: [])
    var channelsObservable: Observable<[InterpreterChannelCellSectionModel]> {
        channelsRelay.asObservable()
    }

    private var dataSourceChannels: [InterpreterChannelCellViewModel] {
        return channelsRelay.value.first?.items ?? []
    }

    let disposeBag = DisposeBag()

    // MARK: Actions
    func manageInterpreterAction() {
        let viewModel = InterpreterManageViewModel(meeting: meeting)
        let viewController = InterpreterManageViewController(viewModel: viewModel)
        meeting.router.push(viewController)
    }

    lazy private(set) var closeAction: CocoaAction = {
        return Action(workFactory: { [weak self] _ in
            self?.hostVC?.presentingViewController?.dismiss(animated: true, completion: nil)
            return .empty()
        })
    }()

    // MARK: Cache
    // i18nKey: i18nString
    private var channelTitlesDict: [String: NSAttributedString] = [LanguageType.main.despI18NKey: LanguageType.mainTitle]

    init(meeting: InMeetMeeting, interpretation: InMeetInterpreterViewModel) {
        self.interpretation = interpretation
        self.meeting = meeting
        manageInterpreterHiddenRelay.accept(!meeting.setting.canEditInterpreter)
        bindChannels()
        meeting.data.addListener(self)
        meeting.setting.addListener(self, for: .canEditInterpreter)
    }

    func selectChannel(_ cellVM: InterpreterChannelCellViewModel) {
        guard cellVM.cellType != .cellTypeMute else { return }
        let old = self.interpretation.selectedChannel
        let new = cellVM.model
        guard new.channelId != old.channelId else { return }
        for vm in self.dataSourceChannels {
            if vm.model.channelId == old.channelId {
                vm.isSelected = false
            } else if vm.model.channelId == new.channelId {
                vm.isSelected = true
            }
        }
        self.interpretation.selectSubscribeChannel(new)
        self.channelsRelay.accept(self.assembleChannelDatas(self.dataSourceChannels, mute: self.muteCellViewModel, manage: manageInterpreterHiddenRelay.value ? nil : self.manageCellViewModel))
        // self.closeAction.execute()  3.43-不关闭页面
    }

    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .canEditInterpreter {
            let isHidden = !isOn
            if isHidden != manageInterpreterHiddenRelay.value {
                manageInterpreterHiddenRelay.accept(isHidden)
            }
        }
    }

    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        if let vc = hostVC, !inMeetingInfo.meetingSettings.isMeetingOpenInterpretation {
            Util.runInMainThread { [weak vc] in
                vc?.presentingViewController?.dismiss(animated: true, completion: nil)
            }
            self.hostVC = nil
        }
    }
}

extension SelectInterpreterChannelViewModel {

    private var mainCellViewModel: InterpreterChannelCellViewModel {
        return InterpreterChannelCellViewModel(with: LanguageType.main.channelId,
                                               model: LanguageType.main,
                                               channelTitle: LanguageType.mainTitle,
                                               isSelected: selectedChannel.isMain,
                                               cellType: InterpreterChannelCellType.cellTypeChannel)
    }

    private var muteCellViewModel: InterpreterChannelCellViewModel {
        return InterpreterChannelCellViewModel(with: "",
                                               model: LanguageType.main,
                                               channelTitle: NSAttributedString(string: I18n.View_G_MuteOriginalAudio, config: .body),
                                               isSelected: false,
                                               cellType: InterpreterChannelCellType.cellTypeMute,
                                               isSwitchOn: self.isMuteOriginChannel,
                                               isRetractBottomLine: true)
    }

    private var manageCellViewModel: InterpreterChannelCellViewModel {
        return InterpreterChannelCellViewModel(with: "",
                                               model: LanguageType.main,
                                               channelTitle: NSAttributedString(string: I18n.View_G_ManageInterpreters, config: .body),
                                               isSelected: false,
                                               cellType: InterpreterChannelCellType.cellTypeManage,
                                               isMeetingOpenInterpretation: true)
    }


    private func bindChannels() {
        let httpClient = meeting.httpClient
        Observable.combineLatest(manageInterpreterHiddenRelay.asObservable(), interpretation.supportLanguagesObservable)
            .compactMap { [weak self] (manageHidden, languages) -> ([InterpreterChannelCellSectionModel], [String], Bool)? in
                guard let self = self else { return nil }
                var cellVMs: [InterpreterChannelCellViewModel] = [self.mainCellViewModel]
                var needRequestI18ns: [String] = []
                for type in languages {
                    let channelId = type.channelId
                    let channelI18nKey = type.despI18NKey
                    let channelTitle = self.channelTitlesDict[channelI18nKey]
                    if nil == channelTitle {
                        needRequestI18ns.append(channelI18nKey)
                    }
                    let vm = InterpreterChannelCellViewModel(with: channelId,
                                                             model: type,
                                                             channelTitle: channelTitle,
                                                             isSelected: channelId == self.selectedChannel.channelId,
                                                             cellType: InterpreterChannelCellType.cellTypeChannel)
                    cellVMs.append(vm)
                }
                if !cellVMs.isEmpty {
                    cellVMs.last?.isRetractBottomLine = true
                }

                return (self.assembleChannelDatas(cellVMs, mute: self.muteCellViewModel, manage: manageHidden ? nil : self.manageCellViewModel), needRequestI18ns, manageHidden)
        }
        .flatMapLatest { [weak self] (sectionVMs, needRequstI18ns, manageHidden) -> Observable<[InterpreterChannelCellSectionModel]> in
            guard !needRequstI18ns.isEmpty else { return Observable.just(sectionVMs) }
            let requestI18nVMs = RxTransform.single {
                httpClient.i18n.get(needRequstI18ns, completion: $0)
            }.asObservable().map { [weak self] i18nsDict -> [InterpreterChannelCellSectionModel] in
                guard let self = self else { return [] }
                for (key, title) in i18nsDict {
                    // 缓存文案
                    self.channelTitlesDict[key] = NSAttributedString(string: title, config: .body)
                }
                for vm in self.dataSourceChannels {
                    if let title = i18nsDict[vm.model.despI18NKey] {
                        vm.channelTitle = NSAttributedString(string: title, config: .body)
                    }
                }
                return self.assembleChannelDatas(self.dataSourceChannels, mute: self.muteCellViewModel, manage: manageHidden ? nil : self.manageCellViewModel)
            }
            return Observable.merge(Observable.just(sectionVMs), requestI18nVMs)
        }
        .bind(to: channelsRelay)
        .disposed(by: disposeBag)
    }

    private func assembleChannelDatas(_ channels: [InterpreterChannelCellViewModel], mute: InterpreterChannelCellViewModel, manage: InterpreterChannelCellViewModel?) -> ([InterpreterChannelCellSectionModel]) {
        mute.isEnableMute = (LanguageType.main.channelId != selectedChannel.channelId)
        mute.isSwitchOn = isMuteOriginChannel
        let channelSectionVM: InterpreterChannelCellSectionModel = InterpreterChannelCellSectionModel(items: channels)
        let muteSectionVM: InterpreterChannelCellSectionModel = InterpreterChannelCellSectionModel(items: [mute])
        var dataSource = [channelSectionVM, muteSectionVM]
        if let manage = manage {
            dataSource.append(InterpreterChannelCellSectionModel(items: [manage]))
        }
        return dataSource
    }
}
