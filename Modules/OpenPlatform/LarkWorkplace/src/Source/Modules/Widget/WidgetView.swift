//
//  WidgetView.swift
//  LarkWorkplace
//
//  Created by 李论 on 2020/5/24.
//

import Foundation
import TTMicroApp
import LKCommonsLogging
import SwiftyJSON
import LarkContainer
import LarkAccountInterface

/// widget biz data flag
struct WidgetBizDataState {
    /// 上一次的业务数据
    var lastBizData: WidgetBizCacheData?
}
// MARK: widget状态标记
/*------------------------------------------*/
//            widget状态
/*------------------------------------------*/
/// 将所有状态标记集中在一起，控制逻辑集中在一起
struct StateLogicFlag {
    /// 开始启动加载
    var didTriggerLoad: Bool?
    /// Meta加载成功
    var metaLoadSuccess: Bool?
    /// config Info 加载成功
    var configInfoLoadSuccess: Bool?
    /// 开始加载卡片程序
    var didStartLoading: Bool?
    /// 加载卡片程序完成
    var didFinishLoading: Bool?
    /// 加载完成，但是遇到了错误
    var didFinishLoadingWithError: Bool?
    /// 客户端版本不支持
    var clientVerNotSupport: Bool?
    /// JSRuntime 准备好了
    var didPrepareJSRuntime: Bool?
    /// widget Data设置进去了
    var didSetWidgetData: Bool?
    /// 运行中遇到错误
    var didRunningWithError: Bool?
    /// 加载widget业务数据错误
    var didLoadWidgetDataWithError: Bool?
    /// biz data flag
    var widgetBizDataFlag: WidgetBizDataState = WidgetBizDataState()
}

/// widget统计信息
struct WidgetViewMetrics {
    var startDate: Date?
    var renderFinishDate: Date?

    mutating func clear() {
        startDate = nil
        renderFinishDate = nil
    }
}
/// widget版本不支持的错误
let widgetVersionErrCode: Int = 1_001
/// widget标示Key
let widgetTagKey: String = "widgetTag"

/// 传递给 Lynx View 的 data key：是否使用 px 作为尺寸单位
let kBizDataKeyPxMode = "isPxMode"
/// 传递给 Lynx View 的 data key：widget 宽度
let kBizDataKeyContainerW = "containerWidthPx"

final class WidgetView: UIView {
    // MARK: widget相关属性
    /// widget依赖的数据模型
    var widgetModel: WidgetModel
    /// widget业务数据请求逻辑，公共逻辑
    var widgetDataManage: WidgetDataManage
    /// widget业务数据刷新逻辑
    var widgetData: WidgetBizDataUpdate?
    /// widget加载中的状态变量
    var flag: StateLogicFlag = StateLogicFlag()
    /// widgetConfig
    var widgetConfig: WidgetConfig?
    /// 上报参数
    var metrics = WidgetViewMetrics()
    /// op monitor
    var widgetRender: OPMonitor?
    /// 上一次点击的时间
    var lastClickTime: Date?
    /// 点击间隔时间（频率控制）
    let clickTimeInterval: Double = 0.5
    /// 正常hitTest时间窗口
    let hitTestTimeWindow: Double = 0.005

    // TODO: 即将下线的业务，暂时直接拿 userResovler
    private var userService: PassportUserService? {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: WorkplaceScope.userScopeCompatibleMode)
        let userService = try? userResolver.resolve(assert: PassportUserService.self)
        return userService
    }

    var tenantId: String? {
        return userService?.userTenant.tenantID
    }

    static let log = Logger.log(WidgetView.self)
    /// cardUrl中是否展示header的参数（后端协议字段）
    static let noHeaderQueryKey: String = "no_header"
    /// cardUrl中不展示header的参数值（后端协议字段）
    static let noHeaderValue: String = "1"
    /// Widget 状态，stateView 观察这个状态的变化来展示对应的状态
    var state: WidgetUIState {
        didSet {
            Self.log.info("\(widgetModel.name) state switch to \(state)")
            if state == .loading {
                metrics.startDate = Date()
            }
            if oldValue != state, state == .running {
                let costTime = Int(Date().timeIntervalSince(metrics.startDate ?? Date()) * 1_000)
                WPMonitor().setCode(WPMCode.workplace_widget_render_success)
                    .setRenderCost(costTime: costTime)
                    .setWidgetTag(appName: widgetModel.name, appId: meta?.uniqueID.appID, widgetVersion: meta?.version)
                    .postSuccessMonitor()
                WPEventReport(
                    name: WPEvent.widget_rendering.rawValue,
                    userId: userId,
                    tenantId: tenantId
                )
                .set(key: WPEventNewKey.appId.rawValue, value: self.meta?.uniqueID.appID ?? "")
                .set(key: "is_suecess", value: 1)   // true
                .post()
                widgetModel.renderCallback?(true)
            }
            if oldValue != state, state == .loadFail {
                WPEventReport(
                    name: WPEvent.widget_rendering.rawValue,
                    userId: userId,
                    tenantId: tenantId
                )
                .set(key: WPEventNewKey.appId.rawValue, value: self.meta?.uniqueID.appID ?? "")
                .set(key: "is_suecess", value: 0)   // false
                .post()
                WPMonitor().setCode(WPMCode.workplace_widget_render_fail)
                    .setWidgetTag(appName: widgetModel.name, appId: meta?.uniqueID.appID, widgetVersion: meta?.version)
                    .setError(errMsg: "widget state switch to Fail, for details workplace_widget_fail")
                    .postFailMonitor()
                widgetModel.renderCallback?(false)
            }
            DispatchQueue.main.async {
                self.stateView.state = self.state
            }
        }
    }
    /// Card Scheme
    let cardUrl: URL
    /// Card Meta
    var meta: CardMeta? {
        didSet {
            /// 更新当前meta的上下文，记录当前加载的widget，作为唯一值
            metaUpdateTime = "\(Date().timeIntervalSince1970)"
                + "_\(meta?.uniqueID.appID ?? "")"
                + "_\(meta?.version ?? "")"
        }
    }
    /// header link click callback
    var headerClick: ((String?) -> Void)?
    var metaUpdateTime: String?
    // MARK: widget的视图组件
    /// Card Container
    /// 管理CardView的生命周期，事件交互
    private lazy var cardContainer: CardContainer = {
        CardContainer(
            schema: cardUrl,
            cardInfoListener: self,
            cardLifeCyclelistener: self,
            cardFrame: self.bounds
        )
    }()
    /// Nav View
    /// nav: icon, name, arrow
    lazy var navBar: WidgetNavBar = {
        let bar = WidgetNavBar(
            iconUrl: widgetModel.iconKey,
            mainTitle: widgetModel.name,
            frame: .zero
        )
        bar.titleClick = { [weak self] in
            self?.handleHeaderClick()
        }
        bar.expandClick = { [weak self] (btn) in
            self?.handleExpandClick(sender: btn)
        }
        return bar
    }()

    /// State View
    /// state: loading, loadFailed, empty
    private lazy var stateView: WidgetStateView = {
        let stateView = WidgetStateView(frame: self.bounds, state: self.state)
        stateView.faildRetryAction = { [weak self] in
            self?.loadCard()
        }
        return stateView
    }()

    /// 计算 navBar 高度
    private var navBarHeight: CGFloat {
        return ItemModel.widgetNavBarHeight
    }

    let userId: String

    // MARK: widget初始化
    /// 初始化方法
    /// - Parameters:
    ///   - cardUrl: cardSchema对应的URL
    ///   - model: widgetView所依赖的model
    ///   - frame: 视图frame
    init(
        userId: String,
        cardUrl: URL,
        model: WidgetModel,
        widgetDataManage: WidgetDataManage,
        frame: CGRect
    ) {
        Self.log.info("WidgetView init with url \(cardUrl)")
        self.userId = userId
        self.widgetModel = model
        self.cardUrl = cardUrl
        self.state = .loading
        self.widgetDataManage = widgetDataManage
        super.init(frame: frame)
        setupInitViews()
        navBar.setExpand(expand: model.widgetContainerState.isExpand)
    }

    /// 默认方式实现
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        if navBar.superview == self {
            navBar.snp.updateConstraints({ (make) in
                make.height.equalTo(self.navBarHeight)
            })
        }
        super.updateConstraints()
    }

    override var bounds: CGRect {
        willSet {
            if !isDisplayHeader() && !bounds.equalTo(.zero) && !bounds.equalTo(newValue) {
                // 修复 iPad Banner bug: 当容器 size 改变时，重新加载卡片
                loadCard()
            }
        }
    }

    /// 初始化widgetView
    private func setupInitViews() {
        clipsToBounds = true
        if isDisplayHeader() {
            layer.cornerRadius = WorkPlaceWidgetCell.widgetRadius
            layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            addSubview(navBar)
            navBar.snp.makeConstraints { (make) in
                make.left.top.right.equalToSuperview()
                make.height.equalTo(self.navBarHeight)
            }
            addSubview(stateView)
            stateView.snp.makeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
                make.top.equalTo(navBar.snp.bottom)
            }
        } else {
            layer.cornerRadius = WorkPlaceWidgetCell.widgetRadius
            layer.maskedCorners = [
                .layerMinXMinYCorner,
                .layerMinXMaxYCorner,
                .layerMaxXMinYCorner,
                .layerMaxXMaxYCorner
            ]
            addSubview(stateView)
            stateView.snp.makeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
                make.top.equalToSuperview().offset(20)
            }
        }
    }

    /// 设置Card Container View
    private func setupCardContainerView() {
        if cardContainer.view.superview == nil {
            addSubview(cardContainer.view)
            setupCardConstraint()
            bringSubviewToFront(stateView)
        }
    }

    private func setupCardConstraint() {
        if isDisplayHeader() {
            cardContainer.view.snp.makeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
                make.top.equalTo(navBar.snp.bottom)
            }
        } else {
            cardContainer.view.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }

    /// 是否展示header
    private func isDisplayHeader() -> Bool {
        if let noHeader = cardUrl.queryParameters[WidgetView.noHeaderQueryKey],
            noHeader == WidgetView.noHeaderValue {
            return false
        } else {
            return true
        }
    }

    /// 开始加载卡片
    func loadCard() {
        Self.log.info("[\(widgetModel.name)] loadCard start")
        /// 初始化状态配置
        state = .loading
        flag = StateLogicFlag()
        /// 配置布局
        setupCardContainerView()
        /// 加载
        cardContainer.loadWithSchema()
        /// 标记启动加载了
        updateFlag { (flag) in
            flag.didTriggerLoad = true
        }
    }

    func reloadCardIfNeed() {
        Self.log.info("[\(widgetModel.name)] reloadCardIfNeed start")
        cardContainer.updateCard()
    }

    /// 更新业务数据
    func updateCardData(widgetData: String?) {
        Self.log.info("updateCardData \(widgetModel.name)")
        if let widgetDic = mergeBizData(widgetData: widgetData) {
            cardContainer.cardRenderEngine.updateCard(with: widgetDic)
        } else {
            cardContainer.cardRenderEngine.updateCard(with: widgetData)
        }
        /// 标记业务数据加载成功
        updateFlag { (flag) in
            /// 如果一开始业务数据加载失败，后面又接收到正常的业务数据，那么将接收业务数据错误设置空
            flag.didLoadWidgetDataWithError = nil
            flag.didSetWidgetData = true
        }
    }
    /// 更新业务数据
    func updateCardData(widgetData: [String: Any]) {
        Self.log.info("updateCard \(widgetModel.name) card data")
        cardContainer.cardRenderEngine.updateCard(with: widgetData) // 通知渲染引擎根据业务数据进行更新
    }
    /// 获取业务数据 + state 状态数据一起的合并后数据
    private func mergeBizData(widgetData: String?) -> [String: Any]? {
        if let jsonString = widgetData,
            let jsonData = jsonString.data(using: .utf8),
            var bizDic: [String: Any] = try? JSONSerialization.jsonObject(
                with: jsonData,
                options: .mutableLeaves
            ) as? [String: Any] {
            for (k, v) in expandStateDic() {
                bizDic[k] = v
            }
            if bizDic["duration"] != nil {
                print("\(String(describing: bizDic["duration"]))")
            }
            bizDic[kBizDataKeyPxMode] = true
            bizDic[kBizDataKeyContainerW] = self.bounds.size.width
            return bizDic
        } else {
            /// 异常逻辑,更新的widget数据不能解析为json
            Self.log.error("[\(widgetModel.name)] mergeBizData dizDic or jsonData or jsonString is nil")
            OPMonitor(WPMWorkplaceCode.workplace_widget_runing)
            .addCategoryValue("app_id", self.meta?.uniqueID.appID ?? "")
            .addCategoryValue("app_name", self.widgetModel.name)
            .addCategoryValue("app_version", self.meta?.version ?? "")
            .setErrorMessage("mergeBizData dizDic or jsonData or jsonString is nil")
            .flush()
        }
        return nil
    }
}

/// 状态变化更新逻辑
extension WidgetView {
    /// 卡片更新
    func updateFlag(updateFlag: (_ flag: inout StateLogicFlag) -> Void) {
        /// 先更新标记位
        updateFlag(&flag)
        /// 判断当前版本是否支持
        if flag.clientVerNotSupport ?? false {
            /// 当前客户端版本低于Meta要求的最低版本，widget不展示
            Self.log.info("current version not support widgetCard")
            self.state = .updateTip
            return
        }
        /// 判断当前容器需要展示的状态
        if flag.didFinishLoadingWithError ?? false {
            /// 加载Meta或者包遇到错误，widget切换到loadFail状态
            Self.log.info("[\(widgetModel.name)] display loadFail because didFinishLoadingWithError")
            self.state = .loadFail
        }

        if needBusinessData() && (flag.didLoadWidgetDataWithError ?? false) {
            /// 加载widget业务数据失败，显示失败
            Self.log.info("[\(widgetModel.name)] display loadFail because didLoadWidgetDataWithError")
            WPMonitor().setCode(WPMCode.workplace_widget_fail)
                .setError(errMsg: "need BizData, but it load failed (didLoadWidgetDataWithError)")
                .postFailMonitor()
            self.state = .loadFail
        }

        if !needBusinessData() || (flag.didSetWidgetData ?? false) {
            /// 已经设置了widget数据，说明js加载完成了，数据也设置进去了
            Self.log.info("[\(widgetModel.name)] display complete")
            self.state = .running
            OPMonitor(WPMWorkplaceCode.workplace_widget_display_success)
            .setResultType("success")
            .flush()
        }
        /// 设置是否支持展开
        DispatchQueue.main.async {
            self.navBar.setCanExpand(enable: self.supportExpand())
        }
    }
    /// widget开始渲染的标记
    func markStartRender() {
        if widgetRender == nil {
            widgetRender = OPMonitor(WPMWorkplaceCode.workplace_widget_render).timing()
        }
    }
    /// 点击频控
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        /// 存在上一次打开的时间戳，本次时间间隔不在hitTest窗口期，但小于频控时间；触发频控
        if let lastTime = lastClickTime,
           Date().timeIntervalSince(lastTime) < clickTimeInterval,
           Date().timeIntervalSince(lastTime) > hitTestTimeWindow {
            return nil
        } else {
            lastClickTime = Date()
            return super.hitTest(point, with: event)
        }
    }
}
