//
//  FileOperateControlAlertDebugController.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2022/11/1.
//

import UIKit
import LarkSecurityComplianceInterface
import LarkContainer
import LarkAccountInterface

final class FileOperateControlAlertDebugController: UIAlertController {
    
    var userResolver: UserResolver?
    
    var complete: ((PolicyModel, AuthEntity?) -> Void)?
    let entityDomianVC: PickViewController = {
        let list = EntityDomain.allCases.map { return $0.rawValue }
        return PickViewController(model: list)
    }()
    let entityTypeVC: PickViewController = {
        let list = EntityType.allCases.map { return $0.rawValue }
        return PickViewController(model: list)
    }()
    let entityOperateVC: PickViewController = {
        let list = EntityOperate.allCases.map { return $0.rawValue }
        return PickViewController(model: list)
    }()
    let fileBizVC: PickViewController = {
        let list = FileBizDomain.allCases.map { return $0.rawValue }
        return PickViewController(model: list)
    }()
    let pointKeyVC: PickViewController = {
        let list = PointKey.allCases.map { return $0.rawValue }
        return PickViewController(model: list)
    }()
    let permTypeVC: PickViewController = {
        let list = FileOperateDebugPermissionType.allCases.map { return $0.rawValue }
        return PickViewController(model: list)
    }()
    let authEntityTypeVC: PickViewController = {
        let list = FileOperateDebugEntityType.allCases.map { return $0.rawValue }
        return PickViewController(model: list)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addTextField { [weak self] textField in
            guard let `self` = self else { return }
            textField.placeholder = "entityDomain 0"
            let picker = UIPickerView()
            textField.inputView = picker
            picker.dataSource = self.entityDomianVC
            picker.delegate = self.entityDomianVC
            self.entityDomianVC.getSelected = {
                textField.text = $0
            }
        }
        addTextField { [weak self] textField in
            guard let `self` = self else { return }
            textField.placeholder = "entityType 1"
            let picker = UIPickerView()
            textField.inputView = picker
            picker.dataSource = self.entityTypeVC
            picker.delegate = self.entityTypeVC
            self.entityTypeVC.getSelected = {
                textField.text = $0
            }
        }
        addTextField { [weak self] textField in
            guard let `self` = self else { return }
            textField.placeholder = "operate 2"
            let picker = UIPickerView()
            textField.inputView = picker
            picker.dataSource = self.entityOperateVC
            picker.delegate = self.entityOperateVC
            self.entityOperateVC.getSelected = {
                textField.text = $0
            }
        }
        addTextField { [weak self] textField in
            guard let `self` = self else { return }
            textField.placeholder = "fileBiz 3"
            let picker = UIPickerView()
            textField.inputView = picker
            picker.dataSource = self.fileBizVC
            picker.delegate = self.fileBizVC
            self.fileBizVC.getSelected = {
                textField.text = $0
            }
        }
        addTextField { [weak self] textField in
            guard let `self` = self else { return }
            textField.placeholder = "pointKey 4"
            let picker = UIPickerView()
            textField.inputView = picker
            picker.dataSource = self.pointKeyVC
            picker.delegate = self.pointKeyVC
            self.pointKeyVC.getSelected = {
                textField.text = $0
            }
        }
        addTextField { [weak self] textField in
            guard self != nil else { return }
            textField.placeholder = "senderUserID 默认值为空 5"
        }
        addTextField { [weak self] textField in
            guard self != nil else { return }
            textField.placeholder = "senderTenantID 默认值为空 6"
        }
        addTextField { [weak self] textField in
            guard self != nil else { return }
            textField.placeholder = "fileKey 7"
        }
        addTextField { [weak self] textField in
            guard self != nil else { return }
            textField.placeholder = "chatID 8"
        }
        addTextField { [weak self] textField in
            guard self != nil else { return }
            textField.placeholder = "chatType 9"
        }
        addTextField { [weak self] textField in
            guard let `self` = self else { return }
            textField.placeholder = "permType 10"
            let picker = UIPickerView()
            textField.inputView = picker
            picker.dataSource = self.permTypeVC
            picker.delegate = self.permTypeVC
            self.permTypeVC.getSelected = {
                textField.text = $0
            }
        }
        addTextField { $0.placeholder = "entityID 11" }
        addTextField { $0.placeholder = "token 12" }
        addTextField { $0.placeholder = "ownerTenantID 默认为空 13" }
        addTextField { $0.placeholder = "ownerUserID 默认为空 14" }
        addTextField { [weak self] textField in
            guard let `self` = self else { return }
            textField.placeholder = "authEntityType 15"
            let picker = UIPickerView()
            textField.inputView = picker
            picker.dataSource = self.authEntityTypeVC
            picker.delegate = self.authEntityTypeVC
            self.authEntityTypeVC.getSelected = {
                textField.text = $0
            }
        }
        
        addAction(UIAlertAction(title: "确定", style: .default, handler: { [weak self] _ in
            guard let `self` = self else { return }
            guard let textFields = self.textFields,
                  let entityDomain = EntityDomain(rawValue: textFields[0].text ?? ""),
                  let entityType = EntityType(rawValue: textFields[1].text ?? ""),
                  let operate = EntityOperate(rawValue: textFields[2].text ?? ""),
                  let fileBiz = FileBizDomain(rawValue: textFields[3].text ?? ""),
                  let pointKey = PointKey(rawValue: textFields[4].text ?? "") else { return }
            let userService = try? self.userResolver?.resolve(assert: PassportUserService.self)
            guard let tenantID = Int64(userService?.userTenant.tenantID ?? ""),
                  let userID = Int64(userService?.user.userID ?? "") else { return }
            
            var authEntity: AuthEntity?
            if let permType = FileOperateDebugPermissionType(rawValue: textFields[10].text ?? "")?.permissionType {
                var entity: Entity?
                if let entityType = FileOperateDebugEntityType(rawValue: textFields[15].text ?? "")?.entityType {
                    entity = Entity()
                    entity?.entityType = entityType
                    entity?.id = textFields[11].text ?? ""
                }
                authEntity = AuthEntity(permType: permType, entity: entity)
            }
            switch entityDomain {
            case .ccm:
                self.complete?(PolicyModel(pointKey,
                                           CCMEntity(entityType: entityType,
                                                             entityDomain: entityDomain,
                                                             entityOperate: operate,
                                                             operatorTenantId: tenantID,
                                                             operatorUid: userID,
                                                             fileBizDomain: fileBiz,
                                                     token: !textFields[12].text.isEmpty ? textFields[12].text : nil,
                                                     ownerTenantId: Int64(textFields[13].text ?? ""),
                                                     ownerUserId: Int64(textFields[14].text ?? "")
                                                    )),
                               authEntity)
            case .im:
                self.complete?(PolicyModel(pointKey,
                                           IMFileEntity(entityType: entityType,
                                                        entityDomain: entityDomain,
                                                        entityOperate: operate,
                                                        operatorTenantId: tenantID,
                                                        operatorUid: userID,
                                                        fileBizDomain: fileBiz,
                                                        senderUserId: Int64(textFields[5].text ?? ""),
                                                        senderTenantId: Int64(textFields[6].text ?? ""),
                                                        fileKey: textFields[7].text.isEmpty ? textFields[7].text : nil,
                                                        chatID: Int64(textFields[8].text ?? ""),
                                                        chatType: Int64(textFields[9].text ?? "")
                                                       )),
                                           authEntity)
            default:
                return
            }
        }))
    }
}
