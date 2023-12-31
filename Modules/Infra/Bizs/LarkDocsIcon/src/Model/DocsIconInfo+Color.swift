//
//  DocsIconInfo+Color.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/6/19.
//

import Foundation
import UniverseDesignColor
extension DocsIconInfo {
    var iconBackgroundColor: UIColor {
        switch objType {
        case .doc:
            let lightColor = UDColor.primaryPri50.alwaysLight
            return lightColor & lightColor.withAlphaComponent(0.2)
        case .docX, .sync:
            let lightColor = UDColor.primaryPri50.alwaysLight
            return lightColor & lightColor.withAlphaComponent(0.2)
        case .sheet:
            let lightColor = UDColor.G50.alwaysLight
            return lightColor & lightColor.withAlphaComponent(0.2)
        case .mindnote:
            let lightColor = UDColor.W50.alwaysLight
            return lightColor & lightColor.withAlphaComponent(0.2)
        case .slides:
            let lightColor = UDColor.O50.alwaysLight
            return lightColor & lightColor.withAlphaComponent(0.2)
        case .bitable:
            let lightColor = UDColor.N100.alwaysLight
            return lightColor & lightColor.withAlphaComponent(0.2)
        case .file:
            let fileColor = fileType?.imageColor.background.alwaysLight ?? UDColor.N100.alwaysLight
            return fileColor & fileColor.withAlphaComponent(0.2)
        case .wiki:
            let lightColor = UDColor.primaryPri50.alwaysLight
            return lightColor & lightColor.withAlphaComponent(0.2)
        default:
            let lightColor = UDColor.N50.alwaysLight
            return lightColor & lightColor.withAlphaComponent(0.2)
        }
    }
}
