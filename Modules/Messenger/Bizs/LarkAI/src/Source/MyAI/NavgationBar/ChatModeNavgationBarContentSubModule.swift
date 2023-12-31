//
//  ChatModeNavgationBarContentSubModule.swift
//  LarkAI
//
//  Created by 李勇 on 2023/11/6.
//

import Foundation
import RxSwift
import RxCocoa
import ServerPB
import LarkModel
import LKRichView
import LarkOpenChat
import LarkRichTextCore
import LKCommonsLogging
import LarkMessengerInterface

/// MyAI分会场使用的ContentSubModule
final class ChatModeNavgationBarContentSubModule: BaseNavigationBarContentSubModule, ChatModeNavgationContentViewDelegate {
    private let logger = Logger.log(ChatModeNavgationBarContentSubModule.self, category: "Module.LarkAI")
    private var chatId: String = ""
    private var _contentView: ChatModeNavgationContentView?
    override var contentView: UIView? { return self._contentView }

    private let disposeBag = DisposeBag()

    override func createContentView(metaModel: ChatNavigationBarMetaModel) {
        guard self._contentView == nil, let pageService = try? self.context.userResolver.resolve(type: MyAIPageService.self) else { return }

        // 获取场景名，兜底展示「加载中...」
        let sceneName = pageService.chatModeScene.value.sceneName.isEmpty ? BundleI18n.LarkAI.MyAI_Scenario_MyScenarios_Loading_EmptyState : pageService.chatModeScene.value.sceneName
        self.logger.info("my ai navgation bar create content view, scene name: \(sceneName)")
        self.chatId = metaModel.chat.id
        self._contentView = ChatModeNavgationContentView(
            sceneName: sceneName,
            aiName: metaModel.chat.displayWithAnotherName,
            barStyle: self.context.navigationBarDisplayStyle()
        )
        self._contentView?.delegate = self
        // 监听场景变化，SDK存的可能是local的，后续需要刷新为remote的
        pageService.chatModeScene.observeOn(MainScheduler.instance).subscribe { [weak self] scene in
            guard let `self` = self, scene.sceneID != -1 else { return }
            // 获取场景名，兜底展示会话名
            let sceneName = scene.sceneName.isEmpty ? metaModel.chat.displayWithAnotherName : scene.sceneName
            self.logger.info("my ai navgation bar create content view, scene name change: \(sceneName)")
            self._contentView?.updateScene(sceneName: sceneName)
        }.disposed(by: self.disposeBag)
    }

    override func barStyleDidChange() {
        self._contentView?.updateBarStyle(barStyle: self.context.navigationBarDisplayStyle())
    }

    // MARK: - ChatModeNavgationContentViewDelegate
    func didClickMyAI(view: ChatModeNavgationContentView) {
        guard let chatVC = (try? self.context.userResolver.resolve(type: ChatOpenService.self))?.chatVC() else { return }

        let body = ChatControllerByBasicInfoBody(
            chatId: self.chatId,
            showNormalBack: false,
            isCrypto: false,
            isMyAI: true,
            chatMode: .default
        )
        // 分会场目前一定是包裹在导航控制器中的，MyAIServiceImpl+ChatMode-presentChatModeBlock，所以用push跳转没有问题
        self.userResolver.navigator.push(body: body, from: chatVC)
    }
}

/// 分会场自定义导航栏中间的ContentView
protocol ChatModeNavgationContentViewDelegate: AnyObject {
    func didClickMyAI(view: ChatModeNavgationContentView)
}
final class ChatModeNavgationContentView: UIView, LKRichViewDelegate {
    weak var delegate: ChatModeNavgationContentViewDelegate?
    /// 上面的名称，样式copy ChatTitleView
    private var chatTintColor: UIColor?
    private lazy var nameAttributes: [NSAttributedString.Key: Any] = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        // 设置attributedText默认不会显示省略号，需要自己主动设置
        paragraphStyle.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .medium),
            .foregroundColor: UIColor.ud.textTitle.chatTintColor(self.chatTintColor),
            .paragraphStyle: paragraphStyle
        ]
        return attributes
    }()
    private lazy var nameLabel: UILabel = UILabel()

    /// 下面的描述，目前内容很少，不需要考虑超出一行的情况；后续如果有这种情况，则copy ReferenceListLayout-fixElement代码
    private lazy var subTitleElement = LKInlineBlockElement(tagName: RichViewAdaptor.Tag.span)
    private lazy var subTitleView: LKRichView = LKRichView(frame: .zero, options: ConfigOptions([.debug(false)]))

    init(sceneName: String, aiName: String, barStyle: OpenChatNavigationBarStyle) {
        super.init(frame: .zero)
        // 设置名称
        self.nameLabel.numberOfLines = 1
        self.nameLabel.attributedText = NSAttributedString(string: sceneName, attributes: self.nameAttributes)
        self.addSubview(self.nameLabel)
        self.nameLabel.snp.makeConstraints { make in
            make.left.greaterThanOrEqualTo(0)
            make.top.centerX.equalToSuperview()
        }

        // 设置描述，添加「来自：」
        let fromStyle = LKRichStyle(); fromStyle.fontSize(.point(10)); fromStyle.color(UIColor.ud.textCaption)
        let fromElement = LKTextElement(style: fromStyle, text: BundleI18n.LarkAI.MyAI_FromAiName_Text(""))
        // 添加「MyAI」，href部分随便写一个，反正不需要用到具体内容
        let myAiStyle = LKRichStyle(); myAiStyle.fontSize(.point(10)); myAiStyle.color(UIColor.ud.textLinkNormal); myAiStyle.textDecoration(.init(line: [], style: .solid))
        let myAiElement = LKAnchorElement(tagName: RichViewAdaptor.Tag.a, style: myAiStyle, text: "", href: "to_main_chat").children([LKTextElement(text: aiName)])
        // 判断「来自：」、「MyAI」的顺序
        if self.fromStringIsFront() {
            self.subTitleElement.addChild(fromElement); self.subTitleElement.addChild(myAiElement)
        } else {
            self.subTitleElement.addChild(myAiElement); self.subTitleElement.addChild(fromElement)
        }
        // 计算占用的大小
        let subTitleCore = LKRichViewCore(); subTitleCore.load(renderer: subTitleCore.createRenderer(self.subTitleElement))
        let subTitleSize = subTitleCore.layout(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)) ?? .zero
        // 渲染描述内容
        self.subTitleView.bindEvent(selectorLists: [[CSSSelector(value: RichViewAdaptor.Tag.a)]], isPropagation: true)
        self.subTitleView.delegate = self
        self.subTitleView.setRichViewCore(subTitleCore)
        self.addSubview(self.subTitleView)
        self.subTitleView.snp.makeConstraints { make in
            make.left.greaterThanOrEqualTo(0)
            make.top.equalTo(self.nameLabel.snp.bottom).offset(2)
            make.width.equalTo(subTitleSize.width)
            make.height.equalTo(subTitleSize.height)
            make.bottom.centerX.equalToSuperview()
        }
    }

    /// 判断「来自：」是否在最前面
    private func fromStringIsFront() -> Bool {
        let fromAIString = BundleI18n.LarkAI.MyAI_FromAiName_Text(UUID().uuidString)
        let fromString = BundleI18n.LarkAI.MyAI_FromAiName_Text("")
        return fromAIString.hasPrefix(fromString)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func updateScene(sceneName: String) {
        // 如果名称和现在的一样，则不需要处理
        if let name = self.nameLabel.attributedText?.string, name == sceneName { return }

        self.nameLabel.attributedText = NSAttributedString(string: sceneName, attributes: self.nameAttributes)
    }

    public func updateBarStyle(barStyle: OpenChatNavigationBarStyle) {
        self.chatTintColor = barStyle.elementTintColor()
        self.nameAttributes[.foregroundColor] = UIColor.ud.textTitle.chatTintColor(self.chatTintColor)
        if let name = self.nameLabel.attributedText?.string {
            self.nameLabel.attributedText = NSAttributedString(string: name, attributes: self.nameAttributes)
        }
    }

    // MARK: - LKRichViewDelegate
    public func updateTiledCache(_ view: LKRichView, cache: LKTiledCache) {}
    public func getTiledCache(_ view: LKRichView) -> LKTiledCache? { return nil }
    public func shouldShowMore(_ view: LKRichView, isContentScroll: Bool) {}
    public func touchStart(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {}
    public func touchMove(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {}
    public func touchEnd(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {
        // 点击了"My AI"链接部分
        if element.tagName.typeID == RichViewAdaptor.Tag.a.rawValue {
            self.delegate?.didClickMyAI(view: self)
            event?.stopPropagation()
            return
        }
    }
    public func touchCancel(_ element: LKRichElement, event: LKRichTouchEvent?, view: LKRichView) {}
}

fileprivate extension UIColor {
    func chatTintColor(_ color: UIColor?) -> UIColor {
        return color ?? self
    }
}
