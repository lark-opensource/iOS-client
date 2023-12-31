//
//  EventDetailViewController.swift
//  Calendar
//
//  Created by Rico on 2021/3/15.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RxRelay
import CalendarFoundation
import LarkCombine
import UniverseDesignColor
import UniverseDesignToast
import LarkContainer
import FigmaKit

final class EventDetailViewController: CalendarController {

    private let viewModel: EventDetailViewModel
    private let rxBag = DisposeBag()
    private var bag: Set<AnyCancellable> = []

    private let backgroundView = UIView()

    // scrollView自动吸附
    private let debounce = Debouncer(delay: 0.1)

    init(viewModel: EventDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        viewModel.unRisterActiveEvent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        isNavigationBarHidden = true

        layoutSelf()
        layoutBackground()
        layoutNavigationHeader()
        loadSpace(navigationSpace, resolvedView: navigationImageWrapperView)

        layoutBottomActionBar()
        loadSpace(bottomActionSpace, resolvedView: bottomActionWrapperView)

        layoutScrollView()
        loadSpace(headerSpace, resolvedView: headerViewWrapper)
        loadSpace(detailTableSpace, resolvedView: stackView)

        bindViewModel()
        bindView()
        bindState()

        viewModel.traceShow()
        viewModel.registerActiveEvent()

    }

    private func bindViewModel() {

        viewModel.rxModel.skip(1)
            .subscribeForUI(onNext: { [weak self] model in
                guard let self = self else { return }
                EventDetail.logInfo("EventDetailVC rxModel update")

                // 更新背景颜色
                if let colors = self.auroraView?.configuration.colors,
                   colors != model.auroraColor.backgroundColors {
                    let auroraView = self.getAuroraViewView(auroraColors: model.auroraColor.backgroundColors,
                                                            auroraOpacity: model.auroraColor.auroraOpacity)
                    self.setBackground(subView: auroraView)
                }

                // 刷底部栏
                for view in self.bottomActionWrapperView.subviews {
                    view.removeFromSuperview()
                }
                self.bottomActionSpace.reloadComponents()
                self.bottomActionSpace.resolveRootView(self.bottomActionWrapperView)

                self.layoutScrollViewTopBottom()
                // 刷新整个Table重新创建对象，可以优化
                self.stackView.clearSubviews()
                self.detailTableSpace.reloadComponents()
                self.detailTableSpace.resolveRootView(self.stackView)

            }).disposed(by: rxBag)

        viewModel.rxToast.bind(to: rx.toast).disposed(by: rxBag)
    }

    private func bindView() {
        #if !LARK_NO_DEBUG
        addDebugGesture()
        #endif
    }

    private func bindState() {

        viewModel.state.$headerHeight
            .receive(on: DispatchQueue.main.ocombine)
            .sink { [weak self] height in
                EventDetail.logInfo("headerHeight changed: \(height)")
                if height > 0 {
                    guard let self = self else { return }
                    self.updateHeaderViewHeight(height)
                }
            }.store(in: &bag)
    }

    // MARK: Lazy Load View

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()

    private lazy var headerViewWrapper: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var navigationImageWrapperView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var bottomActionWrapperView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.isDirectionalLockEnabled = true
        scrollView.bounces = false
        scrollView.isScrollEnabled = true
        scrollView.backgroundColor = UIColor.clear
        scrollView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        scrollView.delegate = self
        return scrollView
    }()

    private lazy var scrollViewWrapper: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var navigationSpace: EventDetailNavigationSpace = {
        let space = EventDetailNavigationSpace(viewController: self, componentProvider: viewModel, state: viewModel.state)
        return space
    }()

    private lazy var headerSpace: EventDetailHeaderSpace = {
        let space = EventDetailHeaderSpace(viewController: self, componentProvider: viewModel, eventDetailState: viewModel.state)
        return space
    }()

    private lazy var detailTableSpace: EventDetailTableSpace = {
        let space = EventDetailTableSpace(viewController: self, componentProvider: viewModel)
        return space
    }()

    private lazy var bottomActionSpace: EventDetailBottomActionSpace = {
        let space = EventDetailBottomActionSpace(viewController: self, componentProvider: viewModel)
        return space
    }()

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        navigationSpace.manager.dispatchLifeCycle(.didLayoutSubviews)
        headerSpace.manager.dispatchLifeCycle(.didLayoutSubviews)
        detailTableSpace.manager.dispatchLifeCycle(.didLayoutSubviews)
        bottomActionSpace.manager.dispatchLifeCycle(.didLayoutSubviews)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.endLoadUITrack()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        CalendarMonitorUtil.endTrackEventDetailView()
    }
}

extension EventDetailViewController {
    private func loadSpace<Space: ViewSpaceType>(_ space: Space, resolvedView: UIView) {
        space.loadComponents()
        space.resolveRootView(resolvedView)
    }
}

// Layout UI
extension EventDetailViewController {
    private func layoutSelf() {
        view.backgroundColor = UDColor.bgBody
    }

    private func layoutBackground() {
        view.insertSubview(backgroundView, at: 0)
        backgroundView.snp.makeConstraints { $0.edges.equalToSuperview() }
        let auroraView = getAuroraViewView(auroraColors: viewModel.auroraColor.backgroundColors,
                                           auroraOpacity: viewModel.auroraColor.auroraOpacity)
        setBackground(subView: auroraView)
    }

    private func layoutNavigationHeader() {
        view.addSubview(navigationImageWrapperView)
        navigationImageWrapperView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
        }
    }

    private func layoutBottomActionBar() {
        view.addSubview(bottomActionWrapperView)
        bottomActionWrapperView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-60)
        }
    }

    private func layoutScrollView() {
        view.addSubview(scrollView)
        let wrapper = scrollViewWrapper
        scrollView.addSubview(wrapper)

        layoutScrollViewTopBottom()

        wrapper.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
            make.height.greaterThanOrEqualTo(scrollView)
        }

        wrapper.addSubview(headerViewWrapper)
        headerViewWrapper.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
        }

        let detailTableWrapper = UIView()
        detailTableWrapper.backgroundColor = .clear
        wrapper.insertSubview(detailTableWrapper, at: 0)
        detailTableWrapper.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(headerViewWrapper.snp.bottom)
        }
        detailTableWrapper.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(4)  // offset 是为了满足 detailTable 上方 view 的距离：header 展开时 30，header 收起时距 navbar 24
            make.bottom.lessThanOrEqualToSuperview()
        }

        view.bringSubviewToFront(bottomActionWrapperView)

        navigationImageWrapperView.snp.remakeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(headerViewWrapper).offset(EventDetail.navigationBarHeight)
        }
    }

    private func layoutScrollViewTopBottom() {
        let topTarget: SnapKit.ConstraintRelatableTarget
        if let navigationBar = navigationSpace.view(for: .navigationBar) {
            topTarget = navigationBar.snp.bottom
        } else {
            topTarget = 64
            assertionFailure("navigation bar not exist! cannot make constraints use default height 64")
        }

        let bottomTarget: SnapKit.ConstraintRelatableTarget
        if let actionBar = bottomActionSpace.view(for: .bottomActionBar) {
            bottomTarget = actionBar.snp.top
        } else {
            bottomTarget = self.view.safeAreaLayoutGuide.snp.bottom
        }

        scrollView.snp.remakeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(topTarget)
            make.bottom.equalTo(bottomTarget).offset(-10)
        }
    }

    private func updateHeaderViewHeight(_ height: CGFloat) {

        // scrollView 同步增加高度，保证头部视图上滑可以完全隐藏
        scrollViewWrapper.snp.remakeConstraints { (make) in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
            make.height.greaterThanOrEqualTo(scrollView).offset(height)
        }
    }
}

// ScrollView自动吸附
extension EventDetailViewController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        hideMenuController()
        let progress = scrollView.contentOffset.y / 40.0
        viewModel.state.headerViewOpaque = progress
        viewModel.state.navigationTitleAlpha = scrollView.contentOffset.y / 26.0
        debounce.call { [weak self] in
            self?.checkMiddleStatus(scrollView: scrollView)
        }
    }

    private func checkMiddleStatus(scrollView: UIScrollView) {
        if scrollView.isTracking {
            debounce.call { [weak self] in
                self?.checkMiddleStatus(scrollView: scrollView)
            }
            return
        }
        let contentOffsetY = scrollView.contentOffset.y
        let shouldPackDown = contentOffsetY < headerHeight / 2.0
        if shouldPackDown {
            scrollViewAnimation(scrollView: scrollView,
                                contentOffset: CGPoint(x: 0, y: 0),
                                progress: 0.0)
            return
        }
        if contentOffsetY > headerHeight / 2.0 && contentOffsetY < headerHeight {
            scrollViewAnimation(scrollView: scrollView,
                                contentOffset: CGPoint(x: 0, y: headerHeight),
                                progress: 1.0)
            return
        }
    }

    private func scrollViewAnimation(scrollView: UIScrollView,
                                     contentOffset: CGPoint,
                                     progress: CGFloat) {
        UIView.animate(withDuration: 0.08,
                       delay: 0.0,
                       options: .curveLinear,
                       animations: {
                        self.viewModel.state.headerViewOpaque = progress
                        scrollView.contentOffset = contentOffset
        }, completion: nil)
    }

    private var headerHeight: CGFloat {
        viewModel.state.headerHeight
    }
}

extension EventDetailViewController {
    private func hideMenuController() {
        let menu = UIMenuController.shared
        if menu.isMenuVisible {
            menu.setMenuVisible(false, animated: true)
        }
    }
}

extension EventDetailViewController {
    private func getAuroraViewView(auroraColors: (UIColor, UIColor, UIColor), auroraOpacity: CGFloat) -> AuroraView {
        let auroraView = AuroraView(config: .init(
            mainBlob: .init(color: auroraColors.0, frame: CGRect(x: -44, y: -26, width: 168, height: 154), opacity: 1),
            subBlob: .init(color: auroraColors.1, frame: CGRect(x: -32, y: -131, width: 284, height: 267), opacity: 1),
            reflectionBlob: .init(color: auroraColors.2, frame: CGRect(x: 122, y: -71, width: 248, height: 199), opacity: 1)
        ))
        auroraView.blobsOpacity = auroraOpacity
        return auroraView
    }

    private func setBackground(subView: UIView) {
        for view in self.backgroundView.subviews {
            view.removeFromSuperview()
        }
        backgroundView.addSubview(subView)
        subView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    private var auroraView: AuroraView? {
        backgroundView.subviews.first as? AuroraView
    }
}

#if !LARK_NO_DEBUG
// MARK: 日程详情页便捷调试
extension EventDetailViewController: ConvenientDebug {
    func addDebugGesture() {
        print("huoyunjie")
        guard FG.canDebug else { return }
        self.view.rx.gesture(Factory<UILongPressGestureRecognizer> { _, _ in })
            .when([.began])
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.showActionSheet(debugInfo: self.viewModel, in: self)
            })
            .disposed(by: self.rxBag)
    }
}
#endif
