//
//  MigrateAPI.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2021/1/10.
//

import Foundation
import RxSwift

protocol MigrateAPI {
    func migrateReset() -> Observable<Void>
}
