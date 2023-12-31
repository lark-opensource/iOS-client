//
//  PickerFeatureGating.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/9/4.
//

import Foundation
import LarkContainer
import LarkSetting
import LarkFeatureGating

class PickerFeatureGating: PickerFeatureGatingType {
    let resolver: UserResolver

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    func isEnable(name: PickerFeatureGatingName) -> Bool {
        return self.resolver.fg.staticFeatureGatingValue(with: FeatureGatingManager.Key(stringLiteral: name.rawValue))
    }
}
