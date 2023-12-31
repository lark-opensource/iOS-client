//
//  SearchFilterClickAction.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/11/15.
//

import Foundation
import RxSwift
import RxCocoa
import EENavigator
import LarkUIKit
import UIKit
import Homeric
import LKCommonsTracker
import LarkContainer
import LarkModel
import UniverseDesignToast
import LarkNavigation

final class SearchFilterClickAction: SearchPickerDelegate {
    let accountContext: MailAccountContext
    private let disposeBag = DisposeBag()
    private let shouldChangeSearchFilterSubject = PublishSubject<MailSearchFilter?>()
    var shouldChangeSearchFilter: Driver<MailSearchFilter?> {
        return shouldChangeSearchFilterSubject.asDriver(onErrorJustReturn: nil)
    }
    private let shouldResetSearchFiltersSubject = PublishSubject<Bool>()
    var shouldResetSearchFilters: Driver<Bool> {
        return shouldResetSearchFiltersSubject.asDriver(onErrorJustReturn: false)
    }

    // 选择归我所有后，高级搜索内文档所有者需要补充“我”
    // 如果用户选择文档所有者过滤器后，回调给外部的筛选器需要去掉额外补充这个“我”
    // 比较合适的是给Chatter加属性，但Chatter是公共模型不太合适
    // 如果有其他方案可以随时替换
    private var mockSelfChatter: Chatter?
    private var searchPopupHelper: SearchPopupHelper?
    private var newPickerAction: (selectItemFilterBlock: ((LarkModel.PickerItem) -> Bool)?,
                                  finishBlock: ([LarkModel.PickerItem]) -> Void)?

    init(accountContext: MailAccountContext) {
        self.accountContext = accountContext
    }

    public func handle(filter: MailSearchFilter, from: UIViewController,
                       completion: ((MailSearchFilter) -> Void)? = nil) {
        switch filter {
        case let .general(generalFilter):
            switch generalFilter {
            case let .date(info, date):
                showDatePicker(date: date, from: from, fromView: nil) { startDate, endDate in
                    let newFilter = MailSearchFilter.general(.date(info, MailSearchFilter.FilterDate(startDate: startDate, endDate: endDate)))
                    completion?(newFilter)
                }
            case let .mailUser(info, pickers):
                showMailUserPicker(selected: pickers,
                                   title: filter.name,
                                   from: from) { [weak self] newSelected in
                    guard let `self` = self else { return }
                    if Set(self.accountContext.dataService.converPickerItemToAddress(pickers)) != Set(self.accountContext.dataService.converPickerItemToAddress(newSelected)) {
                        let newFilter: MailSearchFilter = MailSearchFilter.general(.mailUser(info, newSelected))
                        completion?(newFilter)
                    }
                }
            case let .inputTextFilter(info, texts):
                var scene: SearchInputFilterViewController.Scene = .subjectFilter
                switch info {
                case .subjectText(_):
                    scene = .subjectFilter
                case .notContain(_):
                    scene = .excludeFilter
                default: break
                }
                showInputTextFilterPicker(selectedTexts: texts,
                                          title: filter.name,
                                          scene: scene,
                                          from: from) { newSelected in
                    if Set(texts) != Set(newSelected) {
                        let newFilter: MailSearchFilter = MailSearchFilter.general(.inputTextFilter(info, newSelected))
                        completion?(newFilter)
                    }
                }
            case .multiple(_, _):
                break
            case .single(let info, _):
                if case .hasAttach(let hasAttach) = info {
                    let item = GeneralMultiFilterType(name: BundleI18n.MailSDK.Mail_AdvancedSearchFilter_WithAttachmentTick, id: "attachment")
                    let selection = GeneralMultiSelection(title: info.displayName, availableItems: [item], selectedItems: hasAttach ? [item] : [])
                    showMultiSelection(selection: selection, from: from) { types in
                        if hasAttach != !types.isEmpty {
                            let newFilter = MailSearchFilter.general(.single(.hasAttach(!types.isEmpty), nil))
                            completion?(newFilter)
                        }
//                        self.filterChange(from: filter, changedFilter: newFilter)
                    }
                } else if case .labels(let label) = info {
                    showTagSelection(scene: .filterLabel, selectedLabel: label, from: from) { selectedItem in
                        let newInfo: MailFilterInfo = .labels(selectedItem)
                        let newFilter: MailSearchFilter = .general(.single(newInfo, nil))
                        completion?(newFilter)
                    }
                } else if case .folders(let folder) = info {
                    showTagSelection(scene: .filterFolder, selectedLabel: folder, from: from) { selectedItem in
                        let newInfo: MailFilterInfo = .folders(selectedItem)
                        let newFilter: MailSearchFilter = .general(.single(newInfo, nil))
                        completion?(newFilter)
                    }
                }
            }
        case .date(let date, let source):
            showDatePicker(date: date, from: from, fromView: nil) { startDate, endDate in
                let newFilter = MailSearchFilter.date(date: MailSearchFilter.FilterDate(startDate: startDate, endDate: endDate), source: source)
                completion?(newFilter)
            }
        default:
            assert(false, "new value")
        }
    }

    // MARK: - Router
    private func showChatterPicker(items: [SearchChatterPickerItem],
                                   title: String,
                                   from: UIViewController,
                                   enableMyAi: Bool = false,
                                   finish: @escaping ([SearchChatterPickerItem], Bool) -> Void) {
//        guard let chatterAPI = try? userResolver.resolve(assert: ChatterAPI.self) else { return }

        guard let provider = accountContext.provider.contactPickerProvider else {
            return
        }
        let params = MailContactPickerParams()
        params.selectedCallback = { [weak self] (items) in
            guard let self = self else {
                return
            }
//            var items = [SearchChatterPickerItem]()
//            let chatterIDs = result.chatterInfos.map { $0.ID }
//            let botItems = result.botInfos.map { SearchChatterPickerItem.bot($0) }
//            items.append(contentsOf: botItems)
//            if !chatterIDs.isEmpty {
//                chatterAPI.getChatters(ids: chatterIDs)
//                    .observeOn(MainScheduler.instance)
//                    .subscribe(onNext: { (chatterMap) in
//                        vc?.dismiss(animated: true, completion: nil)
//
//                        let chatterItems = chatterIDs
//                            .compactMap { chatterMap[$0] }
//                            .map { SearchChatterPickerItem.chatter($0) }
//                        items.append(contentsOf: chatterItems)
//                        finish(items, result.isRecommendSelected)
//                    }).disposed(by: self.disposeBag)
//            } else {
//                vc?.dismiss(animated: true, completion: nil)
//                finish(items, result.isRecommendSelected)
//            }
        }
//        let allCount = viewModel.sendToArray.count + viewModel.ccToArray.count + viewModel.bccToArray.count
//
//        params.maxSelectCount = max(0, contentChecker.recipientsLimit - allCount)
        provider.presentMailContactPicker(params: params, vc: from)
//        var body = ChatterPickerBody()
//        body.defaultSelectedChatterIds = items.map { $0.chatterID }
//        body.selectStyle = items.isEmpty ? .singleMultiChangeable : .multi
//        body.title = title
//        body.allowSelectNone = items.isEmpty ? false : true
//        body.enableSearchBot = true
//        body.supportUnfoldSelected = true
//        body.recommendList = recommendList
//        body.hasSearchFromFilterRecommend = true
//        body.enableMyAi = enableMyAi
//        body.selectedCallback = { (vc, result) in
//            var items = [SearchChatterPickerItem]()
//            let chatterIDs = result.chatterInfos.map { $0.ID }
//            let botItems = result.botInfos.map { SearchChatterPickerItem.bot($0) }
//            items.append(contentsOf: botItems)
//            if !chatterIDs.isEmpty {
//                chatterAPI.getChatters(ids: chatterIDs)
//                    .observeOn(MainScheduler.instance)
//                    .subscribe(onNext: { (chatterMap) in
//                        vc?.dismiss(animated: true, completion: nil)
//
//                        let chatterItems = chatterIDs
//                            .compactMap { chatterMap[$0] }
//                            .map { SearchChatterPickerItem.chatter($0) }
//                        items.append(contentsOf: chatterItems)
//                        finish(items, result.isRecommendSelected)
//                    }).disposed(by: self.disposeBag)
//            } else {
//                vc?.dismiss(animated: true, completion: nil)
//                finish(items, result.isRecommendSelected)
//            }
//        }
//        Navigator.shared.present(body: body, from: from, prepare: { $0.modalPresentationStyle = .formSheet })
    }

//    private func showUniversalPicker(pickType: UniversalPickerType,
//                                     items: [ForwardItem],
//                                     selectMode: SearchUniversalPickerBody.SelectMode = .Multi,
//                                     enableMyAi: Bool = false,
//                                     supportFrozenChat: Bool? = nil,
//                                     from: UIViewController,
//                                     finish: @escaping ([ForwardItem]) -> Void) {
//        var body = SearchUniversalPickerBody(pickType: pickType,
//                                             selectedItems: items,
//                                             selectMode: selectMode,
//                                             enableMyAi: enableMyAi,
//                                             supportFrozenChat: supportFrozenChat)
//        body.didFinishPick = { (viewController, items) in
//            viewController.dismiss(animated: true, completion: nil)
//            finish(items)
//        }
//        Navigator.shared.present(
//            body: body,
//            wrap: LkNavigationController.self,
//            from: from,
//            prepare: { $0.modalPresentationStyle = .formSheet })
//    }

//    private func showSingleSelection(selection: SearchFilterSingleSelection,
//                                     from: UIViewController,
//                                     finish: @escaping (SearchFilterItem?) -> Void) {
//        let viewController = SingleSelectionFilterViewController(selection: selection, isModeled: Display.pad)
//        viewController.didSelectType = { (type, from) in
//            from.dismiss(animated: true, completion: nil)
//            finish(type)
//        }
//        if Display.pad {
//            accountContext.navigator.present(viewController,
//                                     wrap: LkNavigationController.self,
//                                     from: from,
//                                     prepare: { $0.modalPresentationStyle = .formSheet })
//        } else {
//            viewController.modalPresentationStyle = .overCurrentContext
//            viewController.transitioningDelegate = viewController
//            accountContext.navigator.present(viewController, from: from, animated: true)
//        }
//    }

    private func showMultiSelection(selection: SearchFilterMultiSelection,
                                    from: UIViewController,
                                    finish: @escaping ([SearchFilterItem]) -> Void) {
        let viewController = MultiSelectionViewController(selection: selection, isModeled: Display.pad)
        viewController.didSelecteItems = { (types, from) in
            from.dismiss(animated: true, completion: nil)
            finish(types)
        }
        if Display.pad {
            accountContext.navigator.present(viewController, wrap: LkNavigationController.self,
                                     from: from,
                                     prepare: { $0.modalPresentationStyle = .formSheet })
        } else {
            viewController.modalPresentationStyle = .overCurrentContext
            viewController.transitioningDelegate = viewController
            accountContext.navigator.present(viewController, from: from, animated: true)
        }
    }
    
    private func showTagSelection(scene: SearchFilterTagViewController.Scene,
                                  selectedLabel: MailFilterLabelCellModel?,
                                  from: UIViewController,
                                  finish: @escaping (MailFilterLabelCellModel?) -> Void) {
        let viewController = SearchFilterTagViewController(scene: scene, selectedLabel: selectedLabel)
        viewController.didSelecteItem = { (tagItem, from) in
            from.dismiss(animated: true, completion: nil)
            finish(tagItem)
        }
        
//        let moveToVC = MailMoveToLabelViewController(threadIds: [viewModel.threadId], fromLabelId: viewModel.labelId, accountContext: accountContext)
//        moveToVC.spamAlertContent = getCurrentSpamAlertContent()
//        if Store.settingData.folderOpen() || Store.settingData.mailClient {
//            moveToVC.scene = .moveToFolder
//            MailTracker.log(event: "email_thread_move_to_folder", params: [MailTracker.sourceParamKey(): MailTracker.source(type: .threadAction), "thread_count": 1])
//        }
        let nav = LkNavigationController(rootViewController: viewController)
        nav.modalPresentationStyle = .fullScreen
        if #available(iOS 13.0, *) {
            nav.modalPresentationStyle = .automatic
        }
        if Display.pad {
            nav.modalPresentationStyle = .formSheet
        }
//        moveToVC.newFolderDelegate = externalDelegate
//        moveToVC.didMoveLabelCallback = { [weak self] toLabel, _, _ in
//            self?.dismissSelf()
//            if toLabel.labelId == Mail_LabelId_Spam {
//                self?.barActionEvent(action: "move_to_spam")
//            }
//        }
        accountContext.navigator.present(nav, from: from, animated: true)
        
//        if Display.pad {
//            accountContext.navigator.present(viewController, wrap: LkNavigationController.self,
//                                     from: from,
//                                     prepare: { $0.modalPresentationStyle = .formSheet })
//        } else {
//            viewController.modalPresentationStyle = .overCurrentContext
////            viewController.transitioningDelegate = viewController
//            accountContext.navigator.present(viewController, from: from, animated: true)
//        }
    }

    // TODO from view
    private func showDatePicker(date: MailSearchFilter.FilterDate?,
                                from: UIViewController,
                                fromView: UIView?,
                                finish: @escaping (Date?, Date) -> Void) {
        if let filterDate = date {
            _showDateFilter(startDate: filterDate.startDate, endDate: filterDate.endDate ?? Date(), fromView: fromView, finish: finish, from: from)
        } else {
            _showDateFilter(startDate: date?.startDate ?? Date(), endDate: Date(), fromView: fromView, finish: finish, from: from)
        }
//        body.fromView = fromView
//        fromView?.window?.endEditing(true)
//        body.confirm = { (vc, startDate, endDate) in
//            vc.dismiss(animated: false, completion: nil)
//            finish(startDate, endDate)
//        }
//        accountContext.navigator.present(body: body, from: from)
//
//        accountContext.provider.routerProvider?.pushSearchDateFilter(startDate: Date?, endDate: Date)
    }

    func _showDateFilter(startDate: Date?, endDate: Date, fromView: UIView?,
                        finish: @escaping (Date?, Date) -> Void, from: UIViewController) {
        let vc = MailSearchDateFilterViewController(startDate: startDate, endDate: endDate, fromView: fromView)
        vc.finishChooseBlock = { (vc, startDate, endDate) in
            //body.confirm?(vc, startDate, endDate)
            from.dismiss(animated: false, completion: nil)
            finish(startDate, endDate)
        }
//        body.fromView = fromView
//        fromView?.window?.endEditing(true)
//        body.confirm = { (fromVC, startDate, endDate) in
//            fromVC.dismiss(animated: false, completion: nil)
//            finish(startDate, endDate)
//        }
//        vc.modalPresentationStyle = .formSheet
//        accountContext.navigator.present(vc, from: from)

        if Display.pad {
            accountContext.navigator.present(vc, wrap: LkNavigationController.self,
                                     from: from,
                                     prepare: { $0.modalPresentationStyle = .formSheet })
        } else {
            vc.modalPresentationStyle = .overCurrentContext
            vc.transitioningDelegate = vc
            accountContext.navigator.present(vc, from: from, animated: true)
        }

    }

    private func showMailUserPicker(selected: [LarkModel.PickerItem],
                                    title: String,
                                    from: UIViewController,
                                    finish: @escaping ([LarkModel.PickerItem]) -> Void) {

        //contactSearchPickerBody.delegate = self

        let filterBlock: ((LarkModel.PickerItem) -> Bool) = { item in
            switch item.meta {
            case .chatter(let meta):
                return !(meta.enterpriseMailAddress ?? "").isEmpty
            case .chat(let meta):
                return !(meta.enterpriseMailAddress ?? "").isEmpty
            case .mailUser(let meta):
                return !(meta.mailAddress ?? "").isEmpty
            default:
                break
            }
            return false
        }

        self.newPickerAction = (filterBlock, finish)
        //accountContext.navigator.present(body: contactSearchPickerBody, from: from, prepare: { $0.modalPresentationStyle = .formSheet })

        accountContext.provider.contactPickerProvider?.presentContactSearchPicker(title: title, confirmText: BundleI18n.MailSDK.Mail_Alert_Confirm, selected: selected, delegate: self, vc: from)
    }

    private func showInputTextFilterPicker(selectedTexts: [String],
                                           title: String,
                                           scene: SearchInputFilterViewController.Scene,
                                           from: UIViewController,
                                           finish: @escaping ([String]) -> Void) {
        let viewController = SearchInputFilterViewController(accountContext: accountContext,
                                                             title: title,
                                                             scene: scene,
                                                             selectedTexts: selectedTexts,
                                                             completion: { newSelectedTexts in
            finish(newSelectedTexts)
        })
        accountContext.navigator.present(viewController,
                                 wrap: LkNavigationController.self,
                                 from: from,
                                 prepare: { $0.modalPresentationStyle = .formSheet },
                                 animated: true)
    }

    func showAdvancedSearch(fromVC: UIViewController, supportFilters: [MailSearchFilter]) {
        var selectDocOwnMe = false
        var filters = supportFilters
//            .filter { filter in
//            switch filter {
//            case .specificFilterValue(_, _, _):
//                return false
//            default:
//                return true
//            }
//        }

        self.mockSelfChatter = nil

        let contentView = SearchAdvancedFilterView(frame: .zero, dataSource: filters)
        let popupContainer = SearchPopupHelper()
        self.searchPopupHelper = popupContainer
        contentView.itemSelect.drive(onNext: { [weak self, weak popupContainer, weak fromVC] filter in
            guard let self = self,
                  let fromVC = fromVC,
                  let container = popupContainer,
                  let filter = filter else { return }
            container.dismiss { [weak self, weak fromVC] in
                guard let self = self,
                      let fromVC = fromVC else { return }
                self.handle(filter: filter, from: fromVC) { [weak self] changedFilter in
                    self?.shouldChangeSearchFilterSubject.onNext(changedFilter)
                }
            }
        }).disposed(by: disposeBag)
        contentView.closeTapEvent.rx.event.asDriver().drive(onNext: { [weak popupContainer] _ in
            popupContainer?.dismiss(completion: {})
        })
        .disposed(by: disposeBag)
        contentView.resetFilterEvent.rx.event.asDriver().drive(onNext: { [weak self, weak popupContainer] _ in
            guard let self = self, let container = popupContainer else { return }
            container.dismiss(completion: {})
            self.shouldResetSearchFiltersSubject.onNext(true)
        })
        .disposed(by: disposeBag)
        popupContainer.showup(sourceVC: fromVC, contentView: contentView)
    }

    func pickerDidFinish(pickerVc: SearchPickerControllerType, items: [LarkModel.PickerItem]) -> Bool {
        if let finish = newPickerAction?.finishBlock {
            finish(items)
        }
        newPickerAction = nil
        return true
    }

    func pickerWillSelect(pickerVc: SearchPickerControllerType, item: LarkModel.PickerItem, isMultiple: Bool) -> Bool {
        if let filterBlock = newPickerAction?.selectItemFilterBlock {
            let result = filterBlock(item)
            if let window = pickerVc.view.window, !result {
                UDToast.showTips(with: BundleI18n.MailSDK.Mail_Common_NetworkError, on: window) // "没有邮箱"
            }

            // BundleI18n.LarkSearch.Lark_Contacts_NoBusinessEmail
            return result
        }
        return true
    }

    func pickerDidCancel(pickerVc: SearchPickerControllerType) -> Bool {
        newPickerAction = nil
        return true
    }
}
