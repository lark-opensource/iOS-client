//
//  SearchBlockPresentable.swift
//  LarkSearch
//
//  Created by Patrick on 2022/4/14.
//

import Foundation

protocol SearchBlockPresentable: SearchCellViewModel {
    var indexPath: IndexPath? { get set }
}
