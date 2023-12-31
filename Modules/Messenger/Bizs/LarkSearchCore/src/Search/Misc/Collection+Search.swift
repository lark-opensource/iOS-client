//
//  LarkSearchCore
//
//  Created by SolaWing on 2020/12/29.
//

import Foundation
import LarkSDKInterface

public extension Search {
    public static func get<E>(array: [E], safeIndex: Int) -> E? {
        if safeIndex >= 0 && safeIndex < array.count {
            return array[safeIndex]
        }
        return nil
    }
}
