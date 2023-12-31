//
//  Mapper.swift
//  SpaceKit
//
//  Created by maxiao on 2020/4/8.
//

extension Array {

    public func toJSONString() -> String? {
        if !JSONSerialization.isValidJSONObject(self) {
            spaceAssertionFailure("Array is invalid JSONObject!")
            return nil
        }
        if let newData: Data = try? JSONSerialization.data(withJSONObject: self, options: []) {
            let JSONString = NSString(data: newData as Data, encoding: String.Encoding.utf8.rawValue)
            return JSONString as String?
        }
        spaceAssertionFailure("To JSONString failed!")
        return nil
    }

}

extension Dictionary {

    public func toJSONString() -> String? {
        if !JSONSerialization.isValidJSONObject(self) {
            spaceAssertionFailure("Dictionary is invalid JSONObject!")
            return nil
        }
        if let newData: Data = try? JSONSerialization.data(withJSONObject: self, options: []) {
            let JSONString = NSString(data: newData as Data, encoding: String.Encoding.utf8.rawValue)
            return JSONString as String?
        }
        spaceAssertionFailure("To JSONString failed!")
        return nil
    }
}

extension String {

    public func toDictionary() -> [String: Any]? {
        guard let JSONData: Data = self.data(using: .utf8) else {
            spaceAssertionFailure("To JSONData failed!")
            return nil
        }
        if let dict = try? JSONSerialization.jsonObject(with: JSONData, options: .mutableContainers) {
            return dict as? [String: Any]
        }
        spaceAssertionFailure("To Dictionary failed!")
        return nil
    }
}

extension Dictionary where Key == String, Value == Any {

    public func mapModel<T: Codable>() -> T? {
        let decoder = JSONDecoder()
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: []) else {
            DocsLogger.error("serialization \(T.self) model error")
            return nil
        }
        do {
            let model = try? decoder.decode(T.self, from: data)
            return model
        } catch {
            DocsLogger.error("decode \(T.self) model error:\(error)")
            return nil
        }
    }
}
