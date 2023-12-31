import Foundation
struct FixRequestMessage: Codable {
    public let apiName: String
    public let data: FixRequestData
    public let callbackID: String
}
struct FixRequestData: Codable {
    var id: String
    var headers: [FixRequestHeaders]?
    var base64Body: String?
}
struct FixRequestHeaders: Codable {
    var key: String
    var value: String
    var method: FixRequestHeadersMethod?
}
enum FixRequestHeadersMethod: String, Codable {
    case replace
    case append
    case delete
}
