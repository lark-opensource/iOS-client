//
//  MeetingRoomOrderViewController.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/2/7.
//

import UIKit
import UniverseDesignIcon
import Foundation
import LarkUIKit
import EENavigator
import LarkRustClient
import RustPB
import ServerPB
import RxSwift
import RoundedHUD
import LarkContainer

final class MeetingRoomOrderViewController: BaseUIViewController, EventEditCoordinatorDelegate, UserResolverWrapper {
    typealias ViewModel = MeetingRoomOrderViewModel

    let userResolver: UserResolver

    @ScopedInjectedLazy var calendarManager: CalendarManager?
    @ScopedInjectedLazy var rustService: RustService?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var calendarInterface: CalendarInterface?

    var settingsService: SettingService?

    private var bag = DisposeBag()
    private var profileJumper: ((String) -> Void)?
    var viewModel: ViewModel
    var originalURL: URL

    private var refreshOnNextAppear = false

    private lazy var loadingView: LoadingPlaceholderView = {
        let loadingView = LoadingPlaceholderView()
        return loadingView
    }()

    private lazy var loadingFailedView: LoadFaildRetryView = {
        let loadingView = LoadFaildRetryView()
        return loadingView
    }()

    private lazy var briefView: MeetingRoomBriefView = {
        let briefView = MeetingRoomBriefView()
        view.addSubview(briefView)
        briefView.layoutMargins.top = 16
        briefView.layoutMargins.bottom = 16
        briefView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        return briefView
    }()

    private lazy var stateView: MeetingRoomStateView = {
        let stateView = MeetingRoomStateView()
        stateView.layoutMargins.top = 16
        stateView.layoutMargins.bottom = 40
        return stateView
    }()

    private lazy var arrangementDetailView: MeetingRoomArrangementDetailView = {
        let arrangementView = MeetingRoomArrangementDetailView()
        arrangementView.layoutMargins = UIEdgeInsets(horizontal: 20, vertical: 20)
        arrangementView.didTapped = { [weak self] model in
            let meetingRoom = model.meetingRoom
            if let self = self {
                CalendarTracer.shared.codeViewCalendar(params: self.viewModel.trackParams)

                var body = CalendarCreateEventBody(meetingRoom: [(meetingRoom, model.building.name, meetingRoom.tenantID)])
                body.attendees = [.meWithMeetingRoom(meetingRoom: meetingRoom)]
                body.perferredScene = .freebusy

                let defaultDuration = TimeInterval(self.settingsService?.getSetting().defaultEventDuration ?? (30 * 24 * 60))
                body.startDate = Date()
                let nextMeetingStartTime = model.calculateCurrentInstanceAndNextInstance().nextMeeting.map { Date(timeIntervalSince1970: TimeInterval($0.0.startTime)) } ?? Date().tomorrow.dayEnd()
                body.endDate = min(Date().addingTimeInterval(defaultDuration * 60), nextMeetingStartTime)
                self.userResolver.navigator.present(body: body, from: self)
                self.refreshOnNextAppear = true
            }
        }
        return arrangementView
    }()

    private lazy var nextMeetingView: MeetingRoomNextMeetingView = {
        let next = MeetingRoomNextMeetingView()
        next.backgroundColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.1)
        return next
    }()

    private lazy var unavailableView: MeetingRoomUnavailableView = {
        let view = MeetingRoomUnavailableView()
        view.layoutMargins.top = 16
        return view
    }()

    private lazy var checkInView: MeetingRoomCheckInView = {
        let view = MeetingRoomCheckInView()
        return view
    }()

    private var activeViews: [UIView] {
        [stateView, checkInView, nextMeetingView]
    }

    init(viewModel: ViewModel, originalURL: URL, userResolver: UserResolver) {
        self.viewModel = viewModel
        self.originalURL = originalURL
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
        SettingService.rxShared().subscribe(onNext: { [weak self] in
            self?.settingsService = $0
        })
        .disposed(by: bag)
        self.profileJumper = { [weak self] chatterID in
            guard let self = self else { return }
            self.calendarDependency?.jumpToPersonCard(chatterID: chatterID, from: self)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        calendarManager?.updateAllCalendar()
        settingsService?.prepare { }

        title = BundleI18n.Calendar.Calendar_MeetingRoom_MeetingRoomCheckIn

        // navigation item
        let closeImage = UDIcon.getIconByKeyNoLimitSize(.closeSmallOutlined).scaleNaviSize().renderColor(with: .primaryOnPrimaryFill)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: closeImage, style: .plain, target: self, action: #selector(MeetingRoomOrderViewController.exit))

        view.backgroundColor = UIColor.ud.primaryContentDefault
        view.layoutMargins.left = 24
        view.layoutMargins.right = 24

        view.addSubview(briefView)
        view.addSubview(stateView)
        view.addSubview(arrangementDetailView)
        view.addSubview(nextMeetingView)
        view.addSubview(unavailableView)
        view.addSubview(checkInView)

        briefView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        stateView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(briefView.snp.bottom)
        }
        arrangementDetailView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        nextMeetingView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(stateView.snp.bottom)
            make.bottom.equalTo(arrangementDetailView.snp.top)
        }
        unavailableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(briefView.snp.bottom)
            make.bottom.equalTo(arrangementDetailView.snp.top)
        }
        checkInView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(stateView.snp.bottom)
            make.bottom.equalTo(arrangementDetailView.snp.top)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(showMeetingRoomDetail))
        briefView.addGestureRecognizer(tap)

        view.addSubview(loadingView)
        loadingView.isHidden = false
        loadingView.snp.makeConstraints { $0.edges.equalToSuperview() }

        view.addSubview(loadingFailedView)
        loadingFailedView.isHidden = true
        loadingFailedView.snp.makeConstraints { $0.edges.equalToSuperview() }
        loadingFailedView.retryAction = { [weak self] in
            self?.loadingView.isHidden = false
            self?.loadingFailedView.isHidden = true
            self?.bind()
        }

        isNavigationBarHidden = false

        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (navigationController as? LkNavigationController)?.update(style: .color(view.backgroundColor ?? .clear))
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.ud.primaryOnPrimaryFill]

        if refreshOnNextAppear {
            refreshOnNextAppear = false
            bind()
        }
    }

    private func bind() {
        bag = DisposeBag()
        viewModel = ViewModel(token: viewModel.token, userResolver: self.userResolver)
        // loading & retry
        viewModel.responseSubject
            .subscribeForUI { [weak self] _ in
                guard let self = self else { return }
                self.loadingView.isHidden = true
                CalendarTracer.shared.codeScan(params: self.viewModel.trackParams)
            } onError: { [weak self] error in
                guard let self = self, let error = error as? RCError else { return }
                RoundedHUD.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_Toast_LoadErrorToast, on: self.view)
                self.loadingView.isHidden = true
                self.loadingFailedView.isHidden = false
            }
            .disposed(by: bag)

        viewModel.responseSubject
            .subscribeForUI(onNext: { [weak self] model in
                guard let self = self else { return }
                let topmost = WindowTopMostFrom(vc: self)
                if model.strategy.status == .inactivated {
                    self.dismiss(animated: false) {
                        var components = URLComponents(url: self.originalURL, resolvingAgainstBaseURL: false)
                        components?.queryItems?.append(URLQueryItem(name: "first_active", value: "1"))
                        if let url = components?.url {
                            self.userResolver.navigator.push(url, from: topmost)
                        }
                    }
                } else if model.strategy.status == .firstActivated {
                    RoundedHUD.showSuccess(with: BundleI18n.Calendar.Calendar_MeetingRoom_QRCodeActivated, on: self.view)
                }
            })
            .disposed(by: bag)

        // 会议室信息 一定显示 与其他数据无关
        viewModel.responseSubject
            .map { ($0.meetingRoom, $0.building) }
            .bind(to: briefView)
            .disposed(by: bag)

        // 整体的背景颜色
        viewModel.responseSubject
            .subscribeForUI(onNext: { [weak self] model in
                if ViewModel.InactiveStatusCalculator.calculate(responseModel: model) != .none {
                    // 禁用
                    self?.updateTheme(backgroundColor: UIColor.ud.N600)
                } else {
                    // 各种可用状态
                    let result = model.calculateCurrentInstanceAndNextInstance()
                    if let current = result.currentMeeting {
                        // 有进行中的日程
                        if result.canCheckInMeetings.contains(where: { $0.0.quadrupleStr == current.0.quadrupleStr }) {
                            // 进行中日程可签到 可签到
                            self?.updateTheme(backgroundColor: UIColor.ud.calTokenSigninBgProcess)
                        } else {
                            // 进行中日程不可签到 使用中
                            self?.updateTheme(backgroundColor: UIColor.ud.calTokenSigninBgUsing)
                        }
                    } else {
                        // 没有进行中的日程 空闲或可签到
                        if result.canCheckInMeetings.isEmpty {
                            // 没有可签到的日程 空闲
                            self?.updateTheme(backgroundColor: UIColor.ud.calTokenSigninBgFree)
                        } else {
                            // 有可签到的日程 可签到
                            self?.updateTheme(backgroundColor: UIColor.ud.calTokenSigninBgProcess)
                        }
                    }
                }
            })
            .disposed(by: bag)

        // 处理会议室禁用情况
        viewModel.responseSubject
            .map { ViewModel.InactiveStatusCalculator.calculate(responseModel: $0) }
            .observeOn(MainScheduler())
            .do(onNext: { [weak self] status in
                if case .none = status {
                    self?.unavailableView.isHidden = true
                } else {
                    self?.unavailableView.isHidden = false
                    self?.activeViews.forEach { $0.isHidden = true }
                }
            })
            .filter { $0 != .none }
            .bind(to: unavailableView)
            .disposed(by: bag)

        viewModel.responseSubject
            .map { model -> MeetingRoomCheckInResponseModel? in
                let invalidStatus = ViewModel.InactiveStatusCalculator.calculate(responseModel: model)
                if invalidStatus == .meetingRoomDisabled || invalidStatus == .qrCodeNotEnable || invalidStatus == .userStrategy {
                    return nil
                }

                // 用户无权限但可 checkIn 时，invalidStatus 为 none，但忙闲入口不展示
                if model.auth == .limitedByUserStrategy {
                    return nil
                }
                return model
            }
            .bind(to: arrangementDetailView)
            .disposed(by: bag)

        viewModel.responseSubject
            .filter { ViewModel.InactiveStatusCalculator.calculate(responseModel: $0) == .none }
            .observeOn(MainScheduler())
            .subscribeForUI(onNext: { [weak self] responseModel in
                let (current, next, checkInList) = responseModel.calculateCurrentInstanceAndNextInstance()
                guard let self = self else { return }
                self.activeViews.forEach { $0.isHidden = false }
                switch (current, next) {
                case (nil, nil):
                    // 没有任何会议
                    self.nextMeetingView.isHidden = true
                    self.checkInView.isHidden = true
                    self.stateView.viewData = .free(until: nil, reservable: responseModel.auth == .authorized, meetingRoom: (responseModel.meetingRoom, responseModel.building.name, responseModel.meetingRoom.tenantID, self.userResolver.userID))
                case let (nil, .some(next)):
                    if checkInList.contains(where: { $0.0.quadrupleStr == next.0.quadrupleStr }) {
                        // 当前无会议 下个会议可签到
                        self.stateView.viewData = .waitingForBegin(startTime: Date(timeIntervalSince1970: TimeInterval(next.0.startTime)),
                                                                   endTime: Date(timeIntervalSince1970: TimeInterval(next.0.endTime)),
                                                                   user: next.0.creator)
                        self.nextMeetingView.isHidden = true
                        self.checkInView.viewData = (next.1.timestamp + responseModel.strategy.durationAfterCheckIn - responseModel.timestamp, responseModel)
                    } else {
                        // 当前无会议 未到下个会议可签到时间
                        self.stateView.viewData = .free(until: Date(timeIntervalSince1970: TimeInterval(next.0.startTime)), reservable: responseModel.auth == .authorized, meetingRoom: (responseModel.meetingRoom, responseModel.building.name, responseModel.meetingRoom.tenantID, self.userResolver.userID))
                        self.nextMeetingView.viewData = (next, responseModel.strategy, responseModel.meetingRoom)
                        self.checkInView.isHidden = true
                    }
                case let (.some(current), nil):
                    self.nextMeetingView.isHidden = true
                    if checkInList.contains(where: { $0.0.quadrupleStr == current.0.quadrupleStr }) {
                        // 正在进行中的会议可签到
                        self.stateView.viewData = .waitingForCheckIn(startTime: Date(timeIntervalSince1970: TimeInterval(current.0.startTime)), endTime: Date(timeIntervalSince1970: TimeInterval(current.0.endTime)),
                                                                     user: current.0.creator)
                        self.checkInView.viewData = (current.1.timestamp + responseModel.strategy.durationAfterCheckIn - responseModel.timestamp, responseModel)
                        self.nextMeetingView.isHidden = true
                    } else {
                        // 正在进行中的会议已经签到
                        self.stateView.viewData = .inUse(startTime: Date(timeIntervalSince1970: TimeInterval(current.0.startTime)),
                                                         endTime: Date(timeIntervalSince1970: TimeInterval(current.0.endTime)),
                                                         user: current.0.creator)
                        self.checkInView.isHidden = true
                        self.nextMeetingView.isHidden = true
                    }
                    break
                case let (.some(current), .some(next)):
                    let currentCanCheckIn = checkInList.contains(where: { $0.0.quadrupleStr == current.0.quadrupleStr })
                    let nextCanCheckIn = checkInList.contains(where: { $0.0.quadrupleStr == next.0.quadrupleStr })

                    switch (currentCanCheckIn, nextCanCheckIn) {
                    case (false, false):
                        // 当前会议进行中 下个会议未到签到时间
                        self.stateView.viewData = .inUse(startTime: Date(timeIntervalSince1970: TimeInterval(current.0.startTime)),
                                                         endTime: Date(timeIntervalSince1970: TimeInterval(current.0.endTime)),
                                                         user: current.0.creator)
                        self.checkInView.isHidden = true
                        self.nextMeetingView.viewData = (next, responseModel.strategy, responseModel.meetingRoom)
                    case (false, true):
                        // 当前会议进行中 下个会议可签到 只显示签到页
                        self.stateView.viewData = .waitingForBegin(startTime: Date(timeIntervalSince1970: TimeInterval(next.0.startTime)), endTime: Date(timeIntervalSince1970: TimeInterval(next.0.endTime)),
                                                                     user: next.0.creator)
                        self.nextMeetingView.isHidden = true
                        self.checkInView.viewData = (next.1.timestamp + responseModel.strategy.durationAfterCheckIn - responseModel.timestamp, responseModel)
                    case (true, _):
                        // 当前会议可签到 下个会议也可签到 只显示当前会议
                        self.stateView.viewData = .waitingForCheckIn(startTime: Date(timeIntervalSince1970: TimeInterval(current.0.startTime)),
                                                                   endTime: Date(timeIntervalSince1970: TimeInterval(current.0.endTime)),
                                                                   user: current.0.creator)
                        self.checkInView.viewData = (current.1.timestamp + responseModel.strategy.durationAfterCheckIn - responseModel.timestamp, responseModel)
                        self.nextMeetingView.isHidden = true
                    }
                }
            })
            .disposed(by: bag)

        viewModel.update()

        stateView.reserveButtonClickedRelay
            .subscribeForUI(onNext: { [weak self] reserveInfo in
                guard let self = self else { return }

                CalendarTracer.shared.codeCreateEvent(params: self.viewModel.trackParams)

                let defaultDuration = TimeInterval(self.settingsService?.getSetting().defaultEventDuration ?? (30 * 24 * 60))
                let nextMeetingStartTime = reserveInfo.nextMeetingStartTime ?? Date().tomorrow.dayEnd()

                let coordinator = self.getCreateEventCoordinator { pointer in
                    pointer.pointee.attendeeSeeds = [.user(chatterId: reserveInfo.creatorID)]
                    pointer.pointee.meetingRooms = [(reserveInfo.fromResource, reserveInfo.buildingName, reserveInfo.tenantId)]
                    pointer.pointee.startDate = Date()
                    pointer.pointee.endDate = min(Date().addingTimeInterval(defaultDuration * 60), nextMeetingStartTime)
                }
                coordinator.delegate = self
                coordinator.start(from: self)
                self.refreshOnNextAppear = true
            })
            .disposed(by: bag)

        checkInView.remainTimeUpRelay
            .subscribeForUI(onNext: { [weak self] in
                self?.bind()
            })
            .disposed(by: bag)

        checkInView.checkInButtonClickedRelay
            .subscribeForUI(onNext: { [weak self] model in
                guard let self = self else { return }
                guard let meetingToCheckIn = model.calculateCurrentInstanceAndNextInstance().canCheckInMeetings.first else {
                    return
                }

                CalendarTracer.shared.codeCheckIn(params: self.viewModel.trackParams)

                var request = ServerPB_Calendarevents_CheckInByQRCodeRequest()
                request.resourceID = model.meetingRoom.id
                request.refID = meetingToCheckIn.0.eventServerID
                request.eventStartTime = meetingToCheckIn.0.startTime
                request.eventEndTime = meetingToCheckIn.0.endTime

                self.rustService?
                    .sendPassThroughAsyncRequest(request, serCommand: .checkInByQrCode, transform: { (response: ServerPB_Calendarevents_CheckInByQRCodeResponse) -> ServerPB_Calendarevents_CheckInByQRCodeResponse.Status in
                        response.checkInResp
                    })
                    .subscribeForUI(onNext: { [weak self] status in
                        if let self = self {
                            switch status {
                            case .success:
                                RoundedHUD.showSuccess(with: BundleI18n.Calendar.Calendar_MeetingRoom_CheckedIn, on: self.view)
                                self.bind()
                            @unknown default:
                                RoundedHUD.showFailure(with: BundleI18n.Calendar.Calendar_MeetingRoom_FailedToCheckIn, on: self.view)
                            }
                        }
                    }, onError: { [weak self] _ in
                        if let self = self {
                            RoundedHUD.showFailure(with: BundleI18n.Calendar.Calendar_MeetingRoom_FailedToCheckIn, on: self.view)
                        }
                    })
                    .disposed(by: self.bag)

            })
            .disposed(by: bag)

        Observable.of(
            stateView.userInfoView.userTappedRelay,
            nextMeetingView.userInfoView.userTappedRelay,
            unavailableView.bottomView.userInfoView.userTappedRelay
        ).merge().subscribeForUI(onNext: { [weak self] chatterID in
            self?.profileJumper?(chatterID)
        }).disposed(by: bag)
    }

    func getCreateEventCoordinator(
        contextBuilder: (UnsafeMutablePointer<EventCreateContext>) -> Void = { _ in }
    ) -> EventEditCoordinator {
        var createContext = EventCreateContext()
        contextBuilder(&createContext)
        return EventEditCoordinator(
            userResolver: self.userResolver,
            editInput: .createWithContext(createContext),
            dependency: EventEditCoordinator.DependencyImpl(userResolver: userResolver),
            actionSource: .qrCode
        )
    }

    private func updateTheme(backgroundColor: UIColor) {
        view.backgroundColor = backgroundColor
        (navigationController as? LkNavigationController)?.update(style: .color(backgroundColor))
    }

    @objc private func showMeetingRoomDetail() {
        guard let calendarID = briefView.viewData?.0.calendarID else { return }
        var context = DetailOnlyContext()
        context.calendarID = calendarID
        let viewModel = MeetingRoomDetailViewModel(input: .detailOnly(context), userResolver: self.userResolver)
        let vc = MeetingRoomDetailViewController(viewModel: viewModel, userResolver: self.userResolver)
        show(vc, sender: self)

        CalendarTracer.shared.calClickMeetingRoomInfoFromQRCode()
    }

    // MARK: - Actions
    @objc private func exit() {
        dismiss(animated: true)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    // MARK: - EventEditCoordinatorDelegate
    func coordinator(_ coordinator: EventEditCoordinator, didSaveEvent pbEvent: Rust.Event, span: Span, extraData: EventEditExtraData?) {
        calendarInterface?.handleCreateEventSucceed(pbEvent: pbEvent, fromVC: self)
        self.refreshOnNextAppear = true
    }
}
