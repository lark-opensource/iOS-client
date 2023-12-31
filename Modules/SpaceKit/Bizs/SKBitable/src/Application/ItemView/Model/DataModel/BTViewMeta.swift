import Foundation

/// 视图Meta数据
struct BTViewMeta: Codable {
    var name: String? // 视图名称，一期不传，传的时候要求改成required
    var description: String? // 视图描述，一期不传，这个业务上是optional
    var property: String // 不同视图的property可能不同，返回到客户端为required String类型，消费字段的时候按照不同的视图类型来解
}

/// 表单视图Meta数据property结构
struct BTFormViewMetaProperty: Codable {
    var formBannerInfo: BTFormBannerInfo? // 传了则表示使用自定义封面，否则使用默认封面
}

/// 表单视图自定义封面信息
struct BTFormBannerInfo: Codable {
    var url: String
}

enum BTViewMetaError: String, Error {
    case modelNil
    case jsResIsNil
    case isValidJSONObject
}
