//
//  FocusDataService.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/9/21.
//

import Foundation
import RxSwift
import RxCocoa
import ServerPB
import RustPB
import LarkModel
import TangramService
import LarkContainer
import LarkRustClient
import LarkSDKInterface
import LarkFocusInterface

public final class FocusDataService: UserResolverWrapper {
    public let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.fetchFocusList()
    }

    @ScopedInjectedLazy var focusAPI: LarkFocusAPI?
    @ScopedInjectedLazy var chatterAPI: ChatterAPI?    
    @ScopedProvider private var rustService: RustService?

    private let disposeBag = DisposeBag()

    private let dataSourceRelay: BehaviorRelay<[UserFocusStatus]> = BehaviorRelay<[UserFocusStatus]>(value: [])

    public var dataSourceObservable: Observable<[UserFocusStatus]> {
        return dataSourceRelay.asObservable()
    }

    public var dataSource: [UserFocusStatus] {
        return dataSourceRelay.value
    }
    
    private let canCreateNewStatusRelay: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: true)
    
    public var canCreateNewStatusObservable: Observable<Bool> {
        return canCreateNewStatusRelay.asObservable()
    }
    
    public var canCreateNewStatus: Bool {
        return canCreateNewStatusRelay.value
    }

    public var recommendedIconKeys: [String]?

    func updateDataSource(with updateList: [Int64: UserFocusStatus]) {
        var statusList = dataSourceRelay.value
        for (index, status) in statusList.enumerated() {
            if let newValue = updateList[status.id] {
                statusList[index] = newValue
            }
        }
        dataSourceRelay.accept(statusList)
    }

    func updateDataSource(with status: UserFocusStatus) {
        var statusList = dataSourceRelay.value
        guard let index = statusList.firstIndex(where: { $0.id == status.id }) else { return }
        statusList[index] = status
        dataSourceRelay.accept(statusList)
    }

    func replaceAllDataSource(with replaceList: [UserFocusStatus]) {
        dataSourceRelay.accept(replaceList.ordered())
    }

    func removeDataSource(at index: Int) {
        var statusList = dataSourceRelay.value
        guard index < statusList.count else { return }
        statusList.remove(at: index)
        dataSourceRelay.accept(statusList)
    }

    func removeDataSource(_ status: UserFocusStatus) {
        var statusList = dataSourceRelay.value
        statusList.removeAll(where: { $0.id == status.id })
        dataSourceRelay.accept(statusList)
    }

    func addDataSource(_ status: UserFocusStatus, at index: Int) {
        var statusList = dataSourceRelay.value
        guard index <= statusList.count else { return }
        statusList.insert(status, at: index)
        dataSourceRelay.accept(statusList)
    }

    func addDataSource(_ status: UserFocusStatus) {
        var statusList = dataSourceRelay.value
        statusList.insert(status, at: 0)
        dataSourceRelay.accept(statusList.ordered())
    }

    // MARK: Create status

    func createFocusStatus(title: String,
                           iconKey: String,
                           statusDescRichText: FocusStatusDescRichText,
                           notDisturb: Bool,
                           updateDataSourceImmediately: Bool = true,
                           onSuccess: ((UserFocusStatus) -> Void)? = nil,
                           onFailure: ((Error) -> Void)? = nil) {
        focusAPI?.createFocusStatus(title: title, iconKey: iconKey, statusDescRichText: statusDescRichText, notDisturb: notDisturb)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] newStatus in
                onSuccess?(newStatus)
                guard let self = self else { return }
                FocusManager.logger.info("\(#function), line: \(#line): create new status succeed: \(newStatus).")
                self.updateCanCreateNewStatusFlag()
                if updateDataSourceImmediately {
                    // 将新 Status 插入列表
                    var statusList = self.dataSourceRelay.value
                    statusList.insert(newStatus, at: 0)
                    self.dataSourceRelay.accept(statusList.ordered())
                }
            }, onError: { error in
                onFailure?(error)
                FocusManager.logger.error("\(#function), line: \(#line): create new status \(title) failed with error: \(error.debugMessage)")
            }).disposed(by: disposeBag)
    }

    // MARK: Delete status

    func deleteFocusStatus(byID id: Int64,
                           updateDataSourceImmediately: Bool = true,
                           onSuccess: (([Int64: UserFocusStatus]) -> Void)? = nil,
                           onFailure: ((Error) -> Void)? = nil) {
        focusAPI?.deleteFocusStatus(byId: id)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] statusDic in
                onSuccess?(statusDic)
                guard let self = self else { return }
                FocusManager.logger.info("\(#function), line: \(#line): delete status \(id) succeed.")
                self.updateCanCreateNewStatusFlag()
                if updateDataSourceImmediately {
                    // 使用返回值更新列表
                    var statusList = self.dataSourceRelay.value
                    statusList.removeAll(where: { $0.id == id })
                    for (index, status) in statusList.enumerated() {
                        if let newStatus = statusDic[status.id] {
                            statusList[index] = newStatus
                        }
                    }
                    self.dataSourceRelay.accept(statusList.ordered())
                }
            }, onError: { error in
                onFailure?(error)
                FocusManager.logger.error("\(#function), line: \(#line): delete status \(id) failed with error: \(error.debugMessage)")
            }).disposed(by: disposeBag)
    }

    // MARK: Update status

    func updateFocusStatus(with updater: FocusStatusUpdater,
                           onSuccess: ((UserFocusStatus) -> Void)? = nil,
                           onFailure: ((Error) -> Void)? = nil) {
        focusAPI?.updateFocusStatus(with: updater)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { newStatus in
                if let newStatus = newStatus {
                    onSuccess?(newStatus)
                    FocusManager.logger.info("\(#function), line: \(#line): update status succeed: \(newStatus).")
                } else {
                    onFailure?(APIError(type: .unknownBusinessError(message: "unexpected return.")))
                    FocusManager.logger.warn("\(#function), line: \(#line): update status succeed, but have unexpected return value.")
                }
            }, onError: { error in
                onFailure?(error)
                FocusManager.logger.error("\(#function), line: \(#line): update status \(updater.fields) failed with error: \(error.debugMessage)")
            }).disposed(by: disposeBag)
    }

    // MARK: Turn on

    func turnOnFocusStatus(_ status: UserFocusStatus,
                           period: FocusPeriod,
                           onFailure: (() -> Void)? = nil,
                           onSuccess: (() -> Void)? = nil) {
        guard let endDate = period.endTime else { return }
        var newStatus = status
        newStatus.effectiveInterval.startTime = FocusUtils.shared.getRelatedServerTime(asLocal: Date())
        newStatus.effectiveInterval.endTime = FocusUtils.shared.getRelatedServerTime(asLocal: endDate)
        // 目前的需求：只有 Focus Filter 同步的状态才会没有结束时间
        newStatus.effectiveInterval.isOpenWithoutEndTime = false
        switch period {
        case .minutes30:
            newStatus.lastSelectedDuration = .minutes30
            newStatus.lastCustomizedEndTime = 0
        case .hour1:
            newStatus.lastSelectedDuration = .hour1
            newStatus.lastCustomizedEndTime = 0
        case .hour2:
            newStatus.lastSelectedDuration = .hour2
            newStatus.lastCustomizedEndTime = 0
        case .hour4:
            newStatus.lastSelectedDuration = .hour4
            newStatus.lastCustomizedEndTime = 0
        case .untilTonight:
            newStatus.lastSelectedDuration = .untilTonight
            newStatus.lastCustomizedEndTime = 0
        case .customized:
            newStatus.lastCustomizedEndTime = newStatus.effectiveInterval.endTime
        case .preset:
            newStatus.lastCustomizedEndTime  = newStatus.systemValidInterval.endTime
        case .noEndTime:
            newStatus.lastCustomizedEndTime = newStatus.effectiveInterval.endTime
        }
        guard let updater = FocusStatusUpdater.assemble(old: status, new: newStatus) else { return }
        focusAPI?.updateFocusStatus(with: [updater])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] updateDic in
                self?.updateDataSource(with: updateDic)
                onSuccess?()
                FocusManager.logger.info("\(#function), line: \(#line): turn on status \(status) succeed")
            }, onError: { [weak self] error in
                onFailure?()
                FocusManager.logger.error("\(#function), line: \(#line): turn on status \(status) failed with error: \(error.debugMessage)")
            }).disposed(by: disposeBag)
    }

    // MARK: Turn off

    func turnOffFocusStatus(_ status: UserFocusStatus,
                            onFailure: (() -> Void)? = nil,
                            onSuccess: (() -> Void)? = nil) {
        var newStatus = status
        newStatus.effectiveInterval = .close
        newStatus.lastCustomizedEndTime = 0
        guard let updater = FocusStatusUpdater.assemble(old: status, new: newStatus) else { return }
        focusAPI?.updateFocusStatus(with: [updater])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] updateList in
                self?.updateDataSource(with: updateList)
                onSuccess?()
                FocusManager.logger.info("\(#function), line: \(#line): turn off status \(status) succeed")
            }, onError: { [weak self] error in
                onFailure?()
                FocusManager.logger.error("\(#function), line: \(#line): turn off status \(status) failed with error: \(error.debugMessage)")
            }).disposed(by: disposeBag)
    }

    // MARK: Set Sync

    func openMeetingSync() {
        guard let meetingStatus = dataSource.first(where: { $0.type == .inMeeting }) else { return }
        var newStatus = meetingStatus
        for (index, _) in newStatus.settingsV2.enumerated() {
            newStatus.settingsV2[index].isOpen = true
        }
        guard let updater = FocusStatusUpdater.assemble(old: meetingStatus, new: newStatus) else { return }
        focusAPI?.updateFocusStatus(with: [updater])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] updateDic in
                self?.updateDataSource(with: updateDic)
                FocusManager.logger.info("\(#function), line: \(#line): open all sync settings of meeting succeed")
            }).disposed(by: disposeBag)
    }

    // MARK: Get server list

    private func fetchFocusList(
        onSuccess: (([UserFocusStatus]) -> Void)? = nil,
        onFailure: ((Error) -> Void)? = nil) {
            focusAPI?
                .getFocusList(strategy: .forceServer)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] status in
                    onSuccess?(status)
                    FocusManager.logger.info("\(#function), line: \(#line): fetch status list succeed, got \(status.count) items.")
                    self?.dataSourceRelay.accept(status.ordered())
                    self?.updateCanCreateNewStatusFlag()
                }, onError: { error in
                    onFailure?(error)
                    FocusManager.logger.error("\(#function), line: \(#line): fetch status list failed with error: \(error)")
                }).disposed(by: disposeBag)
        }
    
    // MARK: Check limitation
    
    func updateCanCreateNewStatusFlag() {
        focusAPI?.checkCanCreateNewStatus()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isAllowed in
                self?.canCreateNewStatusRelay.accept(isAllowed)
                FocusManager.logger.info("\(#function), line: \(#line): check custom status limitation succeed, is allowed: \(isAllowed).")
            }, onError: { [weak self] error in
                guard let self = self else { return }
                let isAllowed = self.dataSource.filter({ $0.isCustomStatus }).count < 20
                self.canCreateNewStatusRelay.accept(isAllowed)
                FocusManager.logger.info("\(#function), line: \(#line): check custom status limitation failed, is allowed: \(isAllowed).")
            }).disposed(by: disposeBag)
    }

    // MARK: Get Chatter

    func getChatter(_ id: String, completion: @escaping (Chatter?) -> Void) {
        chatterAPI?.getChatter(id: id)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] chatter in
                guard self != nil else { return }
                completion(chatter)
                FocusManager.logger.info("\(#function), line: \(#line): getChatter \(id) succeed.")
            }, onError: { (error) in
                completion(nil)
                FocusManager.logger.error("\(#function), line: \(#line): getChatter \(id) failed.")
            }).disposed(by: self.disposeBag)
    }

    // MARK: Get Chatters

    func getChatters(_ ids: [String],
                     _ from: FocusStatusDescRichText,
                     atId2UserIdMap: Dictionary<String, String>,
                     completion: @escaping (FocusStatusDescRichText) -> Void) {
        var toRichText = from
        chatterAPI?.getChatters(ids: ids)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (chatterMap) in
                guard self != nil else { return }
                var convertedElements = from.elements
                // 替换 atElements 里的 content
                for atId in from.atIds {
                    guard var atElement = convertedElements[atId], atElement.tag == .at else { return }
                    guard let userId = atId2UserIdMap[atId] else { return }
                    guard let chatter = chatterMap[userId] else { return }
                    if !chatter.alias.isEmpty {
                        atElement.property.at.content = chatter.alias
                    } else {
                        atElement.property.at.content = chatter.nameWithAnotherName
                    }
                    convertedElements[atId] = atElement
                }
                toRichText.elements = convertedElements
                completion(toRichText)
                FocusManager.logger.info("\(#function), line: \(#line): getChatters \(ids) succeed.")
            }, onError: { (error) in
                completion(toRichText)
                FocusManager.logger.error("\(#function), line: \(#line): getChatters \(ids) failed.")
            }).disposed(by: self.disposeBag)
    }
    
    // MARK: Handle data

    func reloadData(
        onSuccess: (([UserFocusStatus]) -> Void)? = nil,
        onFailure: ((Error) -> Void)? = nil) {
            fetchFocusList(onSuccess: onSuccess, onFailure: onFailure)
        }

    func clearData() {
        self.dataSourceRelay.accept([])
    }
}
