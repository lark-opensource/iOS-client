//
//  UniversalCardLynxPersonListView.swift
//  LarkMessageCard
//
//  Created by ByteDance on 2023/6/14.
//

import Foundation
import Lynx
import LarkUIKit
import LKCommonsLogging
import LKRichView
import EENavigator
import LarkContainer
import UniversalCardInterface
import LarkAccountInterface

fileprivate typealias PersonListData = (
    tag: String?,
    id: String?,
    persons: [Person]?,
    core: LKRichViewCore,
    clickable: Bool
)

public final class UniversalCardLynxPersonListViewShadowNode: LynxShadowNode, LynxCustomMeasureDelegate {

    public static let name: String = "msg-card-person-list"
    private static let logger = Logger.log(
        UniversalCardLynxPersonListViewShadowNode.self,
        category: "UniversalCardLynxPersonListViewShadowNode"
    )
    private let core = LKRichViewCore()
    private var props: PersonListProps?
    private var limitWidth: CGFloat?
    
    private var element: LKRichElement?
    // 重载构造函数
    override init(sign: Int, tagName: String) {
        super.init(sign: sign, tagName: tagName)
        customMeasureDelegate = self
    }
    
    @objc public static func propSetterLookUp() -> [[String]] {
        return [
            ["props", NSStringFromSelector(#selector(setProps))],
        ]
    }
    
    // 代理函数必须实现, 但目前不需要, 无具体实现
    public func align(with param: AlignParam, alignContext context: AlignContext) {}
    
    public func measure(with param: MeasureParam, measureContext context: MeasureContext?) -> MeasureResult {
        let (width, widthMode, height, heightMode ) = (param.width, param.widthMode, param.height, param.heightMode)
        let originSize: CGSize = CGSize(width: width, height: height)
        // 在宽或高为未定义的情况下,给与最大值, 由 richcore 计算宽高
        // 潜在前提, 前端必须至少提供宽或高其中一个值, 否者无法正常进行计算 (可以通过 originSize 进行调试)
        let measureSize = CGSize(
            width: widthMode == .indefinite ? CGFloat.greatestFiniteMagnitude : width,
            height: heightMode == .indefinite ? CGFloat.greatestFiniteMagnitude : height
        )
        //先 setuprichcore 后 layout
        limitWidth = measureSize.width
        let textSize = setupRichCoreIfNeeded().layout(measureSize)
        return MeasureResult(size: textSize ?? originSize, baseline: 0)
    }

    // 实现属性响应，响应的属性为 props，方法名称为 setProps，通过 setNeedsLayout() 触发排版。
    @objc private func setProps(props: Any?, requestReset _: Bool) {
        guard let props = props as? [String: Any] else {
            assertionFailure("UniversalCardLynxPersonListViewShadowNode receive wrong props type: \(String(describing: props.self))")
            Self.logger.error("UniversalCardLynxPersonListViewShadowNode receive wrong props type: \(String(describing: props.self))")
            return
        }
        do {
            let personListProps = try PersonListProps.from(dict: props)
            self.props = personListProps
        } catch let error {
            Self.logger.error("UniversalCardLynxPersonListViewShadowNode props serilize fail: \(error.localizedDescription)")
            assertionFailure("UniversalCardLynxPersonListViewShadowNode props serilize fail: \(error.localizedDescription)")
        }
        setNeedsLayout()
    }
    
    private func setupRichCoreIfNeeded() -> LKRichViewCore {
        guard let props = props, let limitWidth = limitWidth, limitWidth > 0 else {
            Self.logger.error("UniversalCardLynxPersonListViewShadowNode props or limitWidth not ready")
            return core
        }
        let element = LKRichElement.richElement(
            formPersonListProps: props,
            limitWidth: limitWidth
        )
        self.element = element
        core.load(styleSheets: createStyleSheets())
        let renderer = core.createRenderer(element)
        core.load(renderer: renderer)
        return core
    }
    
    public override func getExtraBundle() -> Any {
        let data: PersonListData = (
            tag: props?.tag,
            id: props?.id,
            persons: props?.persons,
            core: core,
            clickable: true
        )
        return data
    }
}

public final class UniversalCardLynxPersonListView: LynxUIView {
    public static let name: String = "msg-card-person-list"
    private static let logger = Logger.log(UniversalCardLynxPersonListView.self, category: "UniversalCardLynxPersonListView")
    private static let universalCardCopyableBaseKey = "universalCardCopyableBaseKey"

    private var cardContext: UniversalCardContext?
    
    private weak var targetElement: LKRichElement?
    
    private var clickable: Bool = true
    private var tag: String?
    private var id: String?
    fileprivate var persons: [Person]?
    
    public override func ignoreFocus() -> Bool { true }
    
    // fix 复制选中态，点击大头针时点到父组件上,  因此扩大组件的点击范围
    public override func contains(_ point: CGPoint, inHitTestFrame:CGRect) -> Bool {
        let frame = inHitTestFrame.inset(by: UIEdgeInsets(edges: CursorSize ))
        return super.contains(point, inHitTestFrame: frame)
    }
    
    private let propagationSelectors: [[CSSSelector]] = [
        [CSSSelector(value: Tag.container)],
        [CSSSelector(value: Tag.person)],
        [CSSSelector(value: Tag.more)],
    ]
    
    private lazy var richContainerView: LKRichContainerView = {
        let richContainerView = LKRichContainerView(options: RichViewConfig)
        richContainerView.richView.displayMode = .sync
        richContainerView.richView.delegate = self
        richContainerView.richView.bindEvent(selectorLists: propagationSelectors, isPropagation: true)
        return richContainerView
    }()
    
    @objc
    public static func propSetterLookUp() -> [[String]] {
        return [
            ["props", NSStringFromSelector(#selector(setProps))],
            ["context", NSStringFromSelector(#selector(setContext))],
        ]
    }
    
    @objc public override func createView() -> LKRichContainerView? {
        return richContainerView
    }
    
    public override func onReceiveOperation(_ value: Any?) {
        guard let data = value as? PersonListData else {
            Self.logger.info("UniversalCardLynxPersonListView Receive Wrong type: \(value.self ?? "")")
            return
        }
        tag = data.tag
        id = data.id
        persons = data.persons
        clickable = data.clickable
        self.richContainerView.setNeedsDisplay()
        DispatchQueue.main.async { self.richContainerView.richView.setRichViewCore(data.core) }
    }
    
    @objc func setProps(props: Any?, requestReset _: Bool) {
        // 空实现, 绑定 lynx 前端组件属性. ShadowNode 的 props 与此值一致
        // 为避免对富文本重复计算, ShadowNode -layoutDidUpdate 会将 core 传过来, 在 ReceiveOperation 中处理
    }
    
    @objc func setContext(context: Any?, requestReset _: Bool) {
        // 空实现, 绑定 lynx 前端组件属性. ShadowNode 的 context 与此值一致
        // 为避免对富文本重复计算, ShadowNode -layoutDidUpdate 会将 core 传过来, 在 ReceiveOperation 中处理
        guard let cardContext = getCardContext() else {
            assertionFailure("UniversalCardLynxPersonListView get cardContext fail")
            return
        }
        if let dependency = cardContext.dependency {
            richContainerView.componentKey = dependency.copyableKeyPrefix + (id ?? UUID().uuidString)
        }
        self.cardContext = cardContext
    }
}

extension UniversalCardLynxPersonListView: LKRichViewDelegate {
    
    public func updateTiledCache(_ view: LKRichView, cache: LKTiledCache) {
    }

    public func getTiledCache(_ view: LKRichView) -> LKTiledCache? {
        return nil
    }

    public func shouldShowMore(_ view: LKRichView, isContentScroll: Bool) {
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
        // 只响应源和目标相同的点击事件,忽略滑动等
        guard event?.target === event?.source, targetElement === event?.source else { return }
        switch element.tagName.typeID {
        case Tag.more.rawValue where clickable:
            handleTagMoreEvent(element, event: event)
        case Tag.person.rawValue where clickable:
            handleTagPersonEvent(element, event: event)
        default:
            // 只有内部可点击, 并且点击区域在可点击范围外才向前段发消息
            guard clickable else { return }
            context?.rootUI?.lynxView?.sendGlobalEvent("dispatchTapEvent", withParams: [])
        }
    }
    
    func handleTagMoreEvent(_ element: LKRichElement, event: LKRichTouchEvent?) {
        guard let cardContext = cardContext,
              let actionService = cardContext.dependency?.actionService,
              let sourceVC = cardContext.sourceVC else { return }
        guard let persons = persons else { return }
        let context = UniversalCardActionContext(
            trace: cardContext.renderingTrace?.subTrace() ?? cardContext.trace.subTrace(),
            elementTag: tag,
            elementID: id,
            bizContext: cardContext.bizContext,
            actionFrom: .innerLink()
        )
        let vc = UniversalCardAvatarListViewController(persons: persons)
        vc.openProfile = { [weak self, weak vc] id in
            guard let sourceVC = self?.cardContext?.sourceVC else { return }
            self?.cardContext?.dependency?.actionService?.openProfile(
                context: context,
                id: id,
                from: vc ?? sourceVC
            )
        }        // 在显示列表后再去拉取一次最新的, 保证获取到远端的用户信息
        actionService.fetchUsers(context: context, ids: persons.map({ $0.id ?? ""})) {[weak vc] error, info in
            guard let info = info else {
                Self.logger.error("UniversalCardLynxPersonListView fetchUsers fail with error: \(error?.localizedDescription ?? "nil")")
                return
            }
            let newPersons = persons.map {
                var avatarKey = $0.avatarKey
                if let id = $0.id, let key = info[id]?.avatarKey {
                    avatarKey = key
                }
                return Person(
                    id: $0.id,
                    type: $0.type,
                    tag: $0.tag,
                    content: $0.content,
                    avatarKey: avatarKey
                )
            }
            vc?.updatePerson(persons: newPersons)
        }
        
        cardContext.dependency?.userResolver?.navigator.present(
            vc,
            wrap: LkNavigationController.self,
            from: sourceVC,
            prepare: { $0.modalPresentationStyle = .formSheet }
        )
    }

    func handleTagPersonEvent(_ element: LKRichElement, event: LKRichTouchEvent?) {
        guard let cardContext = cardContext,
              let actionService = cardContext.dependency?.actionService,
                let sourceVC = cardContext.sourceVC else { return }
        let actionContext = UniversalCardActionContext(
            trace: cardContext.renderingTrace?.subTrace() ?? cardContext.trace.subTrace(),
            elementTag: tag,
            elementID: id,
            bizContext: cardContext.bizContext,
            actionFrom: .innerLink()
        )
        actionService.openProfile(context: actionContext, id: element.id, from: sourceVC)
    }
    
}
