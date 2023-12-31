//
//  ClearCacheView.swift
//  ByteWebImage
//
//  Created by Saafo on 2022/9/5.
//

import UIKit

class ClearCacheViewManager {
    static func viewExisted(on view: UIView) -> Bool {
        cacheView(on: view) != nil
    }
    static func showView(on view: UIView) {
        _ = UIWindow.hookDidAddSubviewIfNeeded
        guard !viewExisted(on: view) else { return }
        let floatView = FloatView(title: "图片缓存", subview: ClearCacheView())
        floatView.layoutSubviews() // make sure bounds is correct
        // right bottom corner
        let superBounds = view.frame.inset(by: view.safeAreaInsets)
        floatView.frame.origin = CGPoint(x: superBounds.maxX - floatView.bounds.width,
                                         y: superBounds.maxY - floatView.bounds.height)
        floatView.tag = clearCacheViewTag
        view.addSubview(floatView)
    }
    static func hideView(on view: UIView) {
        view.viewWithTag(clearCacheViewTag)?.removeFromSuperview()
    }

    static func makeViewTop(on view: UIView) {
        if let cacheView = cacheView(on: view) {
            cacheView.superview?.bringSubviewToFront(cacheView)
        }
    }

    private static func cacheView(on view: UIView) -> UIView? {
        view.viewWithTag(clearCacheViewTag)
    }

    private static let clearCacheViewTag = 114_514
}

class ClearCacheView: UIView {
    var memoryButton: UIButton!
    var allButton: UIButton!
    var sdkButton: UIButton!

    enum UI {
        static let buttonRadius: CGFloat = 8
        static let buttonHeight: CGFloat = 30
        static let buttonBorderWidth: CGFloat = 1 / UIScreen.main.scale
        static let padding: CGFloat = 6
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        memoryButton = makeButton()
        memoryButton.setTitle("清除内存缓存", for: .normal)
        memoryButton.addTarget(self, action: #selector(clearMemoryCache), for: .touchUpInside)
        addSubview(memoryButton)
        allButton = makeButton()
        allButton.setTitle("清除内存磁盘缓存", for: .normal)
        allButton.addTarget(self, action: #selector(clearAllCache), for: .touchUpInside)
        addSubview(allButton)
        sdkButton = makeButton()
        sdkButton.setTitle("清除SDK图片缓存", for: .normal)
        sdkButton.addTarget(self, action: #selector(clearSDKCache), for: .touchUpInside)
        addSubview(sdkButton)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        memoryButton.frame = CGRect(origin: CGPoint(x: UI.padding, y: UI.padding),
                                    size: CGSize(width: bounds.width - 2 * UI.padding, height: UI.buttonHeight))
        allButton.frame = CGRect(origin: CGPoint(x: UI.padding, y: memoryButton.frame.maxY + UI.padding),
                                 size: CGSize(width: bounds.width - 2 * UI.padding, height: UI.buttonHeight))
        sdkButton.frame = CGRect(origin: CGPoint(x: UI.padding, y: allButton.frame.maxY + UI.padding),
                                 size: CGSize(width: bounds.width - 2 * UI.padding, height: UI.buttonHeight))
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let memoryButtonSize = sizeForButton(memoryButton)
        let allButtonSize = sizeForButton(allButton)
        let width = max(memoryButtonSize.width, allButtonSize.width) + 2 * UI.padding
        let height = 3 * (UI.buttonHeight + UI.padding) + UI.padding
        return CGSize(width: width, height: height)
    }

    @objc
    func clearMemoryCache() {
        memoryButton.isUserInteractionEnabled = false
        let originText = memoryButton.title(for: .normal)
        memoryButton.setTitle("清除中...", for: .normal)
        LarkImageService.Debug.clearMemoryCache()
        memoryButton.setTitle("清除成功", for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.memoryButton.setTitle(originText, for: .normal)
            self?.memoryButton.isUserInteractionEnabled = true
        }
    }

    @objc
    func clearAllCache() {
        allButton.isUserInteractionEnabled = false
        let originText = allButton.title(for: .normal)
        allButton.setTitle("清除中...", for: .normal)
        LarkImageService.Debug.clearMemoryAndDiskCache()
        allButton.setTitle("清除成功", for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.allButton.setTitle(originText, for: .normal)
            self?.allButton.isUserInteractionEnabled = true
        }
    }

    @objc
    func clearSDKCache() {
        sdkButton.isUserInteractionEnabled = false
        let originText = sdkButton.title(for: .normal)
        sdkButton.setTitle("清除中...", for: .normal)
        let result = LarkImageService.Debug.clearSDKCache()
        let text = result ? "清除成功" : "清除失败"
        sdkButton.setTitle(text, for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.sdkButton.setTitle(originText, for: .normal)
            self?.sdkButton.isUserInteractionEnabled = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeButton() -> UIButton {
        let button = UIButton()
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.layer.cornerRadius = UI.buttonRadius
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = UI.buttonBorderWidth
        return button
    }

    private func sizeForButton(_ button: UIButton) -> CGSize {
        let intrinsicSize = button.intrinsicContentSize
        return CGSize(width: intrinsicSize.width + UI.padding * 2, height: intrinsicSize.height + UI.padding * 2)
    }
}

class FloatView: UIView {

    let titleLabel: UILabel
    let closeButton: UIButton
    let subview: UIView

    enum UI {
        static let padding: CGFloat = 6
        static let alpha: CGFloat = 0.6
        static let buttonSize: CGFloat = 14
        static let radius: CGFloat = 8
    }

    init(title: String, subview: UIView) {
        // setup
        titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.baselineAdjustment = .alignCenters
        titleLabel.textColor = .white
        closeButton = UIButton()
        if #available(iOS 13.0, *) {
            closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        } else {
            closeButton.setImage(UIImage(named: "xmark"), for: .normal)
            closeButton.imageView?.contentMode = .scaleAspectFill
        }
        closeButton.tintColor = .white
        self.subview = subview
        super.init(frame: .zero)
        addSubview(titleLabel)
        addSubview(closeButton)
        addSubview(subview)
        backgroundColor = .darkGray.withAlphaComponent(UI.alpha)
        layer.cornerRadius = UI.radius
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // layout
        titleLabel.frame = CGRect(origin: CGPoint(x: UI.padding, y: UI.padding),
                                  size: titleLabel.intrinsicContentSize)
        let titleWidth = titleLabel.intrinsicContentSize.width + UI.buttonSize + 3 * UI.padding
        let subviewSize = subview.sizeThatFits(.zero)
        let subviewWidth = subviewSize.width + 2 * UI.padding
        let width = max(titleWidth, subviewWidth)
        closeButton.frame = CGRect(origin: CGPoint(x: width - UI.padding - UI.buttonSize, y: UI.padding),
                                   size: CGSize(width: UI.buttonSize, height: UI.buttonSize))
        subview.frame = CGRect(origin: CGPoint(x: UI.padding, y: titleLabel.frame.maxY + UI.padding),
                               size: subviewSize)
        bounds = CGRect(origin: .zero, size: CGSize(width: width, height: subview.frame.maxY + UI.padding))
    }

    @objc
    func close() {
        self.removeFromSuperview()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Drag interaction
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        let touch = touches.first

        guard let newPlace = touch?.preciseLocation(in: touch?.view?.superview),
              let oldPlace = touch?.previousLocation(in: touch?.view?.superview) else {
            return
        }
        let offsetX = newPlace.x - oldPlace.x
        let offsetY = newPlace.y - oldPlace.y
        let newFrame = frame.offsetBy(dx: offsetX, dy: offsetY)
        if let superview = superview {
            let validRect = superview.frame.inset(by: superview.safeAreaInsets)
            guard validRect.contains(newFrame) else { return }
        }
        frame = newFrame
    }
}

extension UIWindow {
    @objc
    private func bt_didAddSubview(_ subview: UIView) {
        bt_didAddSubview(subview)
        ClearCacheViewManager.makeViewTop(on: self)
    }

    static let hookDidAddSubviewIfNeeded: Void = {
        swizzling(forClass: UIWindow.self, originalSelector: #selector(UIWindow.didAddSubview),
                  swizzledSelector: #selector(UIWindow.bt_didAddSubview))
    }()

}

private func swizzling(forClass: AnyClass, originalSelector: Selector, swizzledSelector: Selector) {
    guard let originalMethod = class_getInstanceMethod(forClass, originalSelector),
          let swizzledMethod = class_getInstanceMethod(forClass, swizzledSelector) else {
        return
    }
    if class_addMethod(
        forClass,
        originalSelector,
        method_getImplementation(swizzledMethod),
        method_getTypeEncoding(swizzledMethod)
    ) {
        class_replaceMethod(
            forClass,
            swizzledSelector,
            method_getImplementation(originalMethod),
            method_getTypeEncoding(originalMethod)
        )
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}
