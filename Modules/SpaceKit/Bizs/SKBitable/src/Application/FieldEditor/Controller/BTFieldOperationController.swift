//
//  BTFieldOperationController.swift
//  SKBitable
//
//  Created by zoujie on 2021/11/30.
//  


import SKFoundation
import SKUIKit
import SKCommon
import SKBrowser
import SKResource
import UniverseDesignToast
import UniverseDesignColor
import UIKit
import SpaceInterface

protocol BTFieldOperationDelegate: AnyObject {
    func didClickOperationButton(action: BTOperationType, fieldEditModel: BTFieldEditModel, baseContext: BaseContext)
    func trackOperationViewEvent(eventType: DocsTracker.EventType,
                                 params: [String: Any],
                                 fieldEditModel: BTFieldEditModel)
}

final class BTFieldOperationController: SKPanelController,
                                  SKOperationViewDelegate,
                                  BTReadOnlyTextViewDelegate,
                                  BTDescriptionViewDelegate,
                                  UIPopoverPresentationControllerDelegate {

    private var fieldEditModel: BTFieldEditModel

    private var hostDocsInfo: DocsInfo?

    private var data: [BTOperationItem] = []

    private var groupData: [[BTOperationItem]] = []

    weak var delegate: BTFieldOperationDelegate?
    
    weak var spaceFollowAPIDelegate: SpaceFollowAPIDelegate?

    weak var hostVC: UIViewController?

    private var currentOrientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation

    //列表距离底部的边距
    private var bottom: CGFloat = 0

    //描述view信息
    private var viewDescriptionHeight: CGFloat = 0
    private var viewDescriptionAttrString: NSAttributedString?
    private var viewDescriptionShouldLimitDescriptionLines = true // 默认折叠

    private var maxViewHeight: CGFloat {
        if self.modalPresentationStyle == .popover {
            return self.preferredContentSize.height
        }
        return (self.hostVC?.view.frame.height ?? SKDisplay.activeWindowBounds.height) * 0.8
    }

    private var minViewHeight: CGFloat {
        if self.modalPresentationStyle == .popover {
            return self.preferredContentSize.height
        }
        return (self.hostVC?.view.frame.height ?? SKDisplay.activeWindowBounds.height) * 0.4
    }

    var viewDidDismissBlock: () -> Void = {}

    var isInPopover: Bool {
        self.modalPresentationStyle == .popover
    }

    private lazy var titleLabel = UILabel().construct { it in
        it.font = .systemFont(ofSize: 17, weight: .medium)
        it.textColor = UDColor.textTitle
    }

    private lazy var headerView = UIView().construct { it in
        it.backgroundColor = .clear
        it.addSubview(titleLabel)

        let bottomSeparator = UIView()
        bottomSeparator.backgroundColor = UDColor.lineDividerDefault
        it.addSubview(bottomSeparator)

        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(24)
            make.center.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview().offset(16)
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }

        bottomSeparator.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    ///字段描述view
    private lazy var fieldDetailView = BTDescriptionView(limitButtonFont:
                                                            BTFieldLayout.Const.fieldDescriptionFont,
                                                         bgColor: self.modalPresentationStyle == .popover ? UDColor.bgFloat : UDColor.bgBody,
                                                         textViewDelegate: self,
                                                         limitButtonDelegate: self)
    // 计算中view，前端数据控制显示与隐藏
    private lazy var calculateView = CalculateView()
    final class CalculateView: UIView {
        var imgView = UIImageView()
        var label = UILabel().construct { it in
            it.font = .systemFont(ofSize: 14)
            it.textColor = UDColor.textCaption
            it.numberOfLines = 0
        }
        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = UDColor.bgFloatOverlay
            layer.cornerRadius = 8
            addSubview(self.imgView)
            addSubview(self.label)
            imgView.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.height.width.equalTo(16)
                make.left.equalToSuperview().offset(16)
            }
            label.snp.makeConstraints { make in
                make.left.equalTo(imgView.snp.right).offset(8)
                make.right.equalToSuperview().offset(-16)
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
            }
        }
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        func startAnimation() {
            BTUtil.startRotationAnimation(view: imgView)
        }
    }
    private lazy var operationList = SKOperationView(frame: .zero,
                                                     displayIcon: true).construct { it in
        it.delegate = self
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return [.allButUpsideDown]
    }
    
    private let baseContext: BaseContext

    init(fieldEditModel: BTFieldEditModel,
         hostDocsInfo: DocsInfo?,
         hostVC: UIViewController,
         baseContext: BaseContext) {
        self.hostDocsInfo = hostDocsInfo
        self.hostVC = hostVC
        self.fieldEditModel = fieldEditModel
        self.baseContext = baseContext
        super.init(nibName: nil, bundle: nil)

        self.dismissalStrategy = []
        self.automaticallyAdjustsPreferredContentSize = false
        self.data = fieldEditModel.operationItems
        self.groupData = (self.data.aggregateByGroupID() as? [[BTOperationItem]]) ?? []
        self.viewDescriptionShouldLimitDescriptionLines = groupData.count > 0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupUI() {
        super.setupUI()
        containerView.addSubview(headerView)
        containerView.addSubview(operationList)

        headerView.snp.makeConstraints { make in
            make.left.top.right.equalTo(containerView.safeAreaLayoutGuide)
            make.height.equalTo(48)
        }

        if self.modalPresentationStyle != .popover {
            bottom = 50
        }

        operationList.snp.makeConstraints { make in
            make.left.right.equalTo(containerView.safeAreaLayoutGuide)
            make.height.equalTo(0)
            make.top.equalTo(headerView.snp.bottom)
            make.bottom.equalToSuperview().offset(-bottom)
        }

        self.navigationController?.navigationBar.isHidden = true
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag) { [weak self] in
            completion?()
            self?.viewDidDismissBlock()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        currentOrientation = UIApplication.shared.statusBarOrientation
        navigationController?.setNavigationBarHidden(true, animated: false) // 从外部网页退回到描述页面时要把导航栏隐藏
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateUI(fieldEditModel: self.fieldEditModel)
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [self] _ in
            if UIApplication.shared.statusBarOrientation != currentOrientation {
                //转屏后刷新页面布局高度
                currentOrientation = UIApplication.shared.statusBarOrientation
                updateUI(fieldEditModel: self.fieldEditModel)
            }
        }
    }

    func convertItem() -> [[SKOperationBaseItem]] {
        var operationGroupItems: [[SKOperationBaseItem]] = []
        countDescriptionViewHeight()

        if viewDescriptionHeight > 0, let descriptionAttrString = viewDescriptionAttrString {
            fieldDetailView.setLimitButtonVisible(visible: groupData.count > 0)

            var customViewItem = SKOperationBaseItem()
            customViewItem.identifier = "customView"
            customViewItem.customView = fieldDetailView
            //需要动态计算描述字段的高度
            customViewItem.customViewHeight = viewDescriptionHeight
            customViewItem.customViewLayoutCompleted = { [weak self] in
                guard let self = self else { return }
                self.fieldDetailView.setDescriptionText(descriptionAttrString, showingHeight: self.viewDescriptionHeight)
            }
            operationGroupItems = [[customViewItem]]
        }
        if UserScopeNoChangeFG.WJS.bitableMobileSupportRemoteCompute {
            if let fieldTips = fieldEditModel.fieldTips {
                if let img = fieldTips.img, let text = fieldTips.text {
                    var customViewItem = SKOperationBaseItem()
                    customViewItem.identifier = "customView2"
                    customViewItem.customView = calculateView
                    calculateView.imgView.image = img
                    calculateView.label.text = text
                    calculateView.startAnimation()
                    operationGroupItems.append([customViewItem])
                }
            }
        }

        groupData.forEach { items in
            var operationItems: [SKOperationBaseItem] = []
            items.forEach { item in
                guard let image = item.iconImage else { return }
                var operation = SKOperationBaseItem()
                operation.image = image
                operation.identifier = item.id.rawValue
                operation.isEnable = item.enable
                operation.disableReason = OperationItemDisableReason(rawValue: item.disableReason) ?? .other
                operation.shouldShowWarningIcon = item.shouldShowWarningIcon
                operation.title = item.title

                operationItems.append(operation)
            }
            operationGroupItems.append(operationItems)
        }

        return operationGroupItems
    }

    func countDescriptionViewHeight() {
        guard let description = fieldEditModel.fieldDesc,
              let content = description.content,
              !content.isEmpty else { return }
        var fullDescHeight: CGFloat = 0
        self.viewDescriptionAttrString = BTUtil.convert(content, font: BTFieldLayout.Const.fieldDescriptionFont)

        if let descriptionAttrText = viewDescriptionAttrString {
            fullDescHeight = calculateTextHeight(descriptionAttrText, inWidth: self.view.frame.width - 32)
        } else {
            return
        }
        let lineHeight = BTFieldLayout.Const.fieldDescriptionFont.figmaHeight
        if fullDescHeight <= BTDescriptionView.maxNumberOfLines * lineHeight && !viewDescriptionShouldLimitDescriptionLines {
            // 在竖屏时点击了展开，转到横屏时可能由于宽度足够不再需要展示 limit button，这种情况下需要修正 flag，不然横屏下就会多出来收起按钮
            viewDescriptionShouldLimitDescriptionLines = true
        }
        let descriptionHeight: CGFloat
        if viewDescriptionShouldLimitDescriptionLines {
            descriptionHeight = min(fullDescHeight, BTDescriptionView.maxNumberOfLines * lineHeight)
        } else {
            descriptionHeight = fullDescHeight + lineHeight // 多出来的一行是收起按钮
        }
        self.viewDescriptionHeight = descriptionHeight
    }

    func calculateTextHeight(_ attrString: NSAttributedString, inWidth width: CGFloat, numberOfLines: Int = 0) -> CGFloat {
        let textView = BTFieldLayout.textHeightCalculator
        textView.attributedText = attrString
        textView.textContainer.maximumNumberOfLines = numberOfLines
        let textViewHeight = textView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        return ceil(textViewHeight)
    }

    func updateUI(fieldEditModel: BTFieldEditModel) {
        self.fieldEditModel = fieldEditModel
        self.titleLabel.text = fieldEditModel.fieldName
        let groupItem = convertItem()
        let preferredHeight = countOperationListPreferredContentHeight()
        operationList.snp.updateConstraints { make in
            make.height.equalTo(preferredHeight)
        }
        operationList.refresh(infos: groupItem)
        if modalPresentationStyle != .popover {
            operationList.setCollectionViewScrollEnable(enable: preferredHeight == (maxViewHeight - headerView.bounds.height - bottom))
        }

        if modalPresentationStyle == .popover {
            preferredContentSize = CGSize(width: 375, height: preferredHeight + 48)
        }
    }

    func countOperationListPreferredContentHeight() -> CGFloat {
        let operationListViewHeight = viewDescriptionHeight + CGFloat(data.count) * SKOperationView.Const.itemHeight + CGFloat((1 + groupData.count) * 16)
        let maxListViewheight = maxViewHeight - headerView.bounds.height - bottom
        let minListViewheight = minViewHeight - headerView.bounds.height - bottom
        if modalPresentationStyle == .popover {
            return min(maxListViewheight, operationListViewHeight)
        } else {
            return max(min(maxListViewheight, operationListViewHeight), minListViewheight)
        }
    }

    func didClickItem(identifier: String, finishGuide: Bool, itemIsEnable: Bool, disableReason: OperationItemDisableReason, at view: SKOperationView) {
        guard itemIsEnable else {
            switch disableReason {
            case .other:
                //暂不支持编辑该字段类型
                UDToast.showWarning(with: BundleI18n.SKResource.Bitable_Field_PleaseModifyOnDesktop, on: self.view)
            case .fg:
                //FG原因
                UDToast.showWarning(with: BundleI18n.SKResource.Bitable_Common_NotEditable_FeatureNotSupported_Mobile, on: self.view)
            case .cantRead:
                // 无阅读权限
                UDToast.showWarning(with: BundleI18n.SKResource.Bitable_AdvancedPermission_UnableToUseCalculate_Tooltip, on: self.view)
                DocsTracker.newLog(enumEvent: .bitableCalculationOperateLimitedView,
                                   parameters: ["reason": "limited_premium_permission",
                                                "field_type": fieldEditModel.compositeType.fieldTrackName])
            case .syncFromOtherBase:
                UDToast.showWarning(with: BundleI18n.SKResource.Bitable_DataReference_SyncFromOtherBase_ActionNotSupported_Tooltip, on: self.view)
            case .noPermission:
                UDToast.showWarning(with: BundleI18n.SKResource.Bitable_AdvancedPermission_NoPermToDuplicateFieldDueToInaccessibleReferencedData_Tooltip, on: self.view)
            }
            return
        }
        delegate?.didClickOperationButton(action: BTOperationType(rawValue: identifier) ?? .unknown, fieldEditModel: self.fieldEditModel, baseContext: baseContext)
    }

    func shouldDisplayBadge(identifier: String, at view: SKOperationView) -> Bool {
        return false
    }

    func readOnlyTextView(_ textView: BTReadOnlyTextView, handleTapFromSender sender: UITapGestureRecognizer) {
        //描述字段内链接点击处理
        guard let hostDocsInfo = hostDocsInfo else { return }
        let attributes = BTUtil.getAttributes(in: textView, sender: sender)
        let hostVC = hostVC ?? self
        BTUtil.didTapView(hostVC: hostVC,
                          hostDocsInfo: hostDocsInfo,
                          needFullScreen: false,
                          withAttributes: attributes,
                          openURLByVCFollowIfNeed: openURLByVCFollowIfNeed)
    }

    
    private func openURLByVCFollowIfNeed(_ url: URL, _ isNeedTransOrientation: Bool) -> Bool {
        let handler: () -> Void = {
            self.dismiss(animated: false) {
                if isNeedTransOrientation {
                    BTUtil.forceInterfaceOrientationIfNeed(to: .portrait)
                }
            }
        }
        if OperationInterceptor.interceptUrlIfNeed(url.absoluteString,
                                                   from: hostVC,
                                                   followDelegate: nil,
                                                   handler: SKDisplay.pad ? nil : handler) {
            //先判断DocComponent是否拦截
            return true
        }
        
        guard let followAPIDelegate = self.spaceFollowAPIDelegate else {
            return false
        }
        if SKDisplay.pad {
            followAPIDelegate.follow(nil, onOperate: .vcOperation(value: .openUrl(url: url.absoluteString)))
        } else {
           
            followAPIDelegate.follow(nil, onOperate: .vcOperation(value: .openUrlWithHandlerBeforeOpen(url: url.absoluteString, handler: handler)))
        }
        return true
    }
    
    func toggleLimitMode(to: Bool) {
        //点击展开/收起后更新面板高度
        viewDescriptionShouldLimitDescriptionLines = to
        updateUI(fieldEditModel: self.fieldEditModel)
    }

    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        viewDidDismissBlock()
    }
}
