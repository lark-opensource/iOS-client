//
//  ChatterManagerProtocol.swift
//  LarkSDKInterface
//
//  Created by Supeng on 2021/5/21.
//

import Foundation
import LarkAccountInterface
import LarkModel
import RxSwift

public protocol ChatterManagerProtocol: LauncherDelegate {
    var currentChatterObservable: Observable<LarkModel.Chatter> { get }
    var currentChatter: LarkModel.Chatter { get set }
    func logout()
    func updateUser(_ user: User)
}
