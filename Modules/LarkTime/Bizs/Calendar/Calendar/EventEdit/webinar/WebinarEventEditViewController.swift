//
//  WebinarEventEditViewController.swift
//  Calendar
//
//  Created by huoyunjie on 2023/1/13.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignTabs
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignToast
import RxSwift
import RxCocoa
import LarkContainer

protocol WebinarEventEditViewControllerDelegate: AnyObject {
    func getEventEditViewController() -> EventEditViewController
    func getVCConfigController() -> UIViewController
}

class WebinarEventEditViewController: UIViewController, UserResolverWrapper {

    @ScopedInjectedLazy var calendarDependency: CalendarDependency?

    let userResolver: UserResolver

    weak var delegate: WebinarEventEditViewControllerDelegate?
    /// 页签视图
    private var tabsView = UDTabsTitleView()
    /// 子视图代理
    private(set) var subViewControllers: [UDTabsListContainerViewDelegate] = []
    /// 子视图映射后的视图
    private lazy var listContainerView: UDTabsListContainerView = { UDTabsListContainerView(dataSource: self)
    }()

    private let bag = DisposeBag()

    init(userResolver: UserResolver, title: String = BundleI18n.Calendar.Calendar_Edit_CreateAWebinarPage) {
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
        self.title = title
        view.backgroundColor = UIColor.ud.bgBase
        makeTabsView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNaviBar()
        self.view.addSubview(tabsView)
        self.view.addSubview(listContainerView)

        tabsView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(-4.5)
            make.right.left.equalToSuperview()
            make.height.equalTo(40)
        }

        listContainerView.backgroundColor = EventEditUIStyle.Color.viewControllerBackground
        listContainerView.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.top.equalTo(tabsView.snp.bottom)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (self.navigationController as? LkNavigationController)?.update(style: .custom(UIColor.ud.bgBody))
        prepareSubVC()
    }

    private func setupNaviBar() {
        let backButton = UIBarButtonItem(image: UDIcon.closeSmallOutlined, style: .plain, target: self, action: #selector(handleClosingClick))
        self.navigationItem.leftBarButtonItem = backButton

        let saveButton = LKBarButtonItem(title: BundleI18n.Calendar.Calendar_Common_Save, fontStyle: .medium)
        saveButton.button.tintColor = UIColor.ud.primaryContentDefault
        navigationItem.rightBarButtonItem = saveButton
        saveButton.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let self = self else { return }
                self.doSaveEvent()
            }.disposed(by: bag)
    }

    @objc
    private func handleClosingClick() {
        guard let subVC = subViewControllers.first,
              let eventEditVC = subVC as? EventEditViewController,
              let leftBarBtn = eventEditVC.navigationItem.leftBarButtonItem,
              let closeBtn = leftBarBtn as? LKBarButtonItem else {
            assertionFailure()
            return
        }
        closeBtn.button.sendActions(for: .touchUpInside)
    }

    @objc
    private func doSaveEvent() {
        guard let subVC = subViewControllers.first,
              let eventEditVC = subVC as? EventEditViewController,
              let rightBarBtn = eventEditVC.navigationItem.rightBarButtonItem,
              let saveBtn = rightBarBtn as? LKBarButtonItem else {
            assertionFailure()
            return
        }
        saveBtn.button.sendActions(for: .touchUpInside)
    }

    private func makeTabsView() {
        // 设置单个页签底部的指示器
        let indicator = UDTabsIndicatorLineView()
        indicator.indicatorHeight = 2                   // 设置指示器高度

        // 设置页签视图
        tabsView.titles = [BundleI18n.Calendar.Calendar_Edit_BasicInfo_Menu, BundleI18n.Calendar.Calendar_Edit_MeetSettings_Button]
        tabsView.backgroundColor = EventEditUIStyle.Color.cellBackground
        tabsView.indicators = [indicator]               // 添加指示器
        tabsView.listContainer = listContainerView      // 添加子视图
        tabsView.delegate = self

        // 设置页签外观配置
        let config = tabsView.getConfig()
        config.layoutStyle = .average                   // 每个页签平分屏幕宽度
        config.isItemSpacingAverageEnabled = false      // 当单个页签的宽度超过整体时，是否还平分，默认为 true
        config.itemSpacing = 0                          // 间距，默认为 20
        config.titleNumberOfLines = 0                   // 多行显示
        tabsView.setConfig(config: config)              // 更新配置

        tabsView.addBottomBorder()
    }

    func prepareSubVC() {
        guard let delegate = delegate, subViewControllers.isEmpty else { return }
        let eventEditVC: EventEditViewController = delegate.getEventEditViewController()
        let params: WebinarEventConfigParam
        switch eventEditVC.viewModel.input {
        case .createWebinar:
            params = WebinarEventConfigParam(configJson: nil,
                                             speakerCanInviteOthers: true,
                                             speakerCanSeeOtherSpeakers: true,
                                             audienceCanInviteOthers: true,
                                             audienceCanSeeOtherSpeakers: true)
        case .editWebinar(let pbEvent, _):
            params = WebinarEventConfigParam(
                configJson: pbEvent.webinarInfo.webinarData,
                speakerCanInviteOthers: pbEvent.webinarInfo.conf.speakerCanInviteOthers,
                speakerCanSeeOtherSpeakers: pbEvent.webinarInfo.conf.speakerCanSeeOtherSpeakers,
                audienceCanInviteOthers: pbEvent.webinarInfo.conf.audienceCanInviteOthers,
                audienceCanSeeOtherSpeakers: pbEvent.webinarInfo.conf.audienceCanSeeOtherSpeakers
            )
        default:
            assertionFailure("cannot run here")
            return
        }

        guard let dep = calendarDependency else { return }
        let configVC = TabWrapperViewController(childVC: dep.createWebinarConfigController(param: params), userResolver: self.userResolver)
        eventEditVC.viewModel.webinarDataGetter = { [weak self] in
            dep.getWebinarLocalConfig(vc: configVC.childVC)
        }

        subViewControllers.append(eventEditVC)
        subViewControllers.append(configVC)

        // isModalInPresentation
        if #available(iOS 13.0, *) {
            eventEditVC.viewModel.rxEventHasChanged.subscribeForUI(onNext: { [weak self] in
                self?.isModalInPresentation = $0
            }).disposed(by: eventEditVC.viewModel.disposeBag)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension WebinarEventEditViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        guard let vcNum = self.navigationController?.viewControllers.count,
              vcNum == 1 else {
            return
        }
        self.handleClosingClick()
    }
}

extension WebinarEventEditViewController: UDTabsListContainerViewDataSource {
    func listContainerView(_ listContainerView: UniverseDesignTabs.UDTabsListContainerView, initListAt index: Int) -> UniverseDesignTabs.UDTabsListContainerViewDelegate {
        return subViewControllers[index]
    }

    func numberOfLists(in listContainerView: UniverseDesignTabs.UDTabsListContainerView) -> Int {
        subViewControllers.count
    }
}

extension WebinarEventEditViewController: UDTabsViewDelegate {
    func tabsView(_ tabsView: UniverseDesignTabs.UDTabsView, canClickItemAt index: Int) -> Bool {
        if index == 1,
           let eventEditVC = subViewControllers.first as? EventEditViewController,
           let isVideoMeetingLiving = eventEditVC.viewModel.permissionModel?.rxModel?.value.isVideoMeetingLiving,
           isVideoMeetingLiving {
            UDToast.showTips(with: BundleI18n.Calendar.Calendar_Edit_NoChnageWebinarStarted, on: self.view)
            return false
        }
        CalendarTracerV2.EventFullCreate.traceClick {
            $0.click("switch_tab")
            $0.event_type = "webinar"
            $0.is_new_create = (self.subViewControllers.first as? EventEditViewController)?.viewModel.input.isFromCreating.description ?? "true"
            $0.tab_type = index == 0 ? "basic_info" : "vc_setting"
        }
        return true
    }
}

extension EventEditViewController: UDTabsListContainerViewDelegate {
    func listView() -> UIView {
        self.view
    }
}

fileprivate class TabWrapperViewController: UIViewController, UDTabsListContainerViewDelegate, UserResolverWrapper {
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?

    let userResolver: UserResolver

    let childVC: UIViewController

    init(childVC: UIViewController, userResolver: UserResolver) {
        self.childVC = childVC
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(childVC)
        view.addSubview(childVC.view)
        childVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func listView() -> UIView {
        self.view
    }
}
