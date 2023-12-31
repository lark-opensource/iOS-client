//
//  AdditionalTimeZoneViewModel.swift
//  Calendar
//
//  Created by chaishenghua on 2023/10/24.
//

import Foundation
import RxSwift
import RxRelay
import ThreadSafeDataStructure
import LarkContainer
import UniverseDesignToast
import Reachability
import CTFoundation

class AdditionalTimeZoneViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    typealias Config = AdditionalTimeZone

    enum SectionType {
        case additonalTimeZoneList
        case addAdditionalTimeZone
    }

    enum Action {
        case insert(at: Int)
        case delete(at: Int)
        case reload
    }

    @ScopedInjectedLazy var timeZoneService: TimeZoneService?
    private let disposebag = DisposeBag()
    private var additionalTimeZoneListViewDatas: [AdditionalTimeZoneViewData] = []
    private var addAdditionalTimeZoneViewData = AddAdditionalTimeZoneViewData()

    private let additionalTimeZoneListRelay = BehaviorRelay<Action>.init(value: .reload)
    private let selectAdditionalTimeZonePublish = PublishRelay<Void>.init()
    private let rxRefreshTableView = PublishRelay<AdditionalTimeZoneViewModel.Action?>.init()
    private let reachability = Reachability()
    private let activateDay: Date

    weak var vc: UIViewController?
    let deviceTimeZone: LocalTimeZoneViewData

    var additionalTimeZoneObservable: Observable<Action> {
        return additionalTimeZoneListRelay.asObservable()
    }

    var rxSelectAdditionalTimeZone: Observable<Void> {
        return selectAdditionalTimeZonePublish.asObservable()
    }

    var isShowAdditionalTimeZone: Bool {
        get {
            return timeZoneService?.showAdditionalTimeZone.value ?? false
        }
        set {
            AdditionalTimeZone.logger.info("showAdditionalTimeZone: \(newValue)")
            timeZoneService?.setShowAdditionalTimeZone(newValue)
            rxRefreshTableView.accept(nil)
        }
    }

    var selectedAdditionalTimeZone: String {
        get {
            return timeZoneService?.additionalTimeZone.value?.identifier ?? ""
        }
        set {
            AdditionalTimeZone.logger.info("selectAdditionalTimeZone: \(newValue)")
            timeZoneService?.setAdditionalTimeZone(newValue)
        }
    }

    private var sections: [SectionType] = []
    init(userResolver: UserResolver, activateDay: JulianDay) {
        self.userResolver = userResolver

        let (year, month, day) = JulianDayUtil.yearMonthDay(from: activateDay)
        var dateComps = DateComponents()
        dateComps.year = year
        dateComps.month = month
        dateComps.day = day
        dateComps.timeZone = .current
        dateComps.hour = 12
        dateComps.minute = 0
        dateComps.second = 0
        self.activateDay = Calendar.gregorianCalendar.date(from: dateComps) ?? Date()

        self.deviceTimeZone = LocalTimeZoneViewData(title: TimeZone.current.standardName(for: self.activateDay),
                                                    subTitle: TimeZone.current.getGmtOffsetDescription(date: self.activateDay))
        self.addAdditionalTimeZoneViewData.clickAction = { [weak self] in
            guard let self = self, let vc = vc else { return }
            guard let timeZoneService = self.timeZoneService else { return }
            if self.additionalTimeZoneListViewDatas.count >= Config.maxAdditionalTimeZones, let window = vc.view.window {
                UDToast.showFailure(with: BundleI18n.Calendar.Calendar_Timezon_MaxTimeZoneLimit(limit: Config.maxAdditionalTimeZones),
                                    on: window)
            } else {
                let selectVC = TimeZoneSearchSelectViewController(service: timeZoneService, anchorDate: Date())
                selectVC.onTimeZoneSelect = { [weak self, weak selectVC] timeZoneModel in
                    guard let self = self else { return }
                    self.addAdditionalTimeZone(timeZoneID: timeZoneModel.identifier)
                    selectVC?.popupViewController?.popViewController(animated: true)
                }
                userResolver.navigator.present(PopupViewController(rootViewController: selectVC), from: vc)
            }
        }
        self.setupData()
        listenSettingPush()
        AdditionalTimeZone.logger.info("showAdditionalTimeZone: \(isShowAdditionalTimeZone) selectAdditionalTimeZone: \(selectedAdditionalTimeZone)")
    }

    private func setupData() {
        let transform = { [weak self] (task: AdditionalTimeZoneViewModel.Action?) -> AdditionalTimeZoneViewModel.Action? in
            guard let self = self else { return nil }
            let oldSections = self.sections
            if isShowAdditionalTimeZone {
                if additionalTimeZoneListViewDatas.isEmpty {
                    self.sections = [.addAdditionalTimeZone]
                } else {
                    self.sections = [.additonalTimeZoneList, .addAdditionalTimeZone]
                }
            } else {
                sections = []
            }
            // 若section发生改变，直接reloaddate，不执行task
            if oldSections != sections {
                return .reload
            } else {
                return task
            }
        }

        rxRefreshTableView.asObservable()
            .observeOn(MainScheduler.instance)
            .map(transform)
            .subscribe(onNext: { [weak self] task in
                guard let self else { return }
                if let task = task {
                    self.additionalTimeZoneListRelay.accept(task)
                    // 如有必要，重新选择被选中的时区
                    reSelectAdditionalTimeZoneIfNeed()
                }
            }).disposed(by: disposebag)

        loadData()
    }

    private func loadData() {
        let additionalTimeZones = SettingService.shared().getSetting().additionalTimeZones
        self.additionalTimeZoneListViewDatas = additionalTimeZones.compactMap { self.transform(timeZoneID: $0, date: self.activateDay) }
        rxRefreshTableView.accept(.reload)
    }

    private func listenSettingPush() {
        SettingService.shared().updateAdditionalTimeZoneSettingPublish
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                AdditionalTimeZone.logger.info("setting push additionalTimeZones: \(SettingService.shared().getSetting().additionalTimeZones)")
                self.additionalTimeZoneListViewDatas = SettingService.shared().getSetting().additionalTimeZones
                    .compactMap { self.transform(timeZoneID: $0, date: self.activateDay) }
                rxRefreshTableView.accept(.reload)
            }).disposed(by: disposebag)
    }

    private func reSelectAdditionalTimeZoneIfNeed() {
        if additionalTimeZoneListViewDatas.isEmpty {
            if !self.selectedAdditionalTimeZone.isEmpty {
                self.selectedAdditionalTimeZone = ""
            }
        } else {
            if !self.additionalTimeZoneListViewDatas.contains(where: { $0.identifier == self.selectedAdditionalTimeZone }) {
                self.selectedAdditionalTimeZone = additionalTimeZoneListViewDatas[0].identifier
                self.selectAdditionalTimeZonePublish.accept(())
            }
        }
    }

    func addAdditionalTimeZone(timeZoneID: String) {
        guard let reachability = self.reachability, reachability.isReachable else {
            if let view = self.vc?.view.window {
                UDToast.showFailure(with: BundleI18n.Calendar.Calendar_Notes_ConnectErrorLater, on: view)
            }
            return
        }
        if additionalTimeZoneListViewDatas.contains(where: { $0.identifier == timeZoneID }) {
            if let view = self.vc?.view.window {
                UDToast.showFailure(with: BundleI18n.Calendar.Calendar_G_TimeZoneAlreadyExists_Toast, on: view)
            }
            return
        }
        guard additionalTimeZoneListViewDatas.count < Config.maxAdditionalTimeZones,
              let model = self.transform(timeZoneID: timeZoneID, date: self.activateDay) else { return }
        self.additionalTimeZoneListViewDatas.append(model)
        AdditionalTimeZone.logger.info("add additionalTimeZone: \(timeZoneID)")
        rxRefreshTableView.accept(.insert(at: self.additionalTimeZoneListViewDatas.count - 1))
        saveAdditionalTimeZones()
    }

    func deleteAdditionalTimeZone(at row: Int) {
        guard let reachability = self.reachability, reachability.isReachable else {
            if let view = self.vc?.view.window {
                UDToast.showFailure(with: BundleI18n.Calendar.Calendar_Notes_ConnectErrorLater, on: view)
            }
            return
        }
        guard row < additionalTimeZoneListViewDatas.count else { return }
        let deletedTimeZone = additionalTimeZoneListViewDatas[row].identifier
        AdditionalTimeZone.logger.info("delete additionalTimeZone: \(deletedTimeZone)")
        additionalTimeZoneListViewDatas.remove(at: row)
        rxRefreshTableView.accept(.delete(at: row))
        saveAdditionalTimeZones()
    }

    func numberOfRows(section: SectionType) -> Int {
        if sections.contains(section) {
            switch section {
            case .additonalTimeZoneList:
                return additionalTimeZoneListViewDatas.count
            case .addAdditionalTimeZone:
                return 1
            }
        }
        return 0
    }

    func cellData(at row: Int) -> AdditionalTimeZoneViewData? {
        guard row < additionalTimeZoneListViewDatas.count else { return nil }
        return additionalTimeZoneListViewDatas[row]
    }

    func getAddAdditionalTimeZoneViewData() -> AddAdditionalTimeZoneViewData {
        return self.addAdditionalTimeZoneViewData
    }

    func numberOfSections() -> Int {
        return sections.count
    }

    func getSection(at section: Int) -> SectionType? {
        guard section < sections.count else { return nil }
        return sections[section]
    }

    func getSectionIndex(_ section: SectionType) -> Int? {
        return sections.firstIndex(of: section)
    }

    private func transform(timeZoneID: String, date: Date) -> AdditionalTimeZoneViewData? {
        guard let timeZone = TimeZone(identifier: timeZoneID) else { return nil }
        return AdditionalTimeZoneViewData(title: timeZone.standardName(for: date),
                                          subTitle: timeZone.getGmtOffsetDescription(date: date),
                                          identifier: timeZone.identifier) { [weak self] cell in
            guard let self = self, let vc = self.vc as? AdditionalTimeZoneViewController else { return }
            guard let indexPath = vc.getCellIndexPath(for: cell) else { return }
            self.deleteAdditionalTimeZone(at: indexPath.row)
        }
    }

    private func saveAdditionalTimeZones() {
        let additionalTimeZones = self.additionalTimeZoneListViewDatas.map { $0.identifier }
        timeZoneService?.saveAdditionalTimeZone(additionalTimeZones: additionalTimeZones) { [weak self] in
            self?.loadData()
            if let view = self?.vc?.view.window {
                UDToast.showFailure(with: BundleI18n.Calendar.Calendar_Edit_SaveFailedTip, on: view)
            }
        }
    }
}
