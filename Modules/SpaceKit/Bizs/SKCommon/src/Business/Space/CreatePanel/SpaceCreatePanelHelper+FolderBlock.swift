//
//  SpaceCreatePanelHelper+FolderBlock.swift
//  SKCommon
//
//  Created by majie.7 on 2023/7/21.
//

import Foundation
import RxSwift
import SpaceInterface
import SKResource
import SKFoundation
import SKInfra
import UniverseDesignToast

// 供文件夹block的新建使用
extension SpaceCreatePanelHelper {
    
    
    public func generateItemsForFolderBlock(reachable: Observable<Bool>, uploadCompelation: @escaping ((String) -> Void)) -> [Item] {
        var items: [Item] = []
        // 注意不要随意调整 items 的添加顺序，最终会表现在创建面板的顺序上
        // Docx / Doc1.0
        if DocsType.docX.enabledByFeatureGating && LKFeatureGating.createDocXEnable {
            items.append(createDocX(enableState: reachable))
        } else {
            items.append(createDocs())
        }
        // Sheet
        items.append(createSheet(enableState: reachable))
        if UserScopeNoChangeFG.PXR.baseWikiSpaceHasSurveyEnable {
            // Bitable
            if DocsType.enableDocTypeDependOnFeatureGating(type: .bitable) {
                items.append(createBitable(preferNonSquareBaseIcon: false, enableState: reachable))
            }
            // survey
            items.append(createSurveyEntranceForDocs(enableState: reachable))
            // mindnote
            if DocsType.mindnoteEnabled {
                items.append(createMindNote(enableState: reachable))
            }
        } else {
            // mindnote
            if DocsType.mindnoteEnabled {
                items.append(createMindNote(enableState: reachable))
            }
            // Bitable
            if DocsType.enableDocTypeDependOnFeatureGating(type: .bitable) {
                items.append(createBitable(preferNonSquareBaseIcon: false, enableState: reachable))
            }
        }
        // Doc1.0
        if !UserScopeNoChangeFG.LJY.disableCreateDoc, DocsType.docX.enabledByFeatureGating, LKFeatureGating.createDocXEnable {
            items.append(createDocs())
        }
        // File & Image
        let driveItems = generateUploadItemForFolderBlock(reachable: reachable, uploadCompelation: uploadCompelation)
        items.append(contentsOf: driveItems)
        
        return items
    }
    
    func generateUploadItemForFolderBlock(reachable: Observable<Bool>, uploadCompelation: @escaping ((String) -> Void)) -> [Item] {
        var items: [Item] = []
        // admin禁用场景，禁止上传文件
        let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
        let request = PermissionRequest(token: "", type: .file,
                                        operation: .upload,
                                        bizDomain: .ccm,
                                        tenantID: nil)
        let response = permissionSDK.validate(request: request)
        switch response.result {
        case .allow:
            items.append(uploadImageInFolderBlock(enableState: reachable, uploadCompletion: uploadCompelation))
            items.append(uploadFileInFolderBlock(enableState: reachable, uploadCompletion: uploadCompelation))
        case let .forbidden(_, preferUIStyle):
            switch preferUIStyle {
            case .hidden:
                break
            case .disabled:
                items.append(uploadImageInFolderBlock(enableState: .just(false), uploadCompletion: uploadCompelation))
                items.append(uploadFileInFolderBlock(enableState: .just(false), uploadCompletion: uploadCompelation))
            case .default:
                items.append(uploadImageInFolderBlock(enableState: reachable, uploadCompletion: uploadCompelation))
                items.append(uploadFileInFolderBlock(enableState: reachable, uploadCompletion: uploadCompelation))
            }
        }
        return items
    }
    
    private func uploadImageInFolderBlock(enableState: Observable<Bool>, uploadCompletion: @escaping ((String) -> Void)) -> Item {
        let uploadHandler = createUploadDriveInFolderBlock(completion: uploadCompletion)
        let clickHanlder: CreateHandler = { event in
            uploadHandler(event, true)
        }
        return Item.Lark.uploadImage(enableState: enableState, clickHandler: clickHanlder)
    }
    
    private func uploadFileInFolderBlock(enableState: Observable<Bool>, uploadCompletion: @escaping ((String) -> Void)) -> Item {
        let uploadHandler = createUploadDriveInFolderBlock(completion: uploadCompletion)
        let clickHanlder: CreateHandler = { event in
            uploadHandler(event, false)
        }
        return Item.Lark.uploadFile(enableState: enableState, clickHandler: clickHanlder)
    }
    
    private func createUploadDriveInFolderBlock(completion: @escaping ((String) -> Void)) -> (CreateEvent, Bool) -> Void {
        return { event, isPhoto in
            let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
            let request = PermissionRequest(token: "", type: .file,
                                            operation: .upload,
                                            bizDomain: .ccm,
                                            tenantID: nil)
            let response = permissionSDK.validate(request: request)
            response.didTriggerOperation(controller: event.createController)
            guard response.allow else { return }
            // admin 的判断在 enable 之前
            guard event.itemEnable else { return }
            event.createController.dismiss(animated: true) {
                let subId = isPhoto ? "insertImage" : "insertFile"
                completion(subId)
            }
            
        }
    }
}
