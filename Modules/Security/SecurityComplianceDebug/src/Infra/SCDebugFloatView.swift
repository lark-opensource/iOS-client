//
//  SCDebugFloatView.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/11/28.
//

import Foundation
import UIKit
import LarkSecurityComplianceInfra
import UniverseDesignIcon
import UniverseDesignColor

final class SecurityComplianeDebugFloatView: UIView, UIGestureRecognizerDelegate {
    
    private(set) static var floatViewTags = [Int]()

    // 经验值
    let minWidth: CGFloat = 50
    let minHieght: CGFloat = 50
    let minScale: CGFloat = 0.5
    let maxScale: CGFloat = 8

    let closeButton: UIButton = {
        let button  = UIButton()
        let closeIcon = UDIcon.getIconByKey(.closeOutlined).ud.withTintColor(.ud.N00)
        button.setImage(closeIcon, for: .normal)
        return button
    }()

    init(viewTag: Int, isZoomable: Bool = false) {
        super.init(frame: .zero)
        guard !Self.floatViewTags.contains(viewTag) else {
            assertionFailure("当前已有 tag 相同的 SecurityComplianeDebugFloatView 实例")
            return
        }
        Self.floatViewTags.append(viewTag)
        let _ = UIWindow.hookDidAddSubview
        
        backgroundColor = UIColor.ud.textTitle.withAlphaComponent(0.5)
        tag = viewTag
        alpha = 0.6

        if isZoomable {
            let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
            addGestureRecognizer(pinchGesture)
        }
        closeButton.addTarget(self, action: #selector(closeButtonClicked(_:)), for: .touchUpInside)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.maximumNumberOfTouches = 1
        addGestureRecognizer(panGesture)

        addSubview(closeButton)
        closeButton.snp.makeConstraints {
            $0.width.height.equalTo(20)
            $0.right.top.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        Self.floatViewTags.removeAll(where: { $0 == tag })
    }

    override func addSubview(_ view: UIView) {
        super.addSubview(view)
        guard view != closeButton else { return }
        view.snp.remakeConstraints {
            $0.top.equalTo(closeButton.snp.bottom)
            $0.left.right.bottom.equalToSuperview()
        }
        view.backgroundColor = .clear
    }

    @objc
    private func closeButtonClicked(_ sender: UIButton) {
        removeFromSuperview()
    }

    @objc
    private func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        let position = sender.location(in: superview)
        let cgRect = frame.offsetBy(dx: position.x - frame.centerX, dy: position.y - frame.centerY)
        updateLocationIfCan(newCGRect: cgRect)
    }

    @objc
    private func handlePinchGesture(_ sender: UIPinchGestureRecognizer) {
        guard sender.state == .changed else { return }
        let scale = max(min(sender.scale, maxScale), minScale)
        let cgRect = frame.scaleTo(scale)
        updateLocationIfCan(newCGRect: cgRect)
    }

    private func updateLocationIfCan(newCGRect: CGRect) {
        guard newCGRect.width > minWidth,
              newCGRect.height > minHieght,
              let safeAreaFrame = superview?.frame.inset(by: LayoutConfig.safeAreaInsets),
              safeAreaFrame.contains(newCGRect) else { return }
        snp.remakeConstraints {
            $0.left.equalTo(newCGRect.minX)
            $0.top.equalTo(newCGRect.minY)
            $0.size.equalTo(newCGRect.size)
        }
    }
}

extension CGRect {
    fileprivate func scaleTo(_ scale: CGFloat) -> CGRect{
        let offsetX = (scale - 1) * width * 0.5
        let offsetY = (scale - 1) * height * 0.5
        let newWidth = scale * width
        let newHeight = scale * height
        return CGRect(x: minX + offsetX, y: minY + offsetY, width: newWidth, height: newHeight)
    }
}
