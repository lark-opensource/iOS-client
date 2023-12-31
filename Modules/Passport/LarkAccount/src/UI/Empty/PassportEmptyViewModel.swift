//
//  PassportNotiveViewModel.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/7/4.
//

import Foundation
import UniverseDesignButton
import UIKit
import UniverseDesignEmpty

class PassportEmptyViewModel {

    var type: UDEmptyType

    let title: String

    let subTitle: String

    let primaryButtonTitle: String

    let secondaryButtonTitle: String?

    init(type: UDEmptyType, title: String, subTitle: String, primaryButtonTitle: String, secondaryButtonTitle: String?) {
        self.type = type
        self.title = title
        self.subTitle = subTitle
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryButtonTitle = secondaryButtonTitle
    }

    func handlePrimaryButtonAction() {}

    func handleSecondaryButtonAction() {}
}
