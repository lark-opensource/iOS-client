//
//  InlineAIMentionUserServiceImpl.swift
//  LarkAI
//
//  Created by ByteDance on 2023/9/27.
//

import Foundation
import LarkModel
import LarkAIInfra
import LarkSearchCore
import LarkContainer
import EENavigator
import LarkUIKit
import RxSwift
import RxCocoa
import LarkMessengerInterface

/// 浮窗组件@ 人服务实现逻辑
class InlineAIMentionUserServiceImpl {

    private var pickCallback: (([LarkModel.PickerItem]?) -> Void)?

    let userResolver: UserResolver

    private var firstPageLoader: Observable<PickerRecommendResult>?
    private var moreLoader: Observable<PickerRecommendResult>?

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    private func createPickerVC(title: String) -> UIViewController {

        let controller = SearchPickerNavigationController(resolver: userResolver)
        let recommendView = PickerRecommendListView(resolver: userResolver)
        recommendView.add(provider: self, for: "key")
        controller.defaultView = recommendView

        controller.searchConfig = PickerSearchConfig(entities: [
            PickerConfig.ChatterEntityConfig() // 选择人员
        ])

        let multiSelection = PickerFeatureConfig.MultiSelection(isOpen: true) // 支持多选

        let naviBarConfig = PickerFeatureConfig.NavigationBar(title: title,
                                                              showSure: true)

        let searchBarConfig = PickerFeatureConfig.SearchBar(hasBottomSpace: false,
                                                            autoFocus: true,
                                                            autoCorrect: true)

        controller.featureConfig = PickerFeatureConfig(scene: .ccmInlineAI,
                                                       multiSelection: multiSelection,
                                                       navigationBar: naviBarConfig,
                                                       searchBar: searchBarConfig)
        controller.pickerDelegate = self
        return controller
    }
}

// MARK: - PickerRecommendLoadable
extension InlineAIMentionUserServiceImpl: PickerRecommendLoadable {

    func load() -> Observable<PickerRecommendResult> {
        return self.firstPageLoader ?? Observable.just(PickerRecommendResult(items: [], hasMore: false, isPage: true))
    }

    func loadMore() -> Observable<PickerRecommendResult> {
        return self.moreLoader ?? Observable.just(PickerRecommendResult(items: [], hasMore: false, isPage: true))
    }
}

// MARK: - InlineAIMentionUserService
extension InlineAIMentionUserServiceImpl: InlineAIMentionUserService {

    func showMentionUserPicker(title: String, callback: @escaping ([PickerItem]?) -> Void) {
        pickCallback = callback

        let pickerVC = createPickerVC(title: title)
        let navFrom = NavigatorFromWrap(userResolver: userResolver)
        userResolver.navigator.present(pickerVC, from: navFrom)
    }

    func onClickUser(chatterId: String, fromVC: UIViewController) {
        let body = PersonCardBody(chatterId: chatterId, source: .calendar) // 目前只有日历在使用inline AI @人的功能
        userResolver.navigator.present(body: body,
                                       wrap: LkNavigationController.self,
                                       from: fromVC,
                                       prepare: { (vc) in vc.modalPresentationStyle = .formSheet },
                                       animated: true,
                                       completion: nil)
    }

    func setRecommendUsersLoader(firstPageLoader: Observable<PickerRecommendResult>,
                                 moreLoader: Observable<PickerRecommendResult>) {
        self.firstPageLoader = firstPageLoader
        self.moreLoader = moreLoader
    }
}

// MARK: SearchPickerDelegate
extension InlineAIMentionUserServiceImpl: SearchPickerDelegate {

    /// Picker完成,回调选中的item数组, 单选模式下返回一个item, 多选模式下返回所有选中的items
    /// - Parameters:
    ///   - pickerVc: 持有picker的顶层vc, picker模式是SearchPickerNavigationController, 大搜模式是SearchPickerViewController, 可用于调用pickerVc的方法, 也可用于手动关闭Picker
    /// - Returns: 返回true时, 完成后默认关闭Picker, 返回false时, 不关闭Picker, 由业务处理后续逻辑
    func pickerDidFinish(pickerVc: LarkModel.SearchPickerControllerType, items: [LarkModel.PickerItem]) -> Bool {
        pickCallback?(items)
        pickCallback = nil
        return true
    }

    /// Picker内部关闭按钮触发时机
    /// - Returns: 返回false时, 不会关闭Picker,需要业务手动实现
    func pickerDidCancel(pickerVc: LarkModel.SearchPickerControllerType) -> Bool {
        pickCallback?([])
        pickCallback = nil
        return true
    }
}

private class NavigatorFromWrap: NavigatorFrom {

    let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    var fromViewController: UIViewController? {
        let topMost = userResolver.navigator.mainSceneTopMost
        return topMost
    }

    var canBeStrongReferences: Bool { false }
}
