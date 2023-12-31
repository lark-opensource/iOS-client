//
//  FeedFilterSettingViewModel.swift
//  LarkFeed
//
//  Created by liuxianyu on 2021/8/23.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import RustPB
import EENavigator
import LarkUIKit
import LarkSDKInterface
import LarkMessengerInterface
import UniverseDesignToast
import LarkContainer

/// 消息筛选器设置代理
protocol FeedFilterSettingViewModelDelegate: AnyObject {}

/// 消息筛选器设置vm
final class FeedFilterSettingViewModel: UserResolverWrapper {
    var userResolver: UserResolver { dependency.userResolver }

    private let disposeBag = DisposeBag()
    private let dependency: FilterSettingDependency

    weak var delegate: FeedFilterSettingViewModelDelegate?

    /// 筛选器 switch
    var messageFilterStatus: Bool = false
    var showMuteStatus: Bool?
    private var hasShowAtAllInAtFilter: Bool = false

    var filtersModel: FiltersModel?
    typealias ViewBulilder = (() -> UIView)?
    /// 分组底部视图
    var footerViews: [ViewBulilder] = []
    /// 数据源
    var items: [[FeedFilterSettingItemProtocol]] = []

    /// 刷新表格视图信号
    public var reloadDataDriver: Driver<Void> { return reloadDataPublish.asDriver(onErrorJustReturn: ()) }
    private var reloadDataPublish = PublishSubject<Void>()

    private var showFailureRelay = BehaviorRelay<String>(value: "")
    var showFailureDriver: Driver<String> {
        return showFailureRelay.asDriver().skip(1)
    }

    init(dependency: FilterSettingDependency) {
        self.dependency = dependency
        /// 初始化数据源
        self.footerViews = createFooterViews()
    }

    func getFilters(on window: UIWindow?) {
        _getFilters(tryLocal: true, on: window)
    }

    private func _getFilters(tryLocal: Bool, on window: UIWindow?) {
        dependency.getFilters(tryLocal: tryLocal)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] filter in
                guard let self = self else { return }
                self.messageFilterStatus = true
                self.showMuteStatus = filter.showMute
                self.hasShowAtAllInAtFilter = filter.hasShowAtAllInAtFilter
                self.filtersModel = filter
                self.items = self.createDataSourceItems()
                self.reloadDataPublish.onNext(())
            }, onError: { [weak window] _ in
                guard let window = window else { return }
                UDToast.showFailure(with: BundleI18n.LarkFeed.Lark_Legacy_FailedtoLoadTryLater, on: window)
            }).disposed(by: disposeBag)
    }

    /// 创建表格视图的分组底部视图
    private func createFooterViews() -> [ViewBulilder] {
        var tempFooterViews: [ViewBulilder] = []

        tempFooterViews.append(nil)
        tempFooterViews.append(nil)

        /// section_3 消息免打扰
        if !Feed.Feature(userResolver).groupSettingEnable {
            tempFooterViews.append {
                let view: UIView = UIView()
                let detailLabel: UILabel = UILabel()
                detailLabel.text = BundleI18n.LarkFeed.Lark_Core_Feed_TurnOnMutedFilterDesc
                detailLabel.font = .systemFont(ofSize: 14)
                detailLabel.textColor = UIColor.ud.textPlaceholder
                detailLabel.numberOfLines = 0
                view.addSubview(detailLabel)
                detailLabel.snp.makeConstraints { (make) in
                    make.top.equalToSuperview().offset(4)
                    make.leading.equalToSuperview().offset(16)
                    make.trailing.equalToSuperview().offset(-6)
                    make.bottom.equalToSuperview().offset(-14)
                }
                return view
            }
        } else {
            tempFooterViews.append(nil)
        }

        return tempFooterViews
    }

    private func createDataSourceItems() -> [[FeedFilterSettingItemProtocol]] {
        var tempItems: [[FeedFilterSettingItemProtocol]] = []

        /// section 1
        if self.messageFilterStatus {
            do {
                var sectionItems: [FeedFilterSettingItemProtocol] = []
                do {
                    sectionItems.append(FeedFilterSettingFeedFilterModel(
                        cellIdentifier: FeedFilterSettingFeedFilterCell.lu.reuseIdentifier,
                        title: BundleI18n.LarkFeed.Lark_Feed_EditCategory,
                        tapHandler: { [weak self] in
                            guard let `self` = self else { return }
                            guard let window = self.delegate as? UIViewController else {
                                assertionFailure("缺少window")
                                return
                            }
                            let body = FeedFilterSettingBody(source: .fromMine)
                            self.navigator.present(body: body,
                                                     wrap: LkNavigationController.self,
                                                     from: window,
                                                     prepare: { $0.modalPresentationStyle = .formSheet },
                                                     animated: true)
                        }
                    ))
                }
                if !sectionItems.isEmpty {
                    tempItems.append(sectionItems)
                }
            }
        }

        /// section 2
        if self.messageFilterStatus && self.hasShowAtAllInAtFilter {
            do {
                var sectionItems: [FeedFilterSettingItemProtocol] = []
                do {
                    sectionItems.append(FeedFilterSettingFeedFilterModel(
                        cellIdentifier: FeedFilterSettingFeedFilterCell.lu.reuseIdentifier,
                        title: BundleI18n.LarkFeed.Lark_Messenger_AtMeMessageGrouping_Subtitle,
                        tapHandler: { [weak self] in
                            guard let `self` = self else { return }
                            guard let window = self.delegate as? UIViewController else {
                                assertionFailure("缺少window")
                                return
                            }
                            guard let vc = try? AtSettingViewController(resolver: self.dependency.userResolver) else {
                                return
                            }
                            self.navigator.present(vc,
                                                     wrap: LkNavigationController.self,
                                                     from: window,
                                                     prepare: { $0.modalPresentationStyle = .formSheet },
                                                     animated: true)
                        }
                    ))
                }
                if !sectionItems.isEmpty {
                    tempItems.append(sectionItems)
                }
            }
        }

        /// section 3
        if messageFilterStatus && dependency.addMuteGroupEnable && !Feed.Feature(userResolver).groupSettingEnable {
            do {
                var sectionItems: [FeedFilterSettingItemProtocol] = []
                do {
                    sectionItems.append(FeedFilterSettingSwitchModel(
                        cellIdentifier: FeedFilterSettingSwitchCell.lu.reuseIdentifier,
                        title: BundleI18n.LarkFeed.Lark_Feed_TurnOnMutedFilter,
                        status: self.showMuteStatus ?? false,
                        switchEnable: true,
                        switchHandler: { [weak self] (_, status) in
                            guard let self = self else { return }
                            self.updateFeedFilterSettings(filterEnable: true, showMute: status)
                            self.dependency.clickMuteToggle(status: status)
                        }
                    ))
                }
                if !sectionItems.isEmpty {
                    tempItems.append(sectionItems)
                }
            }
        }

        return tempItems
    }

    private func updateFeedFilterSettings(filterEnable: Bool, showMute: Bool?) {
        self.dependency.updateFeedFilterSettings(filterEnable: filterEnable, showMute: showMute)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let self = self else { return }
                self.messageFilterStatus = filterEnable
                self.showMuteStatus = showMute
                self.items = self.createDataSourceItems()
                self.reloadDataPublish.onNext(())
            }, onError: { [weak self] (_) in
                guard let self = self else { return }
                // 设置失败的文案 并刷新数据
                self.showFailureRelay.accept(BundleI18n.LarkFeed.Lark_Legacy_NetworkError)
                self.items = self.createDataSourceItems()
                self.reloadDataPublish.onNext(())
            }).disposed(by: self.disposeBag)
    }
}
