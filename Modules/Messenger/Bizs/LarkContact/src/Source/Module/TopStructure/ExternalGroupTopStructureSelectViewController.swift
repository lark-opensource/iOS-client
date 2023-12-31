//
//  ExternalGroupTopStructureSelectViewController.swift
//  LarkContact
//
//  Created by 姜凯文 on 2020/4/25.
//

import UIKit
import Foundation
import LarkSegmentedView
import SnapKit
import LarkSearchCore
import EENavigator

final class NewExternalGroupTopStructureSelectViewController: TopStructureSelectViewController, JXSegmentedListContainerViewListDelegate {
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

    override func unfold(_ picker: Picker) {
        let body = PickerSelectedBody(
            picker: self.picker,
            confirmTitle: BundleI18n.LarkContact.Lark_Legacy_ConfirmInfo,
            allowSelectNone: false,
            completion: { [weak self] _ in
                self?.sureDidClick()
            }
        )
        navigator.push(body: body, from: self)
    }
}
