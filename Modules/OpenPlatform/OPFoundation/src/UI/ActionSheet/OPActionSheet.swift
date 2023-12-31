//
//  OPActionSheet.swift
//  OPFoundation
//
//  Created by baojianjun on 2023/4/23.
//

import LarkUIKit
import LKCommonsLogging
import LarkActionSheet
import LarkSetting
import UniverseDesignActionPanel
import LarkSplitViewController

@objc
public final class OPActionSheet: NSObject {
    
    private static let logger = Logger.oplog(OPActionSheet.self, category: "ActionSheet")
    
    private class func useUD() -> Bool {
        // TODOZJX
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.actionsheet.ud.enable"))
    }
    
    @objc public class func createActionSheet(with items: [EMAActionSheetAction], isAutorotatable: Bool = false) -> UIViewController {
        if useUD() {
            return createUDActionSheet(with: items, isAutorotatable: isAutorotatable)
        } else {
            return createOldActionSheet(with: items)
        }
    }
    
    private class func createOldActionSheet(with items: [EMAActionSheetAction]) -> UIViewController {
        let adapater = ActionSheetAdapter()
        let actionSheet = adapater.create(level: .normalWithCustomActionSheet)
        for item in items {
            switch item.style {
            case .cancel:
                adapater.addCancelItem(title: item.title) {
                    item.handler?()
                }
            default:
                adapater.addItem(title: item.title) {
                    item.handler?()
                }
            }
        }
        return actionSheet
    }
    
    private class func createUDActionSheet(with items: [EMAActionSheetAction], isAutorotatable: Bool) -> UIViewController {
        ///创建面板配置
        var config = UDActionSheetUIConfig()
        if let item = items.first(where: { .cancel == $0.style }) {
            // 还需要处理 tapOutside 的情况
            config.dismissedByTapOutside = {
                item.handler?()
            }
        }

        /// 创建 actionsheet 实例
        let actionsheet = UDActionSheet(config: config)
        actionsheet.isAutorotatable = isAutorotatable
        
        for item in items {
            switch item.style {
            case .cancel:
                actionsheet.setCancelItem(text: item.title) {
                    item.handler?()
                }
            default:
                actionsheet.addDefaultItem(text: item.title) {
                    item.handler?()
                }
            }
        }
        return actionsheet
    }

    @objc
    public class func dynamicAddActions(with items: [EMAActionSheetAction], for actionSheet: UIViewController) {
        if useUD(), let udActionSheet = actionSheet as? UDActionSheet {
            for item in items {
                switch item.style {
                case .cancel:
                    udActionSheet.setCancelItem(text: item.title) {
                        item.handler?()
                    }
                default:
                    udActionSheet.addDefaultItem(text: item.title) {
                        item.handler?()
                    }
                }
            }
            udActionSheet.view.setNeedsLayout()
            udActionSheet.view.layoutIfNeeded()
            return
        }
        guard let adapater = actionSheet.sheetAdapter else {
            OPActionSheet.logger.warn("actionSheet is not managed by actionSheetAdaptor")
            return
        }
        for item in items {
            switch item.style {
            case .cancel:
                adapater.addCancelItem(title: item.title) {
                    item.handler?()
                }
            default:
                adapater.addItem(title: item.title) {
                    item.handler?()
                }
            }
        }
    }
}
