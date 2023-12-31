//
//  SheetFieldModel.swift
//  SKSheet
//
//  Created by JiayiGuo on 2021/5/7.
//


import SKFoundation
import HandyJSON
import CoreGraphics

public enum SheetSegmentType: String, HandyJSONEnum {
    case text = "text"
    case mention = "mention"
    case url = "url"
    case embedImage = "embed-image"
    case pano = "pano"
    case attachment = "attachment"
}

public final class SheetStyleJSON: NSObject, HandyJSON {
    
    public required override init() {
        super.init()
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        
        if let other = object as? SheetStyleJSON {
            return color == other.color &&
                fontWeight == other.fontWeight &&
                fontStyle == other.fontStyle &&
                fontFamily == other.fontFamily &&
                fontSize == other.fontSize &&
                textDecoration == other.textDecoration
        }
        return false
    }
    
    public var color: String = ""
    public var fontWeight: Double = 400
    public var fontStyle: String = "normal"
    public var fontFamily: String = ""
    public var fontSize: Double = 13
    public var textDecoration: String = ""
    
    // 自定义字段
    
    public var showColor: UIColor? {
        if color.isEmpty {
            return UIColor.ud.textTitle
        } else {
            if #available(iOS 13.0, *) {
                if let convertColor = UIColor.docs.convertToShowColor(colorString: color) {
                    return convertColor
                }
            }
            return UIColor.docs.rgb(color)
        }
    }
}


public struct SheetCustomCellStyle {
    //web传过来的cellStyle
    public var webCellStyle: SheetStyleJSON?
    
    //是否添加额外样式，为true时下方的样式才生效，默认只有webCellStyle生效
    public var needExtraStyle: Bool = false
    //段距
    public var paragraphSpacing: CGFloat = 0
    //链接加下划线
    public var underlineInLink: Bool = false
    //附件的换行方式
    public var attachmentLineBreakMode: NSLineBreakMode = .byWordWrapping
    
    public init() {}
    
    public init(_ webStyle: SheetStyleJSON?, needExtraStyle: Bool = false) {
        self.webCellStyle = webStyle
        self.needExtraStyle = needExtraStyle
    }
}

public class SheetSegmentBase: NSObject, HandyJSON {
    public required override init() {
        super.init()
    }
    public override func isEqual(_ object: Any?) -> Bool {
        
        if let other = object as? SheetSegmentBase {
            return self.type == other.type &&
                self.style == other.style
        }
        return false
    }
    
    public var type: SheetSegmentType = .text
    public var style: SheetStyleJSON?
    
    public func mapping(mapper: HelpingMapper) {}
}

public final class SheetTextSegment: SheetSegmentBase {
    public required init() {
        super.init()
        type = .text
    }
    public override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? SheetTextSegment {
            return self.type == other.type &&
                self.text == other.text
        }
        return false
    }
    
    public var text: String = ""
}

public class SheetTextLikeSegment: SheetSegmentBase {
    public override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? SheetTextLikeSegment {
            return self.texts == other.texts
        }
        return false
    }
    public var texts: [SheetTextSegment]?
}

public enum SuiteIconType: Int, HandyJSONEnum {
    case unset = 0
    case emoji = 1
    case image = 2
    case userUploadImage = 3
}

public final class SuiteIcon: NSObject, HandyJSON {
    public required override init() {
        super.init()
    }
    public override func isEqual(_ object: Any?) -> Bool {
        if let rhs = object as? SuiteIcon {
            let lhs = self
            return lhs.key == rhs.key &&
                lhs.type == rhs.type &&
                lhs.fsUnit == rhs.fsUnit
        }
        return false
    }
    public var key: String = ""
    public var type: SuiteIconType = .unset
    public var fsUnit: String? //map
    
    public func mapping(mapper: HelpingMapper) {
        mapper <<< self.fsUnit <-- "fs_unit"
    }
}

public final class SheetMentionSegment: SheetSegmentBase {
    public required init() {
        super.init()
        type = .mention
    }
    public override func isEqual(_ object: Any?) -> Bool {
        if let rhs = object as? SheetMentionSegment {
            let lhs = self
            return lhs.type == rhs.type &&
                lhs.text == rhs.text &&
                lhs.link == rhs.link &&
                lhs.token == rhs.token &&
                lhs.mentionType == rhs.mentionType &&
                lhs.notNotify == rhs.notNotify &&
                lhs.blockNotify == rhs.blockNotify &&
                lhs.icon == rhs.icon &&
                lhs.mentionId == rhs.mentionId &&
                lhs.mentionNotify == rhs.mentionNotify &&
                lhs.category == rhs.category &&
                lhs.name == rhs.name &&
                lhs.enName == rhs.enName
        }
        return false
    }
    public var text: String = ""
    public var link: String = ""
    var token: String = ""
    var mentionType: Int = 0
    var notNotify: Bool?
    var blockNotify: Bool?
    var icon: SuiteIcon?
    var mentionId: String?
    var mentionNotify: Bool?
    var category: String?   //at user block / undefined
    var name: String?
    var enName: String?
    var iconInfo: String?
    
    override public func mapping(mapper: HelpingMapper) {
        mapper <<< self.notNotify <-- "not_notify"
        mapper <<< self.blockNotify <-- "block_notify"
        mapper <<< self.enName <-- "en_name"
    }
}

public final class SheetCellPosition: NSObject, HandyJSON {
    public required override init() {
        super.init()
    }
    public override func isEqual(_ object: Any?) -> Bool {
        if let rhs = object as? SheetCellPosition {
            let lhs = self
            return lhs.sheetId == rhs.sheetId &&
                lhs.rangeId == rhs.rangeId
        }
        return false
    }
    var sheetId: String = ""
    var rangeId: String = ""
}

public final class SheetHyperLinkSegment: SheetTextLikeSegment {
    public required init() {
        super.init()
        type = .url
    }
    public static func == (lhs: SheetHyperLinkSegment, rhs: SheetHyperLinkSegment) -> Bool {
        return lhs.type == rhs.type &&
            lhs.text == rhs.text &&
            lhs.visited == rhs.visited &&
            lhs.link == rhs.link &&
            lhs.cellPosition == rhs.cellPosition
    }

    public var text: String = ""
    var visited: Bool?
    public var link: String?
    var cellPosition: SheetCellPosition?
}

public final class SheetEmbedImageSegment: SheetSegmentBase {
    public required init() {
        super.init()
        type = .embedImage
    }
    public override func isEqual(_ object: Any?) -> Bool {
        if let rhs = object as? SheetEmbedImageSegment {
            let lhs = self
            return lhs.type == rhs.type &&
                lhs.height == rhs.height &&
                lhs.width == rhs.width &&
                lhs.text == rhs.text &&
                lhs.link == rhs.link &&
                lhs.fileToken == rhs.fileToken
        }
        return false
    }

    var height: Double = 0
    var width: Double = 0
    var text: String = ""
    var link: String = ""
    var fileToken: String?
}

public final class SheetPanoSegment: SheetSegmentBase {
    public required init() {
        super.init()
        type = .pano
    }
    public override func isEqual(_ object: Any?) -> Bool {
        if let rhs = object as? SheetPanoSegment {
            let lhs = self
            return lhs.text == rhs.text &&
                lhs.link == rhs.link &&
                lhs.entityId == rhs.entityId
        }
        return false
    }
    
    public var text: String = ""
    public var link: String = ""
    var entityId: String = ""
}

public final class SheetAttachmentSegment: SheetSegmentBase {
    public required init() {
        super.init()
        type = .attachment
    }
    public override func isEqual(_ object: Any?) -> Bool {
        if let rhs = object as? SheetAttachmentSegment {
            let lhs = self
            return lhs.type == rhs.type &&
                lhs.text == rhs.text &&
                lhs.fileToken == rhs.fileToken &&
                lhs.mimeType == rhs.mimeType &&
                lhs.size == rhs.size
        }
        return false
    }

    public var text: String = ""
    var fileToken: String = ""
    var mimeType: String = ""
    var size: Double = 0
}
