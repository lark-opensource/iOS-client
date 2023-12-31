//
//  WbClient.swift
//
//
//  Created by kef on 2022/2/10.
//

import Foundation

public typealias NotificationHanler = (WbNotification) -> Void
public typealias SyncDataHandler = ([UInt8]) -> Void

/// 白板抛出的事件, 通过此回调将结果回传到业务侧
public protocol WbNotificationDelegate: AnyObject {
    /// # 参数
    /// - `notification`: 发生变化的属性值, 详见`WbNotification`
    func onNotification(_ notification: WbNotification)
}

/// 白板 SDK 通过此回调测量文字渲染参数
public protocol WbMeasureInlineTextDelegate: AnyObject {
    /// # 参数
    /// - `ctx`: 由`wb_init_with_2d_render`传入的业务上下文
    /// - `text`: 被测量文字
    /// - `font_size`: 字体尺寸
    /// - `font_weight`: 字体粗细
    ///
    /// # 返回值
    /// 测量完成的字体参数
    func onMeasure(_ text: String, fontSize: Int, fontWeight: Int) -> InlineGlyphSpecs
}

/// 白板图形发生变化时, 通过此回调将协同数据回传到业务侧
public protocol WbSyncDataDelegate: AnyObject {
    /// # 参数
    /// - `type`: 白板产生的同步数据的类型, 和 GrootCell 中的 `DataType` 含义一致
    /// - `bytes`: 协同所需的二进制数据
    func onSyncData(_ type: WbSyncDataType, _ bytes: [UInt8])
}

public class WbClient {
    private var ptr: OpaquePointer? = nil
    private weak var notificationDelegate: WbNotificationDelegate?
    private weak var syncDataDelegate: WbSyncDataDelegate?
    private weak var measureInlineTextDelegate: WbMeasureInlineTextDelegate?
    
    public init(config: WbLibConfig) {
        do {
            try config.toCValue {
                try initInner($0)
            }
        } catch {
            printError("Something went wrong when instantiating WbClient: \(error)")
        }
    }
    
    private func initInner(_ cLibConfig: UnsafePointer<CWbClientConfig>) throws {
        return try wrap_throws {
            wb_client_new_with_cmd_proxy_render(
                // class ptr
                getClassPtr(self),
                // client ptr
                &ptr,
                // lib config
                cLibConfig,
                // on notification
                { classPtr, cNotification, cData in
                    let mySelf = Unmanaged<WbClient>.fromOpaque(classPtr!).takeUnretainedValue()
                    
                    if let delegate = mySelf.notificationDelegate {
                        delegate.onNotification(WbNotification(name: cNotification, dataPtr: cData))
                    }
                },
                // on measure inline text
                { classPtr, cText, fontSize, fontWeight in
                    let mySelf = Unmanaged<WbClient>.fromOpaque(classPtr!).takeUnretainedValue()
                    
                    if let delegate = mySelf.measureInlineTextDelegate {
                        let specs = delegate.onMeasure(
                            String.fromCValue(cText)!,
                            fontSize: Int(fontSize),
                            fontWeight: Int(fontWeight)
                        )

                        return UnsafeMutablePointer<CWbInlineGlyphSpecs>.fromSwift(specs)
                    }
                    
                    return nil
                },
                // destroy CInlineGlyphSpecs
                { cInlineGlyphSpecsPtr in
                    cInlineGlyphSpecsPtr?.freeUnsafeMemory()
                    return true
                }
            )
        }
    }
    
    deinit {
        if ptr == nil {
            printError("WbClient instance can not be de-initialized because it has not been initialized successfully")
            return
        }
        
        wrap { wb_client_destroy(ptr!) }
        ptr = nil
    }
    
    /// 设置 sdk 通知回调
    public func setNotificationDelegate(_ delegate: WbNotificationDelegate) {
        self.notificationDelegate = delegate
    }
    
    /// 设置 sdk 文字测量回调
    public func setMeasureInlineTextDelegate(_ delegate: WbMeasureInlineTextDelegate) {
        self.measureInlineTextDelegate = delegate
    }
    
    /// 设置协同数据回调
    ///
    /// # 注意
    /// 设置时需确保此时数据通道已经建立, 否则可能会丢失协同数据
    public func setSyncDataDelegate(_ delegate: WbSyncDataDelegate) {
        self.syncDataDelegate = delegate
        
        wrap {
            wb_client_set_sync_data_callback(ptr!, { classPtr, dataType, dataPtr, size in
                let mySelf = Unmanaged<WbClient>.fromOpaque(classPtr!).takeUnretainedValue()
                
                if let delegate = mySelf.syncDataDelegate {
                    let data = UnsafeBufferPointer(start: dataPtr, count: Int(size)).compactMap { $0 }
                    delegate.onSyncData(WbSyncDataType(cValue: dataType), data)
                }
            })
        }
    }
    
    /// 处理协同数据
    ///
    /// # 时机
    /// 上层Grout channel收到推送后, 将其数据通过此接口注入SDK
    public func handleSyncData(_ type: WbSyncDataType, _ bytes: [UInt8]) {
        bytes.withUnsafeBufferPointer { cByte in
            wrap { wb_client_handle_sync_payload(ptr!, type.toCValue(), cByte.baseAddress, bytes.count) }
        }
    }
    
    /// 设置一页白板快照数据
    ///
    /// # 返回
    /// 所设置快照页的id, 如果设置失败返回空字符串
    public func setPageSnapshot(_ data: [UInt8]) -> Int64 {
        let cPageId = UnsafeMutablePointer<Int64>.allocate(capacity: 1)
        
        do {
            try data.withUnsafeBufferPointer { cByte in
                try wrap_throws { wb_client_set_page_snapshot(ptr!, cByte.baseAddress, data.count, cPageId) }
            }
        } catch {
            printError("Something went wrong when setPageSnapshot: \(error)")
            return -1
        }
        
        let pageId = cPageId.pointee
        free(cPageId)
        
        return pageId
    }
    
    private func getPageDataHelper<T, CT>(
        _ pageId: Int64,
        _ getter: (OpaquePointer, Int64,UnsafeMutablePointer<UnsafePointer<CT>?>) -> C_WB_RESULT,
        _ fromCConverter: (UnsafePointer<CT>) -> T,
        _ destroyer: (UnsafeMutablePointer<CT>) -> C_WB_RESULT,
        _ failure_default: T
    ) -> T {
        let dataPtr = UnsafeMutablePointer<UnsafePointer<CT>?>.allocate(capacity: 1)
        var data: T = failure_default
        
        do {
            try wrap_throws { getter(ptr!, pageId, dataPtr) }
            data = fromCConverter(dataPtr.pointee!)
            try wrap_throws { destroyer(UnsafeMutablePointer(mutating: dataPtr.pointee!)) }
        } catch {
            printError("Something went wrong when fetching page data \(WbError.getLast.message)")
            return failure_default
        }
        
        free(dataPtr)
        return data
    }
    
    /// 拿取一页白板快照数据
    public func getPageSnapshot(_ pageId: Int64) -> [UInt8] {
        return getPageDataHelper(
            pageId,
            wb_client_get_page_snapshot,
            { $0.pointee.toSwiftArray() },
            wb_client_destroy_page_snapshot_data,
            []
        )
    }
    
    /// 拿取一页白板的所有图形数据
    ///
    /// # 时机
    /// 生成所有页面的缩略预览图时
    public func getPageGraphics(_ pageId: Int64) -> [WbGraphic] {
        return getPageDataHelper(
            pageId,
            wb_client_get_page_graphics,
            { $0.pointee.toSwiftArray() },
            wb_client_destroy_wb_graphic_array,
            []
        )
    }
    
    /// 获取白板页的信息 (etc: 主题)
    ///
    /// 如果白板页不存在, 返回nil
    public func getPageInfo(_ pageId: Int64) -> PageInfo? {
        return getPageDataHelper(
            pageId,
            wb_client_get_page_info,
            { PageInfo($0.pointee) },
            wb_client_destroy_page_info,
            nil
        )
    }
    
    /// 拉取新增的图形指令
    ///
    /// # 时机
    /// 每次渲染周期到时调用
    ///
    /// # 注意
    /// 在收到`HasPendingGraphicCmds(false)`时, 需要确保再至多调用一次该接口确保SDK内无数据残留
    /// SDK不感知渲染周期, 可能在同一渲染周期内发送`HasPendingGraphicCmds(true)`和`HasPendingGraphicCmds(false)`的情况
    public func pullPendingGraphicCmds() -> [WbRenderCmd] {
        let buffer = UnsafeMutablePointer<UnsafePointer<CArray_CEnum_C_WB_RENDER_CMD>?>.allocate(capacity: 1)
        var cmds: [WbRenderCmd] = []
        
        do {
            try wrap_throws { wb_client_pull_pending_graphic_cmds(ptr!, buffer) }
            cmds = buffer.pointee!.pointee.toSwiftArray()
            try wrap_throws { wb_client_destroy_graphic_cmds(UnsafeMutablePointer(mutating:buffer.pointee!))}
        } catch {
            printError("Something went wrong when pulling graphic cmds: \(error)")
        }
        
        free(buffer)
        return cmds
    }
    
    
    /// 外部定时器调用, 驱动 `WbClient` 内部定时相关逻辑
    public func tick() {
        wrap { wb_client_tick(ptr!) }
    }
    
    // 事件
    
    /// 触摸事件 - 点击
    ///
    /// # 参数
    /// - `x`: 坐标 x
    /// - `y`: 坐标 y
    /// - `id`: 触摸输入 id (多指触摸时)
    public func handleTouchDown(x: Float, y: Float, id: Int) {
        wrap { wb_client_handle_touch_down(ptr!, x, y, UInt64(id)) }
    }
    
    /// 触摸事件 - 移动
    ///
    /// # 参数
    /// - `x`: 坐标 x
    /// - `y`: 坐标 y
    /// - `id`: 触摸输入 id (多指触摸时)
    public func handleTouchMoved(x: Float, y: Float, id: Int) {
        wrap { wb_client_handle_touch_moved(ptr!, x, y, UInt64(id)) }
    }
    
    /// 触摸事件 - 释放
    ///
    /// # 参数
    /// - `x`: 坐标 x
    /// - `y`: 坐标 y
    /// - `id`: 触摸输入 id (多指触摸时)
    public func handleTouchLifted(x: Float, y: Float, id: Int) {
        wrap { wb_client_handle_touch_lifted(ptr!, x, y, UInt64(id)) }
    }
    
    /// 触摸事件 - 取消 / 丢失
    ///
    /// # 参数
    /// - `id`: 触摸输入 id (多指触摸时)
    public func handleTouchLost(id: Int) {
        wrap { wb_client_handle_touch_lost(ptr!, UInt64(id)) }
    }
    
    /// 用户事件 - 选择工具
    ///
    /// # 参数
    /// - `tool`: 工具类型
    public func setTool(_ tool: WbTool) {
        wrap { wb_client_set_tool(ptr!, tool.toCValue())}
    }
    
    /// 用户事件 - 清除当前页面全部图形
    public func clearAll() {
        wrap { wb_client_clear_all(ptr!) }
    }
    
    /// 用户事件 - 清除当前页面自己绘制的内容
    public func clearMine() {
        wrap { wb_client_clear_mine(ptr!) }
    }
    
    /// 用户事件 - 清除当前页面其他人绘制的内容
    public func clearOthers() {
        wrap { wb_client_clear_others(ptr!) }
    }
    
    /// 用户事件 - 清除当前页面选择的图形
    public func clearSelected() {
        wrap { wb_client_clear_selected(ptr!) }
    }
    
    /// 用户事件 - 设置填充色 (优先用色号`setFillColorToken`)
    ///
    /// # 参数
    /// - `color`: 32 位4通道颜色数据, 由高位到地位分别位 A R G B
    public func setFillColor(_ color: UInt32) {
        wrap { wb_client_set_fill_color(ptr!, color)}
    }
    
    /// 用户事件 - 设置笔触色 (优先用色号`setStrokeColorToken`)
    ///
    /// # 参数
    /// - `color`: 32 位4通道颜色数据, 由高位到地位分别位 A R G B
    public func setStrokeColor(_ color: UInt32) {
        wrap { wb_client_set_stroke_color(ptr!, color) }
    }
    
    /// 用户事件 - 设置笔触宽度
    ///
    /// # 参数
    /// - `width`: 绘制图形时描边的笔触宽度
    public func setStrokeWidth(_ width: UInt32) {
        wrap { wb_client_set_stroke_width(ptr!, width) }
    }
    
    /// 用户事件 - 撤销
    public func undo() {
        wrap { wb_client_undo(ptr!) }
    }
    
    /// 用户事件 - 重做
    public func redo() {
        wrap { wb_client_redo(ptr!) }
    }
    
    /// 用户事件 - 设置主题
    ///
    /// # 参数
    /// - `theme`: 新的主题
    public func setTheme(_ theme: WbTheme) {
        wrap { wb_client_set_theme(ptr, theme.toCValue()) }
    }
    
    /// 用户事件 - 设置填充色号
    ///
    /// # 参数
    /// - `token`：色号值
    public func setFillColorToken(_ token: WbColorToken) {
        wrap { wb_client_set_fill_color_token(ptr!, token.toCValue()) }
    }
    
    /// 用户事件 - 设置笔触色号
    ///
    /// # 参数
    /// - `token`：色号值
    public func setStrokeColorToken(_ token: WbColorToken) {
        wrap { wb_client_set_stroke_color_token(ptr!, token.toCValue()) }
    }
    
    /// 用户事件 - 新建页面
    ///
    /// # 参数
    /// - `id`: 页 id
    public func newPage(_ id: Int64) {
        wrap { wb_client_new_page(ptr!, id) }
    }
    
    /// 用户事件 - 移除页面
    ///
    /// # 参数
    /// - `id`: 页 id
    public func removePage(_ id: Int64) {
        wrap { wb_client_remove_page(ptr, id) }
    }
    
    /// 用户事件 - 切换页面
    ///
    /// # 参数
    /// - `id`: 页 id
    public func switchPage(_ id: Int64) {
        wrap { wb_client_switch_page(ptr!, id) }
    }
    
    /// 用户事件 - 重置页面 id
    ///
    /// # 参数
    /// - `current_id`: 当前页 id
    /// - `new_id`: 新的页 id
    public func renamePage(_ currentId: Int64, _ newId: Int64) {
        wrap { wb_client_rename_page(ptr!, currentId, newId) }
    }
    
    /// 用户事件 - 开始暂存操作
    ///
    /// 调用该方法后, 会暂存接下来对白板的操作, 直到调用 `wb_client_push_stashed_operations`
    ///
    /// # 适用场景
    /// 当白板状态从本地切换到在线时 (目前是会前->会中), SDK 使用者会做两件事
    /// 1. 把 snapshot 上传到服务端
    /// 2. 建立与服务端的数据传输通道(目前是 Groot), 成功后调用`setSyncDataDelegate`
    ///
    /// 在 1 和 2 之间的空档期, 如果用户继续操作白板, 将导致这部分的数据丢失。为了解决这个问题,
    /// 可以先调用`stashNextOperations`, 后续再调用`pushStashedOperations`将暂存
    /// 的操作发送给服务端。
    ///
    /// # 完整的调用流程
    /// 1. 上传 snapshot
    /// 2. 调用 `stashNextOperations`
    /// 3. 建立与服务端的传输通道
    /// 4. 建立成功后调用 `setSyncDataDelegate`
    /// 5. 调用 `pushStashedOperations`
    ///
    /// # 注意
    /// 调用该接口时, 如果`setSyncDataDelegate`已经设置过了, 则不生效
    public func stashNextOperations() {
        wrap { wb_client_stash_next_operations(ptr!) }
    }
    
    /// 用户事件 - 将暂存的事件推送到远端
    ///
    /// # 注意
    /// 调用该接口时, 需确保已经调用过 `stashNextOperations` 及 `setSyncDataDelegate`
    public func pushStashedOperations() {
        wrap { wb_client_push_stashed_operations(ptr!) }
    }
    
    /// 用户事件 - 设置文字识别结果
    ///
    /// # 参数
    /// - `id`: 文字识别请求开始时带的 id
    /// - `text`: 文字识别结果
    /// - `status`: 文字识别结果状态, 根据请求结果取值
    public func setTextRecognitionResult(id: String, text: String, status: TextRecognitionResultStatus) {
        let cId = id.unsafeMutablePointerRetained()
        let cText = text.unsafeMutablePointerRetained()
        
        wrap { wb_client_set_text_recognition_result(ptr!, cId, cText, status.toCValue())}
        
        cId?.freeUnsafeMemory()
        cText?.freeUnsafeMemory()
    }
    
    // 配置
    
    /// 是否启用文字识别的功能
    ///
    /// 启用后只有在 `Pencil` 工具下, 才会在绘制结束后开始识别
    public func setEnableTextRecognition(enable: Bool) {
        do {
            try wrap_throws { wb_client_set_enable_text_recognition(ptr!, enable) }
        } catch {
            printError("Something went wrong when setEnableTextRecognition: \(error)")
        }
    }
    
    /// 是否启用路径的增量渲染
    ///
    /// 增量渲染只对 Pencil 和 Highlighter 有效
    public func setEnableIncrementalPath(enable: Bool) {
        do {
            try wrap_throws { wb_client_set_enable_incremental_path(ptr!, enable) }
        } catch {
            printError("Something went wrong when setEnableIncrementalPath: \(error)")
        }
    }
    
    /// 设置手写笔迹的识别延迟, 单位为毫秒
    ///
    /// # 默认值
    /// 500 ms
    public func setPathRecognitionDelayMs(delay: UInt32) {
        do {
            try wrap_throws { wb_client_set_path_recognition_delay_ms(ptr!, delay) }
        } catch {
            printError("Something went wrong when setPathRecognitionDelayMs: \(error)")
        }
    }
    
    /// 设置发送协同数据的间隔
    ///
    /// # 参数
    /// - `interval`: 单位 ms
    ///
    /// # 默认
    /// 默认无间隔发送, 既和输入事件频率一致
    public func setSendSyncDataIntervalMs(interval: UInt32) {
        do {
            try wrap_throws { wb_client_set_send_sync_data_interval_ms(ptr!, interval) }
        } catch {
            printError("Something went wrong when setSendSyncIntervalMs: \(error)")
        }
    }
    
    /// 设置播放解析后协同数据的帧率
    ///
    /// # 参数
    /// - `fps`: 单位 fps
    ///
    /// # 默认
    /// 默认全帧率播放, 既和接收到的数据最大帧率一致
    public func setReplaySyncDataFps(fps: UInt32) {
        do {
            try wrap_throws { wb_client_set_replay_sync_data_fps(ptr!, fps) }
        } catch {
            printError("Something went wrong when setReplaySyncFps: \(error)")
        }
    }
}

extension WbClient {
    /// 获取 WbClient 内部的 C 指针, 主要给 WbClientTestRunner 使用
    public func getCPtr() -> OpaquePointer {
        return ptr!
    }
}
