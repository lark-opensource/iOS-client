//
//  Resources.swift
//  LarkSearchFilter
//
//  Created by zc09v on 2019/9/4.
//

import Foundation
import UIKit
import UniverseDesignIcon

final class Resources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkSearchFilterBundle, compatibleWith: nil) ?? UIImage()
    }

    static var doc_filter_all: UIImage { return Resources.image(named: "doc_filter_all") }
    static var doc_filter_doc: UIImage { return Resources.image(named: "doc_filter_doc") }
    static var doc_filter_sheet: UIImage { return Resources.image(named: "doc_filter_sheet") }
    static var doc_filter_slide: UIImage { return Resources.image(named: "doc_filter_slide") }
    static var doc_filter_mindnote: UIImage { return Resources.image(named: "doc_filter_mindnote") }
    static var doc_filter_bitable: UIImage { return Resources.image(named: "doc_filter_bitable") }
    static var doc_filter_file: UIImage { return Resources.image(named: "doc_filter_file") }
    static var doc_filter_slides: UIImage { return UDIcon.getIconByKey(.fileLinkSlidesOutlined, size: CGSize(width: 24, height: 24)) }
    static var search_filter_selected: UIImage { return Resources.image(named: "search_filter_selected") }
    static var search_filter_unselected: UIImage { return Resources.image(named: "search_filter_unselected") }
    static var search_date_picker_forward: UIImage { return UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3) }
    static var search_date_picker_back: UIImage { return UDIcon.getIconByKey(.leftOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3) }
    static var doc_folder_circle: UIImage { return UDIcon.getIconByKey(.fileRoundFolderColorful, size: CGSize(width: 16, height: 16)) }
    static var doc_sharefolder_circle: UIImage { return UDIcon.getIconByKey(.fileRoundSharefolderColorful, size: CGSize(width: 16, height: 16)) }
    static var wikibook_circle: UIImage { return UDIcon.getIconByKey(.wikibookCircleColorful, size: CGSize(width: 16, height: 16)) }
}
