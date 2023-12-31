//
//  Types.swift
//
//
//  Created by kef on 2022/2/14.
//

import Foundation

public struct WbLibConfig {
    public let userId: String
    public let deviceId: String
    public let userType: Int
    
    public init(_ userId: String, _ deviceId: String, _ userType: Int) {
        self.userId = userId
        self.deviceId = deviceId
        self.userType = userType
    }
    
    public func toCValue(body: (UnsafePointer<CWbClientConfig>) throws -> Void) rethrows  {
        var cValue = CWbClientConfig(
            user_id: userId.unsafeMutablePointerRetained(),
            device_id: deviceId.unsafeMutablePointerRetained(),
            user_type: UInt8(userType)
        )
        try body(withUnsafePointer(to: &cValue) { $0 })
        cValue.user_id?.freeUnsafeMemory()
        cValue.device_id?.freeUnsafeMemory()
    }
}

/// 白板产生的同步数据的类型, 和 GrootCell 中的 DataType 含义一致
public enum WbSyncDataType {
    /// 需要应用到白板 Snapshot 中的数据，比如图形的增减
    case DrawData
    /// 不需要应用到白板 Snapshot 中的数据，比如创建图形时的数据更新
    case SyncData
        
    public init(cValue: C_WB_SYNC_DATA_TYPE) {
        switch cValue {
        case C_WB_SYNC_DATA_TYPE_DRAW_DATA:
            self = .DrawData
        case C_WB_SYNC_DATA_TYPE_SYNC_DATA:
            self = .SyncData
        default:
            self = .DrawData
        }
    }
    
    public func toCValue() -> C_WB_SYNC_DATA_TYPE {
        switch self {
        case .DrawData:
            return C_WB_SYNC_DATA_TYPE_DRAW_DATA
        case .SyncData:
            return C_WB_SYNC_DATA_TYPE_SYNC_DATA
        }
    }
}

/// `InlineGlyphSpecs` 用来表示一行文字的布局参数
public struct InlineGlyphSpecs {
    /// 文字块包围盒高度
    ///
    /// - `iOS`: `layer.preferredFrameSize().height` (`layer` 为绘制文字的 `CATextLayer`)
    public let height: Float
    /// 文字块中各字符 (UTF8 字符) 的宽度
    public let widths: Array<Float>
    /// 文字块左上角对齐绘制原点的 x 轴偏移量
    ///
    /// 暂取值默认 0.0 (目前各平台文字左基点都是 advance point 决定, 无偏移)
    public let originOffsetX: Float = 0.0
    /// 文字块左上角对齐绘制原点的 y 轴偏移量
    ///
    /// - `iOS`: 左上角对齐, `0`
    public let originOffsetY: Float = 0.0
    
    public init(_ height: Float, _ width: Array<Float>) {
        self.height = height
        self.widths = width
    }
}

public struct Point: Codable {
    public let x: Float
    public let y: Float
    
    public init(_ x: Float, _ y:Float) {
        self.x = x
        self.y = y
    }
    
    init(cValue: CPoint) {
        self.x = cValue.x
        self.y = cValue.y
    }
    
    public func toCValue(body: (UnsafePointer<CPoint>) throws -> Void) rethrows {
        var cValue = CPoint(x: self.x, y: self.y)
        try body(withUnsafePointer(to: &cValue) { $0 })
    }
}

public struct Vector {
    public let x: Float
    public let y: Float
    
    public init(_ x: Float, _ y:Float) {
        self.x = x
        self.y = y
    }
    
    init(cValue: CVector) {
        self.x = cValue.x
        self.y = cValue.y
    }
    
    public func toCValue(body: (UnsafePointer<CVector>) throws -> Void) rethrows {
        var cValue = CVector(x: self.x, y: self.y)
        try body(withUnsafePointer(to: &cValue) { $0 })
    }
}

public struct Size {
    public let width: Float
    public let height: Float
    
    public init(width: Float, height: Float) {
        self.width = width
        self.height = height
    }
    
    init(cValue: CSize) {
        self.width = cValue.width
        self.height = cValue.height
    }
}


extension Array where Element == UInt8 {
    public func toCValue(body: (UnsafePointer<UInt8>, Int) -> Void) {
        let dataPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: self.count)
        self.enumerated().forEach {
            dataPtr.advanced(by: $0.offset).pointee = $0.element
        }
        
        body(dataPtr, self.count)
        
        dataPtr.deallocate()
    }
    
    public func toCArray(body: (UnsafePointer<CArray_u8>) -> Void) {
        var cValue = CArray_u8(
            data_ptr: UnsafeMutablePointer<UInt8>.allocate(capacity: self.count),
            size: UInt(self.count)
        )
        
        body(withUnsafePointer(to: &cValue) { $0 })
        
        cValue.data_ptr.deallocate()
    }
}

extension UnsafeMutablePointer where Pointee == CArray_f32 {
    public static func fromSwift(_ input: Array<Float>) -> Self {
        let count = input.count
        
        let dataPtr = UnsafeMutablePointer<Float>.allocate(capacity: count)
        input.enumerated().forEach {
            dataPtr.advanced(by: $0.offset).pointee = $0.element
        }
        
        let ptr = UnsafeMutablePointer<CArray_f32>.allocate(capacity: 1)
        ptr.pointee.data_ptr = UnsafePointer<Float>(dataPtr)
        ptr.pointee.size = UInt(count)
        
        return ptr
    }
    
    public func freeUnsafeMemory() {
        self.pointee.data_ptr.deallocate()
        self.deallocate()
    }
}

public struct PageScreenshot {
    public let graphics: [WbGraphic]
    public let theme: WbTheme

    public init(_ graphics: [WbGraphic], _ theme: WbTheme) {
        self.graphics = graphics
        self.theme = theme
    }
}

public struct PageInfo {
    public let theme: WbTheme
    public let lineCount: UInt32
    public let arrowCount: UInt32
    public let ellipseCount: UInt32
    public let rectangleCount: UInt32
    public let triangleCount: UInt32
    public let pencilCount: UInt32
    public let pencilPointCount: UInt32
    public let highlighterCount: UInt32
    public let highlighterPointCount: UInt32
    public let textCount: UInt32
    
    public init(_ cValue: CPageInfo) {
        self.theme = WbTheme(cValue.theme)
        self.lineCount = cValue.line_count
        self.arrowCount = cValue.arrow_count
        self.ellipseCount = cValue.ellipse_count
        self.rectangleCount = cValue.rectangle_count
        self.triangleCount = cValue.triangle_count
        self.pencilCount = cValue.pencil_count
        self.pencilPointCount = cValue.pencil_point_count
        self.highlighterCount = cValue.highlighter_count
        self.highlighterPointCount = cValue.highlighter_point_count
        self.textCount = cValue.text_count
    }
}

public enum WbTool {
    /// 移动画布状态
    case Move
    /// 可选中图形状态
    case Select
    /// 激光笔
    case Comet
    /// 橡皮
    case Eraser
    /// 自由画笔
    case Pencil
    /// 荧光笔
    case Highlighter
    /// 绘制直线
    case Line
    /// 绘制箭头
    case Arrow
    /// 绘制三角形
    case Triangle
    /// 绘制矩形
    case Rect
    /// 绘制椭圆
    case Ellipse
    
    func toCValue() -> C_WB_TOOL {
        switch self {
        case .Move:
            return C_WB_TOOL_MOVE
        case .Select:
            return C_WB_TOOL_SELECT
        case .Comet:
            return C_WB_TOOL_COMET
        case .Eraser:
            return C_WB_TOOL_ERASER
        case .Pencil:
            return C_WB_TOOL_PENCIL
        case .Highlighter:
            return C_WB_TOOL_HIGHLIGHTER
        case .Line:
            return C_WB_TOOL_LINE
        case .Arrow:
            return C_WB_TOOL_ARROW
        case .Triangle:
            return C_WB_TOOL_TRIANGLE
        case .Rect:
            return C_WB_TOOL_RECT
        case .Ellipse:
            return C_WB_TOOL_ELLIPSE
        }
    }
}

public enum WbTheme {
    case Light
    case Dark
    
    init(_ cValue: C_WB_THEME) {
        switch cValue {
        case C_WB_THEME_LIGHT:
            self = .Light
        case C_WB_THEME_DARK:
            self = .Dark
        default:
            self = .Light
        }
    }
    
    func toCValue() -> C_WB_THEME {
        switch self {
        case .Light:
            return C_WB_THEME_LIGHT
        case .Dark:
            return C_WB_THEME_DARK
        }
    }
}

/// 颜色编号
///
/// 具体色值参考:
/// https://www.figma.com/file/xjQCr0EQ38KtwRBA1ZS4gY/%E9%A3%9E%E4%B9%A6%E4%BC%9A%E8%AE%AE%E5%AE%A4%E7%99%BD%E6%9D%BF?node-id=57%3A29550
///
public enum WbColorToken {
    case Primary
    case R500
    case Y500
    case G500
    case B500
    case P500
    case Transparent
    
    public func toCValue() -> C_WB_COLOR_TOKEN {
        switch self {
        case .Primary:
            return C_WB_COLOR_TOKEN_PRIMARY
        case .R500:
            return C_WB_COLOR_TOKEN_R500
        case .Y500:
            return C_WB_COLOR_TOKEN_Y500
        case .G500:
            return C_WB_COLOR_TOKEN_G500
        case .B500:
            return C_WB_COLOR_TOKEN_B500
        case .P500:
            return C_WB_COLOR_TOKEN_P500
        case .Transparent:
            return C_WB_COLOR_TOKEN_TRANSPARENT
        }
    }
}

public enum TextRecognitionResultStatus: Int {
    case Unknown = 0
    case Success = 1
    case ServerError = 2
    case ClientError = 3
    
    func toCValue() -> C_WB_TEXT_RECOGNITION_RESULT_STATUS {
        switch self {
        case .Unknown:
            return C_WB_TEXT_RECOGNITION_RESULT_STATUS_UNKNOWN
        case .Success:
            return C_WB_TEXT_RECOGNITION_RESULT_STATUS_SUCCESS
        case .ServerError:
            return C_WB_TEXT_RECOGNITION_RESULT_STATUS_SERVER_ERROR
        case .ClientError:
            return C_WB_TEXT_RECOGNITION_RESULT_STATUS_CLIENT_ERROR
        }
    }
}
