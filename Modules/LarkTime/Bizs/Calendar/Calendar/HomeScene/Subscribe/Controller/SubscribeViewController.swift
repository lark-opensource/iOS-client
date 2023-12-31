//
//  SubscribeViewController.swift
//  CalendarDemo
//
//  Created by heng zhu on 2019/1/9.
//  Copyright © 2019 EE. All rights reserved.
//

import UniverseDesignIcon
import Foundation
import CalendarFoundation
import UIKit
import SnapKit
import LarkUIKit
import RxSwift
import LarkContainer

public final class SubscribeViewController: UIViewController, UserResolverWrapper {

    public let userResolver: UserResolver

    private lazy var peopleVC: PeopleCalendarViewController = {
        return PeopleCalendarViewController(userResolver: self.userResolver)
    }()
    private lazy var meetingVC: SubscribeCalendarBase = {
        let viewModel = MeetingRoomContainerViewModel(userResolver: userResolver,
                                                      tenantID: currentTenantID,
                                                      multiLevelResources: multiLevelResources,
                                                      actionSource: .calSubscribe)
        let vc = SubscribeMeetingRoomContainer(userResolver: userResolver,
                                               viewModel: viewModel,
                                               meetingRoomApi: calendarApi,
                                               tenantID: currentTenantID)
        vc.equipmentFilterClick = { [weak self] in
            guard let self = self else { return }
            self.view.endEditing(true)
        }
        return vc
    }()
    private lazy var calendarVC: PublicCalendarViewController = {
        return PublicCalendarViewController(calendarApi: calendarApi, userResolver: self.userResolver)
    }()

    private lazy var searchView: SearchView = {
        let view = SearchView(textChanged: { [unowned self] (string) in

            self.currentVC.searchText = string
        })
        return view
    }()

    private lazy var segmentViewTitles: [String] = {
        return [BundleI18n.Calendar.Calendar_Detail_Contacts,
                BundleI18n.Calendar.Calendar_Common_Room,
                BundleI18n.Calendar.Calendar_SubscribeCalendar_Public]
    }()
    private lazy var segmentView: SegmentView = {
        let view = SegmentView(items: segmentViewTitles)
        view.addTarget(self, action: #selector(segmentViewChanged(segmentView:)), for: .valueChanged)
        return view
    }()
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = false
        scrollView.backgroundColor = UIColor.ud.bgBody
        scrollView.delegate = self
        return scrollView
    }()
    var currentPageIdx: Int = 0 {
        didSet {
            currentVC.searchText = searchView.text
            scrollView.setContentOffset(CGPoint(x: scrollView.frame.size.width * CGFloat(currentPageIdx), y: 0), animated: true)
        }
    }

    var currentVC: SubscribeCalendarBase {
        guard let vc = children[currentPageIdx] as? SubscribeCalendarBase else {
            assertionFailure("invalid status")
            return peopleVC
        }
        return vc
    }

    let calendarApi: CalendarRustAPI?
    let currentTenantID: String
    let multiLevelResources: Bool
    private let disappearCallBack: (() -> Void)?
    init(userResolver : UserResolver,
         calendarApi: CalendarRustAPI?,
         currentTenantID: String,
         disappearCallBack: (() -> Void)?) {
        self.userResolver = userResolver
        self.calendarApi = calendarApi
        self.currentTenantID = currentTenantID
        let tenantSetting = SettingService.shared().tenantSetting ?? SettingService.defaultTenantSetting
        self.multiLevelResources = tenantSetting.resourceDisplayType == .hierarchical && FG.multiLevel
        self.disappearCallBack = disappearCallBack
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func segmentViewChanged(segmentView: SegmentView) {
        currentPageIdx = segmentView.selectedIndex
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        if Display.pad {
            self.modalPresentationControl.dismissEnable = true
        }
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationBar.isTranslucent = false
        title = BundleI18n.Calendar.Calendar_SubscribeCalendar_SubscribeCalendar
        addChild(peopleVC)
        addChild(meetingVC)
        addChild(calendarVC)
        layout(searchView: searchView, in: view)
        layout(segmentView: segmentView, in: view)
        layout(scrollView: scrollView, in: view)
        layout(peopleView: peopleVC.view,
               meetingView: meetingVC.view,
               calendarView: calendarVC.view,
               in: scrollView)
        addCloseBtn()
        loadRecentData()
        CalendarTracerV2.CalendarSubscribe.traceView()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.modalPresentationControl.readyToControlIfNeeded()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disappearCallBack?()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    private func addCloseBtn() {
        let closeBarButton: LKBarButtonItem
        closeBarButton = LKBarButtonItem(image: UDIcon.getIconByKeyNoLimitSize(.closeSmallOutlined).scaleNaviSize().renderColor(with: .n1))
        closeBarButton.button.addTarget(self,
                                        action: #selector(dismissSelf),
                                        for: .touchUpInside)
        navigationItem.leftBarButtonItem = closeBarButton
    }

    @objc
    fileprivate func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }

    private func loadRecentData() {
        peopleVC.searchText = ""
        meetingVC.searchText = ""
        calendarVC.searchText = ""
    }

    private func layout(peopleView: UIView, meetingView: UIView, calendarView: UIView, in superView: UIView) {
        superView.addSubview(peopleView)
        superView.addSubview(meetingView)
        superView.addSubview(calendarView)
        peopleView.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.width.height.equalToSuperview()
            make.right.equalTo(meetingView.snp.left)
        }

        meetingView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.width.height.equalToSuperview()
            make.right.equalTo(calendarView.snp.left)
        }
        meetingView.clipsToBounds = true

        calendarView.snp.makeConstraints { (make) in
            make.top.bottom.right.equalToSuperview()
            make.width.height.equalToSuperview()
        }
    }

    override public func viewDidLayoutSubviews() {
        // 重新计算slidingView的宽度
        segmentView.slidingView.frame.size.width = view.frame.width / CGFloat(segmentViewTitles.count)
        // iPad首次进入分屏状态不会触发viewWillTransition方法，只好再这里调用一次
        resetScrollViewOffset(animated: true)
        // 使slidingView复位
        scrollViewDidScroll(scrollView)

        super.viewDidLayoutSubviews()
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let `self` = self else { return }
            // 不要开启动画效果，否则页面会闪
            self.resetScrollViewOffset(animated: false)
        }, completion: nil)
    }

    private func resetScrollViewOffset(animated: Bool) {
        scrollView.setContentOffset(CGPoint(x: view.frame.width * CGFloat(self.currentPageIdx), y: 0), animated: animated)
    }

    private func layout(searchView: UIView, in superView: UIView) {
        superView.addSubview(searchView)
        searchView.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(45)
        }
    }

    private func layout(segmentView: UIView, in superView: UIView) {
        superView.addSubview(segmentView)
        segmentView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(searchView.snp.bottom)
            make.height.equalTo(40)
        }
    }

    private func layout(scrollView: UIView, in superView: UIView) {
        superView.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(segmentView.snp.bottom)
        }
    }
}

extension SubscribeViewController: UIScrollViewDelegate {

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let currentPageIdx = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        self.currentPageIdx = currentPageIdx
        segmentView.setSelectedIndex(currentPageIdx, animated: true)
    }
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.frame.size.width != 0 else {
            segmentView.updateSlidingProgress(0)
            return
        }
        let progress = scrollView.contentOffset.x / (scrollView.frame.size.width * CGFloat(segmentViewTitles.count - 1))
        segmentView.updateSlidingProgress(progress)
    }
}
