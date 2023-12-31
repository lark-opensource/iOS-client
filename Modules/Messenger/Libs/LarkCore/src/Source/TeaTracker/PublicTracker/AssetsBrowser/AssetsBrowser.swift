//
//  AssetsBrowser.swift
//  LarkCore
//
//  Created by 王元洵 on 2021/6/16.
//

import Foundation
import LKCommonsTracker
import Homeric

/// 图片查看器页面相关埋点
public extension PublicTracker {
    struct AssetsBrowser {}
}

/// 图片查看器相关页面的展示
public extension PublicTracker.AssetsBrowser {
    /// 图片查看器的展示
    static func show() {
        Tracker.post(
            TeaEvent(
                Homeric.PUBLIC_PICBROWSER_VIEW
            )
        )
    }

    /// 图片查看器--更多页面的展示
    static func moreView() {
        Tracker.post(TeaEvent(Homeric.PUBLIC_PICBROWSER_MORE_VIEW))
    }

    /// 图片查看器--群相册的展示
    static func chatAlbumView() {
        Tracker.post(TeaEvent(Homeric.PUBLIC_CHAT_ALBUM_VIEW))
    }

    /// 图片查看器--预览图片的展示
    static func previewView() {
        Tracker.post(TeaEvent(Homeric.PUBLIC_PIC_PREVIEW_VIEW))
    }
}

/// 图片查看器相关页面的动作事件
public extension PublicTracker.AssetsBrowser {
    struct Click {
        /// 图片查看器页面点击事件
        enum browserClickType: String {
            case edit
            case download
            case chatAlbum = "chat_album"
            case more
            case press
            case originImage = "origin_image"
            case identify_image
            case translate

            var target: String {
                switch self {
                case .edit, .originImage: return "public_pic_edit_view"
                case .download: return "none"
                case .chatAlbum: return "pubic_chat_album_view"
                case .more: return "public_picbrowser_more_view"
                case .press: return "public_picbrowser_more_view"
                case .identify_image: return "public_identity_select_content_view"
                case .translate: return "none"
                }
            }
        }

        static func browserClick(action: browserClickType) {
            Tracker.post(TeaEvent(Homeric.PUBLIC_PICBROWSER_CLICK,
                                  params: ["click": action.rawValue, "target": action.target]))
        }

        /// 图片查看器--更多页面点击事件
        enum browserMoreClickType: String {
            case translate
            case forward
            case save
            case edit
            case identify_QR
            case jump_to_chat
            case sticker_save
            case identify_image
            var target: String {
                switch self {
                case .translate, .forward, .save, .edit, .identify_QR, .sticker_save: return "none"
                case .jump_to_chat: return "im_chat_main_view"
                case .identify_image: return "public_picbrowser_view"
                }
            }
        }

        static func browserMoreClick(action: browserMoreClickType) {
            Tracker.post(TeaEvent(Homeric.PUBLIC_PICBROWSER_MORE_CLICK,
                                  params: ["click": action.rawValue, "target": action.target]))
        }

        /// 图片查看器--群相册页面点击事件
        public enum chatAlbumClickType: String {
            case select
            case download
            case forward
            case delete
            case sticker_save
        }

        public static func chatAlbumClick(action: chatAlbumClickType) {
            Tracker.post(TeaEvent(Homeric.PUBLIC_CHAT_ALBUM_CLICK,
                                  params: ["click": action.rawValue,
                                           "target": "none"]))
        }

        /// 图片查看器--预览页面点击事件
        public enum previewClickType: String {
            case original_image
            case edit
            case send
            case videoEdit

            var target: String {
                switch self {
                case .original_image: return "none"
                case .edit: return "public_pic_edit_view"
                case .send: return "im_chat_main_view"
                case .videoEdit: return "public_video_edit_view"
                }
            }
        }

        public static func previewClick(action: previewClickType) {
            var click = action.rawValue
            switch action {
            case .videoEdit:
                click = "edit"
            default:
                break
            }
            Tracker.post(TeaEvent(Homeric.PUBLIC_PIC_PREVIEW_CLICK,
                                  params: ["click": click, "target": action.target]))
        }
    }
}
