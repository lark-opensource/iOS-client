//
//  Model.swift
//  TextFiledTest
//
//  Created by SuPeng on 8/7/19.
//  Copyright © 2019 SuPeng. All rights reserved.
//

import UIKit
import Foundation
import RxSwift
import LarkModel
import LarkMessengerInterface
import LarkAccountInterface
import LarkSDKInterface
import LarkOpenFeed
import LarkContainer

protocol ModifierValue {
    var id: String { get }
}

extension String: ModifierValue {
    var id: String { return "\(hashValue)" }
}
