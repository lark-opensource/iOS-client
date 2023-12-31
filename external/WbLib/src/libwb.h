#ifndef WB_LIB_H_
#define WB_LIB_H_

#include <stdarg.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>

// #pragma comment(lib,"wb.dll.lib")


typedef enum C_WB_COLOR_TOKEN
{
    C_WB_COLOR_TOKEN_PRIMARY = 1,
    C_WB_COLOR_TOKEN_R500 = 2,
    C_WB_COLOR_TOKEN_Y500 = 3,
    C_WB_COLOR_TOKEN_G500 = 4,
    C_WB_COLOR_TOKEN_B500 = 5,
    C_WB_COLOR_TOKEN_P500 = 6,
    C_WB_COLOR_TOKEN_TRANSPARENT = 7,
} C_WB_COLOR_TOKEN;

typedef enum C_WB_CURSOR_STYLE
{
    C_WB_CURSOR_STYLE_DEFAULT = 1,
    C_WB_CURSOR_STYLE_GRAB = 2,
    C_WB_CURSOR_STYLE_CROSS = 3,
} C_WB_CURSOR_STYLE;

typedef enum C_WB_FRAME_FORMAT
{
    C_WB_FRAME_FORMAT_PNG = 1,
    C_WB_FRAME_FORMAT_JPEG = 2,
    C_WB_FRAME_FORMAT_RGBA = 3,
    C_WB_FRAME_FORMAT_I420P = 4,
} C_WB_FRAME_FORMAT;

typedef enum C_WB_NOTIFICATION
{
    C_WB_NOTIFICATION_UNDO_REDO_STATUS_CHANGED = 1,
    C_WB_NOTIFICATION_VIEWPORT_SCALE = 2,
    C_WB_NOTIFICATION_VIEWPORT_TRANSLATION = 3,
    C_WB_NOTIFICATION_CURSOR_STYLE = 4,
    C_WB_NOTIFICATION_START_DRAWING = 5,
    C_WB_NOTIFICATION_DRAWING = 6,
    C_WB_NOTIFICATION_END_DRAWING = 7,
    C_WB_NOTIFICATION_CANCEL_DRAWING = 8,
    C_WB_NOTIFICATION_HAS_PENDING_GRAPHIC_CMDS = 9,
    C_WB_NOTIFICATION_THEME_CHANGE = 10,
    C_WB_NOTIFICATION_START_TICKER = 11,
    C_WB_NOTIFICATION_STOP_TICKER = 12,
    C_WB_NOTIFICATION_START_TEXT_RECOGNITION = 13,
    C_WB_NOTIFICATION_TEXT_RECOGNITION_UNEXPECTED = 14,
    C_WB_NOTIFICATION_UNIMPLEMENTED = 999,
} C_WB_NOTIFICATION;

typedef enum C_WB_PATH_ACTION
{
    C_WB_PATH_ACTION_MOVE_TO = 1,
    C_WB_PATH_ACTION_LINE_TO = 2,
    C_WB_PATH_ACTION_QUAD_TO = 3,
    C_WB_PATH_ACTION_CUBIC_TO = 4,
    C_WB_PATH_ACTION_CLOSE = 5,
    C_WB_PATH_ACTION_END = 6,
} C_WB_PATH_ACTION;

typedef enum C_WB_PRIMITIVE
{
    C_WB_PRIMITIVE_PATH = 1,
    C_WB_PRIMITIVE_TEXT = 2,
    C_WB_PRIMITIVE_IMAGE = 3,
} C_WB_PRIMITIVE;

typedef enum C_WB_RENDER_CMD
{
    C_WB_RENDER_CMD_ADD = 1,
    C_WB_RENDER_CMD_UPDATE = 2,
    C_WB_RENDER_CMD_UPDATE_PATH = 3,
    C_WB_RENDER_CMD_UPDATE_STROKE = 4,
    C_WB_RENDER_CMD_UPDATE_FILL = 5,
    C_WB_RENDER_CMD_UPDATE_TRANSFORM = 6,
    C_WB_RENDER_CMD_REMOVE = 7,
    C_WB_RENDER_CMD_CLEAR = 8,
} C_WB_RENDER_CMD;

typedef enum C_WB_RESULT
{
    C_WB_RESULT_OK = 0,
    C_WB_RESULT_KO = 1,
} C_WB_RESULT;

/*
 白板产生的同步数据的类型, 和 GrootCell 中的 DataType 含义一致
 */
typedef enum C_WB_SYNC_DATA_TYPE
{
    C_WB_SYNC_DATA_TYPE_DRAW_DATA = 1,
    C_WB_SYNC_DATA_TYPE_SYNC_DATA = 2,
} C_WB_SYNC_DATA_TYPE;

typedef enum C_WB_TEXT_RECOGNITION_RESULT_STATUS
{
    C_WB_TEXT_RECOGNITION_RESULT_STATUS_UNKNOWN = 0,
    /*
     请求成功
     */
    C_WB_TEXT_RECOGNITION_RESULT_STATUS_SUCCESS = 1,
    /*
     服务端返回错误信息 OCR_ERROR
     */
    C_WB_TEXT_RECOGNITION_RESULT_STATUS_SERVER_ERROR = 2,
    /*
     客户端请求失败 / 超时
     */
    C_WB_TEXT_RECOGNITION_RESULT_STATUS_CLIENT_ERROR = 3,
} C_WB_TEXT_RECOGNITION_RESULT_STATUS;

typedef enum C_WB_THEME
{
    C_WB_THEME_LIGHT = 1,
    C_WB_THEME_DARK = 2,
} C_WB_THEME;

typedef enum C_WB_TOOL
{
    C_WB_TOOL_MOVE = 1,
    C_WB_TOOL_SELECT = 2,
    C_WB_TOOL_COMET = 3,
    C_WB_TOOL_ERASER = 4,
    C_WB_TOOL_PENCIL = 5,
    C_WB_TOOL_HIGHLIGHTER = 6,
    C_WB_TOOL_LINE = 7,
    C_WB_TOOL_ARROW = 8,
    C_WB_TOOL_TRIANGLE = 9,
    C_WB_TOOL_RECT = 10,
    C_WB_TOOL_ELLIPSE = 11,
} C_WB_TOOL;

typedef enum C_WB_TRACE_EVENT_PHASE
{
    /*
     耗时事件, 开始
     */
    C_WB_TRACE_EVENT_PHASE_B = 1,
    /*
     耗时事件, 结束
     */
    C_WB_TRACE_EVENT_PHASE_E = 2,
    /*
     耗时事件
     */
    C_WB_TRACE_EVENT_PHASE_X = 3,
    /*
     单点事件
     */
    C_WB_TRACE_EVENT_PHASE_I = 4,
} C_WB_TRACE_EVENT_PHASE;

/*
 通过一个不透明的 Rust 指针封装 GrootAdaptor

 # 注意
 在使用完毕之后需要将其 Destroy
 */
typedef struct CGrootAdaptor CGrootAdaptor;

/*
 `CWbClient` 是 rust 白板对象 `WbClient` 的不透明封装

 # 创建
 使用 `wb_client_init` 创建该实例

 # 销毁
 使用 `wb_client_destroy` 销毁实例
 */
typedef struct CWbClient CWbClient;

/*
 SkiaRender 相关 C 封装
 `CWbSkiaRender` 是 rust 白板渲染器对象 `Rc<RefCell<wb_lib::SkiaRenderSync>>` 的不透明封装

 # 创建
 使用 `wb_skia_render_new` 创建该实例

 # 销毁
 使用 `wb_skia_render_destroy` 销毁实例
 */
typedef struct CWbSkiaRender CWbSkiaRender;

/*
 用于播放测试的播放器实例
 */
typedef struct WbTestRunner WbTestRunner;

typedef struct CPoint
{
    float x;
    float y;
} CPoint;

typedef struct CEnum_C_WB_RENDER_CMD
{
    enum C_WB_RENDER_CMD ty;
    const void *data;
} CEnum_C_WB_RENDER_CMD;

typedef struct CArray_CEnum_C_WB_RENDER_CMD
{
    const struct CEnum_C_WB_RENDER_CMD *data_ptr;
    uintptr_t size;
} CArray_CEnum_C_WB_RENDER_CMD;

/*
 软渲染中使用的用户名牌样式信息
 */
typedef struct CNameplateStyle
{
    /*
     字号
     */
    uint32_t font_size;
    /*
     字重
     */
    uint32_t font_weight;
    /*
     文字颜色 (32 位 ARGB 四通道颜色)

     # 格式
     0xAARRGGBB
     */
    uint32_t text_color;
    /*
     背景色 (32 位 ARGB 四通道颜色)

     # 格式
     0xAARRGGBB
     */
    uint32_t background_color;
    /*
     水平内边距
     */
    float padding_x;
    /*
     垂直内边距
     */
    float padding_y;
    /*
     圆角弧度
     */
    float corner_radius;
} CNameplateStyle;

/*
 ComplexRender 异步渲染帧数据回调

 # 参数
 - `ctx`: 由 `wb_init_with_complex_render` 传入的业务上下文
 - `format`: 帧格式
 - `width`: 帧宽度
 - `height`: 帧高度
 - `data`: 二进制帧数据
 - `len`: 二进制数据长度
 */
typedef void (*WbOnPostFrameCallback)(void *ctx, enum C_WB_FRAME_FORMAT format, uint32_t width, uint32_t height, const uint8_t *data, size_t len);

typedef struct CPageInfo
{
    enum C_WB_THEME theme;
    uint32_t line_count;
    uint32_t arrow_count;
    uint32_t ellipse_count;
    uint32_t rectangle_count;
    uint32_t triangle_count;
    uint32_t pencil_count;
    uint32_t pencil_point_count;
    uint32_t highlighter_count;
    uint32_t highlighter_point_count;
    uint32_t text_count;
} CPageInfo;

typedef struct CArray_u8
{
    const uint8_t *data_ptr;
    uintptr_t size;
} CArray_u8;

typedef struct CArray_CPageInfo
{
    const struct CPageInfo *data_ptr;
    uintptr_t size;
} CArray_CPageInfo;

typedef struct CEnum_C_WB_PRIMITIVE
{
    enum C_WB_PRIMITIVE ty;
    const void *data;
} CEnum_C_WB_PRIMITIVE;

typedef struct CArray_f32
{
    const float *data_ptr;
    uintptr_t size;
} CArray_f32;

typedef struct CStroke
{
    uint32_t color;
    uint32_t width;
    const struct CArray_f32 *dasharray;
} CStroke;

typedef struct CFill
{
    uint32_t color;
} CFill;

typedef struct CTransform
{
    float a;
    float b;
    float c;
    float d;
    float e;
    float f;
} CTransform;

typedef struct CWbGraphic
{
    const struct CEnum_C_WB_PRIMITIVE *primitive;
    const struct CStroke *stroke;
    const struct CFill *fill;
    const struct CTransform *transform;
} CWbGraphic;

typedef struct CArray_CWbGraphic
{
    const struct CWbGraphic *data_ptr;
    uintptr_t size;
} CArray_CWbGraphic;

/*
 初始化 CWbClient 所需要的参数列表
 */
typedef struct CWbClientConfig
{
    const char *user_id;
    const char *device_id;
    uint8_t user_type;
} CWbClientConfig;

/*
 白板抛出的事件, 通过此回调将结果回传到业务侧

 # 参数
  - `ctx`: 由 `wb_client_new` 传入的业务上下文
  - `eventName`: 事件名, 详见`CWbNotificationName`
  - `data`: 发生变化的属性值, 详见`WbNotification`
 */
typedef void (*OnWbNotificationCallback)(void *ctx, enum C_WB_NOTIFICATION notification, const void *data);

typedef struct CWbInlineGlyphSpecs
{
    float height;
    const struct CArray_f32 *widths;
    float origin_offset_x;
    float origin_offset_y;
} CWbInlineGlyphSpecs;

/*
 白板 SDK 通过此回调测量文字渲染参数

 # 参数
 - `ctx`: 由`wb_init_with_2d_render`传入的业务上下文
 - `text`: 被测量文字
 - `font_size`: 字体尺寸
 - `font_weight`: 字体粗细

 # 字体粗细典型值
 - `300`: Light
 - `400`: Normal (Regular)
 - `700`: Bold

 # 返回值
 测量完成的字体参数

 # 内存安全
 - 返回值使用完成后, 调用 `CInlineGlyphSpecsDestroy` 释放
 */
typedef struct CWbInlineGlyphSpecs *(*OnWbMeasureInlineTextCallback)(void *ctx, const char *text, uint32_t font_size, uint32_t font_weight);

/*
 释放 `CInlineGlyphSpecs` 内存
 */
typedef bool (*CInlineGlyphSpecsDestroy)(struct CWbInlineGlyphSpecs*);

/*
 白板图形发生变化时, 通过此回调将协同数据回传到业务侧

 # 参数
 - `ctx`: 由`wb_init_with_2d_render`传入的业务上下文
 - `data`: 协同所需的二进制数据
 */
typedef void (*OnWbSyncDataChangedCallback)(void *ctx, enum C_WB_SYNC_DATA_TYPE data_type, const uint8_t *data, size_t len);

/*
 该回调用于向服务端拉取丢失 GrootCells

 # 参数
 - `context`: 由 wb_groot_adaptor_new 传入的业务上下文
 - `response_bytes_ptr`: PB - PullGrootCellsResponse 字节流指针
 - `response_bytes_len`: PB - PullGrootCellsResponse 字节流长度
 - `down_version_ptr`: 需要拉取的下行版本号序列指针
 - `down_version_len`: 需要拉取的下行版本号序列长度
 - `channel_meta_ptr`: PB - ChannelMeta 字节流指针
 - `channel_meta_len`: PB - ChannelMeta 字节流长度
 */
typedef void (*CPullGrootCellsCallback)(void *context, const uint8_t **response_bytes_ptr, size_t *response_bytes_len, const int64_t *down_version_ptr, size_t down_version_len, const uint8_t *channel_meta_ptr, size_t channel_meta_len);

/*
 该回调用于向客户端推送排序好的 GrootCells

 # 参数
 - `context`: 由 wb_groot_adaptor_new 传入的业务上下文
 - `bytes`: PB - PushGrootCells 字节流指针
 - `len`: PB - PushGrootCells 字节流长度
 */
typedef void (*CRecvGrootCellsCallback)(void *context, const uint8_t *bytes, size_t len);

/*
 白板内部日志输出, 通过此回调将内容回传到业务侧

 # 参数
 - `category`: 日志分类, UTF8 编码字符串
 - `level`: 日志分级
 - `msg`: 日志内容信息, UTF8 编码字符串

 # 日志分级取值
 - `0`: Error
 - `1`: Warn
 - `2`: Info
 - `3`: Debug (默认关闭)
 - `4`: Trace (默认关闭)
 */
typedef void (*OnWbLogMessageCallback)(const char *category, uint32_t level, const char *msg);

typedef struct CWbTraceEvent
{
    /*
     事件名
     */
    const char *name;
    /*
     事件分类, 可用分号隔开的业务分类名, UI上可以通过该字段筛选展示
     */
    const char *category;
    /*
     事件类型
     */
    const enum C_WB_TRACE_EVENT_PHASE *phase;
    /*
     耗时事件的总时长 (microseconds)
     */
    const uint64_t *duration;
    /*
     自定义参数
     */
    const char *args;
} CWbTraceEvent;

/*
 白板内部 Trace 事件通过此回调回传到业务侧

 # 参数
  - `event`: Trace 事件
 */
typedef void (*OnWbTraceEventCallback)(const struct CWbTraceEvent *event);

typedef struct CSize
{
    float width;
    float height;
} CSize;

typedef struct CUndoRedoStatusData
{
    bool can_undo;
    bool can_redo;
} CUndoRedoStatusData;

typedef struct CDrawingStateData
{
    const char *user_id;
    const char *device_id;
    const char *graphic_id;
    uint8_t user_type;
    const struct CPoint *position;
} CDrawingStateData;

typedef struct CWbAddCmd
{
    const char *id;
    const struct CWbGraphic *graphic;
} CWbAddCmd;

typedef struct CWbUpdateCmd
{
    const char *id;
    const struct CWbGraphic *graphic;
} CWbUpdateCmd;

typedef struct CArray_CPoint
{
    const struct CPoint *data_ptr;
    uintptr_t size;
} CArray_CPoint;

typedef struct CArray_C_WB_PATH_ACTION
{
    const enum C_WB_PATH_ACTION *data_ptr;
    uintptr_t size;
} CArray_C_WB_PATH_ACTION;

typedef struct CPath
{
    const struct CArray_CPoint *points;
    const struct CArray_C_WB_PATH_ACTION *actions;
} CPath;

typedef struct CWbUpdatePathCmd
{
    const char *id;
    bool is_incremental;
    const struct CPath *path;
} CWbUpdatePathCmd;

typedef struct CWbUpdateStrokeCmd
{
    const char *id;
    const struct CStroke *stroke;
} CWbUpdateStrokeCmd;

typedef struct CWbUpdateFillCmd
{
    const char *id;
    const struct CFill *fill;
} CWbUpdateFillCmd;

typedef struct CWbUpdateTransformCmd
{
    const char *id;
    const struct CTransform *transform;
} CWbUpdateTransformCmd;

typedef struct CWbRemoveCmd
{
    const char *id;
} CWbRemoveCmd;

typedef struct CVector
{
    float x;
    float y;
} CVector;

typedef struct CThemeChangeData
{
    int64_t page_id;
    enum C_WB_THEME theme;
} CThemeChangeData;

typedef struct CText
{
    const char *text;
    uint32_t font_size;
    uint32_t font_weight;
} CText;

typedef struct CImage
{
    uint64_t resource_id;
    const struct CSize *size;
} CImage;

typedef struct CArray_CArray_CPoint
{
    const struct CArray_CPoint *data_ptr;
    uintptr_t size;
} CArray_CArray_CPoint;

typedef struct CStartTextRecognitionData
{
    const char *id;
    const struct CArray_CArray_CPoint *points;
    float average_interval_ms;
} CStartTextRecognitionData;

typedef struct CTextRecognitionUnexpectedData
{
    uint8_t code;
    const char *id;
    const char *text;
} CTextRecognitionUnexpectedData;

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

/*
 用户事件 - 清除当前页面全部图形
 */
enum C_WB_RESULT wb_client_clear_all(struct CWbClient *ptr);

/*
 用户事件 - 清除当前页面自己绘制的内容
 */
enum C_WB_RESULT wb_client_clear_mine(struct CWbClient *ptr);

/*
 用户事件 - 清除当前页面其他人绘制的内容
 */
enum C_WB_RESULT wb_client_clear_others(struct CWbClient *ptr);

/*
 用户事件 - 清除当前页面选择的图形
 */
enum C_WB_RESULT wb_client_clear_selected(struct CWbClient *ptr);

/*
 设置用户名牌

 # 参数
 - `ptr`: 指向白板实例的指针
 - `id`: 用户名牌的 uuid, 由 (userId, userType, deviceId) 三元组唯一确定
 - `graphic_id`: 用户名牌所关联的图形 id
 - `name`: 用户名, UTF-8 编码字符串
 - `location`: 显示位置 (左上角)

 # 时机
 仅在 `wb_client_complex_render_start_async_render` 调用后生效
 */
enum C_WB_RESULT wb_client_complex_render_add_nameplate(struct CWbClient *ptr,
                                                        const char *id,
                                                        const char *graphic_id,
                                                        const char *name,
                                                        const struct CPoint *location);

/*
 设置 ComplexRender 画布重绘标记位

 在画布内容没有变更得情况下, 可以通过设置此标记位触发一帧渲染

 # 时机
 仅在 `wb_client_complex_render_start_async_render` 调用后生效
 */
enum C_WB_RESULT wb_client_complex_render_invalidate(struct CWbClient *ptr);

/*
 从白板拉取一次图形指令数据

 # 内存安全
 图形指令数据使用结束后, 通过`wb_client_destroy_graphic_cmds`销毁数据

 # 参数
 - `ptr`: 指向白板实例的指针
 - `data_ptr`: 返回图形指令数据的指针
 */
enum C_WB_RESULT wb_client_complex_render_pull_pending_graphic_cmds(struct CWbClient *ptr,
                                                                    const struct CArray_CEnum_C_WB_RENDER_CMD **data);

/*
 清除用户名牌

 # 参数
 - `ptr`: 指向白板实例的指针
 - `id`: 用户名牌的 uuid, 由 userId, userType, deviceId 三元组唯一确定

 # 时机
 仅在 `wb_client_complex_render_start_async_render` 调用后生效
 */
enum C_WB_RESULT wb_client_complex_render_remove_nameplate(struct CWbClient *ptr,
                                                           const char *id);

/*
 设置 ComplexRender 的 fps 锁定值

 # 参数
 - `fps`: 期望的渲染帧率

 # 时机
 仅在 `wb_client_complex_render_start_async_render` 调用后生效
 */
enum C_WB_RESULT wb_client_complex_render_set_fps(struct CWbClient *ptr,
                                                  uint32_t fps);

/*
 设置 ComplexRender 用户名牌的样式

 # 参数
 - `style`: 名牌样式

 # 时机
 仅在 `wb_client_complex_render_start_async_render` 调用后生效
 */
enum C_WB_RESULT wb_client_complex_render_set_nameplate_style(struct CWbClient *ptr,
                                                              const struct CNameplateStyle *style);

/*
 设置 ComplexRender 的主题色

 # 参数
 - `frame_bytes_len`: 帧数据字节流长度

 # 时机
 仅在 `wb_client_complex_render_start_async_render` 调用后生效
 */
enum C_WB_RESULT wb_client_complex_render_set_theme(struct CWbClient *ptr,
                                                    enum C_WB_THEME theme);

/*
 启动 ComplexRender 的异步渲染能力

 # 参数
 - `width`: 画布宽度
 - `height`: 画布高度
 - `frame_format`: 帧格式
 - `on_post_frame`: 帧回调

 # 线程安全
 注册进来的 `on_post_frame` 会在白板内部的渲染线程被调用, 业务侧需要将帧数据转到对应的线程进行操作
 */
enum C_WB_RESULT wb_client_complex_render_start_async_render(struct CWbClient *ptr,
                                                             uint32_t width,
                                                             uint32_t height,
                                                             enum C_WB_FRAME_FORMAT frame_format,
                                                             WbOnPostFrameCallback on_post_frame);

/*
 停止 ComplexRender 的异步渲染能力

 # 时机
 仅在 `wb_client_complex_render_start_async_render` 调用后生效
 */
enum C_WB_RESULT wb_client_complex_render_stop_async_render(struct CWbClient *ptr);

/*
 更新用户名牌

 # 参数
 - `ptr`: 指向白板实例的指针
 - `id`: 用户名牌的 uuid, 由 userId, userType, deviceId 三元组唯一确定
 - `location`: 显示位置 (左上角)

 # 时机
 仅在 `wb_client_complex_render_start_async_render` 调用后生效
 */
enum C_WB_RESULT wb_client_complex_render_update_nameplate(struct CWbClient *ptr,
                                                           const char *id,
                                                           const struct CPoint *location);

/*
 销毁 `CWbClient` 实例

 # 参数
 - `ptr`: 指向白板实例的指针
 */
enum C_WB_RESULT wb_client_destroy(struct CWbClient *ptr);

/*
 销毁使用结束的图形指令数据

 # 参数
 - `data_ptr`: 返回图形指令数据的指针
 */
enum C_WB_RESULT wb_client_destroy_graphic_cmds(struct CArray_CEnum_C_WB_RENDER_CMD *data_ptr);

/*
 销毁`CPageInfo`

 # 参数
 - `data_ptr`: 指向页数据的裸指针
 */
enum C_WB_RESULT wb_client_destroy_page_info(struct CPageInfo *data_ptr);

/*
 销毁使用结束的页面截图数据

 # 参数
 - `data_ptr`: 返回页面截图数据的指针
 */
enum C_WB_RESULT wb_client_destroy_page_screenshot_data(struct CArray_u8 *data_ptr);

/*
 销毁使用结束的页面快照数据

 # 参数
 - `data_ptr`: 返回页面快照数据的指针
 */
enum C_WB_RESULT wb_client_destroy_page_snapshot_data(struct CArray_u8 *data_ptr);

/*
 销毁 `CArray<CPageInfo>`

 # 参数
 - `data_ptr`: 指向页数据的裸指针
 */
enum C_WB_RESULT wb_client_destroy_pages_info(struct CArray_CPageInfo *data_ptr);

/*
 销毁 `CArray<CWbGraphic>`

 # 参数
 - `data_ptr`: 指向图形数据的裸指针
 */
enum C_WB_RESULT wb_client_destroy_wb_graphic_array(struct CArray_CWbGraphic *data_ptr);

/*
 获取白板页的全部图形

 # 内存安全
 在 `data_ptr` 数据使用结束后, 调用 `wb_client_destroy_wb_graphic_array` 销毁数据, 否则会造成内存泄漏

 # 参数
 - `ptr`: 指向白板实例的指针
 - `page_id`: 白板页id
 - `data_ptr`: 返回图形数据的指针
 */
enum C_WB_RESULT wb_client_get_page_graphics(struct CWbClient *ptr,
                                             int64_t page_id,
                                             const struct CArray_CWbGraphic **data);

/*
 获取白板页的主题

 # 内存安全
 在 `data_ptr` 使用结束后, 调用 `wb_client_destroy_page_info` 销毁数据, 否则会造成内存泄漏

 # 参数
 - `ptr`: 指向白板实例的指针
 - `page_id`: 白板页id
 - `data_ptr`: 返回页数据的指针
 */
enum C_WB_RESULT wb_client_get_page_info(struct CWbClient *ptr,
                                         int64_t page_id,
                                         const struct CPageInfo **data_ptr);

/*
 拿取一页数据快照

 # 参数
 - `ptr`: 指向白板实例的指针
 - `page_id`: 白板页id
 - `data`: 获取的二进制数据

 # 注意
 - `data` 数据使用完成后应该调用 `wb_client_destroy_page_snapshot_data` 销毁, 否则造成内存泄漏
 */
enum C_WB_RESULT wb_client_get_page_snapshot(struct CWbClient *ptr,
                                             int64_t page_id,
                                             const struct CArray_u8 **data);

/*
 获取所有已加载白板页的图形数据

 # 注意
 需要在页数据使用结束后, 调用`wb_client_destroy_pages_info`销毁数据, 否则会造成内存泄漏

 # 参数
 - `ptr`: 指向白板实例的指针
 - `data_ptr`: 返回页数据的指针
 */
enum C_WB_RESULT wb_client_get_pages_info(struct CWbClient *ptr,
                                          const struct CArray_CPageInfo **data_ptr);

/*
 鼠标事件 - 移入白板区域

 # 参数
 - `x`: 坐标 x
 - `y`: 坐标 y
 */
enum C_WB_RESULT wb_client_handle_mouse_enter(struct CWbClient *ptr,
                                              float x,
                                              float y);

/*
 鼠标事件 - 移出白板区域

 # 参数
 - `x`: 坐标 x
 - `y`: 坐标 y
 */
enum C_WB_RESULT wb_client_handle_mouse_left(struct CWbClient *ptr,
                                             float x,
                                             float y);

/*
 鼠标事件 - 移动

 # 参数
 - `x`: 坐标 x
 - `y`: 坐标 y
 */
enum C_WB_RESULT wb_client_handle_mouse_moved(struct CWbClient *ptr,
                                              float x,
                                              float y);

/*
 鼠标事件 - 点击

 # 参数
 - `x`: 坐标 x
 - `y`: 坐标 y
 */
enum C_WB_RESULT wb_client_handle_mouse_pressed(struct CWbClient *ptr,
                                                float x,
                                                float y);

/*
 鼠标事件 - 释放

 # 参数
 - `x`: 坐标 x
 - `y`: 坐标 y
 */
enum C_WB_RESULT wb_client_handle_mouse_released(struct CWbClient *ptr,
                                                 float x,
                                                 float y);

/*
 处理白板协同数据包

 # 参数
 - `ptr`: 指向白板实例的指针
 - `data_type`: 白板产生的同步数据的类型, 和 GrootCell 中的 DataType 含义一致
 - `data`: 需要被处理的二进制数据
 - `len`: 需要被处理的二进制数据长度
 */
enum C_WB_RESULT wb_client_handle_sync_payload(struct CWbClient *ptr,
                                               enum C_WB_SYNC_DATA_TYPE data_type,
                                               const uint8_t *data,
                                               size_t len);

/*
 触摸事件 - 点击

 # 参数
 - `x`: 坐标 x
 - `y`: 坐标 y
 - `id`: 触摸输入 id (多指触摸时)
 */
enum C_WB_RESULT wb_client_handle_touch_down(struct CWbClient *ptr,
                                             float x,
                                             float y,
                                             uint64_t id);

/*
 触摸事件 - 释放

 # 参数
 - `x`: 坐标 x
 - `y`: 坐标 y
 - `id`: 触摸输入 id (多指触摸时)
 */
enum C_WB_RESULT wb_client_handle_touch_lifted(struct CWbClient *ptr,
                                               float x,
                                               float y,
                                               uint64_t id);

/*
 触摸事件 - 取消 / 丢失

 # 参数
 - `id`: 触摸输入 id (多指触摸时)
 */
enum C_WB_RESULT wb_client_handle_touch_lost(struct CWbClient *ptr,
                                             uint64_t id);

/*
 触摸事件 - 移动

 # 参数
 - `x`: 坐标 x
 - `y`: 坐标 y
 - `id`: 触摸输入 id (多指触摸时)
 */
enum C_WB_RESULT wb_client_handle_touch_moved(struct CWbClient *ptr,
                                              float x,
                                              float y,
                                              uint64_t id);

/*
 用户事件 - 新建页面

 # 参数
 - `id`: 页 id
 */
enum C_WB_RESULT wb_client_new_page(struct CWbClient *ptr,
                                    int64_t id);

/*
 创建一个 `CWbClient` 实例, 使用 `CmdProxyRender`

 # 参数
 - `ctx`: 回调函数执行时的上下文
 - `ptr`: 白板实例的不透明指针, 业务侧需持有该指针与白板API进行交互
 - `config`: 初始化参数
 - `on_notification`: 白板属性变化回调
 - `on_measure_text`: 白板文字测量回调
 - `destroy_inline_glyph_specs`: 销毁文字测量参数

 # 内存安全
 创建的 `ptr` 使用完毕后续要通过 `wb_client_destroy` 释放
 */
enum C_WB_RESULT wb_client_new_with_cmd_proxy_render(void *ctx,
                                                     struct CWbClient **ptr,
                                                     const struct CWbClientConfig *config,
                                                     OnWbNotificationCallback on_notification,
                                                     OnWbMeasureInlineTextCallback on_measure_text,
                                                     CInlineGlyphSpecsDestroy destroy_inline_glyph_specs);

/*
 创建一个 `CWbClient` 实例, 使用 `SkiaRender`

 # 参数
 - `ctx`: 回调函数执行时的上下文
 - `ptr`: 白板实例的不透明指针, 业务侧需持有该指针与白板API进行交互
 - `config`: 初始化参数
 - `on_notification`: 白板属性变化回调
 - `skia_render`: 外部实例化完成的`CWbSkiaRender`指针

 # 内存安全
 创建的 `ptr` 使用完毕后续要通过 `wb_client_destroy` 释放
 */
enum C_WB_RESULT wb_client_new_with_skia_render(void *ctx,
                                                struct CWbClient **ptr,
                                                const struct CWbClientConfig *config,
                                                OnWbNotificationCallback on_notification,
                                                struct CWbSkiaRender *skia_render);

/*
 从白板拉取一次图形指令数据

 # 内存安全
 图形指令数据使用结束后, 通过`wb_client_destroy_graphic_cmds`销毁数据

 # 参数
 - `ptr`: 指向白板实例的指针
 - `data_ptr`: 返回图形指令数据的指针
 */
enum C_WB_RESULT wb_client_pull_pending_graphic_cmds(struct CWbClient *ptr,
                                                     const struct CArray_CEnum_C_WB_RENDER_CMD **data);

/*
 用户事件 - 将暂存的事件推送到远端

 # 注意
 调用该接口时, 需确保已经调用过 `wb_client_stash_next_operations` 及 `wb_client_set_sync_data_callback`
 */
enum C_WB_RESULT wb_client_push_stashed_operations(struct CWbClient *ptr);

/*
 用户事件 - 重做
 */
enum C_WB_RESULT wb_client_redo(struct CWbClient *ptr);

/*
 用户事件 - 移除页面

 # 参数
 - `id`: 页 id
 */
enum C_WB_RESULT wb_client_remove_page(struct CWbClient *ptr,
                                       int64_t id);

/*
 用户事件 - 重置页面 id

 # 参数
 - `current_id`: 当前页 id
 - `new_id`: 新的页 id
 */
enum C_WB_RESULT wb_client_rename_page(struct CWbClient *ptr,
                                       int64_t current_id,
                                       int64_t new_id);

enum C_WB_RESULT wb_client_set_enable_incremental_path(struct CWbClient *ptr,
                                                       bool enable);

/*
 是否启用文字识别的功能

 启用后只有在 `Pencil` 工具下, 才会在绘制结束后开始识别
 */
enum C_WB_RESULT wb_client_set_enable_text_recognition(struct CWbClient *ptr,
                                                       bool enable);

/*
 用户事件 - 设置填充色 (优先用色号`wb_client_set_fill_color_token`)

 # 参数
 - `color`: 32 位4通道颜色数据, 由高位到地位分别位 A R G B
 */
enum C_WB_RESULT wb_client_set_fill_color(struct CWbClient *ptr,
                                          uint32_t color);

/*
 用户事件 - 设置填充色号

 # 参数
 - `token`：色号值
 */
enum C_WB_RESULT wb_client_set_fill_color_token(struct CWbClient *ptr,
                                                enum C_WB_COLOR_TOKEN token);

/*
 设置一页数据快照

 # 参数
 - `ptr`: 指向白板实例的指针
 - `page_id`: 白板页 id
 - `data`: 需要被处理的二进制数据
 - `len`: 需要被处理的二进制数据长度
 - `page_id`: 如设置成功, 该 snapshot 所对应页的 id , 如果设置失败返回空字符串
 */
enum C_WB_RESULT wb_client_set_page_snapshot(struct CWbClient *ptr,
                                             const uint8_t *data,
                                             size_t len,
                                             int64_t *page_id);

/*
 设置手写笔迹的识别延迟, 单位为毫秒

 # 默认
 500 ms
 */
enum C_WB_RESULT wb_client_set_path_recognition_delay_ms(struct CWbClient *ptr,
                                                         uint32_t delay);

/*
 设置播放解析后协同数据的帧率

 # 参数
 - `fps`: 单位 fps

 # 默认
 全帧率播放, 既和接收到的数据最大帧率一致
 */
enum C_WB_RESULT wb_client_set_replay_sync_data_fps(struct CWbClient *ptr,
                                                    uint32_t fps);

/*
 设置发送协同数据的间隔

 # 参数
 - `interval`: 单位 ms

 # 默认
 默认无间隔发送, 既和输入事件频率一致
 */
enum C_WB_RESULT wb_client_set_send_sync_data_interval_ms(struct CWbClient *ptr,
                                                          uint32_t interval);

/*
 用户事件 - 设置笔触色 (优先用色号`wb_client_set_stroke_color_token`)

 # 参数
 - `color`: 32 位4通道颜色数据, 由高位到地位分别位 A R G B
 */
enum C_WB_RESULT wb_client_set_stroke_color(struct CWbClient *ptr,
                                            uint32_t color);

/*
 用户事件 - 设置笔触色号

 # 参数
 - `token`：色号值
 */
enum C_WB_RESULT wb_client_set_stroke_color_token(struct CWbClient *ptr,
                                                  enum C_WB_COLOR_TOKEN token);

/*
 用户事件 - 设置笔触宽度

 # 参数
 - `width`: 绘制图形时描边的笔触宽度
 */
enum C_WB_RESULT wb_client_set_stroke_width(struct CWbClient *ptr,
                                            uint32_t width);

/*
 设置协同数据回调

 # 参数
 - `ptr`: 指向白板实例的指针
 - `on_sync_data_changed`: 协同数据回调
 */
enum C_WB_RESULT wb_client_set_sync_data_callback(struct CWbClient *ptr,
                                                  OnWbSyncDataChangedCallback on_sync_data_changed);

/*
 用户事件 - 设置文字识别结果

 # 参数
 - `id`: 文字识别请求开始时带的 id
 - `text`: 文字识别结果
 - `status`: 文字识别结果状态, 根据请求结果取值
 */
enum C_WB_RESULT wb_client_set_text_recognition_result(struct CWbClient *ptr,
                                                       const char *id,
                                                       const char *text,
                                                       enum C_WB_TEXT_RECOGNITION_RESULT_STATUS status);

/*
 用户事件 - 设置主题

 # 参数
 - `theme`: 新的主题
 */
enum C_WB_RESULT wb_client_set_theme(struct CWbClient *ptr,
                                     enum C_WB_THEME theme);

/*
 用户事件 - 选择工具

 # 参数
 - `tool`: 工具类型
 */
enum C_WB_RESULT wb_client_set_tool(struct CWbClient *ptr,
                                    enum C_WB_TOOL tool);

/*
 用户事件 - 开始暂存操作

 调用该方法后, 会暂存接下来对白板的操作, 直到调用 `wb_client_push_stashed_operations`

 # 适用场景
 当白板状态从本地切换到在线时 (目前是会前->会中), SDK 使用者会做两件事
 1. 把 snapshot 上传到服务端
 2. 建立与服务端的数据传输通道(目前是 Groot), 成功后调用`wb_client_set_sync_data_callback`

 在 1 和 2 之间的空档期, 如果用户继续操作白板, 将导致这部分的数据丢失。为了解决这个问题,
 可以先调用`wb_client_stash_next_operations`, 后续再调用`wb_client_push_stashed_operations`将暂存
 的操作发送给服务端。

 # 完整的调用流程
 1. 上传 snapshot
 2. 调用 `wb_client_stash_next_operations`
 3. 建立与服务端的传输通道
 4. 建立成功后调用 `wb_client_set_sync_data_callback`
 5. 调用 `wb_client_push_stashed_operations`

 # 注意
 调用该接口时, 如果`wb_client_set_sync_data_callback`已经设置过了, 则不生效
 */
enum C_WB_RESULT wb_client_stash_next_operations(struct CWbClient *ptr);

/*
 用户事件 - 切换页面

 # 参数
 - `id`: 页 id
 */
enum C_WB_RESULT wb_client_switch_page(struct CWbClient *ptr,
                                       int64_t id);

/*
 外部定时器调用, 驱动定时相关逻辑
 */
enum C_WB_RESULT wb_client_tick(struct CWbClient *ptr);

/*
 用户事件 - 撤销
 */
enum C_WB_RESULT wb_client_undo(struct CWbClient *ptr);

/*
 销毁错误信息字符串

 # 参数
 - `error_msg_ptr`: 指向错误信息描述的字符串指针
 */
enum C_WB_RESULT wb_error_destroy(const char *error_msg_ptr);

/*
 获得白板所在线程的错误信息

 当白板SDK调用产生`WB_RESULT::KO`时, 可以通过此函数获取错误信息

 # 参数
 - `error_msg_ptr`: 指向错误信息描述的字符串指针的指针, 使用过后需要通过`wb_error_destroy`销毁, 否则将造成内存泄漏

 # 注意
 该函数调用只应该返回`WB_RESULT::OK`, 如果返回了`WB_RESULT::KO`, 说明 rust 内部调用出错
 */
enum C_WB_RESULT wb_error_get_last(const char **error_msg_ptr);

/*
 关闭 Groot 通道, 业务结束时调用

 # 参数
 - `ptr`: 指向 GrootAdaptor 实例的指针
 */
enum C_WB_RESULT wb_groot_adaptor_close_channel(struct CGrootAdaptor *ptr);

/*
 销毁`CGrootAdaptor`裸指针所指向的 GrootAdaptor 实例

 # 参数
 - `ptr`: 指向 `CGrootAdaptor` 实例的指针
 */
enum C_WB_RESULT wb_groot_adaptor_destroy(struct CGrootAdaptor *ptr);

/*
 创建一个新的 `GrootAdaptor` 对象

 # 参数
 - `context`: 由 wb_groot_adaptor_new 传入到两个回调函数中的业务上下文
 - `ptr`: 指向 GrootAdaptor 实例的不透明指针, 业务侧需持有该指针与 GrootAdaptor 进行交互
 - `pull_groot_cell_callback`: 用于向服务端拉取丢失 GrootCells
 - `recv_groot_cell_callback`: 用于向客户端推送排序好的 GrootCells
 */
enum C_WB_RESULT wb_groot_adaptor_new(void *context,
                                      struct CGrootAdaptor **ptr,
                                      CPullGrootCellsCallback pull_groot_cells_callback,
                                      CRecvGrootCellsCallback recv_groot_cells_callback);

/*
 开启 Groot 通道

 # 参数
 - `ptr`: 指向 GrootAdaptor 实例的指针
 - `init_down_version`: 初始下行版本号
 - `channel_meta_ptr`: PB - ChannelMeta 字节流指针
 - `channel_meta_len`: PB - ChannelMeta 字节流长度
 */
enum C_WB_RESULT wb_groot_adaptor_open_channel(struct CGrootAdaptor *ptr,
                                               const uint8_t *channel_meta_ptr,
                                               size_t channel_meta_len,
                                               int64_t init_down_version);

/*
 接收服务端推送的未经排序的 GrootCells

 # 参数
 - `ptr`: 指向 GrootAdaptor 实例的指针
 - `bytes`: PB - PushGrootCells 字节流指针
 - `len`: PB - PushGrootCells 字节流长度
 */
enum C_WB_RESULT wb_groot_adaptor_receive_groot_cells_bytes(struct CGrootAdaptor *ptr,
                                                            const uint8_t *bytes,
                                                            size_t len);

/*
 设置日志回调

 # 注意
 日志模块为进程单例, 同一个进程无法设置多个日志回调
 */
enum C_WB_RESULT wb_set_log_callback(OnWbLogMessageCallback on_log_message);

/*
 设置 TraceEvent 回调

 # 注意
 日志模块为进程单例, 同一个进程无法设置多个日志回调
 */
enum C_WB_RESULT wb_set_trace_callback(OnWbTraceEventCallback on_trace_event);

/*
 设置用户名牌

 # 参数
 - `ptr`: 指向白板`SkiaRender`实例的指针
 - `id`: 用户名牌的 uuid, 由 (userId, userType, deviceId) 三元组唯一确定
 - `graphic_id`: 用户名牌所关联的图形 id
 - `name`: 用户名, UTF-8 编码字符串
 - `location`: 显示位置 (左上角)
 */
enum C_WB_RESULT wb_skia_render_add_nameplate(struct CWbSkiaRender *ptr,
                                              const char *id,
                                              const char *graphic_id,
                                              const char *name,
                                              const struct CPoint *location);

/*
 销毁`CWbSkiaRender`实例

 # 参数
 - `ptr`: 指向白板Skia渲染器实例的指针
 */
enum C_WB_RESULT wb_skia_render_destroy(struct CWbSkiaRender *ptr);

/*
 销毁使用结束的帧图形数据

 # 参数
 - `ptr`: 指向白板`SkiaRender`实例的指针
 - `frame_bytes_ptr`: 帧数据字节流指针
 - `frame_bytes_len`: 帧数据字节流长度
 */
enum C_WB_RESULT wb_skia_render_destroy_frame_data(const uint8_t *frame_bytes_ptr,
                                                   size_t frame_bytes_len);

/*
 绘制一帧图形数据

 # 参数
 - `ptr`: 指向白板`SkiaRender`实例的指针
 - `format`: 帧数据类型
 - `frame_bytes_ptr`: 帧数据字节流指针
 - `frame_bytes_len`: 帧数据字节流长度
 */
enum C_WB_RESULT wb_skia_render_draw_frame(struct CWbSkiaRender *ptr,
                                           uint8_t format,
                                           const uint8_t **frame_bytes_ptr,
                                           size_t *frame_bytes_len);

/*
 创建一个新的`CWbSkiaRender`实例

 # 参数
 - `ptr`: 指向白板Skia渲染器实例的指针
 - `width`: 画布宽度
 - `height`: 画布高度
 */
enum C_WB_RESULT wb_skia_render_new(struct CWbSkiaRender **ptr,
                                    uint32_t width,
                                    uint32_t height);

/*
 清除用户名牌

 # 参数
 - `ptr`: 指向白板`SkiaRender`实例的指针
 - `id`: 用户名牌的 uuid, 由 userId, userType, deviceId 三元组唯一确定
 */
enum C_WB_RESULT wb_skia_render_remove_nameplate(struct CWbSkiaRender *ptr,
                                                 const char *id);

/*
 设置 SkiaRender 的主题色

 # 参数
 - `theme`: 白板页渲染主题
 */
enum C_WB_RESULT wb_skia_render_set_theme(struct CWbSkiaRender *ptr,
                                          enum C_WB_THEME theme);

/*
 更新用户名牌

 # 参数
 - `ptr`: 指向白板`SkiaRender`实例的指针
 - `id`: 用户名牌的 uuid, 由 userId, userType, deviceId 三元组唯一确定
 - `location`: 显示位置 (左上角)
 */
enum C_WB_RESULT wb_skia_render_update_nameplate(struct CWbSkiaRender *ptr,
                                                 const char *id,
                                                 const struct CPoint *location);

/*
 销毁 LibTestRunner 对象

 # 参数
 - `_test_runner_ptr`: 测试播放器对象
 */
enum C_WB_RESULT wb_test_runner_destroy(struct WbTestRunner *_test_runner_ptr);

/*
 创建一个 WbTestRunner 对象

 # 参数
 - `_test_runner_ptr`: 测试播放器
 - `_testcase_ptr`: 测试用例指针
 - `_testcase_len`: 测试用例长度
 */
enum C_WB_RESULT wb_test_runner_new(struct WbTestRunner **_test_runner_ptr,
                                    const uint8_t *_testcase_ptr,
                                    size_t _testcase_len);

/*
 以定时方式驱动测试运行器播放操作序列 (在UI线程操作)

 每次调用, 播放新进入时延区间的操作

 # 参数
 - `_test_runner_ptr`: 测试播放器对象
 - `_client_ptr`: 被测试的 `CWbClient`
 - `_progress`: 当前的测试运行进度, 0.0 - 1.0 取值, 1.0 表示完成
 */
enum C_WB_RESULT wb_test_runner_replay_by_now(struct WbTestRunner *_test_runner_ptr,
                                              struct CWbClient *_client_ptr,
                                              float *_progress);

/*
 设置 WbLib 为准备测试状态

 # 参数
 - `_test_runner_ptr`: 测试播放器对象
 - `_client_ptr`: 被测试的 `CWbClient`
 */
enum C_WB_RESULT wb_test_runner_setup(struct WbTestRunner *_test_runner_ptr,
                                      struct CWbClient *_client_ptr);

/*
 重制 CWbClient 到测试前状态

 # 参数
 - `__test_runner_ptr`: 测试播放器对象
 - `_client_ptr`: 被测试的 `CWbClient`
 */
enum C_WB_RESULT wb_test_runner_teardown(struct WbTestRunner *_test_runner_ptr,
                                         struct CWbClient *_client_ptr);

#ifdef __cplusplus
} // extern "C"
#endif // __cplusplus

#endif // WB_LIB_H_
