//
//  WorkPlaceWidgetCell.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/5/8.
//

import LarkUIKit
import RustPB
import LKCommonsLogging
import LarkInteraction
import LarkSetting
import LarkContainer

/// 工作台Widget的Cell
final class WorkPlaceWidgetCell: WorkplaceBaseCell, UIGestureRecognizerDelegate {
    static let logger = Logger.log(WorkPlaceWidgetCell.self)

    // MARK: Cell properties
    /// widget内容
    var widgetView: WidgetView?
    /// 长按操作
    var longPressAction: ((WorkPlaceWidgetCell) -> Void)?
    static let widgetRadius: CGFloat = 12.0
    /// widget report
    var widgetDisplayReport: (() -> Void)?

    // 正在推进下线的业务，直接取 userResoler
    private var enableWidgetComponentFallback: Bool {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: WorkplaceScope.userScopeCompatibleMode)
        let configService = try? userResolver.resolve(assert: WPConfigService.self)
        return configService?.fgValue(for: .enableWidgetComponentFallback) ?? false
    }

    // MARK: cell initial
    override init(frame: CGRect) {
        super.init(frame: frame)
        if enableWidgetComponentFallback {
            let fallbackView = ComponentFallbackView()
            contentView.addSubview(fallbackView)
            fallbackView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        setupContentView() // 这里只初始化外部样式，widgetView通过refresh实现
        setupGestureRecognizer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupGestureRecognizer() {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleGesture(gesture:))
        )
        self.addGestureRecognizer(longPressGestureRecognizer)
        longPressGestureRecognizer.delegate = self
        let rightClick = RightClickRecognizer(target: self, action: #selector(handleGesture(gesture:)))
        self.addGestureRecognizer(rightClick)
        rightClick.delegate = self
    }
    @objc
    private func handleGesture(gesture: UIGestureRecognizer) {
        if (gesture is UILongPressGestureRecognizer && gesture.state == .began) ||
            (gesture is RightClickRecognizer && gesture.state == .began) {
            longPressAction?(self)
        }
    }
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
    /// 避免Lynx内部的长按手势对外部的cell的长按的影响
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if let view = otherGestureRecognizer.view, String(describing: view.self).contains("Lynx") {
            return true
        }
        return false
    }

    override func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        return super.preferredLayoutAttributesFitting(layoutAttributes)
    }

    // MARK: cell layout
    /// 设置contenView样式（cell）
    private func setupContentView() {
        contentView.backgroundColor = UIColor.ud.bgFloat.alwaysLight
        contentView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        contentView.layer.borderWidth = 0.5
        contentView.layer.ud.setShadowColor(UIColor.ud.shadowDefaultLg)
        contentView.layer.shadowOffset = CGSize(width: 0.0, height: 8.0)
        contentView.layer.shadowOpacity = 1.0
        contentView.layer.shadowRadius = 16
        contentView.layer.cornerRadius = WorkPlaceWidgetCell.widgetRadius
    }

    /// 设置views
    private func setupViews() {
        /// widget的布局
        guard let card = widgetView else {
            Self.logger.error("widgetView not ready, widgetCell layout failed")
            return
        }
        contentView.addSubview(card)
        card.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    /// de reuse widget
    private func deReuseWidget(widgetViewCache: NSCache<NSString, UIView>, widgetView: WidgetView?) {
        if let widgetView = widgetView {
            widgetViewCache.setObject(
                widgetView,
                forKey: widgetView.cardUrl.absoluteString as NSString
            )
        }
    }

    /// 数据就位，widget刷新（widget应该有一种默认状态，然后数据就位了，才进行刷新）
    func refresh(
        userId: String,
        widgetModel: WidgetModel,
        widgetDataManage: WidgetDataManage,
        widgetViewCache: NSCache<NSString, UIView>
    ) {
        Self.logger.info("WorkPlaceWidgetCell refresh \(enableWidgetComponentFallback)")
        guard !enableWidgetComponentFallback else { return }

        /// 必须要有cardSchema才能加载刷新widgetView
        guard let widgetUrl = URL(string: widgetModel.cardSchema) else {
            Self.logger.error("cardSchema(\(widgetModel.cardSchema)) parse failed, no fresh widget")
            return
        }
        Self.logger.info("[\(widgetModel.name)]widget start to refresh")
        /// 如果widgetView为空或者因为复用导致的widget内容和当前的model不一致的时候，新建
        if let widgetViewExpandCache = widgetModel.widgetContainerState.getWidgetViewCache() {
            Self.logger.debug("[\(widgetModel.name)]widget's cache is ready，reuse cache to refresh")
            if widgetView?.superview == self.contentView {  // 要判定是当前cell的子view才移除，否则会导致别的cell失去自己的子view
                widgetView?.removeFromSuperview()   // 注意：把之前的widgetView给移除，否则这个旧widgetView会盖在上面
            }
            widgetView = widgetViewExpandCache
            setupViews()
        } else if !isCardUrlEqual(sourceUrl: widgetView?.cardUrl, targetUrl: widgetUrl) {
            /// 新的widget
            if widgetView?.superview == self.contentView {  // 要判定是当前cell的子view才移除，否则会导致别的cell失去自己的子view
                widgetView?.removeFromSuperview()   // 注意：把之前的widgetView给移除，否则这个旧widgetView会盖在上面
            }
            deReuseWidget(widgetViewCache: widgetViewCache, widgetView: widgetView)
            /// 尝试复用其他cell中的widgetview
            widgetView = widgetViewCache.object(forKey: widgetUrl.absoluteString as NSString) as? WidgetView
            Self.logger.info(
                "[\(widgetUrl.absoluteString)] get cache:[\(widgetView?.widgetModel.name)]"
            )
            if widgetView == nil {
                Self.logger.debug("[\(widgetUrl.absoluteString)] get cache failed，new widgetView")
                /// 如果复用失败，那么直接新建一个
                widgetView = WidgetView(
                    userId: userId,
                    cardUrl: widgetUrl,
                    model: widgetModel,
                    widgetDataManage: widgetDataManage,
                    frame: contentView.bounds
                )
            } else {
                Self.logger.debug("[\(widgetUrl.absoluteString)] get cache success, clean cache")
                widgetViewCache.removeObject(forKey: widgetUrl.absoluteString as NSString)
            }
            setupViews()
            Self.logger.info("[\(widgetModel.name)] widget view create with \(widgetUrl)")
        } else {
            Self.logger.debug("[\(widgetModel.name)]is current widget, don't need cache")
        }
        Self.logger.debug("[\(widgetModel.name)] ready to fresh style，state: \(widgetView?.state)")
        /// 如果上次复用的，展示的还是上次的那个widget
        if isCardUrlEqual(sourceUrl: widgetView?.cardUrl, targetUrl: widgetUrl),
            widgetView?.state == .running {
            Self.logger.debug("[\(widgetModel.name)] reuse last style")
            widgetView?.reloadCardIfNeed()
            widgetView?.updateWidgetBizData()
        } else {
            /// 重新加载卡片数据
            Self.logger.debug("[\(widgetModel.name)] reload card's style")
            widgetView?.loadCard()  // 加载卡片样式   ⚠️可能会触发cardSize的变化
        }
        /// 刷新widget
        Self.logger.debug("refresh widget's expand config data")
        widgetView?.updateBizDataForExpand(state: widgetModel.widgetContainerState)
    }
    /// 更新header点击事件
    func setHeaderClick(callback: ((String?) -> Void)?) {
        Self.logger.info("WorkPlaceWidgetCell setHeaderClick \(enableWidgetComponentFallback)")
        guard !enableWidgetComponentFallback else { return }
        widgetView?.headerClick = callback
    }
    /// expand button simulate click
    func expandButtonClick() {
        Self.logger.info("WorkPlaceWidgetCell expandButtonClick \(enableWidgetComponentFallback)")
        guard !enableWidgetComponentFallback else { return }
        widgetView?.simulateExpand()
    }
    /// 判断俩个cardURL是否相等（老的逻辑是直接判断两个url是否相等）
    private func isCardUrlEqual(sourceUrl: URL?, targetUrl: URL) -> Bool {
        guard let url = sourceUrl else {
            return false
        }
        if url.queryParameters["app_id"] == targetUrl.queryParameters["app_id"],
           url.queryParameters["card_id"] == targetUrl.queryParameters["card_id"] {
            return true
        } else {
            return false
        }
    }
    /// on badge update
    override func onBadgeUpdate() {
        Self.logger.info("WorkPlaceWidgetCell onBadgeUpdate \(enableWidgetComponentFallback)")
        guard !enableWidgetComponentFallback else { return }
        if Thread.isMainThread {
            self.widgetView?.navBar.setBadgeNum(num: self.getBadge())
        } else {
            DispatchQueue.main.async {
                self.widgetView?.navBar.setBadgeNum(num: self.getBadge())
            }
        }
    }
}
