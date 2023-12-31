//
//  DataFetcher.swift
//  Lark
//
//  Created by liuwanlin on 2018/6/11.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift

protocol DataFetcher {
    func asyncFetch(with item: CollectItem) -> Observable<PackData>
}
