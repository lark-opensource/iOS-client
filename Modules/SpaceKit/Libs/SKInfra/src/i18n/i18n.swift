import UIKit
import LarkLocalizations
import SKResource

extension I18n {

    //@available(*, deprecated, message: "请在执行 EEScaffold module asset -n DocsSDK 之后使用 BundleResources.SKResource.xxx")
    public class func image(named: String, withColor color: UIColor) -> UIImage? {
        var im = UIImage(named: named, in: self.resourceBundle, compatibleWith: nil)
        im = im?.withColor(color)
        return im
    }

//    @available(*, deprecated, message: "请在执行 EEScaffold module i18n -n DocsSDK 之后使用 BundleI18n.SKResource.xxx")
//    public class func localizedString(_ key: String) -> String {
//        var tableName = ""
//        let larkLauange = LanguageManager.currentLanguage
//
//        tableName = larkLauange.languageIdentifier
//        return self.resourceBundle.localizedString(forKey: key, value: nil, table: tableName)
//    }

    public class func currentLanguage() -> Lang {
        return LanguageManager.currentLanguage
        //        let larkLauange = LanguageManager.currentLanguage
        //        switch larkLauange {
        //        case .en_US: return .en
        //        case .zh_CN: return .zh
        //        case .ja_JP: return .ja
        //        default:
        //            return .en
        //
        //        }
    }

    public class func currentLocale() -> Locale {

        return LanguageManager.locale
        //        let loc = LanguageManager.locale
        //        switch loc.identifier {
        //        case let id where id.starts(with: "zh"): return .zh
        //        case let id where id.starts(with: "en"): return .en
        //        case let id where id.starts(with: "ja"): return .ja
        //
        //        default: return .en
        //        }
    }

    public class func currentLanguageIdentifier() -> String {
        let languageIdentifer = currentLanguage()
        var identifier: String = Lang.en_US.languageIdentifier
        switch languageIdentifer {
        case .de_DE, .en_US, .es_ES, .fr_FR, .hi_IN, .id_ID, .it_IT, .ja_JP, .ko_KR, .pt_BR, .ru_RU, .rw, .th_TH, .vi_VN, .zh_CN, .zh_TW, .zh_HK, .ms_MY:
            identifier = languageIdentifer.languageIdentifier
        default:
            break
        }
        return identifier
    }

}
