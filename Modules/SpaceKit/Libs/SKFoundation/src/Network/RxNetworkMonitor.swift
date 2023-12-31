//
//  RxNetworkMonitor.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/9/26.
//

import Foundation
import RxSwift

public final class RxNetworkMonitor: RxNetworkMonitorType {
    public class func networkStatus(observerObj: AnyObject) -> Observable<NetworkStatus> {
        return Observable.create({[weak observerObj] (observer) -> Disposable in
            guard let observerObj = observerObj else { return Disposables.create() }
            DocsNetStateMonitor.shared.addObserver(observerObj) { (networkType, isReachable) in
                observer.onNext((networkType: networkType, isReachable: isReachable))
            }
            return Disposables.create()
        })
    }
}


public protocol RxNetworkMonitorType {
    typealias NetworkStatus = (networkType: NetworkType, isReachable: Bool)
    static func networkStatus(observerObj: AnyObject) -> Observable<NetworkStatus>
}
