import EENavigator
import Foundation
import LarkOpenAPIModel
import LarkModel
import LKCommonsLogging
import SKFoundation
import SKResource
import Swinject

public protocol FormsChooseContactProtocol {
    
    func chooseContact(
        vc: UIViewController,
        featureConfig: PickerFeatureConfig,
        searchConfig: PickerSearchConfig,
        contactConfig: PickerContactViewConfig,
        dele: SearchPickerDelegate
    )
    
}

fileprivate let chooseContactChatterType = "chatter"

fileprivate let chooseContactChatType = "chat"

// MARK: - ChooseContact Model
final class FormsChooseContactParams: OpenAPIBaseParams {
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "preselectItems")
    var preselectItems: [FormsChooseContactPreselectItem]
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        [_preselectItems]
    }
    
}

final class FormsChooseContactPreselectItem: OpenAPIBaseParams {
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "id")
    var id: String
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "type")
    var type: String
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        [_id, _type]
    }
    
}


final class FormsChooseContactResult: OpenAPIBaseResult {
    
    var selectItems: [SelectItem]
    
    struct SelectItem {
        
        var name: String?
        
        var id: String
        
        var avatarKey: String?
        
        var type: String
        
    }
    
    init(selectItems: [SelectItem]) {
        
        self.selectItems = selectItems
        
    }
    
    override func toJSONDict() -> [AnyHashable: Any] {
        
        let arr = selectItems
            .map { item in
                [
                    "name": item.name,
                    "id": item.id,
                    "avatarKey": item.avatarKey,
                    "type": item.type
                ]
            }
        
        
        return [
            "selectItems": arr
        ]
        
    }
    
}

extension FormsOpenAbility {
    
    func chooseContact(
        vc: UIViewController,
        params: FormsChooseContactParams,
        success: @escaping (FormsChooseContactResult) -> Void,
        cancel: @escaping () -> Void
    ) {
        
        Self.logger.info("chooseContact start, preselectItems.count is: \(params.preselectItems.count)")
        
        chooseContactSuccessBlock = success
        chooseContactCancelBlock = cancel
        
        let featureConfig = PickerFeatureConfig(
            multiSelection: PickerFeatureConfig
                .MultiSelection(
                    isOpen: true,
                    isDefaultMulti: true,
                    preselectItems: params
                        .preselectItems
                        .compactMap { item in
                            if item.type == chooseContactChatterType {
                                return PickerItem(
                                    meta: PickerItem
                                        .Meta
                                        .chatter(
                                            PickerChatterMeta(
                                                id: item
                                                    .id
                                            )
                                        )
                                )
                            } else if item.type == chooseContactChatType {
                                return PickerItem(
                                    meta: PickerItem
                                        .Meta
                                        .chat(
                                            PickerChatMeta(
                                                id: item
                                                    .id,
                                                type: .group
                                            )
                                        )
                                )
                            } else {
                                Self.logger.error("invaild type: \(item.type), please contact front and fix type value")
                                return nil
                            }
                        }
                ),
            navigationBar: PickerFeatureConfig
                .NavigationBar(
                    title: BundleI18n
                        .SKResource
                        .BItable_NewSurvey_Reminder_Mobile_AddRecipients_Button,
                    sureText: BundleI18n
                        .SKResource
                        .Doc_Facade_Ok
                ),
            targetPreview: PickerFeatureConfig
                .TargetPreview(
                    isOpen: true
                )
        )
        
        let searchConfig = PickerSearchConfig(
            entities: [
                PickerConfig
                    .ChatterEntityConfig(
                        tenant: .all,
                        talk: .all,
                        resign: .unresigned,
                        externalFriend: .all
                    ),
                PickerConfig
                    .ChatEntityConfig(
                        tenant: .all,
                        join: .joined,
                        owner: .all,
                        publicType: .all,
                        shield: .noShield,
                        frozen: .noFrozened,
                        crypto: .normal
                    )
            ]
        )
        
        let contactConfig = PickerContactViewConfig(
            entries: [
                PickerContactViewConfig
                    .OwnedGroup(),
                PickerContactViewConfig
                    .Organization()
            ]
        )
        
        do {
            try Container
                .shared
                .getCurrentUserResolver()
                .resolve(
                    type: FormsChooseContactProtocol.self
                )
                .chooseContact(
                    vc: vc,
                    featureConfig: featureConfig,
                    searchConfig: searchConfig,
                    contactConfig: contactConfig,
                    dele: self
                )
        } catch {
            let msg = "chooseContact failure, resolve FormsChooseContactProtocol error: \(error), please contact CCM SpaceKitAssemble owner"
            assertionFailure(msg) // 原则上走不到这里，要是走到了这里请联系 CCM SpaceKitAssemble 负责人
            Self.logger.error(msg, error: error)
        }
        
    }
    
}

extension FormsOpenAbility: SearchPickerDelegate {
    
    /// Picker完成,回调选中的item数组, 单选模式下返回一个item, 多选模式下返回所有选中的items
    /// - Parameters:
    ///   - pickerVc: 持有picker的顶层vc, picker模式是SearchPickerNavigationController, 大搜模式是SearchPickerViewController, 可用于调用pickerVc的方法, 也可用于手动关闭Picker
    ///   - items: 选中的item数组
    /// - Returns: 返回true时, 完成后默认关闭Picker, 返回false时, 不关闭Picker, 由业务处理后续逻辑
    func pickerDidFinish(
        pickerVc: SearchPickerControllerType,
        items: [PickerItem]
    ) -> Bool {
        
        Self.logger.info("pickerDidFinish items count is \(items.count)")
        
        let selectItems = items
            .compactMap { item in
                switch item.meta {
                case .chatter(let pickerChatterMeta):
                    Self.logger.info("pickerDidFinish item is chatter, name.isEmpty: \(pickerChatterMeta.name?.isEmpty), key.isEmpty: \(pickerChatterMeta.avatarKey?.isEmpty)")
                    return FormsChooseContactResult
                        .SelectItem(
                            name: pickerChatterMeta
                                .name,
                            id: pickerChatterMeta
                                .id,
                            avatarKey: pickerChatterMeta
                                .avatarKey,
                            type: chooseContactChatterType
                        )
                case .chat(let pickerChatMeta):
                    Self.logger.info("pickerDidFinish item is chat, name.isEmpty: \(pickerChatMeta.name?.isEmpty), key.isEmpty: \(pickerChatMeta.avatarKey?.isEmpty)")
                    return FormsChooseContactResult
                        .SelectItem(
                            name: pickerChatMeta
                                .name,
                            id: pickerChatMeta
                                .id,
                            avatarKey: pickerChatMeta
                                .avatarKey,
                            type: chooseContactChatType
                        )
                case .userGroup(_):
                    return nil
                case .doc(_):
                    return nil
                case .wiki(_):
                    return nil
                case .wikiSpace(_):
                    return nil
                case .mailUser(_):
                    return nil
                case .unknown:
                    return nil
                }
            }
        
        if let success = chooseContactSuccessBlock {
            Self.logger.info("chooseContact success and invoke success block")
            success(FormsChooseContactResult(selectItems: selectItems))
        } else {
            Self.logger.error("chooseContactSuccess error, chooseContactSuccessBlock is nil")
        }
        cleanChooseContactBlocks()
        
        return true
    }
    
    /// Picker内部关闭按钮触发时机
    /// - Parameter pickerVc: 持有picker的顶层vc, picker模式是SearchPickerNavigationController, 大搜模式是SearchPickerViewController, 可用于调用pickerVc的方法, 也可用于手动关闭Picker
    /// - Returns: 返回false时, 不会关闭Picker,需要业务手动实现
    func pickerDidCancel(
        pickerVc: SearchPickerControllerType
    ) -> Bool {
        
        Self.logger.info("pickerDidCancel")
        
        if let cancel = chooseContactCancelBlock {
            Self.logger.info("chooseContactCancel cancel and invoke cancel block")
            cancel()
        } else {
            Self.logger.error("chooseContactCancel error, chooseContactCancelBlock is nil")
        }
        cleanChooseContactBlocks()
        return true
    }
    
    func pickerDidDismiss(
        pickerVc: SearchPickerControllerType
    ) {
        Self.logger.info("pickerDidDismiss")
        
        if let cancel = chooseContactCancelBlock {
            Self.logger.info("chooseContactCancel cancel without click cancel button and invoke cancel block")
            cancel()
        }
        cleanChooseContactBlocks()
    }
    
}
