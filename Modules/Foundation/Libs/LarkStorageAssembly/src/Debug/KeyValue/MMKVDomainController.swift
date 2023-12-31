//
//  MMKVDomainController.swift
//  LarkStorageAssembly
//
//  Created by 李昊哲 on 2022/11/16.
//

import UIKit
import Foundation
#if !LARK_NO_DEBUG
import MMKV
import RxSwift
import EENavigator

struct MMKVDomainItem: SearchTableItem {
    let key: String
    let actualKey: String
    var title: String { key }
}

final class MMKVDomainController: SearchTableController<MMKVDomainItem> {
    let spaceName: String
    let domainName: String
    let mmkv: MMKV?

    init(space: String, domain: String) {
        spaceName = space
        domainName = domain

        let libraryPath = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
        let rootPath = (libraryPath as NSString).appendingPathComponent("MMKV")
        let mmapID = "lark_storage.\(spaceName)"

        mmkv = MMKV(mmapID: mmapID, rootPath: rootPath)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = domainName
        searchPlaceholder = "输入过滤文本..."
    }

    override func didSelected(item: MMKVDomainItem, cell _: UITableViewCell) {
        guard let mmkv = mmkv else { return }

        let controller = MMKVEditorController(mmkv: mmkv, item: item)
        Navigator.shared.push(controller, from: self)
    }

    override func didRemoved(item: MMKVDomainItem, cell: UITableViewCell) {
        self.mmkv?.removeValue(forKey: item.actualKey)
    }

    override func loadAllData() -> [MMKVDomainItem] {
        guard let mmkv = mmkv else {
            return []
        }

        return mmkv.allKeys().compactMap { key in
            guard let key = key as? String else {
                return nil
            }
            guard let result = keyRegex?.firstMatch(in: key, range: makeNSRange(key)) else {
                return nil
            }
            hasDataSubject.onNext(true)

            let domain = String(substring(key, withNSRange: result.range(at: 1)))
            let virtualKey = String(substring(key, withNSRange: result.range(at: 2)))
            guard domain == domainName else {
                return nil
            }

            return MMKVDomainItem(key: virtualKey, actualKey: key)
        }
    }
}
#endif
