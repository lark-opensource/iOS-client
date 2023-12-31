//
//  EncryptionUpgradeBaseState.swift
//  LarkSecurityCompliance
//
//  Created by AlbertSun on 2023/5/15.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

protocol EncryptionUpgradeState {
    var state: EncryptionUpgrade.State { get }
    var image: UIImage { get }
    var title: String { get }
    var text: String { get }
    func hide()
    func show()
    func onThemeChange(withDarkMode: Bool)
}
