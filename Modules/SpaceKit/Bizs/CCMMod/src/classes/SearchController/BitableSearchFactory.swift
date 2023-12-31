//
//  BitableSearchFactory.swift
//  CCMMod
//
//  Created by qiyongka on 2023/11/5.
//

import Foundation
import EENavigator
import LarkNavigator
import LKCommonsLogging
import SpaceInterface
import LarkContainer
import LarkUIKit
import SKResource

#if MessengerMod
import LarkSearch
import LarkSearchCore
import LarkModel
import LarkMessengerInterface
#endif

final class BitableSearchFactory: BitableSearchFactoryProtocol {
    let userResolver: UserResolver
    
    weak var selectDelegate: BitableSearchFactorySelectProtocol?
    
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
    
    
    func jumpToSearchController(fromVC: UIViewController) {
        #if MessengerMod
        let body = SearchMainBody(topPriorityScene: .rustScene(.searchDoc), sourceOfSearch: .docs)
        Navigator.shared.push(body: body, from: fromVC)
        #endif
    }
    
    func jumpToPickerBaseSearchController(selectDelegate: BitableSearchFactorySelectProtocol, fromVC: UIViewController) {
        #if MessengerMod
        let controller = SearchPickerViewController(resolver: userResolver)
        let searchBarConfig = PickerFeatureConfig.SearchBar(placeholder: SKResource.BundleI18n.SKResource.Bitable_HomeDashboard_SearchBase_Placeholder,
                                                            hasBottomSpace: false,
                                                            autoFocus: false)
        controller.featureConfig = PickerFeatureConfig(scene: .ccmSearchInSpace,
                                                       searchBar: searchBarConfig)
        let viewModel = CCMSpaceSearchViewModel(currentFolder: nil, resolver: userResolver)
        let defaultSearchConfig = viewModel.generateBitableSearchConfig()
        controller.searchConfig = defaultSearchConfig
        controller.pickerDelegate = self
        self.selectDelegate = selectDelegate
        controller.defaultView = PickerRecommendListView(resolver: userResolver)
        
        let targetVC = LkNavigationController(rootViewController: controller)
        targetVC.modalPresentationStyle = .formSheet
        fromVC.present(targetVC, animated: true)
        #endif
    }
    
}

#if MessengerMod
extension BitableSearchFactory: SearchPickerDelegate {
    func pickerDidSelect(pickerVc: SearchPickerControllerType, item: PickerItem, isMultiple: Bool) {
        self.selectDelegate?.pushSearchResultVCWithSelectItem(item, pickerVC: pickerVc)
    }
    
    //是否在完成选择之后关闭当前 searchViewController
    // return false不关闭
    func pickerDidFinish(pickerVc: SearchPickerControllerType, items: [PickerItem]) -> Bool {
        return false
    }
}
#endif
