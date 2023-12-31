//
//  SearchAdvancedSyntaxCellViewModel.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/12/7.
//

import Foundation
import LarkSearchFilter

final class SearchAdvancedSyntaxCellViewModel {
    let filter: SearchFilter
    let requestInfo: RequestInfo

    init(filter: SearchFilter, requestInfo: RequestInfo) {
        self.filter = filter
        self.requestInfo = requestInfo
    }
}
