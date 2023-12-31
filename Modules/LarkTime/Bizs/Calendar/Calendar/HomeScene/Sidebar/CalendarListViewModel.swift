//
//  CalendarListViewModel.swift
//  Calendar
//
//  Created by huoyunjie on 2021/8/19.
//

import UIKit
import Foundation
import LarkContainer
import RxCocoa
import RxSwift
import LarkUIKit
import RustPB
import CalendarFoundation
import UniverseDesignActionPanel
import UniverseDesignToast
import EENavigator
import LKCommonsLogging

final class CalendarListViewModel: UserResolverWrapper {

    let userResolver: UserResolver

    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?

    private var viewContent: [CalendarListSection] = []

    let rxViewContent: PublishRelay<Void> = .init()
    
    let rxIsCellHighlighting: BehaviorRelay<Bool> = .init(value: false)

    private let disposeBag = DisposeBag()
    
    private var dataProviders: [SidebarDataProvider] = []
    
    private var data: [SidebarModelData] {
        dataProviders.map(\.modelData).flatMap { $0 }
    }
    
    struct HighlightData {
        var source: SidebarDataSource
        var id: String
        var uniqueId: String {
            "\(source.description)\(id)"
        }
    }
    
    private(set) var highlightUniqueId: String?
    
    init(userResolver: UserResolver, highlightData: HighlightData? = nil) {
        self.userResolver = userResolver
        self.highlightUniqueId = highlightData?.uniqueId
        
        self.dataProviders.append(CalendarSidebarDataProvider(userResolver: userResolver))
        if FeatureGating.taskInCalendar(userID: userResolver.userID) {
            self.dataProviders.append(TimeContainerSidebarDataProvider(userResolver: userResolver))
        }
        
        self.subscribeDataChanged()
    }
    
    func fetchData() {
        dataProviders.forEach { $0.fetchData() }
    }
    
    private func subscribeDataChanged() {
        Observable.combineLatest(dataProviders.map(\.dataChanged))
            .subscribe(onNext: { [weak self] _ in
                self?.reload()
            }).disposed(by: disposeBag)
    }


    func autoSelectHighlightedCalendar(_ from: UIViewController) {
        // applink 要将高亮 calendar 自动勾选
        guard let uniqueId = highlightUniqueId else { return }
        guard let model = data.first(where: { $0.uniqueId == uniqueId }) else {
            if let window = self.userResolver.navigator.mainSceneWindow {
                UDToast.showFailure(with: I18n.Calendar_Setting_UnsubscribedNoViewToast, on: window)
            }
            return
        }
        guard let provider = dataProviders.first(where: { $0.source == model.source }) else {
            assertionFailure("no data provider")
            return
        }
        if !model.isVisible {
            provider.updateVisibility(with: uniqueId, from: from)
        }
    }

    private func reload() {
        self.viewContent = self.transformViewContent(models: self.data)
        self.rxViewContent.accept(())
    }

    public func getHighlightModelIndexPath() -> IndexPath? {
        guard let uniqueId = highlightUniqueId else { return nil }
        var outIndex: Int?
        var inIndex: Int?
        outIndex = viewContent.firstIndex { listSection in
            if let index = listSection.content.data.firstIndex(where: { $0.uniqueId == uniqueId }) {
                inIndex = index
                return true
            }
            return false
        }
        if let section = outIndex,
           let row = inIndex {
            return IndexPath(row: row, section: section)
        }
        return nil
    }

    public func getGuideCalendarIndexPath() -> IndexPath? {
        guard !viewContent.isEmpty,
              !viewContent[0].content.data.isEmpty else { return nil }
        return IndexPath(row: 0, section: 0)
    }
    
    public func getTimeContainerGuideIndexPath() -> IndexPath? {
        guard !viewContent.isEmpty,
              let row = viewContent[0].content.data.firstIndex(where: { $0.source == .timeContainer }) else { return nil }
        return IndexPath(row: row, section: 0)
    }

    private func transformViewContent(models: [SidebarModelData]) -> [CalendarListSection] {
        // 1. 进行分类
        var calendarList: [CalendarListSection] = []
        let count = self.viewContent.reduce(0) { result, listSection in
            return result + listSection.count
        }
        if !self.viewContent.isEmpty && count == models.count {
            // 局部刷新，在改变可见性场景下，避免viewContent的顺序发生改变
            CalendarList.logInfo("calendar list content update partly, calendar count is \(count)")
            calendarList = viewContent.map { listSection -> CalendarListSection in
                let data = listSection.content.data.map({ model in
                    return models.first(where: { $0.uniqueId == model.uniqueId }) ?? model
                })
                return listSection.reset(with: data)
            }
            return calendarList
        } else {
            // 全量刷新
            CalendarList.logInfo("calendar list content update fully, calendar count is \(models.count)")
            calendarList = [CalendarListSection: [SidebarModelData]](grouping: models, by: { model in
                model.sectionType
            }).map { type, data in
                return type.reset(with: data)
            }
            
            if calendarList.firstIndex(where: { type in
                switch type {
                case .larkMine: return true
                default: return false
                }
            }) == nil {
                // 特殊情况出现没有主日历，tableView也需要有主日历的header出现
                CalendarList.logInfo("calendar list have no larkMine, need insert larkMine header")
                let title = FG.optimizeCalendar ? I18n.Calendar_Manage_Managing : I18n.Calendar_Common_MyCalendars
                calendarList.append(.larkMine(CalendarListSectionContent(sourceTitle: title)))
            }

            if calendarList.firstIndex(where: { type in
                switch type {
                case .larkSubscribe: return true
                default: return false
                }
            }) == nil {
                // 没有订阅日历，tableView也需要有订阅日历的header出现
                CalendarList.logInfo("calendar list have no subscribe, need insert subscribe header")
                calendarList.append(.larkSubscribe(CalendarListSectionContent(sourceTitle: BundleI18n.Calendar.Calendar_Common_SubscribedCalendar)))
            }

            calendarList.sort { l, r in
                if l.tag == r.tag {
                    if case .local = l {
                        return l.content.sourceTitle == r.content.sourceTitle ? l.content.data.isEmpty : l.content.sourceTitle < r.content.sourceTitle
                    }
                    return l.content.data.first?.weight ?? 0 > r.content.data.first?.weight ?? 0
                }
                return l.tag > r.tag
            }

            return calendarList.map { $0.sortedList() }
        }
    }

    public func getModelDataBy(indexPath: IndexPath) -> SidebarModelData? {
        guard indexPath.section < viewContent.count,
              indexPath.row < viewContent[indexPath.section].count else { return nil }
        return viewContent[indexPath.section].content.data[indexPath.row]
    }

    func numberOfSections() -> Int {
        return viewContent.count
    }

    public func isThirdPartyGroup(_ section: Int) -> Bool {
        guard section < viewContent.count else { return false }
        let type = viewContent[section]
        switch type {
        case .google, .exchange:
            return true
        case .larkMine, .larkSubscribe, .local:
            return false
        }
    }

    public func getSectionIn(section: Int) -> CalendarListSection? {
        guard section < viewContent.count else { return nil }
        return viewContent[section]
    }

    public func changeVisibility(indexPath: IndexPath, from vc: UIViewController) {
        guard let modelData = getModelDataBy(indexPath: indexPath) else { return }
        dataProviders
            .first(where: { $0.source == modelData.source })?
            .updateVisibility(with: modelData.uniqueId, from: vc)
    }
}

// MARK: Router
extension CalendarListViewModel {
    private func tapSetting(indexPath: IndexPath, from: UIViewController, _ popAnchor: UIView) {
        guard let model = getModelDataBy(indexPath: indexPath) else { return }
        dataProviders
            .first(where: { $0.source == model.source })?
            .clickTrailView(with: model.uniqueId, from: from, popAnchor)
    }

    private func tapFooter(section: Int, from: UIViewController) {
        guard let listSection = getSectionIn(section: section),
              let firstItem = listSection.content.data.first else { return }
        dataProviders
            .first(where: { $0.source == firstItem.source })?
            .clickFooterView(with: firstItem.uniqueId, from: from)
    }
}

// MARK: ACTION
extension CalendarListViewModel {

    enum TapAction {
        /// 点击日历设置
        case setting(indexPath: IndexPath, from: UIViewController, popAnchor: UIView)
        /// 点击三方日历管理
        case footer(section: Int, from: UIViewController)
    }

    func tap(_ action: TapAction) {
        switch action {
        case let .setting(indexPath, fromVC, sender): tapSetting(indexPath: indexPath, from: fromVC, sender)
        case let .footer(section, fromVC): tapFooter(section: section, from: fromVC)
        }
    }
}
