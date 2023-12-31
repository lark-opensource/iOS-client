//
//  SettingsRegister.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/7/27.
//

import Foundation
import EENavigator
import LarkSecurityComplianceInterface
import LarkSecurityCompliance
import LarkContainer
import UniverseDesignDialog
import LarkAppLog
import UniverseDesignToast
import LarkAccountInterface
import UniverseDesignLoading
import LarkSecurityComplianceInfra
import SwiftyJSON
import RxSwift

final class SettingsRegister: SCDebugModelRegister {
    
    let userResolver: UserResolver
    
    let disposedBag = DisposeBag()
    
    var settingKey: [SCSettingKey] = []
    
    var fgKey: [SCFGKey] = []
    
    let pickerVC = PickViewController(model: BasicType.allCases.map({ $0.rawValue }))
    
    init(resolver: LarkContainer.UserResolver) {
        self.userResolver = resolver
    }
    
    private func registSettingsModels() {
        guard let debugEntrance = try? userResolver.resolve(assert: SCDebugEntrance.self) else { return }
        debugEntrance.regist(section: .settingsAndFG) {
            SCDebugModel(cellTitle: "static json", cellType: .normal, normalHandler: { [weak self] in
                guard let self,
                      let service = try? self.userResolver.resolve(assert: SCSettingService.self),
                      let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
                let vc = SCDebugTextViewController()
                vc.getText = {
                    service.json.rawString() ?? "empty"
                }
                DispatchQueue.main.async {
                    Navigator.shared.push(vc, from: fromVC)
                }
            })
        }

        debugEntrance.regist(section: .settingsAndFG) {
            SCDebugModel(cellTitle: "realtime json", cellType: .normal, normalHandler: { [weak self] in
                guard let self,
                      let service = try? self.userResolver.resolve(assert: SCRealTimeSettingService.self),
                      let fromVC = Navigator.shared.mainSceneWindow?.fromViewController else { return }
                let vc = SCDebugTextViewController()
                vc.getText = {
                    service.json.rawString() ?? "empty"
                }
                DispatchQueue.main.async {
                    Navigator.shared.push(vc, from: fromVC)
                }
            })
        }

        debugEntrance.regist(section: .settingsAndFG) {
            SCDebugModel(cellTitle: "observe Settings Key", cellType: .normal, normalHandler: { [weak self] in
                guard let self,
                      let service = try? self.userResolver.resolve(assert: SCRealTimeSettingService.self),
                      let fromVC = Navigator.shared.mainSceneWindow?.fromViewController,
                      let window = Navigator.shared.mainSceneWindow else { return }
                let dialog = UIAlertController(title: "observe Settings Key", message: nil, preferredStyle: .alert)
                dialog.addTextField { textField in
                    textField.placeholder = "input settings key"
                }
                dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak dialog] _ in
                    guard let str = dialog?.textFields?[0].text else { return }
                    let key = self.generateSettingKeyIfNeed(rawValue: str)
                    let _ = service.registObserver(key: key) { newValue in
                        DispatchQueue.main.async {
                            let message = "\(key) is updated, new value: \(newValue)"
                            SCLogger.info(message)
                            let noticeDialog = UIAlertController(title: "observe Settings Key", message: message, preferredStyle: .alert)
                            noticeDialog.addAction(UIAlertAction(title: "OK", style: .default))
                            Navigator.shared.present(noticeDialog, from: fromVC)
                        }
                    }
                }))
                dialog.addAction(UIAlertAction(title: "cancel", style: .cancel))
                DispatchQueue.main.async {
                    Navigator.shared.present(dialog, from: fromVC)
                }
            })
        }

        debugEntrance.regist(section: .settingsAndFG) {
            SCDebugModel(cellTitle: "bool", cellType: .normal, normalHandler: { [weak self] in
                guard let self,
                      let service = try? self.userResolver.resolve(assert: SCSettingService.self),
                      let realtimeService = try? self.userResolver.resolve(assert: SCRealTimeSettingService.self),
                      let fromVC = Navigator.shared.mainSceneWindow?.fromViewController,
                      let window = Navigator.shared.mainSceneWindow else { return }
                let dialog = UIAlertController(title: "bool settings", message: nil, preferredStyle: .alert)
                dialog.addTextField { textField in
                    textField.placeholder = "input settings key"
                }
                dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak dialog] _ in
                    guard let str = dialog?.textFields?[0].text else { return }
                    let key = self.generateSettingKeyIfNeed(rawValue: str)
                    let textVC = SCDebugTextViewController()
                    textVC.getText = { "static value \(service.bool(key))\n\nrealtime value \(realtimeService.bool(key))" }
                    Navigator.shared.push(textVC, from: fromVC)
                }))
                dialog.addAction(UIAlertAction(title: "cancel", style: .cancel))
                DispatchQueue.main.async {
                    Navigator.shared.present(dialog, from: fromVC)
                }
            })
        }

        debugEntrance.regist(section: .settingsAndFG) {
            SCDebugModel(cellTitle: "int", cellType: .normal, normalHandler: { [weak self] in
                guard let self,
                      let service = try? self.userResolver.resolve(assert: SCSettingService.self),
                      let realtimeService = try? self.userResolver.resolve(assert: SCRealTimeSettingService.self),
                      let fromVC = Navigator.shared.mainSceneWindow?.fromViewController,
                      let window = Navigator.shared.mainSceneWindow else { return }
                let dialog = UIAlertController(title: "int settings", message: nil, preferredStyle: .alert)
                dialog.addTextField { textField in
                    textField.placeholder = "input settings key"
                }
                dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak dialog] _ in
                    guard let str = dialog?.textFields?[0].text else { return }
                    let key = self.generateSettingKeyIfNeed(rawValue: str)
                    let textVC = SCDebugTextViewController()
                    textVC.getText = { "static value \(service.int(key))\n\nrealtime value \(realtimeService.int(key))" }
                    Navigator.shared.push(textVC, from: fromVC)
                }))
                dialog.addAction(UIAlertAction(title: "cancel", style: .cancel))
                DispatchQueue.main.async {
                    Navigator.shared.present(dialog, from: fromVC)
                }
            })
        }

        debugEntrance.regist(section: .settingsAndFG) {
            SCDebugModel(cellTitle: "string", cellType: .normal, normalHandler: { [weak self] in
                guard let self,
                      let service = try? self.userResolver.resolve(assert: SCSettingService.self),
                      let realtimeService = try? self.userResolver.resolve(assert: SCRealTimeSettingService.self),
                      let fromVC = Navigator.shared.mainSceneWindow?.fromViewController,
                      let window = Navigator.shared.mainSceneWindow else { return }
                let dialog = UIAlertController(title: "string settings", message: nil, preferredStyle: .alert)
                dialog.addTextField { textField in
                    textField.placeholder = "input settings key"
                }
                dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak dialog] _ in
                    guard let str = dialog?.textFields?[0].text else { return }
                    let key = self.generateSettingKeyIfNeed(rawValue: str)
                    let textVC = SCDebugTextViewController()
                    textVC.getText = { "static value \(service.string(key))\n\nrealtime value \(realtimeService.string(key))" }
                    Navigator.shared.push(textVC, from: fromVC)
                }))
                dialog.addAction(UIAlertAction(title: "cancel", style: .cancel))
                DispatchQueue.main.async {
                    Navigator.shared.present(dialog, from: fromVC)
                }
            })
        }

        debugEntrance.regist(section: .settingsAndFG) {
            SCDebugModel(cellTitle: "dictionary", cellType: .normal, normalHandler: { [weak self] in
                guard let self,
                      let service = try? self.userResolver.resolve(assert: SCSettingService.self),
                      let realtimeService = try? self.userResolver.resolve(assert: SCRealTimeSettingService.self),
                      let fromVC = Navigator.shared.mainSceneWindow?.fromViewController,
                      let window = Navigator.shared.mainSceneWindow else { return }
                let dialog = UIAlertController(title: "string dictionary", message: nil, preferredStyle: .alert)
                dialog.addTextField { textField in
                    textField.placeholder = "input settings key"
                }
                dialog.addTextField { [weak self] textField in
                    guard let self else { return }
                    textField.placeholder = "input dic value type"
                    let picker = UIPickerView()
                    textField.inputView = picker
                    picker.dataSource = self.pickerVC
                    picker.delegate = self.pickerVC
                    self.pickerVC.getSelected = {
                        textField.text = $0
                    }
                }
                dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak dialog] _ in
                    guard let str = dialog?.textFields?[0].text,
                          let typeStr = dialog?.textFields?[1].text,
                          let typeEnum = BasicType(rawValue: typeStr) else { return }

                    let key = self.generateSettingKeyIfNeed(rawValue: str)
                    let textVC = SCDebugTextViewController()
                    switch typeEnum {
                    case .int:
                        textVC.getText = {
                            let staticValue: [String: Int] = service.dictionary(key)
                            let realtimeValue: [String: Int] = realtimeService.dictionary(key)
                            return "static value \(staticValue)\n\nrealtime value \(realtimeValue)"
                        }
                    case .string:
                        textVC.getText = {
                            let staticValue: [String: String] = service.dictionary(key)
                            let realtimeValue: [String: String] = realtimeService.dictionary(key)
                            return "static value \(staticValue)\n\nrealtime value \(realtimeValue)"
                        }
                    case .bool:
                        textVC.getText = {
                            let staticValue: [String: Bool] = service.dictionary(key)
                            let realtimeValue: [String: Bool] = realtimeService.dictionary(key)
                            return "static value \(staticValue)\n\nrealtime value \(realtimeValue)"
                        }
                    default:
                        textVC.getText = {
                            let staticValue: [String: Any] = service.dictionary(key)
                            let realtimeValue: [String: Any] = realtimeService.dictionary(key)
                            return "static value \(staticValue)\n\nrealtime value \(realtimeValue)"
                        }
                    }
                    Navigator.shared.push(textVC, from: fromVC)
                }))
                dialog.addAction(UIAlertAction(title: "cancel", style: .cancel))
                DispatchQueue.main.async {
                    Navigator.shared.present(dialog, from: fromVC)
                }
            })
        }

        debugEntrance.regist(section: .settingsAndFG) {
            SCDebugModel(cellTitle: "array", cellType: .normal, normalHandler: { [weak self] in
                guard let self,
                      let service = try? self.userResolver.resolve(assert: SCSettingService.self),
                      let realtimeService = try? self.userResolver.resolve(assert: SCRealTimeSettingService.self),
                      let fromVC = Navigator.shared.mainSceneWindow?.fromViewController,
                      let window = Navigator.shared.mainSceneWindow else { return }
                let dialog = UIAlertController(title: "string dictionary", message: nil, preferredStyle: .alert)
                dialog.addTextField { textField in
                    textField.placeholder = "input settings key"
                }
                dialog.addTextField { [weak self] textField in
                    guard let self else { return }
                    textField.placeholder = "input dic value type"
                    let picker = UIPickerView()
                    textField.inputView = picker
                    picker.dataSource = self.pickerVC
                    picker.delegate = self.pickerVC
                    self.pickerVC.getSelected = {
                        textField.text = $0
                    }
                }
                dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak dialog] _ in
                    guard let str = dialog?.textFields?[0].text,
                          let typeStr = dialog?.textFields?[1].text,
                          let typeEnum = BasicType(rawValue: typeStr) else { return }
                    let key = self.generateSettingKeyIfNeed(rawValue: str)
                    let textVC = SCDebugTextViewController()
                    switch typeEnum {
                    case .int:
                        textVC.getText = {
                            let staticValue: [Int] = service.array(key)
                            let realtimeValue: [Int] = realtimeService.array(key)
                            return "static value \(staticValue)\n\nrealtime value \(realtimeValue)"
                        }
                    case .string:
                        textVC.getText = {
                            let staticValue: [String] = service.array(key)
                            let realtimeValue: [String] = realtimeService.array(key)
                            return "static value \(staticValue)\n\nrealtime value \(realtimeValue)"
                        }
                    case .bool:
                        textVC.getText = {
                            let staticValue: [Bool] = service.array(key)
                            let realtimeValue: [Bool] = realtimeService.array(key)
                            return "static value \(staticValue)\n\nrealtime value \(realtimeValue)"
                        }
                    default:
                        textVC.getText = {
                            let staticValue: [Any] = service.array(key)
                            let realtimeValue: [Any] = realtimeService.array(key)
                            return "static value \(staticValue)\n\nrealtime value \(realtimeValue)"
                        }
                    }
                    Navigator.shared.push(textVC, from: fromVC)
                }))
                dialog.addAction(UIAlertAction(title: "cancel", style: .cancel))
                DispatchQueue.main.async {
                    Navigator.shared.present(dialog, from: fromVC)
                }
            })
        }
    }

    private func registFGModels() {
        guard let debugEntrance = try? userResolver.resolve(assert: SCDebugEntrance.self) else { return }
        debugEntrance.regist(section: .settingsAndFG) {
            SCDebugModel(cellTitle: "static & realtime FG", cellType: .normal, normalHandler: { [weak self] in
                guard let self,
                      let service = try? self.userResolver.resolve(assert: SCFGService.self),
                      let fromVC = Navigator.shared.mainSceneWindow?.fromViewController,
                      let window = Navigator.shared.mainSceneWindow else { return }
                let dialog = UIAlertController(title: "static & realtime FG", message: nil, preferredStyle: .alert)
                dialog.addTextField { textField in
                    textField.placeholder = "input FG key"
                }
                dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak dialog] _ in
                    guard let str = dialog?.textFields?[0].text else { return }
                    let key = self.generateFGKeyIfNeed(rawValue: str)
                    let textVC = SCDebugTextViewController()
                    textVC.getText = { "static value \(service.staticValue(key))\n\nrealtime value \(service.realtimeValue(key))" }
                    Navigator.shared.push(textVC, from: fromVC)
                }))
                dialog.addAction(UIAlertAction(title: "cancel", style: .cancel))
                DispatchQueue.main.async {
                    Navigator.shared.present(dialog, from: fromVC)
                }
            })
        }

        debugEntrance.regist(section: .settingsAndFG) {
            SCDebugModel(cellTitle: "Observe FG Key", cellType: .normal, normalHandler: { [weak self] in
                guard let self,
                      let service = try? self.userResolver.resolve(assert: SCFGService.self),
                      let fromVC = Navigator.shared.mainSceneWindow?.fromViewController,
                      let window = Navigator.shared.mainSceneWindow else { return }
                let dialog = UIAlertController(title: "Observe FG Key", message: nil, preferredStyle: .alert)
                dialog.addTextField { textField in
                    textField.placeholder = "input settings key"
                }
                dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak dialog] _ in
                    guard let str = dialog?.textFields?[0].text else { return }
                    let key = self.generateFGKeyIfNeed(rawValue: str)
                    service
                        .observe(key)
                        .subscribe(onNext: { newValue in
                            DispatchQueue.main.async {
                                let message = "\(key) is updated, new value: \(newValue)"
                                SCLogger.info(message)
                                let noticeDialog = UIAlertController(title: "observe Settings Key", message: message, preferredStyle: .alert)
                                noticeDialog.addAction(UIAlertAction(title: "OK", style: .default))
                                Navigator.shared.present(noticeDialog, from: fromVC)
                            }

                        })
                        .disposed(by: self.disposedBag)
                }))
                dialog.addAction(UIAlertAction(title: "cancel", style: .cancel))
                DispatchQueue.main.async {
                    Navigator.shared.present(dialog, from: fromVC)
                }
            })
        }
    }

    func registModels() {
        registSettingsModels()
        registFGModels()
    }
}

extension SettingsRegister {
    private func generateSettingKeyIfNeed(rawValue: String) -> SCSettingKey {
        if let key = settingKey.first(where: { $0.rawValue == rawValue }) {
            return key
        }
        let key = SCSettingKey(rawValue: rawValue, version: "6.9", owner: "chenjinglin")
        settingKey.append(key)
        return key
    }

    private func generateFGKeyIfNeed(rawValue: String) -> SCFGKey {
        if let key = fgKey.first(where: { $0.rawValue == rawValue }) {
            return key
        }
        let key = SCFGKey(rawValue: rawValue, version: "6.9", owner: "chenjinglin")
        fgKey.append(key)
        return key
    }
}

private enum BasicType: String, CaseIterable {
    case int
    case string
    case bool
    case any
}
