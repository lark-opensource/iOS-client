//
//  SearchOptionConvertable.swift
//  LarkSearchCore
//
//  Created by Yuri on 2022/11/22.
//

import Foundation
import LarkModel
import LarkSDKInterface
import RustPB

public protocol SearchOptionSDKConvertable: SearchOptionConvertable {
    func convert(option: Option) -> SearchOption?
}

public extension SearchOptionSDKConvertable {
    func convert(option: Option) -> SearchOption? {
        if let result = option as? LarkSDKInterface.Search.Result,
           let res = result.base as? Search_V2_SearchResult {
            return convert(result: res)
        } else {
            return nil
        }
    }
}
