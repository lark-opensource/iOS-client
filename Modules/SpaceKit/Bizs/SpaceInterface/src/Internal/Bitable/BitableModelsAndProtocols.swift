import Foundation

//MARK: 收集表分享数据模型
public struct FormsShareModel: Codable, BTDDUIPlayload, BTWidgetModelProtocol {
    
    public var baseToken: String

    public var tableId: String
    
    public var viewId: String
    
    public var formName: String
    
    public var panelTitle: String
    
    public var panelComponents: [String]
    
    public var bannerURL: String
    
    public var shareToken: String?
    
    public var noticeMe: Bool?
    
    public var location: FormsShareLocation
    
    public func logInfo() -> String {
        "tableId: \(tableId), viewId: \(viewId), panelTitle: \(panelTitle), panelComponents: \(panelComponents), bannerURL: \(bannerURL), noticeMe: \(noticeMe)"
    }
    
    public var onClick: String?
    
    public var backgroundColor: String?
    
    public var borderColor: String?
}

public struct FormsShareLocation: Codable {

    public var x: CGFloat
    
    public var y: CGFloat
    
    public var width: CGFloat
    
    public var height: CGFloat
    
}

// DDUI 部分，code from xiongmin.super
public protocol BTWidgetModelProtocol {
    
    var onClick: String? { get set }
    
    var backgroundColor: String? { get set }
    
    var borderColor: String? { get set }
    
}

public protocol BTDDUIPlayload { }

public extension BTDDUIPlayload {
    
    var classObject: Self.Type {
        return Self.self
    }
    
}
