//
//  SecurityAuditAlertController.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2022/11/20.
//

import Foundation
import ServerPB
import LarkSecurityAudit

final class SecurityAuditAlertController: UIAlertController {
    var complete: ((CustomizedEntity?) -> Void)?
    override func viewDidLoad() {
        addTextField { textField in
            textField.placeholder = "id"
        }
        addTextField { textField in
            textField.placeholder = "entityType"
        }

        addAction(UIAlertAction(title: "确定", style: .default, handler: { [weak self] _ in
            guard let `self` = self else { return }
            guard let textFields = self.textFields,
                  let id = textFields[0].text,
                  let entityType = textFields[1].text else {
                self.complete?(nil)
                return }
            var entity = CustomizedEntity()
            entity.id = id
            entity.entityType = entityType
            self.complete?(entity)
        }))
    }
}
