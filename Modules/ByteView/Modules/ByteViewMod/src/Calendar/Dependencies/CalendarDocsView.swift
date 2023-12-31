//
//  CalendarDocsView.swift
//  ByteViewMod
//
//  Created by kiri on 2021/10/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteView
import UniverseDesignTheme
import UniverseDesignColor
import CalendarRichTextEditor
import EENavigator
import LarkAppConfig
import LarkSetting
import LarkAccountInterface
import LarkContainer

private class HolderView: UIView {
    private let docView: UIView
    init(docView: UIView) {
        self.docView = docView
        super.init(frame: .zero)
        self.addSubview(docView)
        docView.frame = self.bounds
        self.clipsToBounds = true
        self.backgroundColor = UIColor.ud.primaryOnPrimaryFill
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var autoLayoutHeight: CGFloat = 20.0 {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }

    func setWidth(_ width: CGFloat) {
        var frame = self.docView.frame
        frame.size.width = width
        self.docView.frame = frame
        self.docView.setNeedsLayout()
        self.docView.layoutIfNeeded()
    }

    func shouldAutoResizing() {
        docView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = self.autoLayoutHeight
        return size
    }
}

final class CalendarDocsView: ByteView.CalendarDocsViewHolder {
    weak var delegate: CalendarDocsViewDelegate?
    var customHandle: ((URL, [String: Any]?) -> Void)? {
        didSet {
            docsAPI.customHandle = customHandle
        }
    }
    var autoLayoutHeight: Bool = false
    private var shouldUpdateHeight = false

    private var shouldJumpToURL = false

    private var viewDidGet = false

    private let docsAPI: DocsRichTextView
    private let wrapper: HolderView

    init(userResolver: UserResolver) {
        let settings = DomainSettingManager.shared.currentSetting
        let domainPool = settings[.docsPeer] ?? []
        let spaceApi = settings[.docsApi]?.first ?? ""
        let postMainDomian = settings[.docsMainDomain]?.first ?? ""
        let prefixMainDomian = try? userResolver.resolve(assert: PassportUserService.self).userTenant.tenantDomain
        let mainDomian = "\(prefixMainDomian ?? "").\(postMainDomian)"
        let richTextView = DocsRichTextView()
        richTextView.setDomains(domainPool: domainPool, spaceApiDomain: spaceApi, mainDomain: mainDomian)
        richTextView.disableBecomeFirstResponder = { return true }
        self.docsAPI = richTextView
        self.wrapper = HolderView(docView: docsAPI.view)
        docsAPI.delegate = self
        docsAPI.loadCalendar()
    }

    func setEditable(_ enable: Bool, success: (() -> Void)?, fail: @escaping (Error) -> Void) {
        docsAPI.setEditable(enable, success: success, fail: fail)
        docsAPI.setTextMenu(type: enable ? .readWrite : .readOnly)
    }

    func setDoc(data: String, displayWidth: CGFloat?, success: (() -> Void)?, fail: @escaping (Error) -> Void) {
        if let width = displayWidth {
            wrapper.setWidth(width)
        }
        self.docsAPI.setDoc(data: data, success: success, fail: fail)
    }

    func setThemeConfig(backgroundColor: UIColor, foregroundFontColor: UIColor, linkColor: UIColor, listMarkerColor: UIColor) {
        let config = ThemeConfig(backgroundColor: backgroundColor, foregroundFontColor: foregroundFontColor, linkColor: linkColor, listMarkerColor: listMarkerColor)
        self.docsAPI.setThemeConfig(config)
    }

    func getDocsView(_ autoUpdateHeight: Bool, shouldJumpToWebPage: Bool) -> UIView {
        self.autoLayoutHeight = autoUpdateHeight
        if !autoUpdateHeight {
            wrapper.shouldAutoResizing()
        }
        shouldJumpToURL = shouldJumpToWebPage
        viewDidGet = true
        return wrapper
    }
}

extension CalendarDocsView: DocsRichTextViewDelegate {
    func richTextView(requireOpen url: URL) -> Bool {
        if shouldJumpToURL {
            delegate?.docsView(requireOpen: url)
        }
        return false
    }

    func richTextViewJSContextDidReady() { }

    func richTextViewContentSizeDidChange(_ size: CGSize) {
        if self.autoLayoutHeight && viewDidGet {
            // 为了解一行状态下编辑编辑页docsview底部高度过高问题
            docsAPI.view.frame = CGRect(origin: docsAPI.view.frame.origin, size: size)
            wrapper.autoLayoutHeight = size.height - 5
            wrapper.superview?.layoutIfNeeded()
            docsAPI.setCanScroll(false)
        }
    }

    var clientInfos: [String: String]? {
        return [
            "Docs": "0.2.5",
            "Core": "1.0.0"
        ]
    }
}
