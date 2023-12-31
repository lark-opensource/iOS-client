//
//  OPBlockContainerRouter.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/3.
//

import Foundation
import SnapKit
import OPSDK
import ECOProbe
import LKCommonsLogging
import OPBlockInterface
import UIKit
import LarkContainer

/// OPBlockContainerRouterDelegate
@objc protocol OPBlockContainerRouterDelegate: AnyObject {
    func onContainerViewSizeChange(old: CGSize, new: CGSize)
}

/// OPBlockContainerRouterProtocol
public protocol OPBlockContainerRouterProtocol: OPRouterProtocol {
    /// 当前的容器视图
    var containerView: UIView { get }
    /// 切换当前 Component，会改变 currentComponent
    func switchToComponent(parentNode: OPNodeProtocol, component: OPComponentProtocol, initData: OPComponentDataProtocol) throws
}

/// OPBlockContainerRouterShowErrorProtocol，专用于展示错误页的接口
public protocol OPBlockContainerRouterShowErrorProtocol {
    // status view
    func showStatusView(item: GuideInfoStatusViewItem)
    func hideStatusView()
    func isShowingStatusView() -> Bool

    // error page
    func showErrorPage(
        errorPageCreator: @escaping OPBlockErrorPageCreator,
        isFromHost: Bool,
        errorMessage: String,
        buttonText: String?,
        onButtonClicked: (()->Void)?,
        success: ((Bool)->Void)?,
        failure: (()->Void)?
    )
    func hideErrorPage(
        success: ((Bool)->Void)?,
        failure: (()->Void)?
    )
    func isShowingErrorPage() -> Bool
}

/// router
@objcMembers
public final class OPBlockContainerRouter: NSObject, OPBlockContainerRouterProtocol {
    
    public private(set) var currentComponent: OPComponentProtocol?
    
    private private(set) var currentComponentRenderSlot: OPViewRenderSlot?
    
    weak var delegate: OPBlockContainerRouterDelegate?
    
    @objc dynamic public let containerView: UIView = UIView()

    private var statusView: UIView?

    private var errorPage: OPBaseBlockErrorPage?
    private var isErrorPageFromHost: Bool = false
    private var onButtonClickedHandler: (()->Void)?
    
    private var observation: NSKeyValueObservation?

    private var context: OPContainerContext
    private let userResolver: UserResolver

    private var trace: BlockTrace {
        context.blockTrace
    }

    private let blockComponentUtils: BlockComponentUtils
    
    public init(context: OPContainerContext, userResolver: UserResolver) {
        self.context = context
        self.userResolver = userResolver
        self.blockComponentUtils = BlockComponentUtils(
            blockWebComponentConfig: userResolver.settings.staticSetting(),
            apiConfig: userResolver.settings.staticSetting()
        )
        super.init()
        // 监听 containerView size 变化
        observation = observe(
            \.containerView.bounds,
            options: [.old, .new]
        ) { [weak self] (object, change) in
            guard let self = self,
                  let oldValue = change.oldValue,
                  let newValue = change.newValue,
                  !oldValue.size.equalTo(newValue.size) else {
                return
            }
            self.delegate?.onContainerViewSizeChange(
                old: oldValue.size,
                new: newValue.size)
        }
    }
    
    public func createComponent(fileReader: OPPackageReaderProtocol, containerContext: OPContainerContext) throws -> OPComponentProtocol {
        trace.info("OPBlockContainerRouter.createComponent for app \(containerContext.uniqueID)")
        let useWebRender = try blockComponentUtils.shouldUseWebRender(for: containerContext)
        if useWebRender {
            return OPBlockWebComponent(fileReader: fileReader, context: containerContext)
        } else {
            return OPBlockComponent(fileReader: fileReader, context: containerContext)
        }
    }
    
    public func switchToComponent(parentNode: OPNodeProtocol, component: OPComponentProtocol, initData: OPComponentDataProtocol) throws {
        trace.info("OPBlockContainerRouter.switchToComponent switchTo: \(component.context.uniqueID)")
        unloadCurrentComponent()

        // 由于 OPViewRenderSlot 会弱引用 slotView，所以临时声明一个局部变量，该 view 会被 containerView 引用
        let slotView = UIView(frame: containerView.bounds)
        let renderSlot = OPViewRenderSlot(view: slotView, defaultHidden: false)
        currentComponentRenderSlot = renderSlot
        currentComponent = component
        
        // 添加 View 绑定关系
        containerView.addSubview(slotView)
        slotView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        
        // 添加 Node 绑定关系
        parentNode.addChild(node: component)
        
        // 开始 component 加载
        try component.render(slot: renderSlot, data: initData)
    }
    
    public func unload() {
        trace.info("OPBlockContainerRouter.unload")
        unloadCurrentComponent()
    }
    
    private func unloadCurrentComponent() {
        trace.info("OPBlockContainerRouter.unloadCurrentComponent unload: \(currentComponent?.context.uniqueID)")
        if let currentComponent = currentComponent {
            
            // 解除 Node 绑定关系
            _ = currentComponent.parent?.removeChild(node: currentComponent)
            
            // 解除 View 绑定关系
            currentComponentRenderSlot?.view?.removeFromSuperview()
        }
        currentComponentRenderSlot = nil
        currentComponent = nil
    }
}

// MARK: - Block 错误页
extension OPBlockContainerRouter: OPBlockContainerRouterShowErrorProtocol {
    /// 展示错误页（Block内部）
    /// - Parameter item: guide info 错误信息
    public func showStatusView(item: GuideInfoStatusViewItem) {
        let blockViewHeight = containerView.frame.height
        var data = item
        if isShowingStatusView() {
            hideStatusView()
        }
        // 极简模式
        if blockViewHeight >= 70 && blockViewHeight < 200 {
            data.isSimple = true
            statusView = OPBlockTextStatusView(frame: .zero, data: data, userResolver: userResolver)
        } else if blockViewHeight >= 200 && blockViewHeight < 280 { // 无图模式
            statusView = OPBlockTextStatusView(frame: .zero, data: data, userResolver: userResolver)
        } else { // 有图模式
            statusView = OPBlockImageStatusView(frame: .zero, data: data, userResolver: userResolver)
        }
        guard statusView != nil else {
            assertionFailure("statusView is nil unexpectedly")
            return
        }
        containerView.addSubview(statusView!)
        statusView?.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    /// 隐藏错误页
    public func hideStatusView() {
        guard isShowingStatusView() else {
            return
        }
        statusView?.isHidden = true
        statusView?.removeFromSuperview()
        statusView = nil
    }
    /// 错误页展示状态
    /// - Returns: 是否正在展示
    public func isShowingStatusView() -> Bool {
        return statusView != nil
    }

    /// 展示错误页（业务）
    /// - Parameters:
    ///   - errorPageCreator: 错误页创建方法，便于宿主注入错误页子类
    ///   - isFromHost: 错误页实现是否来自宿主
    ///   - hostName: 宿主名
    ///   - blockTypeID: blockTypeID
    ///   - errorMessage: 错误信息
    ///   - buttonText: 按钮 title
    ///   - success: 成功回调
    ///   - failure: 失败回调
    public func showErrorPage(
        errorPageCreator: @escaping OPBlockErrorPageCreator,
        isFromHost: Bool,
        errorMessage: String,
        buttonText: String?,
        onButtonClicked: (()->Void)?,
        success: ((Bool)->Void)?,
        failure: (()->Void)?
    ) {
        trace.info("OPBlockContainerRouter.showErrorPage", additionalData: [
            "errorMessage": errorMessage,
            "buttonText": String(describing: buttonText)
        ])
        if isShowingErrorPage() {
            hideErrorPage(success: nil, failure: nil)
        }
        errorPage = errorPageCreator(self)
        if let errorPage = errorPage {
            self.isErrorPageFromHost = isFromHost
            self.onButtonClickedHandler = onButtonClicked
            containerView.addSubview(errorPage)
            errorPage.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            let errMsg = errorMessage.isEmpty ? BundleI18n.OPBlock.OpenPlatform_AppCenter_BlcErrDefault : errorMessage
            errorPage.refreshViews(
                contentHight: containerView.frame.height,
                errorMessage: errMsg,
                buttonName: buttonText
            )
            success?(isFromHost)
        } else {
            failure?()
            return
        }
    }

    /// 隐藏错误页
    /// - Parameters:
    ///   - success: 成功回调
    ///   - failure: 失败回调
    public func hideErrorPage(
        success: ((Bool)->Void)?,
        failure: (()->Void)?
    ) {
        guard isShowingErrorPage() else {
            failure?()
            return
        }
        errorPage?.isHidden = true
        errorPage?.removeFromSuperview()
        errorPage = nil
        success?(isErrorPageFromHost)
    }
    
    /// 错误页展示状态
    /// - Returns: 是否正在展示
    public func isShowingErrorPage() -> Bool {
        return errorPage != nil
    }
}

extension OPBlockContainerRouter: OPBlockErrorPageButtonClickDelegate {
    /// error page 按钮点击事件
    public func onBlockErrorPageButtonClicked() {
        let monitor = OPMonitor(
            name: "op_workplace_event",
            code: EPMClientOpenPlatformBlockitCustomErrorPageCode.custom_error_page_button_cklicked
        ).addCategoryValue("is_from_host", self.isErrorPageFromHost)
            .addCategoryValue("host", (context.containerConfig as? OPBlockContainerConfigProtocol)?.host)
            .addCategoryValue("block_type_id", context.uniqueID.identifier)
            .flush()
        trace.info("OPBlockContainerRouter.onBlockErrorPageButtonClicked send event")
        onButtonClickedHandler?()
    }
}
