//
//  CollaborationSearchView.swift
//  LarkContact
//
//  Created by Nix Wang on 2022/11/28.
//

import Foundation
import UIKit
import LarkUIKit

class CollaborationSearchView: NavigationView {

    init(frame: CGRect, rootViewController: UIViewController) {
        super.init(frame: frame, root: rootViewController)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func popToRoot() {
        tapIndex(index: 0)
    }
}
