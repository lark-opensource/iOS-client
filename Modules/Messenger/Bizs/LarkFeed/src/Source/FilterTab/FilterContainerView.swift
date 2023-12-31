//
//  FilterContainerView.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/12/29.
//

import Foundation
import UIKit
import UniverseDesignTabs
import LarkUIKit
import RxSwift
import RxCocoa
import LarkMessengerInterface
import LarkOpenFeed
import LarkNavigation
import EENavigator
import LarkContainer

final class FilterContainerView: UIView, UserResolverWrapper {
    var userResolver: UserResolver { mainViewModel.userResolver }

    private let disposeBag = DisposeBag()
    static var FilterViewHeight: CGFloat { 48 }
    let mainViewModel: FilterContainerViewModel
    weak var delegate: FilterTabsViewDelegate? {
        didSet {
            filterFixedView?.delegate = delegate
        }
    }
    // 固定分组栏
    weak var filterFixedView: FilterFixedView?
    // 汉堡菜单
    weak var menuView: UIView?
    weak var menuGuideView: UIView?
    // 新样式 filter 容器
    private var filterFixedBarContainerView: UIView?

    private lazy var menuButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = UIColor.ud.N200
        button.layer.cornerRadius = (FilterFixedViewLayout.menuButtonWidth) / 2
        button.layer.masksToBounds = true
        button.setImage(Resources.filter_menu, for: .disabled)
        button.isUserInteractionEnabled = false
        button.isEnabled = false
        return button
    }()

    private var viewWidth: CGFloat = 0
    var context: FeedContextService?

    var onFilterFixedViewAppeared = BehaviorRelay<Bool>(value: false)

    var menuClickHandler: ((UIView) -> Void)?

    init(mainViewModel: FilterContainerViewModel,
         context: FeedContextService?) {
        self.mainViewModel = mainViewModel
        self.context = context
        super.init(frame: .zero)
        setupViews()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    private func setupViews() {
        self.backgroundColor = UIColor.ud.bgBody
        self.clipsToBounds = true

        let containerView = UIView()
        containerView.clipsToBounds = true
        self.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.left.right.top.bottom.equalToSuperview()
        }

        // 三栏FG且非iPad条件下，展示固定分组bar
        filterFixedBarContainerView = containerView
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size.width != viewWidth {
            viewWidth = bounds.size.width
            layoutForFixedView()
        }
    }

    private func bind() {
        mainViewModel.filterFixedViewModel.filterShowDriver.drive(onNext: { [weak self] isShow in
            guard let self = self else { return }
            self.showFilterFixedView(isShow)
            self.showMenuView(isShow)
        }).disposed(by: disposeBag)

        mainViewModel.dataStore.filterReloadObservable.drive(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.filterFixedView?.reload()
        }).disposed(by: disposeBag)

        mainViewModel.styleService?.padUnfoldStatusSubject
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                // 调整 button 图标
                self?.refreshMenuIcon()
            })
        mainViewModel.styleService?.styleSubject
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                // 调整 button 图标
                self?.refreshMenuIcon()
            })
        mainViewModel.dataStore.filterReloadObservable.drive(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.filterFixedView?.reload()
        }).disposed(by: disposeBag)
    }
}

// MARK: - 固定分组栏
extension FilterContainerView {
    private func showFilterFixedView(_ isShow: Bool) {
        if isShow {
            guard filterFixedView == nil else {
                filterFixedView?.reload()
                layoutForFixedView()
                onFilterFixedViewAppeared.accept(true)
                return
            }
            let view = FilterFixedView(viewModel: mainViewModel.filterFixedViewModel)
            view.delegate = delegate
            filterFixedView = view
            filterFixedBarContainerView?.addSubview(view)
            if let currentType = context?.dataSourceAPI?.currentFilterType {
                view.changeViewTab(currentType)
            }
            filterFixedView?.reload()
            layoutForFixedView()
            onFilterFixedViewAppeared.accept(true)
        } else {
            guard filterFixedView != nil else {
                return
            }
            self.filterFixedView?.removeFromSuperview()
            self.filterFixedView = nil
            layoutForFixedView()
            onFilterFixedViewAppeared.accept(false)
        }
    }

    private func showMenuView(_ isShow: Bool) {
        if isShow {
            guard menuView == nil else {
                layoutForFixedView()
                return
            }

            refreshMenuIcon()
            let view = UIView()
            view.addSubview(menuButton)

            menuButton.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(16)
                make.width.height.equalTo(FilterFixedViewLayout.menuButtonWidth)
                make.centerY.equalToSuperview()
            }
            view.lu.addTapGestureRecognizer(action: #selector(showSlideFilterList), target: self)
            menuGuideView = menuButton
            menuView = view
            filterFixedBarContainerView?.addSubview(view)
        } else {
            guard menuView != nil else {
                return
            }
            menuGuideView?.removeFromSuperview()
            menuGuideView = nil
            menuView?.removeFromSuperview()
            menuView = nil
        }
        layoutForFixedView()
    }

    private func layoutForFixedView() {
        guard let filterView = self.filterFixedView, let menuView = self.menuView else { return }
        menuView.snp.remakeConstraints { (make) in
            make.leading.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(FilterFixedViewLayout.verticalPadding)
            make.width.equalTo(FilterFixedViewLayout.menuWidth)
        }
        let inset = 16 - FilterFixedViewLayout.verticalPadding - FilterFixedViewLayout.contentEdgeInsetRight
        filterView.snp.remakeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(FilterFixedViewLayout.verticalPadding)
            make.leading.equalTo(menuView.snp.trailing)
            make.trailing.equalToSuperview().inset(inset)
        }
        let maxWidth = bounds.size.width - FilterFixedViewLayout.menuWidth - FilterFixedViewLayout.verticalPadding - inset
        filterView.setTabViewLimitWidth(maxWidth)
    }

    @objc
    private func showSlideFilterList() {
        FeedTracker.ThreeColumns.Click.menuClick()
        self.menuClickHandler?(self.menuButton)
    }

    private func refreshMenuIcon() {
        guard !Feed.Feature(userResolver).groupPopOverForPad else {
            menuButton.setImage(Resources.filter_menu, for: .disabled)
            return
        }

        if let style = mainViewModel.styleService?.currentStyle,
           let padUnfoldStatus = mainViewModel.styleService?.padUnfoldStatus {
            if Display.pad {
                if style != .padRegular {
                    menuButton.setImage(Resources.icon_side_fold, for: .disabled)
                } else {
                    menuButton.setImage(padUnfoldStatus ? Resources.icon_side_expand : Resources.icon_side_fold, for: .disabled)
                }
            } else {
                menuButton.setImage(Resources.filter_menu, for: .disabled)
            }
        } else {
            menuButton.setImage(Resources.filter_menu, for: .disabled)
        }
    }
}
