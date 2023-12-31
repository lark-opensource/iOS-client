//
//  ExternalGroupCustomerSelectController.swift
//  LarkContact
//
//  Created by 姜凯文 on 2020/4/25.
//

import UIKit
import Foundation
import LarkSegmentedView

final class NewExternalGroupCustomerSelectController: CustomerSelectViewController, JXSegmentedListContainerViewListDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBase
        super.picker.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().inset(6)
            make.left.right.bottom.equalToSuperview()
        }
    }

    // MARK: JXSegmentedListContainerViewListDelegate
    func listView() -> UIView {
        return view
    }

    func listWillAppear() {
        configNaviBar()
    }

    func listWillDisappear() {
        let customNavigationItem = self.inputNavigationItem ?? self.navigationItem
        customNavigationItem.rightBarButtonItem = nil
    }
}
