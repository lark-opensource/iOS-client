//
//  File.swift
//  LarkUIKit
//
//  Created by Supeng on 2020/12/10.
//

import Foundation
import RxSwift

public final class ApplicationBadgeNumber {

    public static let shared = ApplicationBadgeNumber()

    public var badgeNumberObservable: Observable<Int>
    private let badgeNumberPublishSubject = PublishSubject<Int>()

    private init() {
        badgeNumberObservable = badgeNumberPublishSubject.asObservable()
    }

    public func getIconBadgeNumber(completion: @escaping (Int) -> Void) {
        LKApplicationBadge.requestNumber(completion)
    }

    public func setIconBadgeNumber(_ badgeNumber: Int) {
        LKApplicationBadge.setApplicationBadgeNumber(badgeNumber, callback: { [weak self] in
            self?.badgeNumberPublishSubject.onNext(badgeNumber)
        })
    }

    public func incrementBadgeBumber(by number: Int) {
        getIconBadgeNumber { [weak self] badgeNumber in
            self?.setIconBadgeNumber(badgeNumber + number)
        }
    }
}
