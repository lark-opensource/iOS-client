//
//  HasViewModel.swift
//  Todo
//
//  Created by 张威 on 2020/11/16.
//

import Foundation

protocol HasViewModel {
    associatedtype ViewModel

    var viewModel: ViewModel { get }
}
