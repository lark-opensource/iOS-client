//
//  PostDraftManager.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/5/5.
//

import UIKit
import LarkAttachmentUploader
import EditTextView
import RustPB
import UniverseDesignToast

public class PostDraftManager {
    /// 获取草稿模型
    /// - Parameters:
    ///   - attribueStr: 内容
    ///   - uploaderDraftData: 草稿的Data 例如图片的草稿：attachmentUploader.draft.atchiverData()
    ///   - title: 标题
    ///   - saveUseInfo: 是否保存用户真实姓名，将来回复的时候也会自动替换
    /// - Returns: 草稿模型
    public static func getDraftModelFor(attributeStr: NSAttributedString,
                          attachmentUploader: AttachmentUploader?,
                          title: String? = nil,
                          saveUseInfo: Bool = true) -> PostDraftModel {

        var postDraft: PostDraftModel = PostDraftModel()
        postDraft.title = title ?? ""
        if let richText = RichTextTransformKit.transformStringToRichText(string: attributeStr) {
            postDraft.content = (try? richText.jsonString()) ?? ""
        }
        if let data = attachmentUploader?.draft.atchiverData(),
           let draftStr = String(data: data, encoding: .utf8) {
            postDraft.uploaderDraft = draftStr
        }
        postDraft.lingoElements = LingoConvertService.transformStringToDraftModel(attributeStr)
        postDraft.userInfoDic = AtTransformer.getAllChatterActualNameMapForAttributedString(attributeStr)
        return postDraft
    }

    /// 将草稿应用到TextView
    /// - Parameters:
    ///   - postDraft: 存的草稿模型
    ///   - attachmentUploader: 图片上传的uploader
    ///   - textView: contentTextView
    ///   - titleTextView: titleTextView
    /// - Returns: contentTextView 有没有应用草稿成功

    public static func applyPostDraftFor(_ postDraft: PostDraftModel,
                                  attachmentUploader: AttachmentUploader?,
                                  contentTextView: LarkEditTextView,
                                  titleTextView: UITextView? = nil) -> Bool {

        if let draftData = postDraft.uploaderDraft.data(using: .utf8),
           let uploaderDraft = AttachmentUploader.Draft(draftData) {
            attachmentUploader?.draft = uploaderDraft
        }

        if let richText = try? RustPB.Basic_V1_RichText(jsonString: postDraft.content) {
            let content = RichTextTransformKit.transformRichTextToStr(
                richText: richText,
                attributes: contentTextView.baseDefaultTypingAttributes,
                attachmentResult: attachmentUploader?.results ?? [:],
                processProvider: postDraft.processProvider)
            AtTransformer.getAllChatterInfoForAttributedString(content).forEach { chatterInfo in
                chatterInfo.actualName = postDraft.userInfoDic[chatterInfo.id] ?? ""
            }
            let contentStr = LingoConvertService.transformModelToString(elements: postDraft.lingoElements, text: content)
            contentTextView.replace(contentStr, useDefaultAttributes: false)
        } else {
            return false
        }

        guard let titleTextView = titleTextView else {
            return true
        }

        if let editTextView = titleTextView as? LarkEditTextView {
            editTextView.replace(NSAttributedString(string: postDraft.title))
        } else {
            titleTextView.attributedText = NSAttributedString(string: postDraft.title)
        }
        return true
    }

    public static func setupAttachment(fromVC: UIViewController,
                                       contentTextView: LarkEditTextView,
                                       attachmentServer: PostAttachmentServer,
                                       finish:(() -> Void)?) {
        var hud: UDToast?
        if let widnow = fromVC.view.window {
            hud = UDToast.showLoading(with: BundleI18n.LarkBaseKeyboard.Lark_Legacy_LoadingLoading,
                                         on: widnow,
                                         disableUserInteraction: true)
        }
        attachmentServer.applyAttachmentDraftForTextView(contentTextView,
                                                         async: true,
                                                         imageMaxHeight: nil,
                                                         imageMinWidth: nil,
                                                         finishBlock: { [weak attachmentServer] in
            hud?.remove()
            attachmentServer?.attachmentUploader.startUpload()
            attachmentServer?.updateImageAttachmentState(contentTextView)
        }, didUpdateAttrText: {
            finish?()
        })
    }
}
