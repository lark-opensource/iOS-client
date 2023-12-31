//
//  SearchViewController+Filter.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/11/16.
//

import Foundation

struct SearchRouteParam {
    let input: SearcherInput
}

extension MailSearchViewController {
//    func route(withParam routeParam: SearchRouteParam) {
////            let targetTab = viewModel.tabService?.getCompleteSearchTab(type: routeParam.type) ?? routeParam.type
//        capsuleViewModel.capsulePage.resetAllFilters()
//        capsuleViewModel.capsulePage.lastInput = nil
//        let capsulePage = capsuleViewModel.capsulePage// viewModel.createCapsulePage(withTab: targetTab)
//        let filters = viewModel.appendTabFilters(searchTabConfig: capsulePage.tabConfig, inputFilters: routeParam.input.filters)
//        capsulePage.coverSelectedFilters(filters: filters)
//        capsuleViewModel.updateCapsulePage(page: capsulePage)
//
//        let newInput = SearcherInput(query: routeParam.input.query,
//                                     filters: capsuleViewModel.mergeSelectedAndSupportFilter(selected: capsulePage.selectedFilters,
//                                                                                             supported: capsulePage.tabConfig?.supportedFilters ?? []))
//        if let contentVC = currentController as? SearchContentViewController {
//            contentVC.routeTo(withSearchInput: newInput, isCapsuleStyle: true)
//        }
//    }


}
