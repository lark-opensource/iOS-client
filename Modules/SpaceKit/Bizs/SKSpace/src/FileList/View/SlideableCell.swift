//
//  SlideableCell.swift
//  FileList
//
//  Created by nine on 2018/1/16.
//

import Foundation
import SnapKit
import SKCommon
import SKResource
import SKUIKit
import UniverseDesignToast
import RxSwift
import UniverseDesignColor
import UniverseDesignIcon
import UIKit
import SpaceInterface
import SKFoundation

/**
 使用步骤:
 1.继承SlideableCell,将控件addSubview到container上。
 2.调用addItem(type: ItemType, title: String, color: UIColor, image: UIImage?, action: @escaping SwipeClosureType)方法，添加滑动按钮
 3.调用setItemWidth设置SwipdeItem的宽度
 注意事项
 1.type按钮类型；title文字，仅.delete类型有用；color按钮颜色；image为按钮图标；action为按钮事件
 2.ItemType分为delete,action,menu三种，.delete类型会有确认特效，确认时的文字为title。.action类型会直接调用action传的闭包。.menu类型会弹出菜单(开发中)
 3.按钮的顺序从右往左依次为添加的顺序，如果存在.delete类型不管何时添加都在最右边
 4.调用setItemWidth设置SwipdeItem的宽度
 */
enum SwipeState {
    case dragging
    case hide
    case dragged
    case finish
}

protocol OneCellDragged: AnyObject {
    func getSlideAction(for file: SpaceEntry, source: FileSource) -> [SlideAction]?
    func cancelDraggedView(to: SlideableCell)
    func cancelOtherCell(current: SlideableCell)
    func setDraggedView(to: SlideableCell)
    func performAction(action: SlideAction, cell: SlideableCell?)
    func disableScroll()
    func enableScroll()
//    func didSelectDeleteAction(action: SlideAction, cell: SlideableCell?, completion: @escaping ((_ isClickConfirmed: Bool) -> Void))
}

// 当前列表中是否有有action view
protocol SlideableSimultaneousGesture: AnyObject {
    var hasActionView: Bool { get set }
}

public class SlideableCell: UICollectionViewCell {
    lazy var pickerBackgroundView: SKPickerBackgroundView = {
        let view = SKPickerBackgroundView()
        view.layer.cornerRadius = 6
        return view
    }()
    
    // 强制允许单元格支持响应多个手势，默认不支持
    public var enableSimultaneousGesture: Bool = false

    override public var isHighlighted: Bool {
        didSet {
            if isHighlighted && swipeState == .hide {
                pickerBackgroundView.isHighlighted = true
            } else {
                // delay 一下是为了让高亮效果停留一下，避免闪烁的效果
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) { [weak self] in
                    guard self?.isHighlighted == false else { return }
                    self?.pickerBackgroundView.isHighlighted = false
                }
            }
        }
    }

    private(set) var hoverGesture: UIGestureRecognizer?

    var swipeEnbale = true
    var type: DocsType?
    var swipeState: SwipeState = .hide
    var deleteSwipeView: SwipeView?
    let container = UIView()
    var actionView: UIView?
    var touchEventView: UIView?
    var buttonList: [SwipeView]?
    var originalCenterX: CGFloat = 0
    var draggedCenterX: CGFloat = 0
    var buttonWidth: CGFloat = CGFloat(66)
    var actions: [SlideAction] = []
    var allowSwipe: Bool = false
    var allowNavigationSwipe: Bool = false
    let bag = DisposeBag()
    weak var delegate: OneCellDragged?
    public var enable: Bool = true
    
    weak var simultaneousDelegate: SlideableSimultaneousGesture?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        container.frame = self.contentView.frame
        contentView.addSubview(container)
        contentView.backgroundColor = UDColor.bgBody
        container.addSubview(pickerBackgroundView)
        pickerBackgroundView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(6)
        }
        originalCenterX = self.container.center.x
        if #available(iOS 13.0, *) {
            setupHoverInteraction()
        }
    }

    @available(iOS 13.0, *)
    private func setupHoverInteraction() {
        let gesture = UIHoverGestureRecognizer()
        gesture.rx.event.subscribe(onNext: { [weak self] gesture in
            guard let self = self else { return }
            switch gesture.state {
            case .began, .changed:
                self.pickerBackgroundView.isHovered = true
            case .ended, .cancelled:
                self.pickerBackgroundView.isHovered = false
            default:
                break
            }
        }).disposed(by: bag)
        hoverGesture = gesture
        contentView.addGestureRecognizer(gesture)
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        isHighlighted = false
        pickerBackgroundView.isHighlighted = false
        enableSimultaneousGesture = false
        simultaneousDelegate = nil
    }

    /// 旋转屏幕时需要
    override public func layoutSubviews() {
        super.layoutSubviews()
        if container.frame != contentView.frame {
            container.frame = contentView.frame
            originalCenterX = container.center.x
        }
    }

    public func setSlideAction(actions: [SlideAction]?) {
        if let actions = actions, actions.count > 0 {
            removeItem()
            self.actions = actions
            setItemWidth(CGFloat(66))
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
            panGesture.delegate = self
            if #available(iOS 13.4, *) {
                panGesture.allowedScrollTypesMask = [.continuous]
            }
            container.addGestureRecognizer(panGesture)
        } else {
            guard let gesture = container.gestureRecognizers?.first else { return }
            container.removeGestureRecognizer(gesture)
        }
    }
    
    // remove: 从当前列表移除，不是真正的删除
    func swipeViewForDelete(enable: Bool, remove: Bool = false) -> SwipeView {
        let icon = remove ? UDIcon.getIconByKey(.noOutlined, iconColor: UDColor.primaryOnPrimaryFill) :
                            UDIcon.getIconByKey(.deleteTrashOutlined, iconColor: UDColor.primaryOnPrimaryFill)
        let action: SlideAction = remove ? .remove : .readyToDelete
        if enable {
            let deleteAction = { [weak self] in
                guard let `self` = self else { return }
                self.delegate?.performAction(action: action, cell: self)
            }
            deleteSwipeView = SwipeView(BundleI18n.SKResource.Doc_List_DeleteConfirm, UDColor.functionDangerContentDefault, icon, deleteAction)
        } else {
            let toastAction = { () -> Void in
                UDToast.showFailure(with: BundleI18n.SKResource.Doc_Permission_DeleteNoPermission, on: self.window ?? self)
            }
            deleteSwipeView = SwipeView(BundleI18n.SKResource.Doc_List_DeleteConfirm, UDColor.functionDangerContentDefault.withAlphaComponent(0.5), icon, toastAction)
            deleteSwipeView?.imageView.alpha = 0.3
        }
        return deleteSwipeView!
    }
    func swipeViewForShare(enable: Bool) -> SwipeView {
        let action: () -> Void
        if enable {
            action = { [weak self] in
                self?.delegate?.performAction(action: .share, cell: self)
            }
        } else {
            action = { [weak self] in
                guard let self = self else { return }
                UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_Docs_NewFileType_Toast, on: self.window ?? self)
            }
        }
        let icon = UDIcon.getIconByKey(.shareOutlined, iconColor: UDColor.primaryOnPrimaryFill)
        let view = SwipeView(BundleI18n.SKResource.Doc_Normal_Share, UIColor.ud.N400, icon, action)
        if !enable {
            view.imageView.alpha = 0.5
        }
        return view
    }

    func swipeViewForMore() -> SwipeView {
        let icon = UDIcon.getIconByKey(.moreOutlined, iconColor: UDColor.primaryOnPrimaryFill)
        let view = SwipeView(BundleI18n.SKResource.Doc_Settings_More, UIColor.ud.N400, icon, { [weak self] in
            self?.delegate?.performAction(action: .more, cell: self)
        })
        return view
    }
    func swipeViewForMove() -> SwipeView {
        let icon = UDIcon.getIconByKey(.moveOutlined, iconColor: UDColor.primaryOnPrimaryFill)
        let view = SwipeView(BundleI18n.SKResource.Doc_Facade_MoveTo, UIColor.ud.N400, icon, { [weak self] in
            self?.delegate?.performAction(action: .move, cell: self)
        })
        return view
    }
    func swipeViewForUnstar() -> SwipeView {
        let icon = UDIcon.getIconByKey(.cancelCollectionOutlined, iconColor: UDColor.primaryOnPrimaryFill)
        let view = SwipeView(BundleI18n.SKResource.Doc_List_AddPin, UDColor.functionDangerContentDefault, icon, { [weak self] in
            self?.delegate?.performAction(action: .unstar, cell: self)
        })
        return view
    }
    func swipeViewForstar() -> SwipeView {
        let icon = UDIcon.getIconByKey(.collectionOutlined, iconColor: UDColor.primaryOnPrimaryFill)
        let view = SwipeView(BundleI18n.SKResource.Doc_List_AddPin, UIColor.ud.colorfulYellow, icon, { [weak self] in
            self?.delegate?.performAction(action: .star, cell: self)
        })
        return view
    }
    func swipeViewForRename() -> SwipeView {
        let icon = UDIcon.getIconByKey(.ccmRenameOutlined, iconColor: UDColor.primaryOnPrimaryFill)
        let view = SwipeView(BundleI18n.SKResource.Doc_Facade_Rename, UIColor.ud.N400, icon, { [weak self] in
            self?.delegate?.performAction(action: .rename, cell: self)
        })
        return view
    }
    func swipeViewForTrashRestore() -> SwipeView {
        let icon = BundleResources.SKResource.Space.FileList.listcell_restore
        let view = SwipeView(BundleI18n.SKResource.Doc_List_TrashRestore, UIColor.ud.N400, icon, { [weak self] in
            self?.delegate?.performAction(action: .trashRestore, cell: self)
        })
        return view
    }
    func swipeViewForRemoveFromPin() -> SwipeView {
        let icon = UDIcon.getIconByKey(.cancelBuzzOutlined, iconColor: UDColor.primaryOnPrimaryFill)
        let view = SwipeView(BundleI18n.SKResource.Doc_List_AddPin, UDColor.functionDangerContentDefault, icon, { [weak self] in
            self?.delegate?.performAction(action: .removeFromPin, cell: self)
        })
        return view
    }
    func swipeViewForTrashDelete() -> SwipeView {
        let icon = UDIcon.getIconByKey(.deleteTrashOutlined, iconColor: UDColor.primaryOnPrimaryFill)
        let view = SwipeView(BundleI18n.SKResource.Doc_Facade_Delete, UDColor.functionDangerContentDefault, icon, { [weak self] in
            self?.delegate?.performAction(action: .trashDelete, cell: self)
        })
        return view
    }
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
// MARK: - public
public extension SlideableCell {
    func removeItem () {
        self.actions.removeAll()
    }
    func setItemWidth (_ width: CGFloat) {
        self.buttonWidth = width
    }
    func cancelCell (animated: Bool = true) {
        self.delegate?.cancelDraggedView(to: self)
        if self.container.center == self.contentView.center {
            return
        }
        let targetCenter = originalCenterX
        UIView.animate(withDuration: animated ? 0.15 : 0, delay: 0, options: .curveLinear, animations: {() -> Void in
            self.container.center = CGPoint(x: targetCenter, y: self.container.center.y)
            self.layoutIfNeeded()
        }, completion: {(_ finished: Bool) -> Void in
            if self.container.center == self.contentView.center && self.swipeState == .dragged {
                self.actionView?.removeFromSuperview()
                self.swipeState = .hide
                if self.enableSimultaneousGesture {
                    self.simultaneousDelegate?.hasActionView = false
                }
            }
        })
    }
}
// MARK: - fileprivate
extension SlideableCell {
    func moveCellViewAnimate (_ velocity: CGPoint) {
        var targetCenter: CGFloat = 0
        if (container.center.x < draggedCenterX && velocity.x <= 0)
            || (velocity.x < -20) || (velocity.x == 0 && container.center.x <= (draggedCenterX + originalCenterX) * 2 / 3) {
            self.swipeState = .dragged//  <---方向
            targetCenter = draggedCenterX
            if self.enableSimultaneousGesture {
                self.simultaneousDelegate?.hasActionView = true
            }
        } else {
            self.swipeState = .hide //  --->方向
            targetCenter = originalCenterX
            if self.enableSimultaneousGesture {
                self.simultaneousDelegate?.hasActionView = false
            }
        }
        guard self.actionView != nil else { return }
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.64, initialSpringVelocity: 0, options: [.curveEaseOut, .allowUserInteraction], animations: {() -> Void in
            self.container.center = CGPoint(x: targetCenter, y: self.container.center.y)
            self.layoutIfNeeded()
        }, completion: {(_ finished: Bool) -> Void in
            if velocity.x > 0 {
                if self.container.center == self.contentView.center {
                    self.swipeState = .hide
                    self.delegate?.cancelDraggedView(to: self)
                    self.actionView?.removeFromSuperview()
                } else {
                    self.swipeState = .dragging
                }
            }
        })
    }

    func addActionView() {
        self.actionView?.removeFromSuperview()
        actionView = UIView()
        buttonList = [SwipeView]()
        actionView?.backgroundColor = UDColor.bgBody
        self.contentView.addSubview(actionView!)
        actionView?.snp.makeConstraints { (make) -> Void in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(self.container.snp.right)
            make.right.equalTo(self.superview!.superview!)
        }
        actions.forEach({ (type) in
            switch type {
            case .delete:
                buttonList?.append(swipeViewForDelete(enable: true))
            case .deleteDisable:
                buttonList?.append(swipeViewForDelete(enable: false))
            case .remove:
                buttonList?.append(swipeViewForDelete(enable: true, remove: true))
            case .share:
                buttonList?.append(swipeViewForShare(enable: true))
            case .shareDisable:
                buttonList?.append(swipeViewForShare(enable: false))
            case .more:
                buttonList?.append(swipeViewForMore())
            case .move:
                buttonList?.append(swipeViewForMove())
            case .rename:
                buttonList?.append(swipeViewForRename())
            case .trashRestore:
                buttonList?.append(swipeViewForTrashRestore())
            case .trashDelete:
                buttonList?.append(swipeViewForTrashDelete())
            case .unstar:
                buttonList?.append(swipeViewForUnstar())
            case .star:
                buttonList?.append(swipeViewForstar())
            case .removeFromPin:
                buttonList?.append(swipeViewForRemoveFromPin())
            case .copyURL, .cancel, .addTo, .readyToDelete, .openWithOtherApp, .moveToTop, .addToPin,
                 .importToOnlineFile, .manualOffline, .unmanualOffline, .copyFile, .changeHiddenStatus,
                 .subscribe, .exportDocument, .addShortCut, .saveToLocal:
//                spaceAssertionFailure("Not support")
                break

            }
        })
        for (i, swipeActionView) in buttonList!.enumerated().reversed() {
            actionView?.addSubview(swipeActionView)
            swipeActionView.snp.makeConstraints { (make) -> Void in
                make.centerY.equalTo(self.snp.centerY)
                make.width.equalTo(actionView!).multipliedBy((2 + CGFloat(i)) / CGFloat(buttonList!.count))
                make.right.equalTo(self.superview!.superview!).offset(buttonWidth)
                make.top.bottom.equalToSuperview()
            }
        }
        self.setNeedsLayout()
        self.layoutIfNeeded()
        self.delegate?.setDraggedView(to: self)
        delegate?.disableScroll()
        draggedCenterX = originalCenterX - buttonWidth * CGFloat(buttonList!.count)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension SlideableCell: UIGestureRecognizerDelegate {
    @objc
    func handlePan(gesture: UIPanGestureRecognizer) {
        guard swipeEnbale, let target = gesture.view else { return }
        guard allowSwipe || gesture.state == .began else { return }
        let velocity = gesture.velocity(in: target)
        allowNavigationSwipe = velocity.x > 20
        switch (gesture.state, swipeState) {
        case (.changed, .dragging):
            guard let buttonList = buttonList else { return }
            let moveTo = gesture.elasticTranslation(in: target,
                                                    withLimit: CGSize(width: buttonWidth * CGFloat(buttonList.count), height: 0),
                                                    fromOriginalCenter: CGPoint(x: originalCenterX, y: 0)).x
            target.center.x = moveTo < originalCenterX ? moveTo : originalCenterX
        case (.changed, .dragged):
            guard let buttonList = buttonList else { return }
            let moveTo = gesture.elasticTranslation(in: target,
                                                    withLimit: CGSize(width: buttonWidth * CGFloat(buttonList.count), height: 0),
                                                    fromOriginalCenter: CGPoint(x: draggedCenterX, y: 0)).x
            target.center.x = moveTo < originalCenterX ? moveTo : originalCenterX
        case (.ended, _):
            moveCellViewAnimate(velocity)
            delegate?.enableScroll()

            if swipeState == .hide {
                // 如果用户侧滑一点点马上放开，会走到这里，重置一下，不然VC认为这个cell是侧滑状态，点击不响应事件
                cancelCell()
            }

        default:
            self.delegate?.cancelOtherCell(current: self)
            guard swipeState == .hide || self.container.center == self.contentView.center else { return }
            if abs(velocity.x) > abs(velocity.y) {
                addActionView()
                swipeState = .dragging
                allowSwipe = true
            } else {
                allowSwipe = false
            }
        }
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.location(in: self).x > 20
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if self.needSimultaneousGesture() {
            return true
        }
        // 如果手势y轴偏移量大于x轴偏移量，则下拉手势和左滑滑动手势同时响应，可以优化成判断偏移量后，来选择响应手势
        let velocityY: CGFloat = ((gestureRecognizer as? UIPanGestureRecognizer)?.velocity(in: gestureRecognizer.view).y) ?? 0
        let velocityX: CGFloat = ((gestureRecognizer as? UIPanGestureRecognizer)?.velocity(in: gestureRecognizer.view).x) ?? 0
        
        return abs(velocityY) >= abs(velocityX)
    }
    
    func needSimultaneousGesture() -> Bool {
        if !self.enableSimultaneousGesture {
            return false
        }
        // 有actionview 不响应多手势
        if let hasView = self.simultaneousDelegate?.hasActionView {
            return !hasView
        }
        return false
    }
    
}

fileprivate extension UIPanGestureRecognizer {
    func elasticTranslation(in view: UIView?, withLimit limit: CGSize, fromOriginalCenter center: CGPoint, applyingRatio ratio: CGFloat = 0.20) -> CGPoint {
        let translation = self.translation(in: view)
        guard let sourceView = self.view else {
            return translation
        }
        let updatedCenter = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
        let distanceFromCenter = CGSize(width: abs(updatedCenter.x - sourceView.bounds.midX),
                                        height: abs(updatedCenter.y - sourceView.bounds.midY))
        let inverseRatio = 1.0 - ratio
        let scale: (x: CGFloat, y: CGFloat) = (updatedCenter.x < sourceView.bounds.midX ? -1 : 1, updatedCenter.y < sourceView.bounds.midY ? -1 : 1)
        let x = updatedCenter.x - (distanceFromCenter.width > limit.width ? inverseRatio * (distanceFromCenter.width - limit.width) * scale.x : 0)
        let y = updatedCenter.y - (distanceFromCenter.height > limit.height ? inverseRatio * (distanceFromCenter.height - limit.height) * scale.y : 0)
        return CGPoint(x: x, y: y)
    }
}
