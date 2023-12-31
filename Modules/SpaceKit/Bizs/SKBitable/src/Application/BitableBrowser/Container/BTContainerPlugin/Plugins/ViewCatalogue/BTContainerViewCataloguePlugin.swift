//
//  BTContainerViewCataloguePlugin.swift
//  SKBitable
//
//  Created by yinyuan on 2023/9/6.
//

import Foundation
import SKFoundation
import UniverseDesignColor
import UniverseDesignIcon
import SKUIKit
import SKCommon

final class BTContainerViewCataloguePlugin: BTContainerBasePlugin {
    
    override var view: UIView? {
        get {
            viewCatalogueContainer
        }
    }
    
    private var lastModel: BTViewContainerModel?
    
    override func setupView(hostView: UIView) {
        hostView.addSubview(viewCatalogueContainer)
    }
    
    private lazy var viewCatalogueContainer: ViewCatalogueContainer = {
        let view = ViewCatalogueContainer()
        view.layer.cornerRadius = BTContainer.Constaints.viewContainerCornerRadius
        view.layer.maskedCorners = .top
        view.clipsToBounds = true
        view.delegate = self

        if UserScopeNoChangeFG.LYL.disableAllViewAnimation {
            // 创建滑动手势识别器
            let upSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            upSwipeGesture.direction = .up
            view.addGestureRecognizer(upSwipeGesture)

            let downSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            downSwipeGesture.direction = .down
            view.addGestureRecognizer(downSwipeGesture)
        }

        return view
    }()
    
    override func updateStatus(old: BTContainerStatus?, new: BTContainerStatus, stage: UpdateStatusStage) {
        super.updateStatus(old: old, new: new, stage: stage)
        
        viewCatalogueContainer.isHidden = new.fullScreenType != .none
        
        viewCatalogueContainer.maxWindowWidth = new.containerSize.width
        
        guard stage == .animationEndStage || stage == .finalStage else {
            return  // 默认只处理 End 和 Final
        }
        if stage == .finalStage {
            if new.viewContainerType != old?.viewContainerType {
                remakeConstraints(status: new)
            } else if new.containerSize != old?.containerSize {
                remakeConstraints(status: new)
            }
        }
        
        let isBaseHeaderSwitchedTop = new.baseHeaderHidden
        let isBlockContainerHidden = new.blockCatalogueHidden
        let isRegularMode = new.isRegularMode
        
        if isRegularMode {
            viewCatalogueContainer.layer.cornerRadius = BTContainer.Constaints.viewContainerCornerRadius
        } else {
            if isBlockContainerHidden {
                if isBaseHeaderSwitchedTop {
                    viewCatalogueContainer.layer.cornerRadius = 0
                } else {
                    viewCatalogueContainer.layer.cornerRadius = BTContainer.Constaints.viewContainerCornerRadius
                }
            } else {
                viewCatalogueContainer.layer.cornerRadius = BTContainer.Constaints.viewContainerCornerRadius
            }
        }
        
        if new.darkMode != old?.darkMode {
            viewCatalogueContainer.updateDarkMode()
        }
    }
    
    // 处理滑动手势的方法
    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        DocsLogger.info("handleSwipe")
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        
        if gesture.direction == .up {
            DocsLogger.info("handleSwipe up")
            service.headerPlugin.trySwitchHeader(baseHeaderHidden: true)
        } else if gesture.direction == .down {
            DocsLogger.info("handleSwipe down")
            service.headerPlugin.trySwitchHeader(baseHeaderHidden: false)
        }
    }
    
    override func didUpdateViewContainerModel(viewContainerModel: BTViewContainerModel) {
        super.didUpdateViewContainerModel(viewContainerModel: viewContainerModel)
        var animated = true
        if self.lastModel?.tableId == nil {
            // 第一次进来，不需要动画
            animated = false
        } else if let lastTableId = self.lastModel?.tableId, lastTableId != viewContainerModel.tableId {
            // 不是第一次加载，并且tableId不同，代表切表
            animated = false
        }
        self.lastModel = viewContainerModel
        viewCatalogueContainer.setData(currentViewData: viewContainerModel, animated: animated)
    }
    
    override func remakeConstraints(status: BTContainerStatus) {
        super.remakeConstraints(status: status)
        if viewCatalogueContainer.superview != nil {
            let show = (status.viewContainerType == .hasViewCatalogHasToolBar || status.viewContainerType == .hasViewCatalogNoToolBar)
            viewCatalogueContainer.isHidden = !show
            viewCatalogueContainer.snp.remakeConstraints { make in
                make.top.left.right.equalToSuperview()
                make.height.equalTo(BTContainer.Constaints.viewCatalogueContainerHeight)
            }
        }
    }
    
}

extension BTContainerViewCataloguePlugin: ViewCatalogueDelegate {
    func viewCatalogueMoreClick(sourceView: UIView) {
        DocsLogger.info("viewCatalogueMoreClick")
        let currentViewData = model.viewContainerModel
        guard let callback = currentViewData?.callback else {
            DocsLogger.btError("[ViewCataloguePlugin] callback is nil")
            return
        }
        self.service?.callFunction(DocsJSCallBack(callback),
                                   params: ["action": currentViewData?.moreAction ?? ""],
                                   completion: nil)
    }

    func viewCatalogue(sourceView: UIView, didSelect index: Int) {
        DocsLogger.info("viewCatalogue didSelect \(index)")
        let currentViewData = model.viewContainerModel
        guard var currentViewData = currentViewData else {
            DocsLogger.btError("currentViewData invalid")
            return
        }
        guard index >= 0, index < currentViewData.viewList?.count ?? 0 else {
            DocsLogger.btError("[ViewCataloguePlugin] index is invalid")
            return
        }
        guard let currentViewId = currentViewData.viewList?[index].id else {
            DocsLogger.btError("[ViewCataloguePlugin] get  currentViewId fail")
            return
        }
        if let callback = currentViewData.callback,
           let model = currentViewData.viewList?.safe(index: index),
           let id = model.id,
           let clickAction = model.clickAction {
            callFunction(DocsJSCallBack(callback),
                              params: ["id": id,
                                       "action": clickAction
                                      ],
                              completion: nil)
        } else {
            DocsLogger.btError("[ViewCataloguePlugin] click empty callback or can not find model")
        }
        
        if UserScopeNoChangeFG.YY.bitableRedesignFormViewFixDisable || currentViewData.currentViewType != .form {
            // form 视图切换之前需要先弹窗确认保存
            currentViewData.currentViewId = currentViewId
            viewCatalogueContainer.setData(currentViewData: currentViewData)
        }
    }
}

extension BTContainerViewCataloguePlugin: ViewCatalogueService {
    func callFunction(_ function: DocsJSCallBack, params: [String : Any]?, completion: ((Any?, Error?) -> Void)?) {
        guard let service = service else {
            DocsLogger.error("invalid service")
            return
        }
        service.callFunction(function, params: params, completion: completion)
    }

    func shouldPopoverDisplay() -> Bool {
        guard let service = service else {
            DocsLogger.error("invalid service")
            return false
        }
        return service.shouldPopoverDisplay()
    }
}
