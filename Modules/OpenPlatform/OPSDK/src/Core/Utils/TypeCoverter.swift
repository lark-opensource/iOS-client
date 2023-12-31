//
//  TypeCoverter.swift
//  OPSDK
//
//  Created by lixiaorui on 2020/11/16.
//

import Foundation
import LarkOPInterface

public extension String {

    func convertToJsonObject() throws -> [String: Any] {
        guard let data = self.data(using: .utf8) else {
            throw OPError.error(monitorCode: OPSDKMonitorCode.can_not_init_data_from_str, message: "can not init data from str")
        }
        do {
            let json = try JSONSerialization.jsonObject(with: data)
            guard let jsonDic = json as? [String: Any] else {
                throw OPError.error(monitorCode: OPSDKMonitorCode.json_object_type_invalid, message: "jsonObject type invalid")
            }
            return jsonDic
        } catch {
            throw error.newOPError(monitorCode: OPSDKMonitorCode.json_decode_failed)
        }
    }
}

public extension Dictionary {
    func convertToJsonStr() throws -> String {
        guard JSONSerialization.isValidJSONObject(self) else {
            throw OPError.error(monitorCode: OPSDKMonitorCode.dictionary_is_not_a_valid_json_object, message: "dictionary is not a valid jsonObject")
        }
        var data: Data
        do {
            data = try JSONSerialization.data(withJSONObject: self)
        } catch {
            throw error.newOPError(monitorCode: OPSDKMonitorCode.json_encode_failed)
        }
        guard let json = String(data: data, encoding: .utf8) else {
            throw OPError.error(monitorCode: OPSDKMonitorCode.can_not_init_str_form_data, message: "can not init str form data")
        }
        return json
    }
}
