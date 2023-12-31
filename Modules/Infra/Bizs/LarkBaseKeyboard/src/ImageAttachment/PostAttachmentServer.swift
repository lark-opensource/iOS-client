//
//  PostAttachmentServer.swift
//  LarkBaseKeyboard
//
//  Created by liluobin on 2023/4/24.
//

import Foundation
import UIKit
import LarkAttachmentUploader
import EditTextView
import LKCommonsLogging

public protocol PostAttachmentServer: AnyObject {
    var attachmentUploader: AttachmentUploader { get }
    var defaultCallBack: (AttachmentUploadTaskCallback)? { get set }
    func updateAttachmentResultInfo(_ attributedText: NSAttributedString)
    func updateImageAttachmentState(_ textView: LarkEditTextView?)
    func updateImageAttachmentState(_ attributedText: NSAttributedString, gifBackgroundColor: UIColor?, retryCallBack: @escaping () -> NSAttributedString)
    /// async 异步处理图片 imageMaxHeight 最大高度 imageMinWidth 最小宽度 finishBlock 处理完成的回调
    func applyAttachmentDraftForTextView(_ textView: LarkEditTextView,
                                         async: Bool,
                                         imageMaxHeight: CGFloat?,
                                         imageMinWidth: CGFloat?,
                                         finishBlock: (() -> Void)?,
                                         didUpdateAttrText: (() -> Void)?)
    func resizeAttachmentView(textView: LarkEditTextView, toSize: CGSize)
    func storeImageToCacheFromDraft(image: UIImage, imageData: Data, originKey: String)
    func retryUploadAttachment(textView: LarkEditTextView, start: (() -> Void)?, finish: ((Bool) -> Void)?)
    func checkAttachmentAllUploadSuccessFor(attruibuteStr: NSAttributedString) -> Bool
    func attachmentIdsForAttruibuteStr(_ attruibuteStr: NSAttributedString) -> [String]
    func updateAttachmentSizeWithMaxHeight(_ height: CGFloat,
                                           imageMinWidth: CGFloat,
                                           attributedText: NSAttributedString?,
                                           textView: LarkEditTextView?)
    func savePostDraftAttachment(attachmentKeys: [String], key: String, async: Bool, log: Log)
}
