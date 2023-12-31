//
//  NativeComponentTracker.swift
//  SKBrowser
//
//  Created by X-MAN on 2022/9/8.
//

import Foundation
import SKFoundation

public final class NativeComponentTracker {
    
    // 标识不同业务方
    struct RenderViewType {
        static let driveFileBlock = "drive_file_block"
    }
    
    // 状态阶段
    struct StageCode {
        static let nativeCompoenentHander = "native_component_handler" // 标明同层SDK收到JSSDK传递的 insert事件后, 在view初始化之前
        static let renderViewOnCreate = "render_view_on_create" // 创建待渲染view
        static let nativeComponentViewAdd = "native_component_view_add" // 将要把带渲染view添加到视图上
        static let nativeComponentViewUpdateFrame = "native_component_view_update_bounds" // 同层SDK收到更新大小/位置指令
        static let drivePreload = "drive_preload" // 最终预览阶段
    }
    
    public struct ResultCode {
        static let DEC0 = "DEC0"
    }
    /// type 业务类别，例如file为 drive_file_block
    /// stage 所处阶段 参照stageCode类定义阶段
    /// viewID 同层组件生成的ComponentID
    /// resultCode 成功用DEC0 失败用Error的错误码
    /// errorMessage 错误信息，如果有
    /// 错误信息处理来自 OpenAPIError 非成功code 为 error.innerCode message 为error.monitorMsg, 参照DriveFileBlock处理
    static func log(type: String, stage: String, viewID: String, resultCode: String, errorMessage: String? = nil) {
        var params = [
            "render_view_type": type,
            "stage_code": stage,
            "view_id": viewID,
            "resultCode": resultCode
        ] as [AnyHashable: Any]
        if let message = errorMessage {
            params["error_message"] = message
        }
        DocsTracker.newLog(enumEvent: .docsDevSameRenderOpenFinish, parameters: params)
        DocsLogger.debug("view_id \(viewID), stage: \(stage), resultCode: \(resultCode)")
    }
}
