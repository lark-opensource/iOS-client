//
//  CalendarManagerLoadingController.swift
//  Calendar
//
//  Created by harry zou on 2019/3/29.
//

import UIKit
import Foundation
import CalendarFoundation
import LarkKeyCommandKit
import RxSwift
import RustPB
import RoundedHUD
import LarkContainer

final class EditCalendarLoadingController: CalendarController {
    var dependency: CalendarManagerDependency
    var calendarDependency: CalendarDependency
    private var selfCalendarId: String
    private var calendarManangerModel: CalendarManagerModel
    private lazy var subController: CalendarManagerController = {
        return generateSubController(with: calendarManangerModel, dependency: dependency)
    }()

    private lazy var roundedHud = RoundedHUD()
    let disposeBag = DisposeBag()
    private let disappearCallBack: (() -> Void)?

    init(with dependency: CalendarManagerDependency,
         calendarDependency: CalendarDependency,
         selfCalendarId: String,
         disappearCallBack: (() -> Void)?) {
        self.dependency = dependency
        self.calendarDependency = calendarDependency
        self.selfCalendarId = selfCalendarId
        self.disappearCallBack = disappearCallBack
        self.calendarManangerModel = CalendarManagerModel(calendar: dependency.calendar,
                                                          members: [],
                                                          skinType: dependency.skinType,
                                                          selfUserId: dependency.selfUserId)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.Calendar.Calendar_Setting_CalendarSetting
        self.addDismissItem()
        self.view.backgroundColor = UIColor.ud.bgBody
        loadModel()
        CalendarTracerV2.CalendarSetting.traceView {
            $0.calendar_id = self.calendarManangerModel.calendar.serverId
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disappearCallBack?()
    }

    func loadModel() {
        self.addSubviewController(subController: self.subController)

        dependency.api.getCalendars(with: dependency.calendar.serverId,
                                    skinType: dependency.skinType,
                                    selfUserId: dependency.selfUserId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (model) in
                guard let `self` = self else { return }
                self.calendarManangerModel.calendarMembers = model.calendarMembers
                self.calendarManangerModel.calendar = model.calendar
                self.calendarManangerModel.calendarMembersInitiated = true
                self.subController.originalCalendarMember = model.calendarMembers
                self.subController.updateNewModelData()
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                self.roundedHud.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_Common_FailedToLoad, on: self.view)
            }).disposed(by: disposeBag)
    }

    func addSubviewController(subController: CalendarManagerController) {
        self.view.addSubview(subController.view)
        subController.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        subController.setLeftNaviationItem = { [unowned self] leftItem in
            self.navigationItem.leftBarButtonItem = leftItem
        }
        subController.setRightNaviationItem = { [unowned self] rightItem in
            self.navigationItem.rightBarButtonItem = rightItem
        }
        self.addChild(subController)
    }

    func generateSubController(with model: CalendarManagerModel, dependency: CalendarManagerDependency) -> CalendarManagerController {
        let calendar = model.calendar
        let setLeftItem = { [unowned self] item in
            self.navigationItem.leftBarButtonItem = item
        }
        let setRightItem = { [unowned self] item in
            self.navigationItem.rightBarButtonItem = item
        }
        var vcResolver = { () -> CalendarManagerController in
            if calendar.isMyOrOthersPrimaryCalendar() {
                // 我的主日历
                if calendar.serverId == self.selfCalendarId {
                    return MyPrimaryCalendarController(dependency: dependency,
                                                       calendarDependency: self.calendarDependency,
                                                       model: model,
                                                       setLeftNaviationItem: setLeftItem,
                                                       setRightNaviationItem: setRightItem)
                }
                // 我有管理权限的主日历
                if calendar.selfAccessRole == .owner {
                    return OwnedPrimaryCalendarController(dependency: dependency,
                                                          calendarDependency: self.calendarDependency,
                                                          model: model,
                                                          setLeftNaviationItem: setLeftItem,
                                                          setRightNaviationItem: setRightItem)
                }
                // 我订阅的主日历
                return SubscribedPrimaryCalendarController(dependency: dependency,
                                                           calendarDependency: self.calendarDependency,
                                                           model: model,
                                                           setLeftNaviationItem: setLeftItem,
                                                           setRightNaviationItem: setRightItem)
            }
            // 会议室日历
            if calendar.type == .resources {
                return SubscribedMeetingroomCalendarController(dependency: dependency,
                                                               calendarDependency: self.calendarDependency,
                                                               model: model,
                                                               setLeftNaviationItem: setLeftItem,
                                                               setRightNaviationItem: setRightItem)
            }
            // 我有管理权限的共享日历
            if calendar.selfAccessRole == .owner {
                return OwnedSharedCalendarController(dependency: dependency,
                                                     calendarDependency: self.calendarDependency,
                                                     model: model,
                                                     setLeftNaviationItem: setLeftItem,
                                                     setRightNaviationItem: setRightItem)
            }
            // 我订阅的共享日历
            return SubscribedSharedCalendarController(dependency: dependency,
                                                      calendarDependency: self.calendarDependency,
                                                      model: model,
                                                      setLeftNaviationItem: setLeftItem,
                                                      setRightNaviationItem: setRightItem)
        }
        let vc = vcResolver()
        // 标识是日历设置
        vc.inSetting = true
        return vc
    }
}

final class NewCalendarLoadingController: CalendarController {

    private lazy var loadingView = LoadingView(displayedView: self.view)
    var dependency: CalendarManagerDependencyProtocol & AddMemberableDependencyProtocol
    let disposeBag = DisposeBag()
    let showSidebar: () -> Void
    private let disappearCallBack: (() -> Void)?
    private let finishSharingCallBack: ((_ calendar: RustPB.Calendar_V1_Calendar) -> Void)?

    private var shouldShowLoading: Bool = true
    private let summary: String?
    var calendarDependency: CalendarDependency?

    init(dependency: CalendarManagerDependencyProtocol & AddMemberableDependencyProtocol,
         calendarDependency: CalendarDependency?,
         showSidebar: @escaping () -> Void,
         disappearCallBack: (() -> Void)?,
         finishSharingCallBack: ((_ calendar: RustPB.Calendar_V1_Calendar) -> Void)?,
         summary: String? = nil) {
        self.dependency = dependency
        self.showSidebar = showSidebar
        self.disappearCallBack = disappearCallBack
        self.summary = summary
        self.calendarDependency = calendarDependency
        self.finishSharingCallBack = finishSharingCallBack
        super.init(nibName: nil, bundle: nil)
        self.view.backgroundColor = UIColor.ud.bgBody
        self.title = BundleI18n.Calendar.Calendar_Setting_NewCalendar
        self.addDismissItem()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disappearCallBack?()
    }

    override func handleModalDismissKeyCommand() {
        // 重写 cmd + W 快捷键逻辑，取到 AddNewCalendarController 则调用 cancelPressed 来 dismiss
        if let newCalendarVC = children.first as? AddNewCalendarController {
            newCalendarVC.cancelPressed()
        } else {
            super.handleModalDismissKeyCommand()
        }
    }

    private func loadData() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if self.shouldShowLoading {
                self.loadingView.showLoading()
            }
        }
        dependency.api.getCalendarMembers(with: "", userIds: [dependency.selfUserId], chatIds: [])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (memberPBs) in
                let members = memberPBs.map { CalendarMember(pb: $0) }
                guard let userId = members.first?.userID,
                      let `self` = self else {
                    assertionFailureLog()
                    return
                }
                var member = members[0]
                member.accessRole = .owner
                self.shouldShowLoading = false
                self.hideLoading()
                var calendar = CalendarModelFromPb.defaultCalendar(skinType: self.dependency.skinType)
                calendar.userId = self.dependency.selfUserId
                let model = AddNewCalendarViewData(calendar: calendar,
                                                   members: [member],
                                                   skinType: self.dependency.skinType,
                                                   selfUserId: userId)
                if let summary = self.summary {
                    model.calSummary = summary
                }
                guard let calendarDependency = self.calendarDependency else { return }
                let newCalendarVC = AddNewCalendarController(dependency: self.dependency,
                                                             calendarDependency: calendarDependency,
                                                             model: model,
                                                             showSidebar: self.showSidebar, setLeftNaviationItem: { [unowned self]  (leftItem) in
                    self.navigationItem.leftBarButtonItem = leftItem
                }, setRightNaviationItem: { [unowned self] (rightItem) in
                    self.navigationItem.rightBarButtonItem = rightItem
                })
                self.addChild(newCalendarVC)
                self.view.addSubview(newCalendarVC.view)
                newCalendarVC.view.snp.makeConstraints({ (make) in
                    make.edges.equalToSuperview()
                })
            }, onError: { [weak self] (_) in
                self?.showFailed { [weak self] () in
                    self?.loadData()
                }
            }).disposed(by: disposeBag)
    }

    func hideLoading() {
        loadingView.hideSelf()
    }

    func showFailed(withRetry: @escaping () -> Void) {
        loadingView.showFailed(withRetry: withRetry)
    }
}
