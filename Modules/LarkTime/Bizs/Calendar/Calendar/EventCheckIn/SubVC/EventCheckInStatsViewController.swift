//
//  EventCheckInStatusViewController.swift
//  Calendar
//
//  Created by huoyunjie on 2022/9/19.
//

import Foundation
import ServerPB
import RxSwift
import RxCocoa
import LarkContainer
import EENavigator
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignButton
import UniverseDesignTabs
import UniverseDesignIcon
import UIKit
import UniverseDesignEmpty

extension EventCheckInStatsViewController: UDTabsListContainerViewDelegate {
    func listView() -> UIView {
        return self.view
    }
}

class EventCheckInStatsViewController: UIViewController, UserResolverWrapper {

    typealias CheckInStats = ServerPB_Calendarevents_GetEventCheckInInfoResponse.CheckInStats

    private let disposeBag = DisposeBag()

    private let rxCheckInStats: BehaviorRelay<CheckInStats> = .init(value: CheckInStats())

    private let signedView: CheckInStatsView = CheckInStatsView(title: I18n.Calendar_Event_CheckedInNum)

    private let attendeeView: CheckInStatsView = CheckInStatsView(title: I18n.Calendar_Detail_Guests)

    private lazy var bitableUrlView: UDButton = {
        let button = UDButton(.secondaryBlue)
        button.config.type = .big
        button.setTitle(I18n.Calendar_Event_CheckInStatsDetails, for: .normal)
        button.setImage(UDIcon.fileLinkBitableOutlined.ud.withTintColor(UDColor.primaryContentDefault), for: .normal)
        button.addTarget(self, action: #selector(clickBitableUrl), for: .touchUpInside)
        return button
    }()

    private lazy var loadingView: LoadingView = {
        let loadingView = LoadingView(displayedView: self.view)
        loadingView.backgroundColor = self.view.backgroundColor
        return loadingView
    }()

    private let viewModel: EventCheckInInfoViewModel

    // 埋点需要
    private var eventID: String = ""
    private let startTime: Int64

    let userResolver: UserResolver

    init(viewModel: EventCheckInInfoViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = userResolver
        self.startTime = viewModel.startTime
        super.init(nibName: nil, bundle: nil)
        self.setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        loadingView.showLoading()
        self.loadData()
            .subscribeForUI(onNext: { [weak self] status in
                self?.rxCheckInStats.accept(status)
                self?.loadingView.remove()
                CalendarTracerV2.CheckInfo.traceClick {
                    $0.click("stat").target("none")
                    $0.mergeEventCommonParams(commonParam: CommonParamData(calEventId: self?.eventID,
                                                                           eventStartTime: self?.viewModel.startTime.description,
                                                                           originalTime: self?.viewModel.originalTime.description,
                                                                           uid: self?.viewModel.key))
                }
                self?.startPoll()
            }, onError: { [weak self] error in
                if error.errorType() == .calendarEventCheckInApplinkNoPermission {
                    self?.loadingView.show(image: UDEmptyType.noAccess.defaultImage(), title: I18n.Calendar_Event_NoPermitView)
                } else {
                    self?.loadingView.showFailed { [weak self] in
                        self?.setup()
                    }
                }
            })
            .disposed(by: disposeBag)
    }

    private func loadData() -> Observable<CheckInStats> {
        return self.viewModel.getEventCheckInInfo(condition: [.stats])
            .map({ [weak self] res in
                self?.eventID = String(res.eventID)
                return res.checkInStats
            })
    }

    private func startPoll() {
        Observable<Int>.interval(.milliseconds(2000), scheduler: MainScheduler.asyncInstance)
            .flatMap { [weak self] _ -> Observable<CheckInStats> in
                guard let self = self else { return .empty() }
                return self.loadData()
            }
            .bind(to: rxCheckInStats)
            .disposed(by: disposeBag)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UDColor.bgBase

        let splitView = UIView()
        splitView.backgroundColor = UDColor.lineDividerDefault

        let container = UIView()
        container.backgroundColor = UDColor.bgFloat
        container.layer.cornerRadius = 12

        view.addSubview(container)
        container.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(80)
            make.right.left.equalToSuperview().inset(24)
        }

        container.addSubview(signedView)
        container.addSubview(attendeeView)
        container.addSubview(splitView)

        signedView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(32)
            make.left.equalToSuperview()
            make.right.equalTo(splitView.snp.left)
        }

        attendeeView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(32)
            make.right.equalToSuperview()
            make.left.equalTo(splitView.snp.right)
        }

        splitView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.height.equalTo(51)
            make.width.equalTo(1)
        }

        view.addSubview(bitableUrlView)
        bitableUrlView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(24)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).inset(12)
        }

        bindRxCheckInStats()
    }

    private func bindRxCheckInStats() {
        self.rxCheckInStats
            .subscribeForUI(onNext: { [weak self] stats in
                self?.signedView.setNumber(stats.signedInCount)
                self?.attendeeView.setNumber(stats.attendeeCount)
            }).disposed(by: disposeBag)
    }

    @objc
    private func clickBitableUrl() {
        guard var url = URL(string: rxCheckInStats.value.bitableURL),
              let topVC = userResolver.navigator.mainSceneTopMost else { return }
        CalendarTracerV2.CheckInfo.traceClick {
            $0.click("stat_info").target("none")
            $0.mergeEventCommonParams(commonParam: CommonParamData(calEventId: eventID,
                                                                   eventStartTime: viewModel.startTime.description,
                                                                   originalTime: viewModel.originalTime.description,
                                                                   uid: viewModel.key))
        }
        let type = "from_lark_vc_stats_checkin"
        url = url.append(parameters: ["ccm_open_type": type, "from": type])
        userResolver.navigator.present(url, from: topVC)
    }
}

fileprivate class CheckInStatsView: UIView {
    private let numberLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.cd.dinBoldFont(ofSize: 36)
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UDFont.body2
        label.textColor = UDColor.textCaption
        return label
    }()

    init(title: String) {
        super.init(frame: .zero)

        self.numberLabel.text = "0"
        self.titleLabel.text = title

        let stackView = UIStackView(arrangedSubviews: [numberLabel, titleLabel])
        stackView.spacing = 4
        stackView.axis = .vertical
        stackView.alignment = .center

        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setNumber(_ number: Int64) {
        self.numberLabel.text = String(number)
    }
}
