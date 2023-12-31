//
//  SKPasteboard.swift
//  SKCommon
//
//  Created by ByteDance on 2022/8/30.
//

import Foundation
import LarkEMM
import LarkSensitivityControl
import SKFoundation
 
public final class SKPasteboard {
    public static func items(with pointId: String?,
                                psdaToken: String,
                           shouldImmunity: Bool? = false) -> [[String: Any]]? {
        let config = PasteboardConfig(token: Token(psdaToken),
                                    pointId: pointId,
                             shouldImmunity: shouldImmunity)
        return SCPasteboard.general(config).items
    }
    
    public static func setItems(_ items: [[String: Any]]?,
                                pointId: String? = nil,
                              psdaToken: String,
                         shouldImmunity: Bool? = false) -> Bool {
        
        let config = PasteboardConfig(token: Token(psdaToken),
                                    pointId: pointId,
                             shouldImmunity: shouldImmunity)
        do {
            let pasteboard = try SCPasteboard.generalUnsafe(config)
            pasteboard.items = items
            return true
        } catch {
            DocsLogger.error("SKPasteboard get Pasteboard error, \(error)")
            return false
        }
    }
    
    public static func string(with pointId: String? = nil,
                                 psdaToken: String,
                            shouldImmunity: Bool? = false) -> String? {
        
        let config = PasteboardConfig(token: Token(psdaToken),
                                    pointId: pointId,
                             shouldImmunity: shouldImmunity)
        return SCPasteboard.general(config).string
    }
    
    public static func setString(_ string: String?,
                                  pointId: String? = nil,
                                psdaToken: String,
                           shouldImmunity: Bool? = false) -> Bool {
        
        let config = PasteboardConfig(token: Token(psdaToken),
                                    pointId: pointId,
                             shouldImmunity: shouldImmunity)
        do {
            let pasteboard = try SCPasteboard.generalUnsafe(config)
            pasteboard.string = string
            return true
        } catch {
            DocsLogger.error("SKPasteboard get Pasteboard error, \(error)")
            return false
        }
    }
    
    public static func strings(with pointId: String? = nil,
                                  psdaToken: String,
                             shouldImmunity: Bool? = false) -> [String]? {
        
        let config = PasteboardConfig(token: Token(psdaToken),
                                    pointId: pointId,
                             shouldImmunity: shouldImmunity)
        return SCPasteboard.general(config).strings
    }
    
    public static func setStrings(_ strings: [String]?,
                                    pointId: String? = nil,
                                  psdaToken: String,
                             shouldImmunity: Bool? = false) -> Bool {
        
        let config = PasteboardConfig(token: Token(psdaToken),
                                    pointId: pointId,
                             shouldImmunity: shouldImmunity)
        do {
            let pasteboard = try SCPasteboard.generalUnsafe(config)
            pasteboard.strings = strings
            return true
        } catch {
            DocsLogger.error("SKPasteboard get Pasteboard error, \(error)")
            return false
        }
    }
    
    public static var hasStrings: Bool {
        return SCPasteboard.general(SCPasteboard.defaultConfig()).hasStrings
    }
}
