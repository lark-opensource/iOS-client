//
//  PushDispatcher.swift
//  LarkAIInfra
//
//  Created by huayufan on 2023/7/19.
//  


import RxSwift
import RxCocoa


final class PushDispatcher {

    init() {}

    static let shared = PushDispatcher()
    
    var pushResponse = PublishRelay<InlineAIPushResponse>()
    
}
