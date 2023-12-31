//
//  FileAppealDebugRegister.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2022/10/13.
//

import Foundation
import LarkSecurityCompliance
import LarkSecurityComplianceInfra
import EENavigator
import LarkContainer

final class FileAppealDebugRegister: SCDebugModelRegister {

    let userResolver: UserResolver

    init(resolver: LarkContainer.UserResolver) {
        self.userResolver = resolver
    }

    func registModels() {
        guard let debugEntrance = try? userResolver.resolve(assert: SCDebugEntrance.self) else { return }
        debugEntrance.regist(section: .default) {
            SCDebugModel(cellTitle: "file appeal jump test", cellType: .normal, normalHandler: { [weak self] in
                guard let self else { return }
                let alertController = self.createAlertController()
                // 使用body作参数进行跳转
                let usingBodyArgsAction = UIAlertAction(title: "jump using body args", style: .default) { _ in
                    guard let textFields = alertController.textFields else {
                        return
                    }
                    let objToken = textFields[0].text ?? ""
                    let version = Int(textFields[1].text ?? "") ?? 0
                    let fileType = Int(textFields[2].text ?? "") ?? 0
                    let locale = textFields[3].text ?? ""
                    let body = FileAppealPageBody(objToken: objToken, version: version, fileType: fileType, locale: locale)
                    guard let vc = self.userResolver.navigator.mainSceneWindow else { return }
                    self.navigator.push(body: body, from: vc)
                }
                // 使用url作参数进行跳转
                let usingUrlArgsAction = UIAlertAction(title: "jump using url args", style: .default) { _ in
                    guard let textFields = alertController.textFields, var url = URL(string: "/client/file_security_check/appeal")else {
                        return
                    }
                    var parameters = [String: String]()
                    parameters.updateValue(textFields[0].text ?? "", forKey: "obj_token")
                    parameters.updateValue(textFields[1].text ?? "", forKey: "version")
                    parameters.updateValue(textFields[2].text ?? "", forKey: "file_type")
                    parameters.updateValue(textFields[3].text ?? "", forKey: "locale")
                    url = url.append(parameters: parameters, forceNew: false)
                    guard let vc = self.userResolver.navigator.mainSceneWindow else { return }
                    self.navigator.push(url, from: vc)
                }
                alertController.addAction(usingBodyArgsAction)
                alertController.addAction(usingUrlArgsAction)
                guard let vc = userResolver.navigator.mainSceneWindow else {
                    return
                }
                self.navigator.present(alertController, from: vc)
            })
        }
    }

    private func createAlertController() -> UIAlertController {
        let alertController = UIAlertController(title: "Please input your args", message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = "objToken: String"
        }
        alertController.addTextField { textField in
            textField.placeholder = "version: Int"
        }
        alertController.addTextField { textField in
            textField.placeholder = "fileType: Int"
        }
        alertController.addTextField { textField in
            textField.placeholder = "locale: String"
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        return alertController
    }

}
