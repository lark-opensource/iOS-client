//
//  PSDATokensConfig.swift
//  SKInfra
//
//  Created by huangzhikai on 2023/5/15.
//

import Foundation

public enum PSDATokens {
    
    public enum Pasteboard {
        
        //sheet文档输入框粘贴
        public static let sheet_inputview_do_paste = "LARK-PSDA-sheet_inputview_do_paste"
        
        //文档-分享-链接分享（已开启）- 复制链接或者复制链接和密码
        public static let docs_share_link_do_copy = "LARK-PSDA-docs_share_link_do_copy"
        
        //文档评论输入框，读取粘贴版内容，识别粘贴文档链接，进行转换成对应文档名称等操作
        public static let docs_comment_input_do_paste = "LARK-PSDA-docs_comment_input_do_paste"
        
        //文档详情-右上角通知-feed列表-长按复制评论
        public static let docs_feed_do_copy = "LARK-PSDA-docs_feed_do_copy"
        
        //编辑和查看所有类型文档，读取剪切板字符串，粘贴到文档
        public static let docs_edit_do_paste_get_string = "LARK-PSDA-docs_edit_do_paste_get_string"
        
        //编辑和查看所有类型文档，读取剪切板内容，粘贴到文档
        public static let docs_edit_do_paste_get_items = "LARK-PSDA-docs_edit_do_paste_get_items"
        
        //编辑和查看所有类型文档，复制文档内容，设置到剪切板
        public static let docs_edit_do_paste_set_items = "LARK-PSDA-docs_edit_do_paste_set_items"
        
        //编辑和查看所有类型文档，复制文档字符串，设置到剪切板
        public static let docs_edit_do_paste_set_strings = "LARK-PSDA-docs_edit_do_paste_set_strings"
        
        //sheet文档-卡片视图-右上角分享按钮-分享文本
        public static let sheet_card_view_share_text = "LARK-PSDA-sheet_card_view_share_text"

        //文档评论-每条评论右上角点击更多-复制评论
        public static let docs_comment_reaction_panel_action_do_copy = "LARK-PSDA-docs_comment_reaction_panel_action_do_copy"
        
        //文档评论-右上角点击更多-复制评论链接
        public static let docs_comment_anchor_link_do_copy = "LARK-PSDA-docs_comment_anchor_link_do_copy"
        
    }
    
    public enum DocX {
        //docx文档点击「图片分享」后点击 「下载操作」
        public static let docx_imageShare_do_download = "LARK-PSDA-docx_export_long_image_click_download"
        
        //docx文档点击 流程图预览 后点击 「下载操作」
        public static let docx_diagram_do_download = "LARK-PSDA-docx_diagram_click_download"
        
        //doc1.0 sheet 打开附件 是图片,且格式是：jpeg 或png
        public static let doc_or_sheet_open_image = "LARK-PSDA-doc_or_sheet_open_image"
        
        //doc1.0 sheet 打开附件 是视频进行预览，且格式为mp4 mov 或者mp3触发
        public static let doc_or_sheet_open_video = "LARK-PSDA-doc_or_sheet_open_video"
        
        //Docx doc1.0 插入视频的时候 点击确认的时候触发
        public static let docx_insert_video_click_comfirm = "LARK-PSDA-docx_insert_video_click_comfirm"
        
        //Docx doc1.0选择视频后点击「上传」后会触发
        public static let doc_insert_video_write_data = "LARK-PSDA-doc_insert_video_write_data"
        
        //文档中进行编辑，点击图片按钮在内容中插入一张图片，点击右下角「上传」按钮触发
        public static let docx_insert_image_click_upload = "LARK-PSDA-docx_insert_image_click_upload"
        
        //在小程序中复用了文档的编辑栏能力，点击编辑栏中的图片按钮，选择图片后点击右下角的「上传」按钮触发
        public static let mini_app_insert_image_click_upload = "LARK-PSDA-mini_app_insert_image_click_upload"
        
        //文档1.0中进行编辑，点击图片按钮在内容中插入一张图片，点击右下角「上传」按钮触发一次
        public static let doc_insert_image_click_upload = "LARK-PSDA-doc_insert_image_click_upload"
        
        //文档中的封面，点击「编辑封面」后，选择「本地上传」，选取好图片后点击右下角「上传」按钮触发
        public static let cover_replace_image_click_upload = "LARK-PSDA-cover_replace_image_click_upload"
        
        //文档中的封面，点击编辑封面后 选择 拍照，拍完照后点击右下角上传触发
        public static let cover_takephoto_click_upload = "LARK-PSDA-cover_takephoto_click_upload"
        
    }
    
    public enum Sheet {
        //sheet 点击「分享」后点击「图片分享」再点击「下载」
        public static let sheet_share_image_do_download = "LARK-PSDA-sheet_image_share_click_download"
    }
    
    public enum MindNote {
        //在mindnote中预览图片的时候点击右下角「下载」
        public static let mindnote_preview_image_do_download = "LARK-PSDA-mindnote_image_click_download"
    }
    
    public enum Bitable {
        //Bitable 点击「添加附件」 从相册中选择一张图片点击「确定」进行上传
        public static let bitable_upload_image_do_confirm = "LARK-PSDA-bitable_upload_image_click_confirm"
        
        //bitable中上传附件 ，附件类型是视频 且需要压缩的时候点击「确定」时触发
        public static let bitable_upload_compress_video = "LARK-PSDA-bitable_upload_compress_video"
        
        //bitable上传图片或视频时，不进行压缩 上传原图的时候点击确定按钮触发
        public static let bitable_upload_original_asset_click_confirm = "LARK-PSDA-bitable_upload_original_asset_click_confirm"
        
        //Bitable列表中，点击附件「+」号按钮后点击 上传图片后进入到图片选择器，在图片选择器中选择图片且图片类型是GIF动图，取消「原图」按钮，后点击右下角「上传」触发
        public static let bitable_compress_gif_click_upload = "LARK-PSDA-bitable_compress_gif_click_upload"
        
        //Bitable列表中，点击附件「+」号按钮后点击 上传图片后进入到图片选择器，在图片选择器中选择图片后点击下方「预览」按钮后再点击「编辑」进行编辑，编辑完后点击右下角「上传」触发
        public static let bitable_edita_image_click_upload = "LARK-PSDA-bitable_edita_image_click_upload"
    }
    
    public enum Space {
        //Space列表中上传附件 ，附件类型是视频 且需要压缩的时候点击「确定」时触发
        public static let space_upload_compress_video = "LARK-PSDA-space_upload_compress_video"
        
        //Space列表上传图片或视频时，不进行压缩 上传原图的时候点击确定按钮触发
        public static let space_upload_original_asset_click_confirm = "LARK-PSDA-space_upload_original_asset_click_confirm"
        
        //云文档列表中，点击右下角蓝色「+」号按钮后点击 上传图片后进入到图片选择器，在图片选择器中选择图片后点击右下角「上传」触发
        public static let space_upload_image_click_upload = "LARK-PSDA-space_upload_image_click_upload"
        
        //云文档列表中，点击右下角蓝色「+」号按钮后点击 上传图片后进入到图片选择器，在图片选择器中选择图片且图片类型是GIF动图，取消「原图」按钮,后点击右下角「上传」触发
        public static let space_upload_gif_click_upload = "LARK-PSDA-space_upload_gif_click_upload"
        
        //云文档列表中，点击右下角蓝色「+」号按钮后点击 上传图片后进入到图片选择器，在图片选择器中选择拍照按钮进行照片，拍完后点击图片右下角「上传」触发
        public static let space_takephoto_click_upload = "LARK-PSDA-space_takephoto_click_upload"
        
        //云文档列表中，点击右下角蓝色「+」号按钮后点击 上传图片后进入到图片选择器，在图片选择器中选择拍照按钮进行照片，，拍完后点击图片右下角「上传」并且取消 原图按钮触发
        public static let space_takephoto_click_upload_no_fg = "LARK-PSDA-space_takephoto_click_upload_no_fg"
    }
    
    public enum Drive {
        //预览Drive（本地文件）类型文件的时候类型是图片,点击右上角More按钮弹出功能框，点击功能框中的「保存到本地」进行下载
        public static let drive_preview_image_click_download = "LARK-PSDA-drive_preview_image_click_download"
        
        //预览Drive（本地文件）类型文件的时候类型是视频,点击右上角More按钮弹出功能框，点击功能框中的「保存到本地」进行下载
        public static let drive_preview_video_click_download = "LARK-PSDA-drive_preview_video_click_download"
        
        //预览Drive（本地文件）类型文件的时候类型是GIF,点击右上角More按钮弹出功能框，点击功能框中的「保存到本地」进行下载
        public static let drive_preview_gif_click_download = "LARK-PSDA-drive_preview_gif_click_download"
        
        //预览Drive（本地文件）类型文件的时候,点击右上角More按钮弹出功能框，点击功能框中的「保存到本地」进行下载会判断权限并触发
        public static let drive_preview_download_check_permission = "LARK-PSDA-drive_preview_download_check_permission"
        
        //预览Drive（本地文件）类型文件的时候,点击AI 分会话场景，点击分会话中AI返回的内容
        public static let drive_preview_aiservice_copy_content = "LARK-PSDA-drive_preview_aiservice_copy_content"

    }
    
    public enum Comment {
        //文档中的评论，点击评论框中的话筒图案触发请求权限
        public static let docx_comment_click_microphone = "LARK-PSDA-docx_comment_click_microphone"
        
        //文档中的评论框中 点击 图片图案选择相应的图片后，点击右下角的「上传」按钮触发
        public static let comment_upload_image = "LARK-PSDA-comment_upload_image"
        
        //文档中的评论，插入一张图片进行评论后，点击评论中的图片进行预览，点击右下角「下载」按钮进行下载触发
        public static let comment_preview_image_click_download = "LARK-PSDA-comment_preview_image_click_download"
    }
}
