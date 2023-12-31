//
//  NewShareSettingsVMProtocol.swift
//  ByteView
//
//  Created by Tobb Huang on 2021/5/27.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

protocol NewShareSettingsVMProtocol {
    var adapter: IterableAdapter { get }

    var showLoadingObservable: Observable<Bool> { get set }

    var validFileTypes: [NewShareContentItem] { get }
}
