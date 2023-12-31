//
//  ColdStartDialog.swift
//  LarkContact
//
//  Created by ByteDance on 2022/9/16.
//

import UIKit
import Foundation
import LarkMessageCore
import LKRichView
import ByteWebImage
import UGDialog
import UGReachSDK
import LarkContainer
import EENavigator
import LarkUIKit
import LarkRichTextCore
import LarkNavigator

final class ColdStartDialogManager: UserResolverWrapper {
    static let dialogScenrioId = "SCENE_COLD_START"
    static let reachPointId = "RP_COLD_START_DIALOG"
    var userResolver: LarkContainer.UserResolver

    @ScopedInjectedLazy private var ugService: UGReachSDKService?

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    lazy var reachPoint: DialogReachPoint? = {
        let bizContextProvider = UGSyncBizContextProvider(scenarioId: Self.dialogScenrioId) { [:] }
        let reachPoint: DialogReachPoint? = ugService?.obtainReachPoint(
            reachPointId: Self.reachPointId,
            bizContextProvider: bizContextProvider
        )
        return reachPoint
    }()

    lazy var ugDialog: UGDialogTemplate = UGDialogTemplate(userResolver: userResolver, richTextHandler: { [weak self] richText in
        // parseRichTextToRichElement做了二进制不兼容的变更，需要更新LarkContact
        let element = RichViewAdaptor.parseRichTextToRichElement(
            richText: richText,
            isFromMe: false,
            isShowReadStatus: false,
            checkIsMe: { _ in return false },
            maxLines: 100,
            maxCharLine: 200,
            imageAttachmentProvider: { [weak self] (property) in
                guard let self = self else {
                    return LKRichAttachmentImp(view: UIView())
                }
                var index = 0
                let width = RichTextDialogLayout.dialogWidth - 2 * RichTextDialogLayout.horizontalPadding
                let height = CGFloat(property.originHeight) == 0 ? width * 9.0 / 16.0 : CGFloat(property.originHeight)
                var originSize = CGSize(width: width, height: height)
                var imageView = ByteImageView()
                imageView.contentMode = .scaleAspectFill
                runInMain {
                    imageView.layer.cornerRadius = 4
                    imageView.clipsToBounds = true
                    imageView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
                    imageView.layer.borderWidth = 1 / UIScreen.main.scale

                    imageView.tag = index
                    index += 1
                    imageView.bt.setLarkImage(with: .default(key: property.urls.first ?? ""))
                    imageView.frame = CGRect(origin: .zero, size: originSize)
                }
                var attachMent = LKAsyncRichAttachmentImp(
                    size: originSize,
                    viewProvider: { imageView },
                    verticalAlign: .baseline
                )
                return attachMent
            }
        )
        let richView = LKRichView(frame: .zero)
        richView.delegate = self
        richView.bindEvent(selectors: [CSSSelector(value: RichViewAdaptor.Tag.a)], isPropagation: true)
        richView.loadStyleSheets(Self.createStyleSheets())
        richView.documentElement = element
        return richView
    })

    public func triggerColdStartDialog() {
        reachPoint?.delegate = ugDialog
        ugService?.tryExpose(by: Self.dialogScenrioId, specifiedReachPointIds: [Self.reachPointId])
    }

    private weak var targetElement: LKRichElement?

    deinit {
        ugService?.recycleReachPoint(reachPointId: Self.reachPointId, reachPointType: DialogReachPoint.reachPointType)
    }

    public static func createStyleSheets() -> [CSSStyleSheet] {
        var styleSheets = RichViewAdaptor.createStyleSheets(config: RichViewAdaptor.Config(normalFont: UIFont.systemFont(ofSize: 16, weight: .regular), atColor: AtColor()))
        let tagPStyleSheet = CSSStyleSheet(rules: [
            CSSStyleRule.create(CSSSelector(value: RichViewAdaptor.Tag.p), [
                StyleProperty.lineHeight(.init(.point, 22)),
                StyleProperty.margin(.init(.value, Edges(.point(3), .point(0), .point(0), .point(0))))
            ])
        ])
        styleSheets.append(tagPStyleSheet)
        return styleSheets
    }
}

extension ColdStartDialogManager: LKRichViewDelegate {

    func updateTiledCache(_ view: LKRichView, cache: LKTiledCache) {
    }

    func getTiledCache(_ view: LKRichView) -> LKTiledCache? {
        return nil
    }

    func shouldShowMore(_ view: LKRichView, isContentScroll: Bool) {
    }

    public func touchStart(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        targetElement = event?.source
    }

    public func touchMove(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        if targetElement !== event?.source { targetElement = nil }
    }

    public func touchCancel(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        targetElement = nil
    }

    public func touchEnd(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        guard targetElement === event?.source else { return }

        var needPropagation = true
        switch element.tagName.typeID {
        case RichViewAdaptor.Tag.a.typeID: needPropagation = handleTagAEvent(element: element, event: event, view: view)
        default: break
        }
        if !needPropagation {
            event?.stopPropagation()
            targetElement = nil
        }
    }

    /// Return - 事件是否需要继续冒泡
    private func handleTagAEvent(element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) -> Bool {
        guard let anchor = element as? LKAnchorElement else { return true }
        if let href = anchor.href,
           let url = URL(string: href),
           let httpUrl = url.lf.toHttpUrl(),
           let window = userResolver.navigator.mainSceneWindow {
            userResolver.navigator.present(httpUrl, wrap: LkNavigationController.self, from: window, prepare: {
                $0.modalPresentationStyle = .custom
            })
            return false
        }
        return true
    }
}

func runInMain(_ callback: () -> Void) {
    if Thread.isMainThread {
        callback()
    } else {
        DispatchQueue.main.sync {
            callback()
        }
    }
}
