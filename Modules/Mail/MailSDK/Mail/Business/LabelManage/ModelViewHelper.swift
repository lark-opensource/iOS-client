//
//  ModelViewHelper.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2021/9/30.
//

import Foundation
import UniverseDesignColor
import UIKit

class ModelViewHelper {
    static func navColor() -> UIColor {
        if Display.pad {
            return UIColor.ud.bgFloat
        } else {
            if #available(iOS 13.0, *) {
                return UIColor.ud.bgFloat
            } else {
                return UIColor.ud.bgBody
            }
        }
    }

    static func bgColor() -> UIColor {
        if Display.pad {
            return UIColor.ud.bgFloatBase
        } else {
            if #available(iOS 13.0, *) {
                return UIColor.ud.bgFloatBase
            } else {
                return UIColor.ud.bgBody
            }
        }
    }

    static func listColor() -> UIColor {
        if Display.pad {
            return UIColor.ud.bgFloat
        } else {
            if #available(iOS 13.0, *) {
                return UIColor.ud.bgFloat
            } else {
                return UIColor.ud.bgBody
            }
        }
    }
}

// @laile 要求的
extension ModelViewHelper {
    static func bgColor(vc: UIViewController) -> UIColor {
        var color = UIColor.ud.bgFloatBase
        if vc.modalPresentationStyle == .fullScreen {
            color = UIColor.ud.bgFloatBase
        } else if vc.modalPresentationStyle == .formSheet {
            if Display.pad {
                color = UIColor.ud.bgFloatBase
            } else {
                if #available(iOS 13.0, *) {
                    color = UIColor.ud.bgFloatBase
                } else { // iphone上13以前没有sheet样式
                    color = UIColor.ud.bgBase
                }
            }
        }
        return color
    }

    static func listColor(vc: UIViewController) -> UIColor {
        var color = UIColor.ud.bgFloat
        if vc.modalPresentationStyle == .fullScreen {
            color = UIColor.ud.bgFloat
        } else if vc.modalPresentationStyle == .formSheet {
            if Display.pad {
                color = UIColor.ud.bgFloat
            } else {
                if #available(iOS 13.0, *) {
                    color = UIColor.ud.bgFloat
                } else { // iphone上13以前没有sheet样式
                    color = UIColor.ud.bgBody
                }
            }
        }
        return color
    }
}
