//
//  RecordExtensions.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/3/1.
//

import Foundation
import ByteViewNetwork

extension ViewUserSetting.RecordLayoutType {
    var detail: String {
        switch self {
        case .sideLayout:
            return I18n.View_G_ShowSharedContent
        case .fullScreenLayout:
            return I18n.View_G_ShowOnlySharedAndSpeaker
        case .speakerLayout:
            return I18n.View_G_SpeakerExplain
        case .galleryLayout:
            return I18n.View_G_GallerySetExplain
        }
    }

    var title: String {
        switch self {
        case .sideLayout:
            return I18n.View_G_SideBySide
        case .fullScreenLayout:
            return I18n.View_G_FullScreen
        case .speakerLayout:
            return I18n.View_G_Speaker
        case .galleryLayout:
            return I18n.View_G_GallerySet
        }
    }

    var image: UIImage {
        switch self {
        case .sideLayout:
            return BundleResources.ByteViewSetting.Settings.sideBySide
        case .fullScreenLayout:
            return BundleResources.ByteViewSetting.Settings.fullScreen
        case .speakerLayout:
            return BundleResources.ByteViewSetting.Settings.speaker
        case .galleryLayout:
            return BundleResources.ByteViewSetting.Settings.record_layout_gride
        }
    }
}
