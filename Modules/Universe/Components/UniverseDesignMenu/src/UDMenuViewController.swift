//
//  UDMenuViewController.swift
//  UDMenu
//
//  Created by  豆酱 on 2020/10/26.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignStyle
import UniverseDesignPopover
import UniverseDesignShadow

final class UDMenuViewController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    var actions: [UDMenuAction]
    let style: UDMenuStyleConfig
    let config: UDMenuConfig

    let popSource: UDPopoverSource
    private let menuViewBoarderWidth: CGFloat = 1

    let dismissed: (() -> Void)?

    var sourceRect: CGRect {
        return popSource.sourceRect
    }

    private var isPopover: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    var menuSize: CGSize = .zero
    var actionHeights: [CGFloat] = []

    // popover 下的圆角展示不全会被裁切，因此 popover 下将展示和系统 popover 一致的圆角
    private let popoverCornerRadius: CGFloat = 15

    // popover 下因为有箭头，所以将不在 popover 箭头模式下展示边框
    private var shouldShowBorder: Bool {
        guard isPopover else { return true }
        guard style.showArrowInPopover else { return true }
        return false
    }

    lazy var menuView: UITableView = {
        let menuView = UITableView(frame: CGRect.zero, style: .plain)
        menuView.backgroundColor = self.style.menuColor
        menuView.separatorStyle = .none
        menuView.alwaysBounceVertical = false
        menuView.estimatedRowHeight = style.menuItemHeight
        menuView.rowHeight = UITableView.automaticDimension
        menuView.register(UDMenuActionCell.self, forCellReuseIdentifier: UDMenuActionCell.ReuseIdentifier)
        let insetValue = self.style.menuListInset
        menuView.contentInset = UIEdgeInsets(top: insetValue, left: 0, bottom: insetValue, right: 0)
        menuView.layer.cornerRadius = isPopover ? popoverCornerRadius : self.style.cornerRadius
        menuView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        menuView.layer.borderWidth = shouldShowBorder ? menuViewBoarderWidth : 0
        menuView.delegate = self
        menuView.dataSource = self
        return menuView
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(popSource: UDPopoverSource,
         actions: [UDMenuAction],
         style: UDMenuStyleConfig,
         config: UDMenuConfig,
         dismissed: (() -> Void)? = nil) {
        self.actions = actions
        self.style = style
        self.config = config
        self.popSource = popSource
        self.dismissed = dismissed
        super.init(nibName: nil, bundle: nil)

        if isPopover {
            self.modalPresentationStyle = .popover
            self.popoverPresentationController?.delegate = self
            if !style.showArrowInPopover {
                self.popoverPresentationController?.popoverBackgroundViewClass = NoArrowPopoverBackgroundView.self
            }
            self.popoverPresentationController?.permittedArrowDirections = popSource.arrowDirection
            self.popoverPresentationController?.sourceView = popSource.sourceView
            self.popoverPresentationController?.sourceRect = popSource.sourceView?
                .bounds.insetBy(dx: -CGFloat(abs(style.menuOffsetFromSourceView)),
                                dy: -CGFloat(abs(style.menuOffsetFromSourceView))) ?? .zero
        } else {
            self.modalPresentationStyle = .overFullScreen
            self.transitioningDelegate = self
        }
    }

    // MARK: view lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        if !isPopover {
            /// iPad上不应该有背景色
            self.view.backgroundColor = style.maskColor
        }

        view.addSubview(menuView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapBackgroundHandler))
        tap.delegate = self
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        makeConstraints()
        setAppearance()
    }

    // swiftlint:disable control_statement function_body_length
    func makeConstraints() {
        self.menuSize = calculateMenuSize()
        let menuHeight = menuSize.height
        let menuWidth = menuSize.width
        let marginToSourceY = CGFloat(style.marginToSourceY)
        let marginToSourceX = CGFloat(style.marginToSourceX)
        let sourceCenterX = sourceRect.minX + sourceRect.width / 2
        let sourceBottom = sourceRect.maxY
        let sourceTop = sourceRect.minY

        var menuBelowSource = true
        var menuAlignSourceRight = false
        var menuAlignSourceLeft = false

        if isPopover {
            /// 约束inset 设置的1，所以width + 2 Fix: 原来宽度+2 iPad表现很奇怪
            self.preferredContentSize = CGSize(width: menuSize.width, height: menuSize.height)
        }

        // 默认情况下，Menu 处于 source 下方
        // 例外： 下方可用空间 < 上方可用空间 ==> (view.height - bottom - safeAreaInset.bottom) <（top - safeAreaInset.top)
        //       && 且下方空间，放不下 menuView
        if(view.bounds.height - sourceBottom - view.safeAreaInsets.bottom < sourceTop - view.safeAreaInsets.top
            && sourceRect.maxY + marginToSourceY + menuHeight + view.safeAreaInsets.bottom > view.frame.height) {
            menuBelowSource = false
        }

        // 3. 判定 MenuView 是否与 SourceRect 左/右对齐，默认情况下，居中对齐

        // superLargeMenuWidth 为临时变量，防止超长的 MenuWidth 在这儿计算错误，最后同时左右都对齐导致最后布局错误
        let superLargeMenuWidth = menuWidth > (MenuCons.sceneFrame.width / 2) ? (menuWidth / 2) : menuWidth
        if(sourceCenterX + superLargeMenuWidth + view.safeAreaInsets.right > view.frame.maxX) {
            menuAlignSourceRight = true
        }

        if(sourceCenterX - superLargeMenuWidth - view.safeAreaInsets.left < view.frame.minX) {
            menuAlignSourceLeft = true
        }

        switch config.position {
        case .bottomAuto:
            menuBelowSource = true
        case .bottomLeft:
            menuBelowSource = true
            menuAlignSourceLeft = true
            menuAlignSourceRight = false
        case .bottomRight:
            menuBelowSource = true
            menuAlignSourceLeft = false
            menuAlignSourceRight = true
        case .topAuto:
            menuBelowSource = false
        case .topLeft:
            menuBelowSource = false
            menuAlignSourceLeft = true
            menuAlignSourceRight = false
        case .topRight:
            menuBelowSource = false
            menuAlignSourceLeft = false
            menuAlignSourceRight = true
        case .auto:
            self.popoverPresentationController?.permittedArrowDirections = menuBelowSource ? .up : .down
            break
        }

        menuView.snp.remakeConstraints { (maker) in
            if isPopover {
                maker.edges.equalToSuperview()
            } else {
                if(menuBelowSource) {
                    maker.top.equalToSuperview().inset(sourceBottom + marginToSourceY)
                } else {
                    maker.bottom.equalTo(view.snp.top).offset(sourceTop - marginToSourceY)
                }

                if(menuAlignSourceLeft) {
                    maker.left.equalToSuperview().inset(sourceRect.minX - marginToSourceX)
                }
                if(menuAlignSourceRight) {
                    maker.right.equalToSuperview().inset(view.bounds.width - sourceRect.maxX - marginToSourceX)
                }
                if(!menuAlignSourceRight && !menuAlignSourceLeft) {
                    maker.centerX.equalTo(view.snp.left).inset(sourceCenterX)
                }

                maker.height.equalTo(menuHeight).priority(.medium)
                maker.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.bottom).priority(.high)
                maker.top.greaterThanOrEqualTo(view.safeAreaLayoutGuide.snp.top).priority(.high)
                maker.width.equalTo(menuWidth).priority(.low)
                maker.left.greaterThanOrEqualToSuperview()
                maker.right.lessThanOrEqualToSuperview()
            }
        }
    }

    private func setAppearance() {
        switch self.style.menuShadowSize {
        case .small:
            switch self.style.menuShadowPosition {
            case .down:
                self.view.layer.ud.setShadow(type: .s3Down)
            case .up:
                self.view.layer.ud.setShadow(type: .s3Up)
            case .left:
                self.view.layer.ud.setShadow(type: .s3Left)
            case .right:
                self.view.layer.ud.setShadow(type: .s3Right)
            default:
                self.view.layer.ud.setShadow(type: .s3Down)
                self.view.layer.ud.setShadow(type: .s3Up)
                self.view.layer.ud.setShadow(type: .s3Left)
                self.view.layer.ud.setShadow(type: .s3Right)
            }
        case .medium:
            switch self.style.menuShadowPosition {
            case .down:
                self.view.layer.ud.setShadow(type: .s4Down)
            case .up:
                self.view.layer.ud.setShadow(type: .s4Up)
            case .left:
                self.view.layer.ud.setShadow(type: .s4Left)
            case .right:
                self.view.layer.ud.setShadow(type: .s4Right)
            default:
                self.view.layer.ud.setShadow(type: .s4Down)
                self.view.layer.ud.setShadow(type: .s4Up)
                self.view.layer.ud.setShadow(type: .s4Left)
                self.view.layer.ud.setShadow(type: .s4Right)
            }
        case .large:
            switch self.style.menuShadowPosition {
            case .down:
                self.view.layer.ud.setShadow(type: .s5Down)
            case .up:
                self.view.layer.ud.setShadow(type: .s5Up)
            case .left:
                self.view.layer.ud.setShadow(type: .s5Left)
            case .right:
                self.view.layer.ud.setShadow(type: .s5Right)
            default:
                self.view.layer.ud.setShadow(type: .s5Down)
                self.view.layer.ud.setShadow(type: .s5Up)
                self.view.layer.ud.setShadow(type: .s5Left)
                self.view.layer.ud.setShadow(type: .s5Right)
            }
        }
    }

    /// 计算menuSize
    private func calculateMenuSize() -> CGSize {
        let menuWidth = widthForItems(actions)
        var menuHeight: CGFloat = style.menuListInset * 2
        for action in actions {
            let height = heightForItem(action, withMaxWidth: menuWidth)
            menuHeight += height
            actionHeights.append(height)
        }
        return CGSize(width: menuWidth, height: menuHeight)
    }

    /// 计算最长宽度
    private func widthForItems(_ items: [UDMenuAction]) -> CGFloat {
        if let menuWidth = style.menuWidth {
            return menuWidth
        }
        var maxTextWidth: CGFloat = 0
        let textSize = CGSize(width: CGFloat.infinity, height: CGFloat.infinity)
        for action in items {
            maxTextWidth = max(getTextWidthAndHeight(text: action.title,
                                                      font: MenuCons.titleFont,
                                                      textSize: textSize).width, maxTextWidth)
            if style.showSubTitleInOneLine, let subTitle = action.subTitle  {
                maxTextWidth = max(getTextWidthAndHeight(text: subTitle,
                                                             font: MenuCons.subTitleFont,
                                                             textSize: textSize).width, maxTextWidth)
            }
        }
        let totalWidth = MenuCons.otherWidth + maxTextWidth
        if totalWidth >= style.menuMaxWidth {
            return style.menuMaxWidth
        } else if totalWidth < style.menuMinWidth {
            return style.menuMinWidth
        } else {
            return ceil(totalWidth)
        }
    }

    /// 计算单个cell高度
    private func heightForItem(_ item: UDMenuAction, withMaxWidth width: CGFloat) -> CGFloat {
        var actionDividerHeight: CGFloat = 0
        if item.showBottomBorder {
            actionDividerHeight = MenuCons.menuDivideViewHeight
        }

        guard let subTitle = item.subTitle else {
            return MenuCons.menuItemDefaultHeight + actionDividerHeight
        }
        let textWidth = width - MenuCons.otherWidth
        let textSize = CGSize(width: textWidth, height: CGFloat.infinity)
        var menuSubTitleHeight: CGFloat = getTextWidthAndHeight(text: subTitle,
                                                            font: MenuCons.subTitleFont,
                                                            textSize: textSize).height
        if menuSubTitleHeight > MenuCons.subTitleLineHeight {
            menuSubTitleHeight = MenuCons.subTitleLineHeight * 2
        } else {
            menuSubTitleHeight = MenuCons.subTitleLineHeight
        }
        return ceil(menuSubTitleHeight + MenuCons.otherHeight + actionDividerHeight)
    }

    /// 获取文本的宽高
    private func getTextWidthAndHeight(text: String, font: UIFont, textSize: CGSize) -> CGRect {
        var size: CGRect
        let lineHeight = font.figmaHeight
        let baselineOffset = (lineHeight - font.lineHeight) / 2.0 / 2.0
        let mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.minimumLineHeight = lineHeight
        mutableParagraphStyle.maximumLineHeight = lineHeight
        size = (text as NSString).boundingRect(with: textSize,
                                               options: [.usesLineFragmentOrigin],
                                               attributes: [
                                                    .font: font,
                                                    .baselineOffset : baselineOffset,
                                                    .paragraphStyle : mutableParagraphStyle
                                                    ],
                                               context: nil)
        return size
    }


    @objc
    private func tapBackgroundHandler() {
        dismissMenuAsync()
    }
    
    private func dismissMenuAsync(_ completion: (() -> Void)? = nil) {
        dismiss(animated: true) { [weak self] in
            self?.dismissed?()
            completion?()
        }
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // 分屏，旋转时关闭菜单
        if self.isPopover {
            self.dismiss(animated: true)
        } else {
            self.dismiss(animated: true, completion: dismissed)
        }
    }
}

extension UDMenuViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !(touch.view?.isDescendant(of: menuView) ?? false)
    }
}

extension UDMenuViewController: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UDMenuActionCell.ReuseIdentifier, for: indexPath)
        if let cell = cell as? UDMenuActionCell {
            guard indexPath.row < actions.count else {
                return cell
            }
            let action = actions[indexPath.row]
            cell.configure(action: action, style: style)
            cell.selectionStyle = action.isDisabled ? .none : .default
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.row < actions.count, indexPath.row < actionHeights.count else {
            return 0
        }
        return actionHeights[indexPath.row]
    }
}

extension UDMenuViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < actions.count else {
            dismissMenuAsync()
            return
        }
        let action = actions[indexPath.row]
        let handler = action.isDisabled ? action.tapDisableHandler : action.tapHandler
        if action.shouldInvokeTapHandlerAfterMenuDismiss {
            dismissMenuAsync(handler)
        } else {
            dismissMenuAsync()
            handler?()
        }
    }

}

extension UDMenuViewController: UIViewControllerTransitioningDelegate, UIPopoverPresentationControllerDelegate {
    // swiftlint:disable line_length
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return UDMenuAminator(presentStyle: .present)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return UDMenuAminator(presentStyle: .dismiss)
    }

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

// unit test support, need expose some private variables
extension UDMenuViewController {
    #if DEBUG
    func menuTableView() -> UITableView {
        return menuView
    }
    #endif
}
