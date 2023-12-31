//
//  TestViewController.swift
//  LarkAddressBookSelectorDev
//
//  Created by zhenning on 2021/2/21.
//

import UIKit
import Foundation
import LarkAddressBookSelector
import RxSwift

class TestViewController: UIViewController {

    let btn = UIButton()
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .white

        btn.frame = CGRect(100, 150, 280, 44)
        btn.backgroundColor = .gray
        btn.titleLabel?.font = .systemFont(ofSize: 12)
        btn.setTitle("push selectContactListVC", for: .normal)
        btn.addTarget(self, action: #selector(clickBtn), for: .touchUpInside)
        self.view.addSubview(btn)
    }

    @objc
    func clickBtn() {
        let naviBarTitle = "从通讯录导入"
        let selectContactListVC = SelectContactListController(
            contactContentType: .phone,
            contactTableSelectType: .multiple,
            naviBarTitle: naviBarTitle,
            contactNumberLimit: 50)
        selectContactListVC.delegate = self
        self.navigationController?.pushViewController(selectContactListVC, animated: true)
        print("click btn")
    }
}

extension TestViewController: SelectContactListControllerDelegate {
    func onContactsDataLoadedByExtrasIfNeeded(loaded: Bool, allContacts: [AddressBookContact]) -> Observable<[ContactExtraInfo]>? {
        let contactExtras: [ContactExtraInfo] = allContacts.compactMap { (contact) -> ContactExtraInfo in
            return ContactExtraInfo(contact: contact, contactTag: ContactTag(tagContent: "飞书用户"))
        }
        return Observable.just(contactExtras)
    }
}
