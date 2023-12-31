//
//  ZoomAlternativeHostViewModel.swift
//  Calendar
//
//  Created by pluto on 2022/11/2.
//

import Foundation
import RxSwift

protocol ZoomAlternativeHostViewModelDelegate: AnyObject {
    func refreshData()
}

final class ZoomAlternativeHostViewModel {

    var selectedData: [String]
    weak var delegate: ZoomAlternativeHostViewModelDelegate?

    init(info: [String]) {
        self.selectedData = info
    }

    func removeAddr(pos: Int) {
        if pos < 0 || pos > selectedData.count { return }
        selectedData.remove(at: pos)

        DispatchQueue.main.async {
            self.delegate?.refreshData()
        }
    }
}
