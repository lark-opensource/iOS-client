//
//  Graphic.swift
//  
//
//  Created by kef on 2022/2/14.
//

import Foundation

/// `Action`表示矢量路径上的一个关键操作
///
/// 每一个操作会消费不同数量的关键点, 具体规则如下
///
/// - MoveTo, 1, 目标点 (x,y)
/// - LineTo, 1, 目标点 (x,y)
/// - QuadTo, 2, 控制点 (x,y) 目标点 (x,y)
/// - CubicTo, 3, 控制点1 (x,y) 控制点2 (x,y) 目标点 (x,y)
/// - Close, 0
/// - End, 0
public enum PathAction {
    case MoveTo
    case LineTo
    case QuadTo
    case CubicTo
    case Close
    case End
    
    init(cValue: C_WB_PATH_ACTION) {
        switch cValue {
        case C_WB_PATH_ACTION_MOVE_TO: self = .MoveTo
        case C_WB_PATH_ACTION_LINE_TO: self = .LineTo
        case C_WB_PATH_ACTION_QUAD_TO: self = .QuadTo
        case C_WB_PATH_ACTION_CUBIC_TO: self = .CubicTo
        case C_WB_PATH_ACTION_CLOSE: self = .Close
        case C_WB_PATH_ACTION_END: self = .End
        default: self = .End
        }
    }
}

/// `Path`表示一个矢量路径
///
/// `points`: 路径上的关键点
/// `actions`: 路径上的关键操作
///
/// 在构建路径的过程中, 关键操作`Action`根据不同的类型消费不同数量的关键点`Point`
public struct Path {
    public let points: [Point]
    public let actions: [PathAction]
    
    init(cValue: CPath) {
        self.points = cValue.points.pointee.toSwiftArray()
        self.actions = cValue.actions.pointee.toSwiftArray()
    }
}

public typealias WbPrimitivePath = Path

/// `Text` 表示一个需要被渲染的文字
///
/// `text` UTF8 编码的文字内容
/// `font_size` 文字大小
/// `font_family` 文字适用的字体族
public struct Text {
    public let text: String
    public let fontSize: Int
    public let fontWeight: Int
    
    init(cValue: CText) {
        self.text = String.fromCValue(cValue.text)!
        self.fontSize = Int(cValue.font_size)
        self.fontWeight = Int(cValue.font_weight)
    }
}

public typealias WbPrimitiveText = Text

/// `Image` 表示一个需要被渲染的图片
///
/// `resource_id` 图片在资源池中的id
/// `size` 图片的尺寸
public struct Image {
    public let resourceId: Int64
    public let size: Size
    
    init(cValue: CImage) {
        self.resourceId = Int64(cValue.resource_id)
        self.size = Size(cValue: cValue.size.pointee)
    }
}

public typealias WbPrimitiveImage = Image

/// `Stroke`表示绘制时笔触配置
///
/// `dasharray`: 线段虚实, 参考SVG的stroke-dasharray属性
public struct Stroke {
    public let color: Int
    public let width: Int
    public let dasharray: [Float]?
    
    init(cValue: CStroke) {
        self.color = Int(cValue.color)
        self.width = Int(cValue.width)
        self.dasharray = nil
    }
}

/// `Fill`表示绘制时填充配置
public struct Fill {
    public let color: Int
    
    init(cValue: CFill) {
        self.color = Int(cValue.color)
    }
}

/// `Transform`表示一个针对矢量路径上所有关键点的变换
///
/// 定义规则参考: https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/setTransform
public struct Transform {
    public let a : Float
    public let b : Float
    public let c : Float
    public let d : Float
    public let e : Float
    public let f : Float
    
    init(cValue: CTransform) {
        self.a = cValue.a
        self.b = cValue.b
        self.c = cValue.c
        self.d = cValue.d
        self.e = cValue.e
        self.f = cValue.f
    }
}

public enum WbPrimitive {
    case Path(WbPrimitivePath)
    case Text(WbPrimitiveText)
    case Image(WbPrimitiveImage)
    
    /// 发生错误 或 该事件SDK内已支持但未在Swift侧封装
    case Unknown
    
    public init(cValue: CEnum_C_WB_PRIMITIVE) {
        let name = cValue.ty
        let dataPtr = cValue.data
        
        switch name {
        case C_WB_PRIMITIVE_PATH:
            let v = WbPrimitivePath(cValue: dataPtr!.load(as: CPath.self))
            self = .Path(v)
        case C_WB_PRIMITIVE_TEXT:
            let v = WbPrimitiveText(cValue: dataPtr!.load(as: CText.self))
            self = .Text(v)
        case C_WB_PRIMITIVE_IMAGE:
            let v = WbPrimitiveImage(cValue: dataPtr!.load(as: CImage.self))
            self = .Image(v)
        default:
            self = .Unknown
        }
    }
    
}

/// `WbGraphic` 表示白板上的一个图形单元
///
/// 构建路径后, 用所包含的填充样式和笔触样式绘制
public struct WbGraphic {
    public var primitive: WbPrimitive
    public var stroke: Stroke?
    public var fill: Fill?
    public var transform: Transform?
    
    init(cValue: CWbGraphic) {
        self.primitive = WbPrimitive.init(cValue: cValue.primitive.pointee)
        
        if let cStroke = cValue.stroke?.pointee {
            self.stroke = Stroke(cValue: cStroke)
        } else {
            self.stroke = nil
        }
        if let cFill = cValue.fill?.pointee {
            self.fill = Fill(cValue: cFill)
        } else {
            self.fill = nil
        }
        if let cTransform = cValue.transform?.pointee {
            self.transform = Transform(cValue: cTransform)
        } else {
            self.transform = nil
        }
    }
}
