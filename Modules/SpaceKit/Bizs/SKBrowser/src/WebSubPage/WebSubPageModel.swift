import Foundation
import SKUIKit

public class WebSubPageHelper {
    
    static var subPageModel: SubPageModel?
    
    static func set(model: SubPageModel) {
        subPageModel = model
    }
    
    static func get() -> SubPageModel? {
        if let model = subPageModel {
            subPageModel = nil
            return model
        } else {
            return nil
        }
    }
}

public struct SubPageModel: Codable {
    
    public var pageStyle: SubPageStyleModel
    
    public var showNavigationBar: Bool {
        if SKDisplay.pad {
            return true
        }
        if pageStyle.navigationbarInfo == nil {
            return false
        } else {
            return true
        }
    }
    
    public var canDrag: Bool {
        if SKDisplay.pad {
            return false
        }
        if pageStyle.dragParams == nil {
            return false
        } else {
            return true
        }
    }
    
}

public enum PageType: String {
    case page
    case fullScreen
}

public struct SubPageStyleModel: Codable {
    
    public var pageType: String?
    
    public var pageHeight: Double?
    
    public var dragParams: SubPageStyleDragParamsModel?
    
    public var navigationbarInfo: SubPageNavigationbarInfoModel?
    
//    public var backgroundColor: String?
    
    public var bounces: Bool?
    
    func getPageType() -> PageType? {
        guard let pageType = pageType else {
            return nil
        }
        return PageType(rawValue: pageType)
    }
}

public struct SubPageStyleDragParamsModel: Codable {
    
    public var minHeight: Double?
    
    public var maxHeight: Double?
    
}

public struct SubPageNavigationbarInfoModel: Codable {
    
    public var initTitle: String?
    
//    public var backgroundColor: String?
}
