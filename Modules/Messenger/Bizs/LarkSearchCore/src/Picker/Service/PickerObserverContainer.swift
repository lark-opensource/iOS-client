//
//  PickerObserverContainer.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/8/7.
//

import Foundation
import LarkModel

class PickerHandlerContainer {
    var observerMap = [String: SearchPickerHandlerType]()

    var observers: [SearchPickerHandlerType] {
        return Array(observerMap.values)
    }

    func register(observer: SearchPickerHandlerType) {
        self.observerMap[observer.pickerHandlerId] = observer
    }
}
