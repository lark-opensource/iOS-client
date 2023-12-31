//
//  WaterMarkPassportDelegate.swift
//  LarkWaterMark
//
//  Created by Xingjian Sun on 2022/9/22.
//

import Foundation
import LarkAccountInterface
import RxSwift
import RxCocoa

protocol WaterMarkPassportDelegate: PassportDelegate {
    var userLoginSignal: Observable<String> { get }
    var userLogoutSignal: Observable<String> { get }
}

final class WaterMarkUserStateDelegate: WaterMarkPassportDelegate {
    let name: String = "WaterMarkPassportDelegate"
    
    var userLoginSignal: Observable<String> {
        return onUserOnline.asObservable()
    }
    
    var userLogoutSignal: Observable<String> {
        return onUserOffline.asObservable()
    }
    
    private let onUserOnline = PublishRelay<String>()
    private let onUserOffline = PublishRelay<String>()
    
    public func userDidOnline(state: PassportState) {
        onUserOnline.accept(state.description)
    }
    
    public func userDidOffline(state: PassportState) {
        onUserOffline.accept(state.description)
    }
}
