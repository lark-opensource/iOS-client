//
//  SendReceiveViewController.swift
//  LarkFinance
//
//  Created by SuPeng on 12/25/18.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift
import LarkModel
import EENavigator
import UniverseDesignActionPanel
import UniverseDesignFont
import UniverseDesignDatePicker
import UniverseDesignTabs
import UniverseDesignToast
import LarkSDKInterface
import LarkMessengerInterface
import LarkContainer

enum SendReceiveType {
    case send
    case receive
}

final class SendReceiveViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UserResolverWrapper {

    var userResolver: LarkContainer.UserResolver
    private let type: SendReceiveType
    private let currentUserID: String
    private let currentUserAvatarKey: String
    private let redPacketAPI: RedPacketAPI
    private var historyData: RedPacketHistoryDataSource?

    private let tableView = UITableView()
    private let headerView = RedPacketHistoryTableHeaderView()
    private var emptyDataView: RedPacketHistoryNoDataView?

    private let disposeBag = DisposeBag()

    init(type: SendReceiveType,
         currentUserID: String,
         currentUserAvatarKey: String,
         redPacketAPI: RedPacketAPI,
         userResolver: UserResolver) {
        self.type = type
        self.currentUserID = currentUserID
        self.currentUserAvatarKey = currentUserAvatarKey
        self.redPacketAPI = redPacketAPI
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        isNavigationBarHidden = true
        view.backgroundColor = UIColor.ud.bgBase

        headerView.delegate = self
        headerView.setContent(entityId: currentUserID, avatarKey: currentUserAvatarKey, descriptionText: nil, sumOfMoney: nil)
        headerView.sizeToFit()
        tableView.tableHeaderView = headerView

        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 64
        tableView.separatorStyle = .none
        tableView.lu.register(cellSelf: RedPacketHistoryTableViewCell.self)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        tableView.insetsContentViewsToSafeArea = false // 底部不漏出颜色

        requestRecord(year: Date().year, cursor: "")
    }

    private func reloadTable() {
        emptyDataView?.removeFromSuperview()
        if let historyData = historyData {
            if historyData.historyRecords.isEmpty {
                let emptyDataView = RedPacketHistoryNoDataView(type: type)

                let convertedFrame = tableView.convert(headerView.bounds, from: headerView)
                emptyDataView.frame = CGRect(x: 0,
                                             y: convertedFrame.maxY,
                                             width: tableView.bounds.width,
                                             height: tableView.bounds.height - convertedFrame.maxY)
                self.emptyDataView = emptyDataView
                tableView.addSubview(emptyDataView)
            }
        }
        tableView.reloadData()
    }

    private func requestRecord(year: Int, cursor: String) {
        let hud = UDToast.showLoading(on: view)

        let ob: Observable<RedPacketHistoryDataSource>
        switch type {
        case .receive:
            ob = redPacketAPI.grabRedPacketRecords(year: year, cursor: cursor, count: 20)
                .map { $0 as RedPacketHistoryDataSource }
        case .send:
            ob = redPacketAPI.sendRedPacketRecords(year: year, cursor: cursor, count: 20)
                .map { $0 as RedPacketHistoryDataSource }
        }

        ob
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (result) in
                guard let self = self else { return }
                if let historyData = self.historyData,
                    historyData.year == result.year,
                    !historyData.nextCursor.isEmpty,
                    historyData.nextCursor == result.currentCursor {
                    var newHistoryData = result
                    newHistoryData.historyRecords = historyData.historyRecords + result.historyRecords
                    self.historyData = newHistoryData
                } else {
                    self.historyData = result
                }

                let descriptionTextPrefix: String
                switch self.type {
                case .receive:
                    descriptionTextPrefix = BundleI18n.LarkFinance.Lark_Legacy_HistoryTotalGrabPrefix
                case .send:
                    descriptionTextPrefix = BundleI18n.LarkFinance.Lark_Legacy_HistoryTotalSendPrefix
                }
                let descriptionTextSuffix = BundleI18n.LarkFinance.Lark_Legacy_HistoryTotalSuffix
                self.headerView.setContent(entityId: self.currentUserID,
                                           avatarKey: self.currentUserAvatarKey,
                                           descriptionText: descriptionTextPrefix + "\(result.totalNumber)" + descriptionTextSuffix,
                                           sumOfMoney: result.totalAmount)
                self.headerView.set(year: year)
                self.headerView.sizeToFit()
                self.reloadTable()
                if result.hasMore {
                    self.tableView.addBottomLoadMoreView { [weak self] in
                        self?.requestRecord(year: result.year, cursor: result.nextCursor)
                    }
                    self.tableView.tableFooterView = nil
                } else {
                    self.tableView.removeBottomLoadMore()
                }
                hud.remove()
            }, onError: { [weak self] error in
                hud.remove()
                if let view = self?.view {
                    UDToast.showFailure(with: BundleI18n.LarkFinance.Lark_Legacy_UnknownError, on: view, error: error)
                }
            })
            .disposed(by: disposeBag)
    }
    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historyData?.historyRecords.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: RedPacketHistoryTableViewCell.self))
        guard
            let historyCell = cell as? RedPacketHistoryTableViewCell,
            let record = historyData?.historyRecords[indexPath.row] else {
                return UITableViewCell()
        }

        historyCell.setContent(record: record)
        return historyCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: false)
        guard let record = historyData?.historyRecords[indexPath.row] else {
            return
        }
        guard let window = view.window else { return }
        let hud = UDToast.showLoading(on: window, disableUserInteraction: true)

        let infoOb = redPacketAPI.getRedPaketInfo(
            redPacketID: record.redPacketID)
        let receiveOb = redPacketAPI.getRedPacketReceiveDetail(
            redPacketID: record.redPacketID,
            type: .unknown,
            cursor: "",
            count: 20)
        Observable.zip(infoOb, receiveOb)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (infoResponse, detailResponse) in
                guard let `self` = self else {
                    return
                }
                let body = RedPacketResultBody(redPacketInfo: infoResponse, receiveInfo: detailResponse)
                self.userResolver.navigator.presentOrPush(body: body, wrap: LkNavigationController.self, from: self, prepareForPresent: {
                    $0.modalPresentationStyle = .formSheet
                })
                hud.remove()
            }, onError: { [weak self] (error) in
                let serverMessage = (error.underlyingError as? APIError)?.displayMessage ?? ""
                let errorMessage = serverMessage.isEmpty ? BundleI18n.LarkFinance.Lark_Legacy_UnknownError : serverMessage
                if let view = self?.view {
                    hud.showFailure(with: errorMessage, on: view)
                } else {
                    hud.remove()
                }
            })
            .disposed(by: disposeBag)
    }
}

extension SendReceiveViewController: RedPacketHistoryTableHeaderViewDelegate {
    func headerView(_ headerView: RedPacketHistoryTableHeaderView, didTapped year: Int) {
        let selectedYear = Date(year: year, month: 1, day: 1)
        let startYear = Date(year: redPacketServiceStartYear, month: 1, day: 1)
        let config = UDWheelsStyleConfig(mode: .year, maxDisplayRows: 5, textFont: UDFont.title4)
        let datePicker = UDDateWheelPickerViewController(customTitle: "",
                                                         date: selectedYear,
                                                         maximumDate: Date(),
                                                         minimumDate: startYear,
                                                         timeZone: .current,
                                                         wheelConfig: config)

        let actionPanel = UDActionPanel(
            customViewController: datePicker,
            config: UDActionPanelUIConfig(
                originY: UIScreen.main.bounds.height - datePicker.intrinsicHeight,
                canBeDragged: false
            )
        )
        datePicker.confirm = { [weak actionPanel, weak self] date in
            let year = date.year
            actionPanel?.dismiss(animated: true, completion: { [weak self] in
                self?.requestRecord(year: year, cursor: "")
            })
        }
        present(actionPanel, animated: true, completion: nil)
    }
}
