//
//  DriveTextViewModel.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/11/25.
//  

import Foundation
import SKCommon
import SKFoundation
import SKResource
import RxCocoa
import RxSwift
import LarkDocsIcon

protocol DriveTextRenderDelegate: AnyObject {
    func renderPlainText(content: String)
    func renderRichText(content: NSAttributedString)

    func loadHTMLFileURL(_ fileURL: URL, baseURL: URL)
    func evaluateJavaScript(_: String, completionHandler: ((Any?, Error?) -> Void)?)
    func webViewRenderSuccess()

    func renderFailed()
    func fileUnsupport(reason: DriveUnsupportPreviewType)
}

enum DriveTextRenderMode {
    case plainText
    case richText
    case markdown
    case code
    case auto

    var htmlTemplateURL: URL? {
        switch self {
        case .plainText:
            return nil
        case .richText:
            return nil
        case .markdown:
            return DriveModule.getPreviewResourceURL(name: "MarkdownTemplate", extensionType: "html")
        case .code:
            return DriveModule.getPreviewResourceURL(name: "CodeTemplate", extensionType: "html")
        case .auto:
            return nil
        }
    }

    func transformRawContent(content: String) -> String? {
        switch self {
        case .plainText:
            return content
        case .richText:
            return content
        case .markdown:
            return content.data(using: .utf8)?.base64EncodedString()
        case .code:
            return content.data(using: .utf8)?.base64EncodedString()
        case .auto:
            return content
        }
    }
}

class DriveTextPreviewViewModel: NSObject {
    private let renderQueue = DispatchQueue(label: "drive.text.preview")

    private let sizeLimited: UInt64
    let fileURL: SKFilePath
    private(set) var renderMode: DriveTextRenderMode

    weak var renderDelegate: DriveTextRenderDelegate?
    // MARK: security copy
    let token: String?
    private let hostToken: String?
    private let canCopyRelay: BehaviorRelay<Bool>
    private let canEditRelay: BehaviorRelay<Bool>
    private let enableCopySecurity: Bool
    var needSecurityCopyDriver: Driver<(String?, Bool)> {
        let encryptId = ClipboardManager.shared.getEncryptId(token: hostToken)
        let referenceToken = encryptId ?? token
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            return copyManager.monitorCopyPermission(token: referenceToken, allowSecurityCopy: enableCopySecurity)
        } else {
            return copyManager.needSecurityCopyAndCopyEnable(token: referenceToken,
                                                             canEdity: canEditRelay,
                                                             canCopy: canCopyRelay,
                                                             enableSecurityCopy: enableCopySecurity)
        }
    }
    // 复制权限变更
    var canCopyUpdated: Driver<Bool> {
        return canCopyRelay
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)
    }
    
    var canCopy: Bool {
        return canCopyRelay.value
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    func needCopyIntercept() -> DriveCopyMananger.InterceptCopyResult {
        return copyManager.interceptCopy(token: token,
                                         canEdit: canEditRelay.value,
                                         canCopy: canCopy,
                                         enableSecurityCopy: enableCopySecurity)
    }

    func checkCopyPermission() -> DriveCopyMananger.DriveCopyResponse {
        return copyManager.checkCopyPermission(allowSecurityCopy: enableCopySecurity)
    }
    
    private let copyManager: DriveCopyMananger

    init(fileURL: SKFilePath,
         token: String?,
         hostToken: String?, // 附件宿主token, 用于单文档复制保护
         canEdit: BehaviorRelay<Bool>,
         canCopy: BehaviorRelay<Bool>,
         preferedRenderMode renderMode: DriveTextRenderMode = .auto,
         enableCopySecurity: Bool = LKFeatureGating.securityCopyEnable,
         sizeLimited: UInt64 = DriveFeatureGate.textPreviewMaxSize,
         copyMananger: DriveCopyMananger) {
        self.fileURL = fileURL
        self.token = token
        self.hostToken = hostToken
        self.canEditRelay = canEdit
        self.canCopyRelay = canCopy
        self.renderMode = renderMode
        self.enableCopySecurity = enableCopySecurity
        self.sizeLimited = sizeLimited
        self.copyManager = copyMananger
    }

    func setup() {
        let fileExtension = SKFilePath.getFileExtension(from: fileURL.pathURL.lastPathComponent)
        let fileType = DriveFileType(fileExtension: fileExtension)
        guard fileType.isText else {
            DocsLogger.error("drive.text.preview --- unknown file type: \(fileType)")
            renderDelegate?.fileUnsupport(reason: .typeUnsupport)
            return
        }
        guard let fileSize = fileURL.fileSize else {
            DocsLogger.error("drive.text.preview --- failed to get file size")
            renderDelegate?.renderFailed()
            return
        }
        guard fileSize <= sizeLimited else {
            DocsLogger.error("drive.text.preview --- file size too big: \(fileSize)")
            renderDelegate?.fileUnsupport(reason: .sizeTooBig)
            return
        }
        updateMode(fileType: fileType, fileSize: fileSize)
    }

    func updateMode(fileType: DriveFileType, fileSize: UInt64) {
        switch renderMode {
        case .plainText:
            return
        case .richText:
            guard fileType.isRichText else {
                spaceAssertionFailure("drive.text.preview --- not richText file! file type: \(fileType)")
                DocsLogger.error("drive.text.preview --- not richText file! file type: \(fileType)")
                renderMode = .plainText
                return
            }
            if fileSize > DriveFeatureGate.richTextRenderMaxSize {
                DocsLogger.driveInfo("drive.text.preview --- renderMode downgrade from richText to plainText due to oversize")
                renderMode = .plainText
            }
        case .markdown:
            guard fileType == .md else {
                spaceAssertionFailure("drive.text.preview --- not markdown file! file type: \(fileType)")
                DocsLogger.error("drive.text.preview --- not markdown file! file type: \(fileType)")
                renderMode = .plainText
                return
            }
            if fileSize > DriveFeatureGate.markdownRenderMaxSize {
                DocsLogger.driveInfo("drive.text.preview --- renderMode downgrade from md to plainText due to oversize")
                renderMode = .plainText
            }
        case .code:
            guard fileType.isCode else {
                spaceAssertionFailure("drive.text.preview --- not code file! file type: \(fileType)")
                DocsLogger.error("drive.text.preview --- not code file! file type: \(fileType)")
                renderMode = .plainText
                return
            }
            if fileSize > DriveFeatureGate.codeHighlightMaxSize {
                DocsLogger.driveInfo("drive.text.preview --- renderMode downgrade from code to plainText due to oversize")
                renderMode = .plainText
            }
        case .auto:
            if fileType == .md, fileSize < DriveFeatureGate.markdownRenderMaxSize {
                DocsLogger.driveInfo("drive.text.preview --- deduce renderMode to markdown")
                renderMode = .markdown
            } else if fileType.isCode, fileSize < DriveFeatureGate.codeHighlightMaxSize {
                DocsLogger.driveInfo("drive.text.preview --- deduce renderMode to code")
                renderMode = .code
            } else if fileType.isRichText, fileSize < DriveFeatureGate.richTextRenderMaxSize {
                DocsLogger.driveInfo("drive.text.preview --- deduce renderMode to richText")
                renderMode = .richText
            } else {
                DocsLogger.driveInfo("drive.text.preview --- deduce renderMode to plainText")
                renderMode = .plainText
            }
        }
    }

    func loadContent() {
        renderQueue.async {
            self.prepareContent()
        }
    }

    private func prepareContent() {
        switch renderMode {
        case .plainText:
            preparePlainText()
        case .richText:
            prepareRichText()
        case .markdown:
            prepareWebContent()
        case .code:
            prepareWebContent()
        case .auto:
            spaceAssertionFailure("drive.text.preview --- auto renderMode should not be present here!")
            DocsLogger.error("drive.text.preview --- auto renderMode should not be present here!")
            preparePlainText()
        }
    }
}

extension DriveTextPreviewViewModel {
    private func preparePlainText() {
        DocsLogger.driveInfo("drive.text.preview --- prepare plain text content")
        guard let content = stringContentForURL(fileURL) else {
            DocsLogger.error("drive.text.preview --- fail to parse content from file")
            DispatchQueue.main.async {
                self.renderDelegate?.fileUnsupport(reason: .typeUnsupport)
            }
            return
        }
        // 对字符内容进行转义，避免 webview 把 html 标签无法作为纯文本显示出来
        let escapedContent = content.addingUnicodeEntities()
        DispatchQueue.main.async {
            self.renderDelegate?.renderPlainText(content: escapedContent)
        }
    }

    private func stringContentForURL(_ url: SKFilePath) -> String? {
        let encodings = [   .utf8,
                            String.Encoding(rawValue: 0x80000631), //GBK18030
                            String.Encoding(rawValue: 0x80000632), //GBK
                            String.Encoding(rawValue: 0x80000503), //greek
                            String.Encoding(rawValue: 0x80000504),  //turkish
                            .utf16LittleEndian,
                            .utf16BigEndian
                        ]
        let resultData = try? Data.read(from: url)
        if let resultData = resultData {
            for encoding in encodings {
                if let resultString = String(data: resultData, encoding: encoding) {
                    return resultString
                }
            }
        }
        return nil
    }

    private func prepareRichText() {
        DocsLogger.driveInfo("drive.text.preview --- prepare rich text content")
        guard let richTextContent = try? NSAttributedString(url: fileURL.pathURL, options: [:], documentAttributes: nil) else {
            DocsLogger.error("drive.text.preview --- fail to read rich text content from file, fallback to plainText")
            renderMode = .plainText
            preparePlainText()
            return
        }
        DispatchQueue.main.async {
            self.renderDelegate?.renderRichText(content: richTextContent)
        }
    }
}

extension DriveTextPreviewViewModel {
    private func prepareWebContent() {
        DocsLogger.driveInfo("drive.text.preview --- prepare web content")
        guard let templateURL = renderMode.htmlTemplateURL else {
            DocsLogger.error("drive.text.preview --- failed to get template url for mode: \(renderMode)")
            preparePlainText()
            return
        }
        DispatchQueue.main.async {
            self.renderDelegate?.loadHTMLFileURL(templateURL, baseURL: templateURL.deletingLastPathComponent())
        }
    }

    func loadWebContent() {
        DocsLogger.driveInfo("drive.text.preview --- loading web content")
        renderQueue.async {
            self.renderWebContent()
        }
    }

    private func renderWebContent() {
        DocsLogger.driveInfo("drive.text.preview --- rendering web content")
        guard let content = try? String.read(from: fileURL) else {
            DocsLogger.error("drive.text.preview --- failed to read content from file")
            DispatchQueue.main.async {
                self.renderDelegate?.fileUnsupport(reason: .typeUnsupport)
            }
            return
        }
        guard let transformedContent = renderMode.transformRawContent(content: content) else {
            DocsLogger.error("drive.text.preview --- failed to transform content for mode: \(renderMode)")
            renderMode = .plainText
            DispatchQueue.main.async {
                self.renderDelegate?.renderPlainText(content: content)
            }
            return
        }
        DispatchQueue.main.async {
            self.renderDelegate?.evaluateJavaScript("renderContent('\(transformedContent)')") { [weak self] result, error in
                guard let self = self else { return }
                if let error = error {
                    DocsLogger.error("drive.text.preview --- js renderContent failed with error", error: error)
                    self.renderMode = .plainText
                    self.renderDelegate?.renderPlainText(content: content)
                    return
                }
                DocsLogger.debug("drive.text.preview --- js renderContent success with result", extraInfo: ["result": result as Any])
                self.renderDelegate?.webViewRenderSuccess()
            }
        }
    }
}


extension String {
    /// 转义字符串中的 html 标签元素
    func addingUnicodeEntities() -> String {
        var result = ""
        let htmlUnicodeCharacters: Set<Character> = ["!", "\"", "$", "%", "&", "'", "+", ",", "<", "=", ">", "@", "[", "]", "`", "{", "}"]
        for character in self {
            if htmlUnicodeCharacters.contains(character), let asciiValue = character.asciiValue {
                result.append(contentsOf: "&#\(asciiValue);")
            } else {
                result.append(character)
            }
        }
        return result
    }
}
