//
// Created by duanxiaochen.7 on 2020/3/14.
// Affiliated with DocsSDK.
//
// Description:

import SKFoundation
import HandyJSON
import SwiftyJSON
import SKCommon
import SKBrowser
import SKResource
import UniverseDesignIcon
import UniverseDesignColor
import SKInfra

enum BTPanelItemStyle: String, HandyJSONEnum {
    case red
    case disabled
}

public protocol ContentCustomViewProtocol: UIView {
    init?(model: Any)
}

/// 新增 case，需要指定 modelType 和 viewType
public enum ContentCustomViewType: String, HandyJSONEnum {
    case EMPTY_VIEW = "empty_view"

    private func viewType() -> ContentCustomViewProtocol.Type {
        switch self {
        case .EMPTY_VIEW:
            return BTPanelEmptyContentView.self
        }
    }

    private func modelType() -> HandyJSON.Type {
        switch self {
        case .EMPTY_VIEW:
            return BTPanelEmptyContentModel.self
        }
    }

    func view(json: String) -> UIView {
        guard let model = modelType().deserialize(from: json) else {
            DocsLogger.btError("[BTPanel] modelType deserialize fail")
            return UIView()
        }
        guard let view = viewType().init(model: model) else {
            DocsLogger.btError("[BTPanel] viewType init fail")
            return UIView()
        }
        return view
    }
}

public enum CommonListCustomViewType: String, HandyJSONEnum {
    case DEFAULT_HEADER = "default_header"
    case AVATAR_HEADER = "avatar_header"
}

/// JSBridge `showPanel` 的传参
struct BTPanelItemActionParams: HandyJSON, Equatable {
    var data: [BTCommonItem] = []
    var title: String?
    var headerExtendMode: CommonListCustomViewType?
    var desc: [BTRichTextSegmentModel]?
    var location: BTPanelLocation?
    var bottomFixedData: BTCommonItem?
    var callback: String = ""
    
    var independent: Bool?
    
    var leftAction: BTCommonItem?
    
    var rightAction: BTCommonItem?
    
    var groupInfo: [GroupInfo]?
    
    var heightPercent: CGFloat?
    
    var modalPresentationStyle: String?

    var contentExtendModel: ContentCustomViewType?

    var extra: String?

    var groupedItems: [[BTCommonItem]] {
        let newData = data.map { item in
            var data = item
            if data.groupId == "" {
                data.groupId = data.id
            }
            return data
        }
        guard let aggregatedResult = newData.aggregateByGroupID() as? [[BTCommonItem]] else { return [] }
        return aggregatedResult
    }
    
    // 数据为空，需要关闭面板
    var verifyEmpty: Bool {
        return data.isEmpty && (desc?.isEmpty ?? true) && bottomFixedData == nil
    }
}


struct GroupInfo: HandyJSON, Equatable {
    
    var groupId: String = ""
    
    var groupName: String = ""
    
}

struct CheckboxStruct: HandyJSON, Equatable, SKFastDecodable {
    
    var value: Bool = false

    static func deserialized(with dictionary: [String: Any]) -> CheckboxStruct {
        var model = CheckboxStruct()
        model.value <~ (dictionary, "value")
        return model
    }
    
}

struct BTPanelLocation: HandyJSON, Equatable {
    var x: CGFloat = 0.0
    var y: CGFloat = 0.0
    var width: CGFloat = 0.0
    var height: CGFloat = 0.0
    var sourceViewID: String = ""   // 指定的 Native View ID
}

// MARK: - Jira Menu

/// JSBridge `launchActionSheet` 的传参
struct BTJiraMenuParams: HandyJSON {
    var blockId: String = ""
    var title: String = ""
    var desc: String = ""
    var callback: String = ""
    var actions: [BTJiraMenuAction] = []
}

struct BTJiraMenuAction: HandyJSON {
    var text: String = ""
    var id: String = ""
    var enable: Bool = true
}
