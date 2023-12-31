//
//  AlignPopoverViewController.swift
//  ByteView
//
//  Created by Tobb Huang on 2020/11/16.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import SnapKit
import RxSwift
import ByteViewUI

protocol AlignPopoverPresentationDelegate: AnyObject {
    func didPresent()
    func didDismiss()
}

extension AlignPopoverPresentationDelegate {
    func didPresent() {}
    func didDismiss() {}
}

class AlignPopoverViewController: BaseViewController {

    private(set) var childVC: UIViewController
    private var anchor: AlignPopoverAnchor
    private let highlightedImageView: UIImageView = UIImageView()
    private var childView: UIView?

    weak var delegate: AlignPopoverPresentationDelegate?

    private var containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.backgroundColor = UIColor.ud.bgBody
        view.clipsToBounds = true
        return view
    }()

    private var shadowView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.backgroundColor = UIColor.ud.bgBody
        view.layer.ud.setShadowColor(UIColor.ud.shadowDefaultLg)
        view.layer.shadowOffset = CGSize(width: 0, height: 6)
        view.layer.shadowRadius = 24
        view.layer.shadowOpacity = 1
        return view
    }()

    init(childVC: UIViewController, anchor: AlignPopoverAnchor, delegate: AlignPopoverPresentationDelegate? = nil) {
        self.childVC = childVC
        self.anchor = anchor
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
        self.addChild(childVC)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = anchor.dimmingColor
        containerView.backgroundColor = anchor.containerColor
        shadowView.backgroundColor = anchor.containerColor

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismiss(tap:)))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)

        containerView.layer.cornerRadius = anchor.cornerRadius
        if let borderColor = anchor.borderColor {
            containerView.layer.borderWidth = 1.0
            containerView.layer.ud.setBorderColor(borderColor)
        }
        view.addSubview(containerView)

        if let shadowType = anchor.shadowType {
            view.layer.ud.setShadow(type: shadowType)
        } else if let shadowColor = anchor.shadowColor {
            shadowView.layer.ud.setShadowColor(shadowColor)
            shadowView.layer.cornerRadius = containerView.layer.cornerRadius
            view.insertSubview(shadowView, belowSubview: containerView)
        }

        highlightedImageView.clipsToBounds = true
        view.addSubview(highlightedImageView)

        highlightSourceView()
        repositionChildView()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return childVC.preferredStatusBarStyle
    }

    override var prefersStatusBarHidden: Bool {
        return childVC.prefersStatusBarHidden
    }

    override var shouldAutorotate: Bool {
        return childVC.shouldAutorotate
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return childVC.supportedInterfaceOrientations
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.containerView.alpha = 0
        self.shadowView.alpha = 0
        self.highlightedImageView.alpha = 0
        coordinator.animate(alongsideTransition: nil, completion: { [weak self] _ in
            // nolint-next-line: magic number
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.highlightSourceView()
                self?.repositionChildView()
                self?.view.layoutIfNeeded()
                // nolint-next-line: magic number
                UIView.animate(withDuration: 0.25) {
                    self?.containerView.alpha = 1
                    self?.shadowView.alpha = 1
                    self?.highlightedImageView.alpha = 1
                }
            }
        })
    }

    func update(childVC: UIViewController? = nil, anchor: AlignPopoverAnchor) {
        if let childVC = childVC {
            self.childVC.removeFromParent()
            self.childVC = childVC
            self.addChild(childVC)
        }
        self.anchor = anchor
        highlightSourceView()
        repositionChildView()
    }

    private func highlightSourceView() {
        highlightedImageView.isHidden = !anchor.highlightSourceView
        guard anchor.highlightSourceView else { return }

        let sourceView = anchor.sourceView
        if let controlView = sourceView as? UIControl {
            controlView.isHighlighted = false
        }

        guard let sourceFrame = sourceView.superview?.convert(sourceView.frame, to: self.view) else { return }
        highlightedImageView.image = sourceView.vc.screenshot()
        highlightedImageView.frame = sourceFrame
        highlightedImageView.layer.cornerRadius = sourceView.layer.cornerRadius
    }

    private func repositionChildView() {
        let sourceView = anchor.sourceView
        guard let sourceFrame = sourceView.superview?.convert(sourceView.frame, to: self.view) else { return }

        var contentWidth: CGFloat = 0
        switch anchor.contentWidth {
        case .equalToSourceView:
            contentWidth = sourceView.bounds.width
        case let .fixed(fixedWidth):
            contentWidth = fixedWidth
        }
        let contentMaxHeight = anchor.contentHeight

        let totalMaxWidth = contentWidth + anchor.contentInsets.left + anchor.contentInsets.right
        let totalMaxHeight = contentMaxHeight + anchor.contentInsets.top + anchor.contentInsets.bottom

        let topOffset: CGFloat
        let leftOffset: CGFloat
        let actualWidth: CGFloat
        let actualHeight: CGFloat
        switch anchor.alignmentType {
        case .auto:
            if let rect = calculateAutoOriginCoordinate(maxWidth: totalMaxWidth,
                                                        maxHeight: totalMaxHeight,
                                                        sourceFrame: sourceFrame) {
                leftOffset = rect.minX
                topOffset = rect.minY
                actualWidth = rect.width
                actualHeight = rect.height
            } else {
                return
            }
        default:
            if let rect = calculateOriginCoordinate(maxWidth: totalMaxWidth, maxHeight: totalMaxHeight, sourceFrame: sourceFrame) {
                leftOffset = rect.minX
                topOffset = rect.minY
                actualWidth = rect.width
                actualHeight = rect.height
            } else {
                return
            }
        }

        childView?.removeFromSuperview()

        childView = childVC.view
        containerView.addSubview(childVC.view)
        childVC.view.snp.remakeConstraints { (maker) in
            maker.width.equalTo(actualWidth - anchor.contentInsets.left - anchor.contentInsets.right)
            maker.height.equalTo(actualHeight - anchor.contentInsets.top - anchor.contentInsets.bottom)
            maker.edges.equalToSuperview().inset(anchor.contentInsets)
        }

        containerView.snp.remakeConstraints { (maker) in
            maker.top.equalToSuperview().offset(topOffset)
            maker.left.equalToSuperview().offset(leftOffset)
        }

        if shadowView.superview != nil {
            shadowView.snp.remakeConstraints { (maker) in
                maker.edges.equalTo(containerView)
            }
        }
    }

    private func calculateOriginCoordinate(maxWidth: CGFloat, maxHeight: CGFloat, sourceFrame: CGRect) -> CGRect? {
        guard anchor.alignmentType != .auto else { return nil }

        var topOffset: CGFloat = 0
        var leftOffset: CGFloat = 0
        switch anchor.arrowDirection {
        case .left:
            leftOffset = sourceFrame.maxX
        case .right:
            leftOffset = sourceFrame.minX - maxWidth
        case .up:
            topOffset = sourceFrame.maxY
        case .down:
            topOffset = sourceFrame.minY - maxHeight
        }

        switch (anchor.alignmentType, anchor.arrowDirection) {
        case (.left, _):
            leftOffset = sourceFrame.minX
        case (.right, _):
            leftOffset = sourceFrame.maxX - maxWidth
        case (.top, _):
            topOffset = sourceFrame.minY
        case (.bottom, _):
            topOffset = sourceFrame.maxY - maxHeight
        case (.center, .left), (.center, .right):
            topOffset = sourceFrame.midY - maxHeight / 2
        case (.center, .up), (.center, .down):
            leftOffset = sourceFrame.midX - maxWidth / 2
        default:
            return nil
        }

        leftOffset += anchor.positionOffset.x
        topOffset += anchor.positionOffset.y

        var actualWidth = maxWidth
        var actualHeight = maxHeight
        let minPadding = anchor.safeMinPadding
        let sceneWidth = VCScene.bounds.width
        let sceneHeight = VCScene.bounds.height

        // 计算左侧是否超出边界
        if leftOffset < minPadding.left {
            actualWidth -= (minPadding.left - leftOffset)
            leftOffset = minPadding.left
        }

        // 计算右侧是否超出边界
        if leftOffset + actualWidth > sceneWidth - minPadding.right {
            actualWidth = sceneWidth - minPadding.right - leftOffset
        }

        // 计算上侧是否超出边界
        if topOffset < minPadding.top {
            actualHeight -= (minPadding.top - topOffset)
            topOffset = minPadding.top
        }

        // 计算下侧是否超出边界
        if topOffset + actualHeight > sceneHeight - minPadding.bottom {
            actualHeight = sceneHeight - minPadding.bottom - topOffset
        }

        // 当宽/高被压缩时但一侧仍有空间时，无视对齐方式、强制拉伸
        // 上下拉伸
        if anchor.arrowDirection == .left || anchor.arrowDirection == .right {

            if actualHeight < maxHeight {
                if topOffset > minPadding.top {
                    let y = min(topOffset - minPadding.top, maxHeight - actualHeight)
                    topOffset -= y
                    actualHeight += y
                } else if topOffset + actualHeight < sceneHeight - minPadding.bottom {
                    let y = min(sceneHeight - topOffset - actualHeight - minPadding.bottom, maxHeight - actualHeight)
                    actualHeight += y
                }
            }
        }
        // 左右拉伸
        if anchor.arrowDirection == .up || anchor.arrowDirection == .down {

            if actualWidth < maxWidth {
                if leftOffset > minPadding.left {
                    let x = min(leftOffset - minPadding.left, maxWidth - actualWidth)
                    leftOffset -= x
                    actualWidth += x
                } else if leftOffset + actualWidth < sceneWidth - minPadding.right {
                    let x = min(sceneWidth - leftOffset - actualWidth - minPadding.right, maxWidth - actualWidth)
                    actualWidth += x
                }
            }
        }

        return CGRect(x: leftOffset, y: topOffset, width: actualWidth, height: actualHeight)
    }

    weak var fullScreenDetector: InMeetFullScreenDetector?
    private var blockFullScreenToken: BlockFullScreenToken?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.blockFullScreenToken = fullScreenDetector?.requestBlockAutoFullScreen()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.blockFullScreenToken?.invalidate()
    }

    // Menu自动布局规则：
    // 菜单默认出现在内容正下方;
    // 如果下方空间较少，气泡则自动适配出现到内容上方;
    // 如左方和右方空间较小，气泡无法出现在正下方，则视情况让气泡展示在左下方或右下方;
    // 如果左方、右方和下方，空间同时较小，则视情况让气泡展示在左上方或右上方
    // 详见: https://bytedance.feishu.cn/wiki/wikcnneokoPmTL4MkAZrzUvdChq#
    private func calculateAutoOriginCoordinate(maxWidth: CGFloat, maxHeight: CGFloat, sourceFrame: CGRect) -> CGRect? {
        guard anchor.alignmentType == .auto else { return nil }

        var actualWidth = maxWidth
        var actualHeight = maxHeight
        let minPadding = anchor.safeMinPadding
        let sceneWidth = VCScene.bounds.width
        let sceneHeight = VCScene.bounds.height

        // 首先尝试正下方
        var topOffset: CGFloat = sourceFrame.maxY + anchor.positionOffset.y
        var leftOffset: CGFloat = sourceFrame.midX - maxWidth / 2

        // 下方空间不够且下方空间小于上方，则切换到上方
        if topOffset + maxHeight + minPadding.bottom > sceneHeight {
            let topSpace = sourceFrame.minY - anchor.positionOffset.y - minPadding.top
            let bottomSpace = sceneHeight - sourceFrame.maxY - anchor.positionOffset.y - minPadding.bottom
            if topSpace > bottomSpace {
                topOffset = sourceFrame.minY - maxHeight - anchor.positionOffset.y
            }
        }

        if leftOffset - minPadding.left < 0 {
            // 左边空间不够，则切换到左对齐
            leftOffset = sourceFrame.minX
        } else if leftOffset + maxWidth + minPadding.right > sceneWidth {
            // 右边空间不够，则切换到右对齐
            leftOffset = sourceFrame.maxX - maxWidth
        }

        // 计算左侧是否超出边界
        if leftOffset < minPadding.left {
            actualWidth -= (minPadding.left - leftOffset)
            leftOffset = minPadding.left
        }

        // 计算右侧是否超出边界
        if leftOffset + actualWidth > sceneWidth - minPadding.right {
            actualWidth = sceneWidth - minPadding.right - leftOffset
        }

        // 计算上侧是否超出边界
        if topOffset < minPadding.top {
            actualHeight -= (minPadding.top - topOffset)
            topOffset = minPadding.top
        }

        // 计算下侧是否超出边界
        if topOffset + actualHeight > sceneHeight - minPadding.bottom {
            actualHeight = sceneHeight - minPadding.bottom - topOffset
        }

        return CGRect(x: leftOffset, y: topOffset, width: actualWidth, height: actualHeight)
    }

    @objc private func dismiss(tap: UITapGestureRecognizer) {
        let point = tap.location(in: self.view)
        if !self.containerView.frame.contains(point) {
            AlignPopoverManager.shared.dismiss(animated: true)
        }
    }

    func update(sourceView: UIView) {
        anchor.sourceView = sourceView
        highlightSourceView()
        repositionChildView()
    }
}
