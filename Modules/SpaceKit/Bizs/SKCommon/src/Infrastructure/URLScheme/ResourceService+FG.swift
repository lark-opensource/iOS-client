//
//  ResourceService+FG.swift
//  SKCommon
//
//  Created by lijuyou on 2023/7/25.
//

import SKFoundation
import LarkSetting
import LarkContainer

/// Web注入FG
/// https://bytedance.feishu.cn/wiki/Oj8qwBCtTiiol8kW9FvcYrEPnKu
class WebFeatureGating {
    private var fgCache: String?
    
    func getWebFGJsonString() -> String? {
        if let fgCache = self.fgCache {
            DocsLogger.info("==get webfg== jsonstring from cache: \(fgCache)")
            return fgCache
        }
        DocsLogger.info("==get webfg== jsonstring start...")
        var dict = [String: Bool]()
        if UserScopeNoChangeFG.LJY.injectTXTProfileFg {
            let fgKeys = getFGKeysFromProfile()
            for key in fgKeys {
                let val = fgValue(for: key)
                if val {
                    dict[key] = val //只注入true的fg
                }
            }
            dict["ccm.mobile.inject_fg_enable"] = true
        } else {
            for key in injectFGKeys {
                let val = fgValue(for: key)
                dict[key] = val
            }
        }
        guard let json = dict.toJSONString() else {
            DocsLogger.error("==get webfg== jsonstring fail")
            return nil
        }
        self.fgCache = json
        DocsLogger.info("==get webfg== jsonstring end:\(dict.count) \(json)")
        return json
    }
    
    /// 从资源包配置读取FG列表
    func getFGKeysFromProfile() -> [String] {
        guard let data = ResourceService.resource(resourceName: "featureGatingKeys.txt") else {
            DocsLogger.info("==get webfg== read txt failed")
            return []
        }
        guard let keyString = String(data: data, encoding: .utf8) else {
            DocsLogger.info("==get webfg== parse txt failed")
            return []
        }
        let keys: [String] = keyString.split(separator: ",").compactMap {
            if $0.isEmpty {
                return nil
            } else {
                return String($0)
            }
        }
        DocsLogger.info("==get webfg== parse txt success.(\(keys.count)")
        return keys
    }
    
    private func fgValue(for key: String) -> Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: key))
    }
}

// 注入到Web的FG列表
private let injectFGKeys = [
    //模版加载过程中的fg
    "request_meltdown_ajax_enable",
    "spacekit.mobile.common_bridge_async_slice_apply",
    "ccm.permission.web.reduce_mget_userids",
    "bitable.mobile.dev_setting",
    "ccm.bitable.oom_retry_request_in_web",
    "ccm.bitable.add_autonumber_field",
    "bitable.field.location",
    "ccm.bitable.field.barcode",
    "ccm.bitable.field.progress",
    "ccm.bitable.field.group",
    "ccm.bitable.field.rating",
    "ccm.bitable.field.button",
    "ccm.bitable.hierarchy.enabled",
    "bitable.pricing.recordsnumandgantt.fe",
    "ccm.bitable.base_refer_block.enable.mobile",
    "spacekit.mobile.set_prefetch_keys",
    "ccm.bitable.field.group.new_edit_panel",
    "debug.docx_h5.full_feature_enabled",
    "spacekit.mobile.docx_table_operation_enabled",
    "spacekit.mobile.docx_table_creation_enabled",
    "ccm.icon.suite_custom_icon",
    "ccm.docx.equation_insert_enabled",
    "spacekit.mobile.doc_block_equation_editable",
    "ccm.wiki.recent_block_enabled",
    "ccm.wiki.catalog_block_enabled",
    "ccm.wiki.mobile.deleted_restore_optimization",
    "spacekit.mobile.docs_diy_icon",

    //文档打开过程中的fg
    "ccm.common.batch_log",
    "ccm.docx.enable_mobile_image_ssr",
    "ccm.docx.pc.chart_block.chart_refer_host_perm",
    "ccm.gpe.is_preview_control_able",
    "ccm.permission.mobile.sensitivty_label",
    "ccm.mobile.sensitivitylabel.forcedlabel",
    "ccm.permission.attachment_seperate_auth_enable",
    "spacekit.mobile.show_appeal_entry",
    "ccm.permission.mobile.permission_settings",
    "ccm.sheet.mobile.bridge_storage_pagination",
    "ccm.docx.mention_doc_quick_share_enable",
    "ccm.sheet.mobile.enable.ssr",
    "ccm.comment.reslove_permission",
    "cache_comment_panal_status",
    "spacekit.mobile.translate_enabled",
    "ccm.docx.mobile.watchdog",
    "ccm.docx.comment.syncv2",
    "ccm.gpe.comment.anchor_link_mobile",
    "spacekit.mobile.display_none_first_screen",
    "spacekit.mobile.block_menu_v2_enable",
    "spacekit.mobile.click_comment_enable",
    "spacekit.mobile.grammar_check_enabled",
    "spacekit.mobile.isv_block_enabled",
    "spacekit.mobile.common.copy_security_enable",
    "spacekit.mobile.docx_edit_entrance_enable",
    "ccm.docx.enable_mobile_block_ssr",
    "ccm.sheet.embed_hide_header_enable",
    "ccm.docx.comment_refactor_fe"
]
