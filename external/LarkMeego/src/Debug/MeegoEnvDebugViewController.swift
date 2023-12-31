//
//  MeegoEnvDebugViewController.swift
//  LarkFlutterContainerExample_Example
//
//  Created by shizhengyu on 2021/9/10.
//  Copyright © 2021 shizhengyu All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import UniverseDesignToast
import LarkMeegoPush
import LarkMeegoLogger
import LarkEnv
import LarkAccountInterface
import LarkContainer

public class MeegoEnvDebugViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {
    private var envValueList: [MeegoEnv.MeegoDebugEnvKey: String] = [:]

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        for key in MeegoEnv.envKeyList {
            let value = MeegoEnv.get(key)
            if key == .domainType && value.isEmpty {
                let passportUserService = try? Container.shared.getCurrentUserResolver().resolve(assert: PassportUserService.self)
                let isInnerDomain = (EnvManager.env.isStaging || passportUserService?.userTenant.tenantID == "1")
                envValueList[key] = isInnerDomain ? "0" : "1"
            } else {
                envValueList[key] = value
            }
        }

        title = "Meego Env Debugger"
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.left.right.bottom.equalToSuperview()
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MeegoEnv.envKeyList.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let envDebugKey = MeegoEnv.envKeyList[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: envDebugKey.cellType.rawValue) as? MeegoEnvDebugBaseCell {
            cell.envName = envDebugKey.description

            switch envDebugKey.cellType {
            case .display:
                if let cell = cell as? MeegoEnvDebugDisplayCell {
                    cell.update(envValueList[envDebugKey] ?? "")
                }
            case .textEdit:
                if let cell = cell as? MeegoEnvDebugTextEditCell {
                    cell.update(envValueList[envDebugKey] ?? "")
                    cell.listen = { [weak self] (newValue) in
                        self?.textEditCellValueChanged(newValue: newValue, key: envDebugKey)
                    }
                }
            case .switch:
                if let cell = cell as? MeegoEnvDebugSwitchCell {
                    cell.update(envValueList[envDebugKey] ?? "")
                    cell.listen = { (newValue: Bool) in
                        MeegoEnv.set(envDebugKey, value: newValue ? "1" : "0")
                    }
                }
            case .operation:
                if let cell = cell as? MeegoEnvDebugOperationCell {
                    cell.listen = { [weak self] in
                        self?.executeOperation(key: envDebugKey)
                    }
                }
            }

            return cell
        }

        return UITableViewCell()
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = UIColor.ud.bgBase
        tableView.bounces = true
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.register(MeegoEnvDebugDisplayCell.self, forCellReuseIdentifier: MeegoEnvDebugInteractType.display.rawValue)
        tableView.register(MeegoEnvDebugTextEditCell.self, forCellReuseIdentifier: MeegoEnvDebugInteractType.textEdit.rawValue)
        tableView.register(MeegoEnvDebugSwitchCell.self, forCellReuseIdentifier: MeegoEnvDebugInteractType.switch.rawValue)
        tableView.register(MeegoEnvDebugOperationCell.self, forCellReuseIdentifier: MeegoEnvDebugInteractType.operation.rawValue)
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
}

private extension MeegoEnvDebugViewController {
    func executeOperation(key: MeegoEnv.MeegoDebugEnvKey) {
        switch key {
        case .clearFlutterCache:
            if let appDomain = Bundle.main.bundleIdentifier, let prefs = UserDefaults.standard.persistentDomain(forName: appDomain) {
                for (key, value) in prefs where key.hasPrefix("flutter.") {
                    UserDefaults.standard.removeObject(forKey: key)
                }
            }
            if let storagePath = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first {
                try? FileManager.default.removeItem(atPath: storagePath + "/mgstorage")
            }
            UDToast.showSuccess(with: "清理成功", on: view)
        case .mgFeatureGatingDebug:
            let FGDebugVC = MeegoFGDebugController()
            navigationController?.pushViewController(FGDebugVC, animated: true)
            break
        default:
            break
        }
    }

    func textEditCellValueChanged(newValue: String, key: MeegoEnv.MeegoDebugEnvKey) {
        switch key {
        case .registerTopic:
            var testTopic = Topic(topicType: 101,
                                  topicName: newValue)

            MeegoPushNativeService.registerPush(topic: testTopic, listener: self)
        case .unregisterTopic:
            var testTopic = Topic(topicType: 101,
                                  topicName: newValue)

            MeegoPushNativeService.unregisterPush(topic: testTopic)
        default:
            MeegoEnv.set(key, value: newValue)
            break
        }
    }
}

// Mark - func of MeegoPushDataListener

extension MeegoEnvDebugViewController: MeegoPushDataListener {
    public func onTopicVersionAtLastPush(topicName: String, currentVersion: Int, currentTimestamp: Int) {
        MeegoLogger.debug("[LarkMeegoPush] 🚀 onTopicVersionAtLastPush: seqID: \(currentVersion) timestamp: \(currentTimestamp)")
    }

    public func onPushContentData(_ content: Data, seqID: Int64, timestamp: Int64) {
        MeegoLogger.debug("[LarkMeegoPush] 🚀 onPushContentData: seqID: \(seqID) timestamp: \(timestamp)")
    }

    public func onPushPayload(_ payload: Data) {
    }
}
