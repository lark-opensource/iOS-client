//
//  UGBannerInfo+JSON.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/10/14.
//  


import SKFoundation
import UGBanner
import ServerPB

protocol Convertable {
    func toDictionary() -> [String: Any]
}

extension UGBanner.BannerInfo: Convertable {
    func toDictionary() -> [String: Any] {
        var dict = [String: Any]()
        dict["mbanner_name"] = self.bannerName
        dict["mbanner_type"] = self.bannerType.rawValue
        switch self.bannerType {
        case .normal: dict["mnormal_banner"] = self.normalBanner.toDictionary()
        case .template: dict["mtemplate_banner"] = self.templateBanner.toDictionary()
        @unknown default:
            break
        }
        return dict
    }
}
extension ServerPB_Ug_reach_material_NormalBannerMaterial: Convertable {
    func toDictionary() -> [String: Any] {
        var dict = [String: Any]()
        dict["mbackground_color"] = self.backgroundColor
        dict["mbanner_icon"] = self.bannerIcon.toDictionary()
        dict["mtitle"] = self.title.toDictionary()
        dict["mtitle_color"] = self.titleColor
        dict["msub_title"] = self.subTitle.toDictionary()
        dict["msub_title_color"] = self.subTitleColor
        dict["mcta_title"] = self.ctaTitle.toDictionary()
        dict["mcta_title_color"] = self.ctaTitleColor
        dict["mcta_background_color"] = self.ctaBackgroundColor
        dict["mbanner_closeable"] = self.bannerCloseable
        dict["mbanner_closeable_color"] = self.bannerCloseableColor
        dict["mbutton_link"] = self.buttonLink.toDictionary()
        dict["mlayout"] = self.layout.rawValue
        dict["mframe_color"] = self.frameColor
        return dict
    }
}
extension ServerPB_Ug_reach_material_TemplateBannerMaterial: Convertable {
    func toDictionary() -> [String: Any] {
        var dict = [String: Any]()
        dict["mbackground_color"] = self.backgroundColor
        dict["mbanner_icon"] = self.bannerIcon.toDictionary()
        dict["mbackground_pic"] = self.backgroundPic.toDictionary()
        dict["mtitle"] = self.title.toDictionary()
        dict["mtitle_color"] = self.titleColor
        dict["mbanner_closeable"] = self.bannerCloseable
        dict["mbanner_closeable_color"] = self.bannerCloseableColor
        dict["mlayout"] = self.layout.rawValue
        dict["mtemplate_categories"] = self.templateCategories.toDictArray()
        dict["mtemplate_more"] = self.templateMore.toDictionary()
        dict["mframe_color"] = self.frameColor
        dict["msub_title"] = self.subTitle.toDictionary()
        dict["msub_title_color"] = self.subTitleColor
        return dict
    }
}
extension Array where Element: Convertable {
    func toDictArray() -> [[String: Any]] {
        var array: [[String: Any]] = []
        for ele in self {
            array.append(ele.toDictionary())
        }
        return array
    }
}
extension ServerPB_Ug_reach_material_ImageElement: Convertable {
    func toDictionary() -> [String: Any] {
        var dict = [String: Any]()
        dict["mtype"] = self.type.rawValue
        switch self.type {
        case .rawCdnURL, .encryptedCdnURL:
            dict["mcdn_image"] = self.cdnImage.toDictionary()
        case .rawBytes, .encryptedBytes:
            dict["mraw_image"] = self.rawImage.toDictionary()
        case .unknown:
            break
        @unknown default:
            spaceAssertionFailure("unknown default")
        }
        return dict
    }
}

extension ServerPB_Ug_reach_material_CdnImageElement: Convertable {
    func toDictionary() -> [String: Any] {
        var dict = [String: Any]()
        dict["murl"] = self.url
        dict["msecrets"] = self.secrets
        return dict
    }
}

extension ServerPB_Ug_reach_material_RawImageElement: Convertable {
    func toDictionary() -> [String: Any] {
        var dict = [String: Any]()
        dict["mraw_data"] = self.rawData
        dict["msecrets"] = self.secrets
        return dict
    }
}

extension ServerPB_Ug_reach_material_TextElement: Convertable {
    func toDictionary() -> [String: Any] {
        var dict = [String: Any]()
        dict["mcontent"] = self.content
        dict["mtype"] = self.type.rawValue
        return dict
    }
}

extension ServerPB_Ug_reach_material_BannerTemplateCategory: Convertable {
    func toDictionary() -> [String: Any] {
        var dict = [String: Any]()
        dict["mbackground_color"] = self.backgroundColor
        dict["mfront_pic"] = self.frontPic.toDictionary()
        dict["mcategory_name"] = self.categoryName.toDictionary()
        dict["mlink"] = self.link.toDictionary()
        dict["mtemplate_num"] = self.templateNum
        dict["mdym_pics"] = self.dymPics.toDictArray()
        dict["mcta_title"] = self.ctaTitle.toDictionary()
        dict["mcta_title_color"] = self.ctaTitleColor
        dict["mframe_color"] = self.frameColor
        dict["mcta_frame_color"] = self.ctaFrameColor
        dict["mcta_background_color"] = self.ctaBackgroundColor
        dict["mcta_shadow_color"] = self.ctaShadowColor
        return dict
    }
}

extension ServerPB_Ug_reach_material_BannerTemplateMore: Convertable {
    func toDictionary() -> [String: Any] {
        var dict = [String: Any]()
        dict["mbackground_color"] = self.backgroundColor
        dict["mcontent_pic"] = self.contentPic.toDictionary()
        dict["mname"] = self.name.toDictionary()
        dict["mlink"] = self.link.toDictionary()
        dict["mframe_color"] = self.frameColor
        return dict
    }
}
