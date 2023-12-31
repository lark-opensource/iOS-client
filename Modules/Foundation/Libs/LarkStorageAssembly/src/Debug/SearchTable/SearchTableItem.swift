//
//  SearchTableItem.swift
//  LarkStorageAssembly
//
//  Created by 李昊哲 on 2022/11/4.
//

#if !LARK_NO_DEBUG
import Foundation
import RxDataSources

protocol SearchTableItem: IdentifiableType, Equatable where Identity == String.Identity {
    var title: String { get }
    var identity: String { get }
}

extension SearchTableItem {
    var identity: String { title }
}

extension String: SearchTableItem {
    var title: String { self }
}
#endif
