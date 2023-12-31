//
//  ServiceStateManager.swift
//  Calendar
//
//  Created by 白言韬 on 2020/9/27.
//

import Foundation

protocol ServiceStateManagerDelegate: AnyObject {
    func reloadData()
    func clearData()
}

final class ServiceStateManager {
    var isActive: Bool
    var isClean: Bool
    private var activateCount: Int
    private var initValue: (Bool, Bool, Int)
    weak var delegate: ServiceStateManagerDelegate?

    init(
        isActive: Bool = false,
        isClean: Bool = false,
        activateCount: Int = 0
    ) {
        self.isActive = isActive
        self.isClean = isClean
        self.activateCount = activateCount
        self.initValue = (isActive, isClean, activateCount)
    }

    func reset() {
        isActive = initValue.0
        isClean = initValue.1
        activateCount = initValue.2
        delegate?.clearData()
    }

    func activate() {
        if !isClean {
            delegate?.reloadData()
        }
        activateCount += 1
        isActive = true
    }

    func inActivate() {
        activateCount -= 1
        if activateCount == 0 {
            isActive = false
        }
        if activateCount < 0 {
            assertionFailure("activate() and inActivate() do not appear in pairs")
        }
    }
}
