//Warning: Do Not Edit It!
//Created by EEScaffold, if you want to edit it please check the manual of EEScaffold
//Toolchains For EE
/*
*
*
*  ______ ______ _____        __
* |  ____|  ____|_   _|      / _|
* | |__  | |__    | |  _ __ | |_ _ __ __ _
* |  __| |  __|   | | | '_ \|  _| '__/ _` |
* | |____| |____ _| |_| | | | | | | | (_| |
* |______|______|_____|_| |_|_| |_|  \__,_|
*
*
*/
import Foundation
import UIKit
import UniverseDesignIcon
import LarkLocalizations

final class Resources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkAudioBundle, compatibleWith: nil) ?? UIImage()
    }

    static let recognitionIcon = UDIcon.voice2textOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let recordIcon = UDIcon.getIconByKey(.voiceOutlined, size: CGSize(width: 28, height: 28)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let recordCancelIcon = UDIcon.getIconByKey(.deleteTrashOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)

    static let voice_bottombar = UDIcon.voiceOutlined.ud.withTintColor(UIColor.ud.iconN3)
    static let voice_bottombar_selected = UDIcon.voiceOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)

    static let voice_text_icon = UDIcon.voice2textOutlined.ud.withTintColor(UIColor.ud.iconN3)
    static let voice_text_icon_select = UDIcon.voice2textOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)

    static let new_float_record_normal = UDIcon.voiceOutlined.ud.withTintColor(UIColor.ud.B500)
    static let new_float_record_cancel = UDIcon.voiceOutlined.ud.withTintColor(UIColor.ud.R500)

    static let conversation_arrow = UDIcon.getIconByKey(.expandRightFilled, size: CGSize(width: 10, height: 10)).ud.withTintColor(UIColor.ud.iconN1)

    static let loading1 = Resources.image(named: "loading1")
    static let loading2 = Resources.image(named: "loading2")
    static let loading3 = Resources.image(named: "loading3")

    static let selected = UDIcon.getIconByKey(.doneOutlined, size: CGSize(width: 18, height: 18)).ud.withTintColor(UIColor.ud.colorfulBlue)

    static let recordTime = Resources.image(named: "recordTime")
    static let warningIcon = Resources.image(named: "voice_warning_filled")

    private static var isCNIcon: Bool {
        let lang = LanguageManager.currentLanguage
        switch lang {
        case .zh_CN, .zh_TW, .zh_HK:
            return true
        default:
            return false
        }
    }
    static var new_record_andText_icon: UIImage {
        if isCNIcon {
            return UDIcon.voice2textCnOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
        } else {
            return UDIcon.voice2textEnOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
        }
    }
    static var record_with_Text_icon: UIImage {
        if isCNIcon {
            return UDIcon.voice2textCnOutlined.ud.withTintColor(UIColor.ud.staticWhite)
        } else {
            return UDIcon.voice2textEnOutlined.ud.withTintColor(UIColor.ud.staticWhite)
        }
    }
    static var new_voice_with_text_icon: UIImage {
        if isCNIcon {
            return UDIcon.voice2textCnOutlined.ud.withTintColor(UIColor.ud.iconN3)
        } else {
            return UDIcon.voice2textEnOutlined.ud.withTintColor(UIColor.ud.iconN3)
        }
    }
    static var new_voice_with_text_icon_select: UIImage {
        if isCNIcon {
            return UDIcon.voice2textCnOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)
        } else {
            return UDIcon.voice2textEnOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)
        }
    }
    static var new_audio_send_only_text: UIImage {
        if isCNIcon {
            return UDIcon.voice2textCnOutlined.ud.withTintColor(UIColor.ud.iconN1)
        } else {
            return UDIcon.voice2textEnOutlined.ud.withTintColor(UIColor.ud.iconN1)
        }
    }
    static var new_voice_send_only_text: UIImage {
        if isCNIcon {
            return UDIcon.textCnOutlined.ud.withTintColor(UIColor.ud.iconN1)
        } else {
            return UDIcon.text2Outlined.ud.withTintColor(UIColor.ud.iconN1)
        }
    }
}
