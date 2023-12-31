//
//  LanguageModel.swift
//  LarkUIKit
//
//  Created by Miaoqi Wang on 2020/7/30.
//

import Foundation
import LarkLocalizations

public final class LanguageModel: Equatable {

    public private(set) var name: String
    public private(set) var language: Lang
    public private(set) var isSystem: Bool
    var isSelected: Bool

    public init(name: String, language: Lang, isSelected: Bool, isSystem: Bool = false) {
        self.name = name
        self.language = language
        self.isSelected = isSelected
        self.isSystem = isSystem
    }

    public static func == (lhs: LanguageModel, rhs: LanguageModel) -> Bool {
        return lhs.language == rhs.language && lhs.isSystem == rhs.isSystem
    }
}
