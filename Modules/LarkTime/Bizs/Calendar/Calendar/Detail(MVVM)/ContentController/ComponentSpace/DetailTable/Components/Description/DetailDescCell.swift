//
//  DescCombo.swift
//  Calendar
//
//  Created by jiayi zou on 2018/2/2.
//  Copyright © 2018年 EE. All rights reserved.
//

import UniverseDesignIcon
import UIKit
import RichLabel
import RustPB
import CalendarFoundation

protocol DetailDescCellContent {
    var desc: String { get }
    var docsData: String { get }
    var contentType: DetailDescCell.ContentType { get }
}

final class DetailDescCell: DetailCell {

    enum ContentType {
        case docsData
        case docsHtml
        case textHtml
    }

    var content: DetailDescCellContent?
    var docsViewHolder: DocsViewHolder
    var disableWebViewCanBecomeFirstResponder = true
    var openUrl: ((URL, [String: Any]?) -> Void)? {
        didSet {
            docsViewHolder.customHandle = openUrl
        }
    }
    var openSelectTranslateHandler: ((String) -> Void)? {
        didSet {
            docsViewHolder.openSelectTranslateHandler = openSelectTranslateHandler
        }
    }
    // 后续有更新 取375作为临时值
    private var maxWidth: CGFloat = 375

    convenience init(maxWidth: CGFloat, docsViewHolder: DocsViewHolder) {
        self.init(docsViewHolder: docsViewHolder)
        self.maxWidth = maxWidth
    }

    init(docsViewHolder: DocsViewHolder) {
        self.docsViewHolder = docsViewHolder
        super.init(frame: .zero)
        self.setLeadingIcon(UDIcon.getIconByKeyNoLimitSize(.slideOutlined).renderColor(with: .n3).withRenderingMode(.alwaysOriginal))
        self.layoutDocsView()
        self.docsViewHolder.disableBecomeFirstResponder = { [weak self] in return self?.disableWebViewCanBecomeFirstResponder ?? true }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateMaxWidth(_ width: CGFloat) {
        guard width != 0,
              self.maxWidth != width else { return }
        maxWidth = width
        if let content = self.content {
            self.updateContent(content)
        }
    }

    private var haslayout = false

    func updateContent(_ content: DetailDescCellContent) {

        if !haslayout {
            self.layoutDocsView()
            haslayout = true
        }

        self.content = content

        let displayWidth: CGFloat = maxWidth - 16 - 48

        switch content.contentType {
        case .docsData:
            docsViewHolder.setDoc(data: content.docsData,
                                  displayWidth: displayWidth,
                                  success: { [weak self] in
                self?.disableWebViewCanBecomeFirstResponder = false},
                                  fail: { (_) in
                assertionFailureLog()
            })
        case .docsHtml:
            docsViewHolder.setDoc(html: content.desc,
                                  displayWidth: displayWidth,
                                  success: { [weak self] in
                self?.disableWebViewCanBecomeFirstResponder = false},
                                  fail: { (_) in
                assertionFailureLog()
            })
        case .textHtml:
            layoutTextView(desc: content.desc, maxLayoutWidth: displayWidth)
        }

    }

    func layoutDocsView() {
        let docsLabel = docsViewHolder.getDocsView(true, shouldJumpToWebPage: true)
        self.addCustomView(docsLabel, edgeInset: UIEdgeInsets(top: -1, left: 0, bottom: -10, right: 0))
        docsLabel.snp.updateConstraints { make in
            make.bottom.equalToSuperview().offset(10)
        }
        docsViewHolder.setEditable(false, success: nil) { (_) in
//            assertionFailureLog()
        }
        operationLog(message: "DetailDescCell: \(ObjectIdentifier(self)) add DocsView: \(ObjectIdentifier(docsLabel))")
    }

    private lazy var textView: UITextView = DescTextView()
    private func layoutTextView(desc: String, maxLayoutWidth: CGFloat) {
        textView.delegate = self

        var modifiedRichText = String(format: "<span style=\"font-family: 'Helvetica Neue', 'PingFang SC'; font-size: 16\">%@</span>", desc)
        modifiedRichText = modifiedRichText.replacingOccurrences(of: "\n", with: "<br>")
        guard let attrString = try? NSAttributedString(data: modifiedRichText.data(using: .utf8)!,
                                                       options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html,
                                                                 NSAttributedString.DocumentReadingOptionKey.characterEncoding: String.Encoding.utf8.rawValue],
                                                       documentAttributes: nil)
            else {
                assertionFailureLog()
                return
        }
        let textp = LKTextParserImpl()
        textp.originAttrString = attrString
        textp.parse()
        textView.attributedText = textp.renderAttrString
        let rect = attrString.boundingRect(with: CGSize(width: maxLayoutWidth,
                                                        height: 10_000),
                                           options: [.usesLineFragmentOrigin, .usesFontLeading],
                                           context: nil)
        textView.textContainer.lineFragmentPadding = 0
        textView.linkTextAttributes = [
            .foregroundColor: UIColor.ud.primaryContentDefault,
            .underlineColor: UIColor.clear
        ]
        textView.textContainerInset = .zero
        self.addCustomView(textView)
        textView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.height.equalTo(rect.height + 1)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        operationLog(message: "\(ObjectIdentifier(self)) did layout subviews, frame: \(self.frame)")
    }
}

extension DetailDescCell: UITextViewDelegate {
    func textView(_ textView: UITextView,
                  shouldInteractWith URL: URL,
                  in characterRange: NSRange) -> Bool {
        openUrl?(URL, nil)
        return false
    }
}

private final class DescTextView: UITextView {
    init() {
        super.init(frame: .zero, textContainer: nil)
        self.backgroundColor = UIColor.clear
        self.isEditable = false
        self.bounces = false
        self.isScrollEnabled = false
        self.dataDetectorTypes = .link
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return [#selector(select(_:)),
                #selector(selectAll(_:)),
                #selector(copy(_:))].contains(action)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.resignFirstResponder()
    }
}
