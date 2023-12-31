//
//  FileMigrationVC.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/11/28.
//

import UIKit
import LarkContainer

typealias FileMigrationDebugFrom = FileMigrationDebugVC.From

protocol FileMigrationDebug {
    init(userResolver: UserResolver, from: FileMigrationDebugFrom, vc: UIViewController?)
    
    func trigger()
}

final class FileMigrationDebugVC: UITableViewController, FileCryptoDebugHandle {
    
    enum Action: String {
        case v1ToV2 = "v1 to v2"
        case normalToV2 = "normal to v2"
        
        case v2ToV1 = "v2 to v1"
        case normalToV1 = "normal to v1"
        
        case perfs = "大文件检测"
    }
    
    enum From: String {
        case fileHandle = "File Handle"
        case inputStream = "Input Stream"
        case sandboxInputStream = "Sandbox Input Stream"
    }
    
    struct Section {
        let title: From
        let actions: [Action]
    }
    
    let cryptoEntrances: [Action: FileMigrationDebug.Type] = {
        [
            .normalToV2: FileMigrationNormalToV2DebugHandle.self,
            .perfs: FileMigrationPerfsDebugHandle.self
        ]
    }()
    
    let models: [Section] = [
        Section(title: .fileHandle, actions: [.normalToV2, .perfs]),
        Section(title: .inputStream, actions: [.normalToV2]),
        Section(title: .sandboxInputStream, actions: [.normalToV2]),
    ]
    
    let userResolver: UserResolver
    weak var viewController: UIViewController?
    
    init(userResolver: UserResolver, viewController: UIViewController?) {
        self.userResolver = userResolver
        self.viewController = viewController
        if #available(iOS 13.0, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func handle() {
        viewController?.navigationController?.pushViewController(self, animated: true)
    }
    
    private var keys: [Crypto] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "测试数据迁移"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        models.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        models[section].actions.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        models[section].title.rawValue
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell")
        let key = models[indexPath.section].actions[indexPath.row]
        cell?.textLabel?.text = key.rawValue
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let key = models[indexPath.section].actions[indexPath.row]
        let debugType = cryptoEntrances[key]
        debugType?.init(userResolver: userResolver, from: models[indexPath.section].title, vc: self).trigger()
    }
    
}
