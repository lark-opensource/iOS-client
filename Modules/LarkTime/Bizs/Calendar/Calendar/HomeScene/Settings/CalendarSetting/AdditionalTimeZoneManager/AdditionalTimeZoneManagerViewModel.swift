//
//  AdditionalTimeZoneManagerViewModel.swift
//  Calendar
//
//  Created by chaishenghua on 2023/10/19.
//

import Foundation
import ThreadSafeDataStructure
import RxSwift
import RxRelay
import LarkContainer
import Reachability
import UniverseDesignToast
import CTFoundation

class AdditionalTimeZoneManagerViewModel: UserResolverWrapper {
    let userResolver: LarkContainer.UserResolver
    
    typealias Config = AdditionalTimeZone
    @ScopedInjectedLazy private var timeZoneService: TimeZoneService?
    private let provider: SettingPageProvider
    weak var vc: UIViewController?
    private let reachability = Reachability()
    private var viewDatas: [AdditionalTimeZoneViewDataType] = []
    private var additionalTimeZoneListsViewDatas: [AdditionalTimeZoneViewData] = []
    private var addAdditionalTimeZoneViewData = AddAdditionalTimeZoneViewData()
    private let disposebag = DisposeBag()
    private let relay = BehaviorRelay<Void>.init(value: ())
    var additionalTimeZoneObservable: Observable<Void> {
        return self.relay.asObservable()
    }

    init(_ provider: SettingPageProvider,
         userResolver: UserResolver) {
        self.provider = provider
        self.userResolver = userResolver
        self.addAdditionalTimeZoneViewData.clickAction = { [weak self] in
            self?.addAdditionalTimeZoneAction()
        }
        self.additionalTimeZoneListsViewDatas = SettingService.shared().getSetting().additionalTimeZones.compactMap { transform(timeZoneID: $0) }
        self.relay.accept(())
        listenSettingPush()
    }

    private func listenSettingPush() {
        SettingService.shared().updateAdditionalTimeZoneSettingPublish
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.additionalTimeZoneListsViewDatas = SettingService.shared().getSetting().additionalTimeZones
                    .compactMap { self.transform(timeZoneID: $0) }
                self.relay.accept(())
            }).disposed(by: disposebag)
    }

    private func transform(timeZoneID: String) -> AdditionalTimeZoneViewData? {
        guard let timeZone = TimeZone(identifier: timeZoneID) else { return nil }
        return AdditionalTimeZoneViewData(title: timeZone.standardName(for: Date()),
                                          subTitle: timeZone.gmtOffsetDescription,
                                          identifier: timeZone.identifier,
                                          isSelectable: false,
                                          showBottomBorder: true) { [weak self] cell in
            self?.deleteAction(cell: cell)
        }
    }

    private func addAdditionalTimeZoneList(timeZoneID: String) {
        guard let reachability = self.reachability, reachability.isReachable else {
            if let view = self.vc?.view.window {
                UDToast.showFailure(with: BundleI18n.Calendar.Calendar_Notes_ConnectErrorLater, on: view)
            }
            return
        }
        if additionalTimeZoneListsViewDatas.contains(where: { $0.identifier == timeZoneID }) {
            if let view = self.vc?.view.window {
                UDToast.showFailure(with: BundleI18n.Calendar.Calendar_G_TimeZoneAlreadyExists_Toast, on: view)
            }
            return
        }
        guard additionalTimeZoneListsViewDatas.count < Config.maxAdditionalTimeZones,
              let viewData = transform(timeZoneID: timeZoneID) else { return }
        AdditionalTimeZone.logger.info("add additionalTimeZone: \(timeZoneID)")
        self.additionalTimeZoneListsViewDatas.append(viewData)
        self.relay.accept(())
        saveAdditionalTimeZones()
    }

    private func deleteAdditionalTimeZone(at row: Int) {
        guard let reachability = self.reachability, reachability.isReachable else {
            if let view = self.vc?.view.window {
                UDToast.showFailure(with: BundleI18n.Calendar.Calendar_Notes_ConnectErrorLater, on: view)
            }
            return
        }
        guard row < additionalTimeZoneListsViewDatas.count else { return }
        AdditionalTimeZone.logger.info("delete additionalTimeZone: \(additionalTimeZoneListsViewDatas[row].identifier)")
        additionalTimeZoneListsViewDatas.remove(at: row)
        self.relay.accept(())
        saveAdditionalTimeZones()
    }

    private func saveAdditionalTimeZones() {
        provider.setAdditionalTimeZoneList(additionalTimeZones: additionalTimeZoneListsViewDatas.map { $0.identifier }) { [weak self] setting in
            guard let self = self else { return }
            self.additionalTimeZoneListsViewDatas = setting.additionalTimeZones.compactMap { self.transform(timeZoneID: $0) }
            if let view = self.vc?.view.window {
                UDToast.showFailure(with: BundleI18n.Calendar.Calendar_Edit_SaveFailedTip, on: view)
            }
            self.relay.accept(())
        }
    }

    func numberOfRows() -> Int {
        return self.additionalTimeZoneListsViewDatas.count + 1
    }

    func additionalTimeZoneListsCount() -> Int {
        return self.additionalTimeZoneListsViewDatas.count
    }

    func cellData(at row: Int) -> AdditionalTimeZoneViewDataType? {
        if row < additionalTimeZoneListsViewDatas.count {
            return additionalTimeZoneListsViewDatas[row]
        } else if row == additionalTimeZoneListsViewDatas.count {
            return addAdditionalTimeZoneViewData
        }
        return nil
    }

    func getCellHeight(at row: Int) -> CGFloat {
        if row < additionalTimeZoneListsViewDatas.count {
            return AdditionalTimeZoneUIStyle.Setting.additonalTimeZoneCellHeight
        } else {
            return AdditionalTimeZoneUIStyle.Setting.addAdditionalTimeZoneHeight
        }
    }

    func deleteAction(cell: UITableViewCell) {
        guard let vc = vc as? AdditionalTimeZoneManagerViewController else { return }
        guard let indexPath = vc.getCellIndexPath(cell: cell) else { return }
        deleteAdditionalTimeZone(at: indexPath.row)
    }

    func addAdditionalTimeZoneAction() {
        guard let vc = vc,
              let timeZoneService = self.timeZoneService else { return }
        if additionalTimeZoneListsViewDatas.count >= Config.maxAdditionalTimeZones {
            UDToast.showFailure(with: BundleI18n.Calendar.Calendar_Timezon_MaxTimeZoneLimit(limit: Config.maxAdditionalTimeZones),
                                on: vc.view)
        } else {
            let selectVC = TimeZoneSearchSelectViewController(service: timeZoneService, anchorDate: Date())
            selectVC.onTimeZoneSelect = { [weak self, weak selectVC] timeZoneModel in
                guard let self = self else { return }
                self.addAdditionalTimeZoneList(timeZoneID: timeZoneModel.identifier)
                selectVC?.dismiss(animated: true)
            }
            vc.present(PopupViewController(rootViewController: selectVC), animated: true, completion: nil)
        }
    }
}
