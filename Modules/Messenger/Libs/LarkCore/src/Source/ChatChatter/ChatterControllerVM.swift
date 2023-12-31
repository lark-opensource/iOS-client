//
//  ChatterControllerVM.swift
//  LarkCore
//
//  Created by JackZhao on 2021/7/20.
//

import UIKit
import Foundation
import RustPB
import RxSwift
import LarkTag
import RxCocoa
import LarkModel
import EENavigator
import LarkListItem
import LarkContainer
import LKCommonsLogging
import LarkSDKInterface
import LarkFeatureGating
import UniverseDesignToast
import LarkAccountInterface
import UniverseDesignDialog
import LarkMessengerInterface
import ThreadSafeDataStructure

public protocol ChatterControllerVMDelegate: AnyObject {
    // 是否支持左滑
    func canLeftSlide() -> Bool
    func getCellByIndexPath(_ indexPath: IndexPath) -> ChatChatterCellProtocol?
    func onRemoveEnd(_ error: Error?)
}

public enum ChatterSortType {
    case alphabetical
    case joinTime
}

// 成员页抽象ViewModel，不可直接使用，请使用继承此类的子类
open class ChatterControllerVM: UserResolverWrapper {
    public let userResolver: UserResolver

    public enum DataLoader: Equatable {
        case none
        case firstScreen
        case up(indexPath: IndexPath)
        case upAndDown(indexPath: IndexPath)
        case down(indexPath: IndexPath)

        public static func == (lhs: DataLoader, rhs: DataLoader) -> Bool {
            switch (lhs, rhs) {
            case (.none, .none):
                return true
            case (.firstScreen, .firstScreen):
                return true
            case let (.up(lhsIndex), .up(rhsIndex)):
                return lhsIndex == rhsIndex
            case let (.upAndDown(lhsIndex), .upAndDown(rhsIndex)):
                return lhsIndex == rhsIndex
            case let (.down(lhsIndex), .down(rhsIndex)):
                return lhsIndex == rhsIndex
            default:
                return false
            }
        }
    }

    // 基础数据
    public let id: String

    // 列表数据相关
    public var datas: [ChatChatterSection] {
        get { _datas.value }
        set { _datas.value = newValue }
    }
    private var _datas: SafeAtomic<[ChatChatterSection]> = [] + .readWriteLock
    private(set) var searchDatas: [ChatChatterSection] = []
    public let statusBehavior = BehaviorSubject<ChatChatterViewStatus>(value: .loading)
    public var statusVar: Driver<ChatChatterViewStatus> {
        return statusBehavior.asDriver(onErrorRecover: { .just(.error($0)) })
    }
    private var isFirstDataLoaded: Bool = false

    // 选择器相关
    let maxSelectModel: (Int, String)? // $0: 最大选择人数，$1: 选择超出限制的文案
    let showSelectedView: Bool
    public var defaultSelectedIds: [String]? // 默认选择的列表
    public var defaultUnableCancelSelectedIds: [String]? // 默认选中，无法取消选中的列表
    var onLoadDefaultSelectedItems: ((_ items: [ChatChatterItem]) -> Void)?

    // 搜索相关
    public let searchPlaceHolder: String
    public var filterKey: String?
    public var isInSearch: Bool {
        !(filterKey ?? "").isEmpty
    }

    // 页面底部是否显示安全策略view组件
    public var shouldShowTipView: Bool = false

    public weak var delegate: ChatterControllerVMDelegate?
    public weak var targetVC: UIViewController?

    // 群成员首字母排序
    public private(set) var sortType: ChatterSortType = .joinTime

    static let logger = Logger.log(ChatterControllerVM.self, category: "ChatterControllerVM")
    public let schedulerType: SchedulerType
    public let disposeBag = DisposeBag()
    private var searchDisposeBag = DisposeBag()

    public var mergeDataHandler: ((_ currentData: [ChatChatterSection], _ appendData: [ChatChatterSection]) -> [ChatChatterSection])?

    // 是否显示右侧的索引条
    let showIndexBar: Bool

    public init(userResolver: UserResolver,
                id: String,
                searchPlaceHolder: String,
                maxSelectModel: (Int, String)? = nil,
                showSelectedView: Bool = true,
                showIndexBar: Bool = true) {
        self.userResolver = userResolver
        self.id = id
        self.maxSelectModel = maxSelectModel
        self.showSelectedView = showSelectedView
        self.searchPlaceHolder = searchPlaceHolder
        self.showIndexBar = showIndexBar
        let queue = DispatchQueue.global()
        self.schedulerType = SerialDispatchQueueScheduler(queue: queue, internalSerialQueueName: queue.label)
    }

    // MARK: - 需要被子类实现的方法
    // 拉取列表数据
    open func loadData(_ loader: ChatterControllerVM.DataLoader = .none) -> Observable<[ChatChatterSection]> {
        assertionFailure("must be override")
        return .just([])
    }

    // 列表是否还有更多数据
    open func hasMoreData() -> Bool {
        assertionFailure("must be override")
        return false
    }

    // 删除所选的成员
    open func removeChatterBySelectedItems(_ selectedItems: [ChatChatterItem]) {
        assertionFailure("must be override")
    }

    open func loadDefaultSelectedItem(defaultSelectedIds: [String]) -> Observable<[ChatChatterItem]> {
        return .just([])
    }

    // 组装左滑item
    open func structureActionItems(tapTask: @escaping () -> Void,
                              indexPath: IndexPath) -> [UIContextualAction]? {
        assertionFailure("must be override")
        return nil
    }

    open func clearOrderedChatChatters() {
    }

    // 加载更多
    // 在首字母排序中需要区分方向
    open func loadMoreData(_ loader: ChatterControllerVM.DataLoader = .none) {
        guard isFirstDataLoaded else { return }
        loadData(loader)
            .observeOn(schedulerType)
            .subscribe(onNext: { [weak self] (datas) in
                guard let self = self else { return }
                // loadData 在首字母排序的需求直接更新
                if self.sortType == .alphabetical {
                    self.datas = datas
                    self.statusBehavior.onNext(.viewStatus(.update))
                    return
                }
                // 由于分页且分组，所以数据需要merge而不是直接追加
                if let mergeDataHandler = self.mergeDataHandler {
                    self.datas = mergeDataHandler(self.datas, datas)
                } else {
                    self.datas.merge(datas)
                }
                self.statusBehavior.onNext(.viewStatus(.display))
            }, onError: { [weak self] (error) in
                ChatterControllerVM.logger.error(
                    "load more chat chatter error",
                    additionalData: ["chatID": self?.id ?? ""],
                    error: error)
                self?.statusBehavior.onNext(.viewStatus(.display))
            }).disposed(by: disposeBag)
    }

    // 首次加载数据，需要加载默认选中的数据，所以单独拉出来处理
    open func loadFirstScreenData() {
        loadData(.firstScreen)
            .flatMap { [weak self] (result) -> Observable<([ChatChatterSection], [ChatChatterItem])> in
                guard let self = self else { return .empty() }
                if let defaultSelectedIds = self.defaultSelectedIds {
                    return self.loadDefaultSelectedItem(defaultSelectedIds: defaultSelectedIds).map { (result, $0) }
                } else {
                    return .just((result, []))
                }
            }
            .observeOn(schedulerType)
            .subscribe(onNext: { [weak self] (datas, defaultSeletedItems) in
                guard let self = self else { return }

                ChatterControllerVM.logger.info(
                    "chat chatter default selected items count: \(defaultSeletedItems.count)")

                self.datas = datas
                self.onLoadDefaultSelectedItems?(defaultSeletedItems)

                self.statusBehavior.onNext(.viewStatus(datas.isEmpty ? .empty : .display))
            }, onError: { [weak self] (error) in
                ChatterControllerVM.logger.error(
                    "first load chat chatter error",
                    additionalData: ["chatID": self?.id ?? ""],
                    error: error)
                self?.statusBehavior.onNext(.error(error))
            }, onDisposed: { [weak self] in
                self?.isFirstDataLoaded = true
            }).disposed(by: disposeBag)
    }
}

// MARK: - 对vc提供的接口
extension ChatterControllerVM {

    // 搜索接口
    func loadFilterData(_ key: String) {
        guard isFirstDataLoaded else { return }

        filterKey = key
        searchDisposeBag = DisposeBag()
        // 重新搜索的时候, 先清除掉保存的搜索数据, 避免下次搜索时先展示上次的结果
        self.searchDatas.removeAll()
        if isInSearch {
            statusBehavior.onNext(.viewStatus(.loading))
        } else {
            statusBehavior.onNext(.viewStatus(datas.isEmpty ? .empty : .display))
            return
        }

        loadData()
            .observeOn(schedulerType)
            .subscribe(onNext: { [weak self] (result) in
                guard let self = self else { return }
                self.searchDatas = result
                self.statusBehavior.onNext(.viewStatus(result.isEmpty ? .searchNoResult(key) : .display))
            }, onError: { [weak self] (error) in
                ChatterControllerVM.logger.error(
                    "load filter chat chatter error",
                    additionalData: [
                        "chatID": self?.id ?? "",
                        "filterKey": key
                    ],
                    error: error)
                self?.statusBehavior.onNext(.error(error))
            }).disposed(by: searchDisposeBag)
    }
}
