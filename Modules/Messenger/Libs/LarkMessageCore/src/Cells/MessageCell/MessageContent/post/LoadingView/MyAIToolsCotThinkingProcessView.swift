//
//  MyAIToolsCotThinkingProcessView.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2023/6/13.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import RxSwift
import RxCocoa
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignFont
import ByteWebImage
import LarkMessengerInterface
import LarkModel
import LarkBizAvatar
import LKCommonsLogging
import LarkRustClient
import LarkContainer
import RustPB
import UniverseDesignTheme
import LKRichView
import LarkRichTextCore

public class MyAIToolsCotThinkingProcessView: UIView, UserResolverWrapper {
    static let logger = Logger.log(MyAIToolsCotThinkingProcessView.self, category: "Module.LarkMessageCore.TextPostCellTag")
    typealias MyAIToolInfoCallBack = ((MyAIToolInfo, Bool) -> Void)

    private var rustService: RustService?
    public var userResolver: LarkContainer.UserResolver
    private let disposeBag = DisposeBag()

    private let toolNameView: LKRichView = LKRichView(frame: .zero)
    private let toolNameText = LKTextElement(text: "")
    private let richViewCore = LKRichViewCore()

    private var toolItem: MyAIToolInfo
    private var toolId: String
    private var toolStatus: MyAIToolCotState
    private var toolsInfoCallBack: MyAIToolInfoCallBack?
    private var isRefresh: Bool = false
    private let loadingView = MyAILoadingView.createView()
    private let font: UIFont
    private let color: UIColor
    private let maxWidth: CGFloat
    private var loadingAttachment: LKRichAttachment {
        let attachmentSize = CGSize(width: MyAILoadingView.size.width + Self.Cons.toolNameLabelRightMargin, height: self.font.lineHeight)
        let loadingAttachment = LKAsyncRichAttachmentImp(size: attachmentSize, viewProvider: { () in
            // 虽然"..."高度只有8，但是我们外面还是包一层有一行高度的UIView，因为当一个内容都没有时，也可以让"..."撑起一行的高度，进而撑起气泡
            let view = UIView(frame: CGRect(origin: .zero, size: attachmentSize))
            let loadingView = self.loadingView
            loadingView.frame.origin.x = Self.Cons.toolNameLabelRightMargin
            loadingView.frame.origin.y = (attachmentSize.height - loadingView.frame.height) / 2 + 1
            view.addSubview(loadingView)

            return view
        }, ascentProvider: { [weak self] _ in self?.font.ascender ?? 0 }, verticalAlign: .baseline)
        return loadingAttachment
    }

    init(toolItem: MyAIToolInfo,
         toolStatus: MyAIToolCotState,
         userResolver: UserResolver,
         font: UIFont,
         textColor: UIColor,
         maxWidth: CGFloat) {
        self.toolItem = toolItem
        self.toolId = toolItem.toolId
        self.toolStatus = toolStatus
        self.userResolver = userResolver
        self.color = textColor
        self.rustService = try? self.userResolver.resolve(assert: RustService.self)
        self.font = font
        self.maxWidth = maxWidth
        super.init(frame: .zero)
        setupSubViews()
        loadData()
    }

    init(toolId: String,
         toolStatus: MyAIToolCotState,
         toolName: String,
         userResolver: UserResolver,
         font: UIFont,
         maxWidth: CGFloat,
         textColor: UIColor,
         toolsInfoCallBack: MyAIToolInfoCallBack? = nil) {
        self.toolItem = MyAIToolInfo(toolId: toolId, toolName: toolName, toolAvatar: "", toolDesc: "")
        self.toolId = toolId
        self.toolStatus = toolStatus
        self.toolsInfoCallBack = toolsInfoCallBack
        self.isRefresh = toolName.isEmpty
        self.userResolver = userResolver
        self.font = font
        self.maxWidth = maxWidth
        self.color = textColor
        self.rustService = try? self.userResolver.resolve(assert: RustService.self)
        super.init(frame: .zero)
        setupSubViews()
        loadData()
        loadToolsInfoByToolIds()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubViews() {
        toolNameText.style.font(font)
        toolNameText.style.fontSize(.point(font.pointSize))
        self.addSubview(self.toolNameView)

        toolNameView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func loadData() {
        toolNameText.text = Self.getToolCotName(by: toolItem.toolName, status: toolStatus)
        let inlineElement = LKInlineElement(tagName: RichViewAdaptor.Tag.p)

        if toolStatus == .runing {
            let attachmentElement = LKAttachmentElement(style: LKRichStyle().display(.inlineBlock), attachment: loadingAttachment)
            inlineElement.children([toolNameText, attachmentElement])
        } else {
            inlineElement.children([toolNameText])
        }
        toolNameText.style.color(color)
        richViewCore.load(renderer: richViewCore.createRenderer(inlineElement))

        let size = richViewCore.layout(CGSize(width: maxWidth, height: CGFloat(MAXFLOAT))) ?? .zero
        toolNameView.frame = CGRect(origin: .zero, size: size)
        toolNameView.setRichViewCore(richViewCore)
    }

    private func loadToolsInfoByToolIds() {
        Self.logger.info("load loadingToolsInfo \(self.toolId)")
        self.getMyAIToolsInfo(toolIds: [self.toolId])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (tools) in
                Self.logger.info("load loadingToolsInfo success \(tools)")
                guard let self = self,
                        !tools.isEmpty,
                      let tool = tools.first(where: { info in
                          info.toolId == self.toolId
                      }) else { return }

                self.toolItem = tool
                self.loadData()
                self.toolsInfoCallBack?(tool, self.isRefresh)
            }, onError: { (error) in
                Self.logger.info("load loadingToolsInfo failure error: \(error)")
            }).disposed(by: self.disposeBag)
    }

    static func sizeToFit(toolName: String, toolStatus: MyAIToolCotState, maxWidth: CGFloat, font: UIFont) -> CGSize {

        let attachmentSize = CGSize(width: MyAILoadingView.size.width + Self.Cons.toolNameLabelRightMargin, height: MyAILoadingView.size.height)
        let loadingAttachment = LKAsyncRichAttachmentImp(size: attachmentSize, viewProvider: { () in
            // 虽然"..."高度只有8，但是我们外面还是包一层有一行高度的UIView，因为当一个内容都没有时，也可以让"..."撑起一行的高度，进而撑起气泡
            let view = UIView(frame: CGRect(origin: .zero, size: attachmentSize))
            let loadingView = MyAILoadingView.createView()
            loadingView.frame.origin.x = Self.Cons.toolNameLabelRightMargin
            loadingView.frame.origin.y = (attachmentSize.height - loadingView.frame.height) / 2
            view.addSubview(loadingView)
            return view
        }, ascentProvider: { _ in font.ascender }, verticalAlign: .baseline)

        let toolNameText = LKTextElement(text: Self.getToolCotName(by: toolName, status: toolStatus))
        toolNameText.style.font(font)
        toolNameText.style.fontSize(.point(font.pointSize))
        let inlineElement = LKInlineElement(tagName: RichViewAdaptor.Tag.p)
        if toolStatus == .runing {
            let attachmentElement = LKAttachmentElement(style: LKRichStyle().display(.inlineBlock), attachment: loadingAttachment)
            inlineElement.children([toolNameText, attachmentElement])
        } else {
            inlineElement.children([toolNameText])
        }
        let richViewCore = LKRichViewCore()

        richViewCore.load(renderer: richViewCore.createRenderer(inlineElement))

        let size = richViewCore.layout(CGSize(width: maxWidth, height: CGFloat(MAXFLOAT))) ?? .zero

        return size
    }

    static func getToolCotName(by toolName: String, status: MyAIToolCotState) -> String {
        return status == .success ? BundleI18n.LarkMessageCore.MyAI_IM_UsedSpecificExtention_Text(toolName) : BundleI18n.LarkMessageCore.MyAI_IM_UsingSpecificExtention_Text(toolName)
    }

    func getMyAIToolsInfo(toolIds: [String]) -> Observable<[MyAIToolInfo]> {
        guard let rustService = self.rustService else {
            return .just([])
        }
        var request = RustPB.Im_V1_MGetMyAIExtensionBasicInfoRequest()
        request.extensionIds = toolIds
        let response: Observable<RustPB.Im_V1_MGetMyAIExtensionBasicInfoResponse> = rustService.sendAsyncRequest(request)
        return response.flatMap { (res) -> Observable<[MyAIToolInfo]> in
            Observable.create { (observer) -> Disposable in
                let toolList = res.extensionList.map { MyAIToolInfo.transform(pb: $0) }
                observer.onNext(toolList)
                observer.onCompleted()
                return Disposables.create()
            }
        }
        .do(onNext: { (_) in
            Self.logger.info("Get myAIToolInfo success")
        }, onError: { (error) in
            Self.logger.error("Get myAIToolInfo error", error: error)
        })
    }

    deinit {
        print("MyAIToolsCotThinkingProcessView - deinit")
    }

}

extension MyAIToolsCotThinkingProcessView {
    enum Cons {
        static var toolNameLabelRightMargin: CGFloat { 8.auto() }
    }
}

public enum MyAIToolCotState: Int {
    case runing
    case success
    case failed
    public static func transform(pb: RustPB.Basic_V1_RichTextElement.MyAIToolProperty.Status) -> MyAIToolCotState {
        return MyAIToolCotState(rawValue: pb.rawValue) ?? .success
    }
}
