//
//  RxSwift+Extension.swift
//  Calendar
//
//  Created by Rico on 2021/10/18.
//

import Foundation
import RxSwift
import RxRelay

extension BehaviorRelay where Element == Bool {

    func toggle() {
        accept(!value)
    }
}
