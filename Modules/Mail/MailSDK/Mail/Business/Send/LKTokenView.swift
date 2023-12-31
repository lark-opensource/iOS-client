//
//  LKTokenView.swift
//  LKTokenInputView
//
//  Created by majx on 05/26/19 from CLTokenInputView-Swift by Robert La Ferla.
//
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignIcon
import RxSwift
import RustPB

protocol LKTokenViewDelegate: AnyObject {
    func tokenViewDidRequestDelete(tokenView: LKTokenView, replaceWithText replacementText: String?)
    func tokenViewDidRequestSelection(tokenView: LKTokenView)
    /// drag drop
    func tokenViewDidStartDragDrop(tokenView: LKTokenView)
    func tokenViewDidDragFocus(at target: LKTokenInputView, tokenView: LKTokenView)
    func tokenViewDidDragDrop(to target: LKTokenInputView, tokenView: LKTokenView) -> LKTokenView?
    func tokenViewDidEndDragDrop(target: LKTokenInputView?, tokenView: LKTokenView)
    func tokenViewDidUpdate()
}

// 样式设置
protocol LKTokenViewStyle {
    var bgColor: UIColor { get }
    var textColor: UIColor { get }
    var selectedBgColor: UIColor { get }
    var selectedTextColor: UIColor { get }

    var errorBgColor: UIColor { get }
    var errorTextColor: UIColor { get }
    var errorSelectedBgColor: UIColor { get }
    var errorSelectedTextColor: UIColor { get }

    var cornerRadius: CGFloat { get }
    var paddingX: CGFloat { get }
    var paddingY: CGFloat { get }
    var font: UIFont { get }
    var selectedFont: UIFont { get }
    var minWidth: CGFloat { get }
    var maxWidth: CGFloat { get set }
    var iconSize: CGSize { get }
}

// 默认样式配置
struct LKTokenViewDefaultStyle: LKTokenViewStyle {
    private var _maxWidth: CGFloat = UIScreen.main.bounds.size.width
    var bgColor: UIColor { return UDColor.composeDefaultBubbleBgNormal }
    var textColor: UIColor { return UIColor.ud.textTitle }
    var selectedBgColor: UIColor { return UDColor.composeDefaultBubbleBgSelected }
    var selectedTextColor: UIColor { return UIColor.ud.textTitle }

    var errorBgColor: UIColor { return UDColor.composeErrBubbleBgNormal }
    var errorTextColor: UIColor { return UIColor.ud.functionDanger600 }
    var errorSelectedBgColor: UIColor { return UDColor.composeErrBubbleBgSelected }
    var errorSelectedTextColor: UIColor { return UIColor.ud.primaryOnPrimaryFill }

    var cornerRadius: CGFloat { return 12.5 }
    var paddingX: CGFloat { return 8 }
    var paddingY: CGFloat { return 4 }
    var font: UIFont { return UIFont.systemFont(ofSize: 14) }
    var selectedFont: UIFont { return UIFont.systemFont(ofSize: 14, weight: .regular) }
    var minWidth: CGFloat { return 14 }
    var maxWidth: CGFloat {
        get {
            return _maxWidth
        }
        set {
            _maxWidth = newValue
        }
    }
    var iconSize: CGSize { return CGSize(width: 16, height: 16) }
}
let lkTokenViewNotificationName = NSNotification.Name("MAIL_LKTokenView_STATUS_CHANGE")
let lkTokenViewRemoveNotificationName = NSNotification.Name("MAIL_LKTokenView_REMOVE")
// MARK: - LKTokenView
class LKTokenView: UIView {
    struct DragDropConfig {
        static let placeholderAlpha: CGFloat = 0.3
        static let dragViewScale: CGFloat = 1.2
        static let dragViewOffsetY: CGFloat = 12

        var dragFloatView: UIView?
        var dragView: LKTokenView?
        var originalFrame: CGRect?
        var targetInputViews: [WeakBox<LKTokenInputView>]?
        weak var focusInputView: LKTokenInputView?

    }

    var dragDropConfig = DragDropConfig(dragFloatView: nil, originalFrame: .zero)

    weak var delegate: LKTokenViewDelegate?
    /// views
    var backgroundView: UIView = .init()
    var label: UILabel = .init()
    var selectedBackgroundView: UIView = .init()
    var selectedLabel: UILabel = .init()
    var displayText: String!
    var iconView: UIImageView?
    var style: LKTokenViewStyle!

    /// recognizer
    var longPressRecognizer: UILongPressGestureRecognizer?
    var tapRecognizer: UITapGestureRecognizer?
    let disposeBag = DisposeBag()

    var token: LKToken! {
         didSet {
             updateStatus()
         }
     }

    var clickEnable: Bool = false {
        didSet {
            tapRecognizer?.isEnabled = clickEnable
        }
    }

    var selected: Bool = false {
        didSet {
            if oldValue != self.selected {
                self.setSelectedNoCheck(selectedBool: self.selected, animated: false)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    convenience init(with token: LKToken, _ style: LKTokenViewStyle?) {
        self.init(frame: .zero, token: token, style)
    }

    init(frame: CGRect, token: LKToken, _ style: LKTokenViewStyle?) {
        if style != nil {
            self.style = style!
        } else {
            self.style = LKTokenViewDefaultStyle()
        }
        self.token = token
        super.init(frame: frame)

        self.backgroundView = UIView(frame: .zero)
        self.backgroundView.isHidden = false
        self.addSubview(self.backgroundView)

        self.label = UILabel(frame: CGRect(x: self.style.paddingX + iconWidthWithSpace, y: self.style.paddingY, width: 0.0, height: 0.0))
        self.label.backgroundColor = UIColor.clear
        self.label.textAlignment = .left

        self.addSubview(self.label)

        self.selectedBackgroundView = UIView(frame: .zero)
        self.selectedBackgroundView.isHidden = true
        self.addSubview(self.selectedBackgroundView)

        self.selectedLabel = UILabel(frame: CGRect(x: self.style.paddingX + iconWidthWithSpace, y: self.style.paddingY, width: 0.0, height: 0.0))
        self.selectedLabel.textAlignment = .left

        self.addSubview(self.selectedLabel)
        self.setupIconView()
        self.updateStatus()

        /// add recognizer
        let tapRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LKTokenView.handleTapGestureRecognizer(sender: )))
        self.addGestureRecognizer(tapRecognizer)

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(LKTokenView.handleLongPressGestureRecognizer(sender: )))
        longPressRecognizer.minimumPressDuration = 0.2
        self.addGestureRecognizer(longPressRecognizer)

        self.tapRecognizer = tapRecognizer
        self.longPressRecognizer = longPressRecognizer
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveStatusChangeNotification(notification:)), name: lkTokenViewNotificationName, object: nil)
    }

    @objc
    func didReceiveStatusChangeNotification(notification: Notification) {
        guard let text = notification.object as? String, text == token.address else { return }
        token.status = .error
        updateStatus()
    }
    
    func mailAddressChange() {
        let model = self.token.context as? MailAddressCellViewModel
        var needUpdate = false
        var replaceName = ""
        if let model = model,
                  let newName = MailAddressChangeManager.shared.uidNameMap[String(model.larkID)] {
            needUpdate = true
            replaceName = newName
        } else if let newName = MailAddressChangeManager.shared.addressNameMap[self.token.address],
                  newName != self.token.name {
            needUpdate = true
            replaceName = newName
        }
        if needUpdate &&
            !replaceName.isEmpty {
            self.token.forceDisplay = replaceName
            self.updateName()
        }
    }
    
    func replaceNameIfNeed() {
        guard MailAddressChangeManager.shared.addressNameOpen() else { return }
        //MailAddressChangeManager.shared.processTokenAddress(token: self.token)
        var item = AddressRequestItem()
        item.address = self.token.address
        if let model = self.token.context as? MailAddressCellViewModel {
            if !FeatureManager.open(.groupShareReplace) && model.type == .enterpriseMailGroup {
                // 邮件组不需要替换名字
                return
            }
            if !model.larkID.isEmpty {
                item.larkEntityID = model.larkID
            }
            if let type = model.type, type == .group {
                item.addressType = .chatGroup
            }
        }
        MailDataServiceFactory.commonDataService?.getMailAddressNames(addressList: [item]).subscribe( onNext: { [weak self]  MailAddressNameResponse in
            guard let `self` = self else { return }
            if let respItem = MailAddressNameResponse.addressNameList.first,
               !respItem.name.isEmpty,
               respItem.name != self.token.displayText,
               !MailAddressChangeManager.shared.noUpdate(type: respItem.addressType) {
                self.token.forceDisplay = respItem.name
                if var model = self.token.context as? MailAddressCellViewModel {
                    let fgOpen = FeatureManager.open(.replyCheckAddress)
                    let respValid = !respItem.tenantID.isEmpty && respItem.tenantID != "0" && !respItem.larkEntityID.isEmpty && respItem.larkEntityID != "0"
                    let modelInValid = model.tenantId.isEmpty || model.tenantId == "0" || model.larkID.isEmpty || model.larkID == "0"
                    if (fgOpen && respValid) || modelInValid {
                        model.tenantId = respItem.tenantID
                        model.larkID = respItem.larkEntityID
                        model.type = self.convertModelType(nameItem: respItem)
                        self.token.context = model as AnyObject
                    }
                }
                
                self.setupIconView()
                self.updateStatus()
                self.delegate?.tokenViewDidUpdate()
            }
            }, onError: { (error) in
                MailLogger.error("token getAddressNames resp error \(error)")
            }).disposed(by: disposeBag)
    }
    func convertModelType(nameItem: Email_Client_V1_AddressName) -> ContactType {
        var type = ContactType.unknown
        if nameItem.addressType == .chatGroup {
            type = .group
        } else if nameItem.addressType == .mailGroup {
            type = .enterpriseMailGroup
        } else if nameItem.addressType == .larkUser {
            type = .chatter
        } else if nameItem.addressType == .mailShare {
            type = .sharedMailbox
        }
        return type
    }
    
    func updateName() {
        displayText = token.displayText
        label.text = displayText
        selectedLabel.text = displayText
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func updateBgColor() {
        if token.status == .normal {
            backgroundView.backgroundColor = style.bgColor
        } else if token.status == .error {
            backgroundView.backgroundColor = style.errorBgColor
        }
    }
    func setupIconView() {
        if needShowGroupIcon && (self.iconView == nil || self.iconView?.superview == nil) {
            self.iconView = UIImageView(image: groupTypeIcon == 1 ?
                                            UDIcon.allmailOutlined.withRenderingMode(.alwaysTemplate) :
                                            UDIcon.groupOutlined.withRenderingMode(.alwaysTemplate))
            self.iconView?.tintColor = UIColor.ud.iconN1
            self.iconView?.frame = CGRect(x: self.style.paddingX, y: self.style.paddingY, width: self.style.iconSize.width, height: self.style.iconSize.height)
            if let iconView = self.iconView {
                self.addSubview(iconView)
            }
        } else {
            self.iconView?.removeFromSuperview()
        }
    }

    /// 更新状态
    func updateStatus() {
        displayText = token.displayText
        label.text = displayText
        selectedLabel.text = displayText

        label.font = style.font
        backgroundView.layer.cornerRadius = style.cornerRadius

        selectedLabel.isHidden = !token.selected
        selectedLabel.font = style.selectedFont
        selectedLabel.backgroundColor = UIColor.clear
        selectedBackgroundView.isHidden = !token.selected
        selectedBackgroundView.layer.cornerRadius = style.cornerRadius
        iconView?.isHighlighted = token.selected

        if token.status == .normal {
            label.textColor = style.textColor
            backgroundView.backgroundColor = style.bgColor
            selectedLabel.textColor = style.selectedTextColor
            selectedBackgroundView.backgroundColor = style.selectedBgColor
        } else if token.status == .error {
            label.textColor = style.errorTextColor
            backgroundView.backgroundColor = style.errorBgColor
            selectedLabel.textColor = style.errorSelectedTextColor
            selectedBackgroundView.backgroundColor = style.errorSelectedBgColor
        }

        // updateLabelAttributedText()
        setNeedsLayout()
        layoutIfNeeded()
    }

    private var needShowGroupIcon: Bool {
        if let addressModel = token.context as? MailAddressCellViewModel,
           addressModel.type == .group || addressModel.type == .enterpriseMailGroup {
            return true
        } else {
            return false
        }
    }

    private var groupTypeIcon: Int {
        if let addressModel = token.context as? MailAddressCellViewModel,
           addressModel.type == .enterpriseMailGroup {
            return 1
        } else if let addressModel = token.context as?
                    MailAddressCellViewModel, addressModel.type == .group {
            return 0
        } else {
            return -1
        }
    }

    private var iconWidthWithSpace: CGFloat {
        return needShowGroupIcon ? style.iconSize.width + 4 : 0
    }

    override var intrinsicContentSize: CGSize {
        let labelIntrinsicSize: CGSize = self.selectedLabel.intrinsicContentSize
        let maxWidth = min(labelIntrinsicSize.width + iconWidthWithSpace, style.maxWidth)
        return CGSize(width: max(maxWidth, style.minWidth) + 2.0 * style.paddingX,
                      height: labelIntrinsicSize.height + 2.0 * style.paddingY)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let maxWidth = min(size.width - iconWidthWithSpace - 2.0 * style.paddingX, style.maxWidth)
        let fittingSize = CGSize(width: maxWidth, height: size.height - 2.0 * style.paddingY)
        let labelSize = self.selectedLabel.sizeThatFits(fittingSize)
        let width = max(labelSize.width + iconWidthWithSpace, style.minWidth)
        return CGSize(width: width + 2.0 * style.paddingX, height: labelSize.height + 2.0 * style.paddingY)
    }

    @objc
    func handleTapGestureRecognizer(sender: UIGestureRecognizer) {
        self.delegate?.tokenViewDidRequestSelection(tokenView: self)
    }

    @objc
    func handleLongPressGestureRecognizer(sender: UILongPressGestureRecognizer) {

        if let view = sender.view as? LKTokenView, let dragFloatView = dragDropConfig.dragFloatView {
            var dragView: LKTokenView? = self.dragDropConfig.dragView
            func restore(to newFrame: CGRect) {
                let animateTime: Double = 0.25
                UIView.animate(withDuration: animateTime, delay: 0, animations: {
                    dragView?.transform = CGAffineTransform.identity
                    if newFrame != .zero {
                        dragView?.frame = newFrame
                    }
                    self.alpha = 1.0
                }) { (_) in
                    dragView?.removeFromSuperview()
                }
            }

            let location = sender.location(in: dragFloatView)
            let newCenter = CGPoint(x: location.x, y: location.y - DragDropConfig.dragViewOffsetY)
            if sender.state == .began {
                /// update self status
                delegate?.tokenViewDidStartDragDrop(tokenView: self)
                /// add a new dragView
                dragView = addDragView(view, dragFloatView: dragFloatView, location: newCenter)
            } else if sender.state == .cancelled || sender.state == .ended {
                var target: LKTokenInputView?
                var targetFrame: CGRect = .zero
                if let focusInputView = dragDropConfig.focusInputView {
                    target = focusInputView
                    if let targetTokenView = delegate?.tokenViewDidDragDrop(to: focusInputView, tokenView: self) {
                        let newFrame = CGRect(x: targetTokenView.frame.origin.x, y: targetTokenView.frame.origin.y, width: self.frame.width, height: self.frame.height)
                        targetFrame = dragFloatView.convert(newFrame, from: targetTokenView.superview)
                    }
                } else {
                    targetFrame = dragFloatView.convert(self.frame, from: self.superview)
                }
                restore(to: targetFrame)
                delegate?.tokenViewDidEndDragDrop(target: target, tokenView: self)
            } else {
                /// update dragView location
                updateMatchInputView(point: newCenter, at: dragFloatView)
                dragView?.center = newCenter
            }
        }
    }

    private func addDragView(_ view: LKTokenView, dragFloatView: UIView, location: CGPoint) -> LKTokenView {
        dragDropConfig.dragView = nil
        /// copy a new drag view
        let dragView = LKTokenView(with: view.token, view.style)
        dragView.frame = view.frame
        dragView.token.selected = true
        dragView.updateStatus()
        dragView.alpha = 0.0

        let convertFrame = dragFloatView.convert(frame, from: superview)
        dragDropConfig.originalFrame = convertFrame
        dragDropConfig.dragView = dragView
        dragView.frame = convertFrame
        dragFloatView.addSubview(dragView)
        /// show drag view
        let animateTime: Double = 0.15
        UIView.animate(withDuration: animateTime, delay: 0, usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
                        dragView.alpha = 1.0
                        dragView.transform = CGAffineTransform(scaleX: DragDropConfig.dragViewScale, y: DragDropConfig.dragViewScale)
                        dragView.center = location
                        self.alpha = DragDropConfig.placeholderAlpha
        }) { (_) in
        }

        return dragView
    }

    private func updateMatchInputView(point: CGPoint, at dragFloatView: UIView) {
        let lastMatchInputView = dragDropConfig.focusInputView
        if let targetInputViews = dragDropConfig.targetInputViews {
            targetInputViews.forEach { $0.value?.showHighLight = false }
            if let focusInputItem = targetInputViews.first(where: { (value) -> Bool in
                if let view = value.value {
                    let globalFrame = dragFloatView.convert(view.frame, from: view.superview)
                    return globalFrame.contains(point)
                }
                return false
            }) {
                guard let focusInputView = focusInputItem.value else {
                    return
                }
                focusInputView.showHighLight = true
                dragDropConfig.focusInputView = focusInputView
                if lastMatchInputView != focusInputView {
                    delegate?.tokenViewDidDragFocus(at: focusInputView, tokenView: self)
                }
            } else {
                dragDropConfig.focusInputView = nil
            }
        }
    }

    func setSelected(selectedBool: Bool, animated: Bool) {
        if self.selected == selectedBool && self.selected == self.token.selected {
            return
        }
        self.token.selected = selectedBool
        self.selected = selectedBool
        self.setSelectedNoCheck(selectedBool: selectedBool, animated: animated)
    }

    func setSelectedNoCheck(selectedBool: Bool, animated: Bool) {
       // setSelected(selectedBool: selectedBool, animated: false)
        if animated {
            UIView.animate(withDuration: timeIntvl.uiAnimateNormal) {
                self.updateStatus()
            }
        } else {
            self.updateStatus()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        var bounds: CGRect = self.bounds
        bounds = CGRect(x: 0, y: 0,
                        width: max(bounds.width, style.minWidth),
                        height: bounds.height)
        backgroundView.frame = bounds
        selectedBackgroundView.frame = bounds
        let labelFrame = CGRect(x: bounds.minX + style.paddingX + iconWidthWithSpace,
                                y: bounds.minY + style.paddingY,
                                width: bounds.width - iconWidthWithSpace - 2.0 * style.paddingX,
                                height: bounds.height - 2.0 * style.paddingY)
        selectedLabel.frame = labelFrame
        label.frame = labelFrame
    }
}

// MARK: - COPY
extension LKTokenView: NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        let tokenView = LKTokenView(frame: self.frame, token: self.token, self.style)
        return tokenView
    }
}
