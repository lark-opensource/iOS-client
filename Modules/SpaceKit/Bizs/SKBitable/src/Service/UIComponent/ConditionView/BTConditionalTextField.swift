//
//  BTConditionalTextField.swift
//  SKBitable
//
//  Created by zhysan on 2022/12/27.
//

import SKUIKit
import SKCommon
import SKFoundation
import UniverseDesignToast
import SKResource
import UniverseDesignInput
import SpaceInterface
import SKInfra

// MARK: ⚠️ 接入条件访问控制的 UITextField & UDTextField，此文件内不推荐新增其他逻辑，有其它需求可继承此类
// 条件访问控制：会根据管理员设置的策略，判断是否需要阻止复制、剪切操作，并给出弹窗提示

private func checkCopyOrCutAvailability(view: UIView) -> Bool {
    guard UserScopeNoChangeFG.WWJ.permissionSDKEnable else {
        return legacyCheckCopyOrCutAvailability(view: view)
    }
    //安全改造：https://bytedance.feishu.cn/base/XCUWbdXVIarbLZsQH6PczViynyh?table=tblUpbjqUuiyv2hU&view=vewk4g6dC1
    //检查 permissionSDK 是否能正常获取，默认返回能力不可用【false】
    guard let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self) else {
        return false
    }
    let request = PermissionRequest(token: "", type: .bitable, operation: .copyContent, bizDomain: .ccm, tenantID: nil)
    let response = permissionSDK.validate(request: request)
    response.didTriggerOperation(controller: view.affiliatedViewController ?? UIViewController())
    return response.allow
}

@available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
private func legacyCheckCopyOrCutAvailability(view: UIView) -> Bool {
    let validation = CCMSecurityPolicyService.syncValidate(
        entityOperate: .ccmCopy,
        fileBizDomain: .ccm,
        docType: .bitable,
        token: nil
    )
    guard validation.allow else {
        switch validation.validateSource {
        case .fileStrategy:
            DocsLogger.error("copy validation failed due to fileStrategy")
            CCMSecurityPolicyService.showInterceptDialog(entityOperate: .ccmCopy, fileBizDomain: .ccm, docType: .bitable, token: nil)
            return false
        case .securityAudit:
            DocsLogger.error("copy validation failed due to securityAudit")
            if let window = view.superview?.window {
                UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, on: window)
            }
            return false
        case .dlpDetecting, .dlpSensitive, .unknown, .ttBlock:
            DocsLogger.info("unknown type or dlp type")
            return true
        }
    }
    return true
}

private func checkCopyOrCutAvailability(view: UIView, baseContext: BaseContext?) -> Bool {
    guard let baseContext = baseContext, UserScopeNoChangeFG.YY.bitableReferPermission else {
        return checkCopyOrCutAvailability(view: view)
    }
    return baseContext.checkCopyOrCutAvailabilityWithToast(view: view)
}

final class BTUDConditionalTextField: UDTextField {
    
    var baseContext: BaseContext? {
        didSet {
            if let input = self.input as? BTConditionalTextField {
                input.baseContext = baseContext
            }
        }
    }
    
    override init(config: UDTextFieldUIConfig = UDTextFieldUIConfig()) {
        super.init(config: config, textFieldType: BTConditionalTextField.self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class BTConditionalTextField: SKBaseTextField {
    
    var baseContext: BaseContext?
    
    override func cut(_ sender: Any?) {
        guard checkCopyOrCutAvailability(view: self, baseContext: baseContext) else {
            return
        }
        super.cut(sender)
    }
    
    override func copy(_ sender: Any?) {
        guard checkCopyOrCutAvailability(view: self, baseContext: baseContext) else {
            return
        }
        super.copy(sender)
    }
}

class BTConditionalPlacehoderTextView: SKPlacehoderTextView {
    
    var baseContext: BaseContext?
    
    override func cut(_ sender: Any?) {
        guard checkCopyOrCutAvailability(view: self, baseContext: baseContext) else {
            return
        }
        super.cut(sender)
    }
    
    override func copy(_ sender: Any?) {
        guard checkCopyOrCutAvailability(view: self, baseContext: baseContext) else {
            return
        }
        super.copy(sender)
    }
}


class BTConditionalSearchUITextField: SKSearchUITextField {
    
    var baseContext: BaseContext?
    
    override func cut(_ sender: Any?) {
        guard checkCopyOrCutAvailability(view: self, baseContext: baseContext) else {
            return
        }
        super.cut(sender)
    }
    
    override func copy(_ sender: Any?) {
        guard checkCopyOrCutAvailability(view: self, baseContext: baseContext) else {
            return
        }
        super.copy(sender)
    }
}
