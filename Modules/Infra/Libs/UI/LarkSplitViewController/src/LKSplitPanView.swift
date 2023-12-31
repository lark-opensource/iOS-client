//
//  LKSplitPanView.swift
//  LarkSplitViewController
//
//  Created by 李晨 on 2021/3/29.
//

import UIKit
import Foundation
import LarkInteraction
import LarkKeyboardKit
import LKCommonsLogging
import LKCommonsTracker
import SnapKit
import RxSwift
import UniverseDesignColor

final class SplitPanView: UIView {

    var handleView = IndicatorView()
    var handleWrapperView = UIView()
    var hotAreaView = UIView()
    var highlightLine = UIView()
    var highlightLineShouldHidden = true {
        didSet {
            updateHighlightLineHidden()
        }
    }
    var isRight = true {
        didSet {
            updateHighlightLineLayout()
        }
    }

    /// 是否忽略系统 hitTest 调用
    private var ignoreHitTest = false

    var dragging: Bool = false {
        didSet {
            self.updateHandleViewColor()
            self.updateHighlightLineHidden()
            self.updateHighlightLineLayout()
        }
    }
    let keyboardDisposeBag = DisposeBag()

    init() {
        super.init(frame: .zero)

        // 设置 alpha 和 color 是为了处理
        // hittest 必须有颜色才能真正的拦截下方 remoteView 的手势和触摸
        hotAreaView.alpha = 0.01
        hotAreaView.backgroundColor = UIColor.white.withAlphaComponent(0.01)
        self.addSubview(hotAreaView)
        self.addSubview(handleWrapperView)
        handleWrapperView.addSubview(handleView)
        handleView.layer.cornerRadius = 2.5
        updateHandleViewLayout()
        updateHandleViewColor()

        self.addSubview(highlightLine)
        highlightLine.backgroundColor = UIColor.ud.lineDividerDefault
        updateHighlightLineLayout()
        updateHighlightLineHidden()

        hotAreaView.snp.makeConstraints { (maker) in
            maker.center.equalTo(handleView)
            maker.height.equalTo(200)
            maker.width.equalTo(24)
        }

        handleWrapperView.snp.makeConstraints { (maker) in
            maker.center.equalTo(handleView)
            maker.width.equalTo(handleView).offset(8)
            maker.height.equalTo(handleView).offset(12)
        }

        handleWrapperView.addPointer(.highlight(shape: { (size) -> PointerInfo.ShapeSizeInfo in
            return (size, size.width / 2)
        }))

        // 监听键盘出现
        KeyboardKit.shared
            .keyboardEventChange
            .observeOn(MainScheduler.instance)
            .filter({ (event) -> Bool in
                let handleEventType: [KeyboardEvent.TypeEnum] = [
                    .willShow, .willHide
                ]
                return handleEventType.contains(event.type)
            })
            .subscribe(onNext: { [weak self] (event) in
                var keyboardHeight: CGFloat = 0
                if event.type == .willShow {
                    keyboardHeight = event.keyboard.frame.height
                }
                self?.updateHandleViewLayout(keyboardHeight: keyboardHeight)
                UIView.animate(
                    withDuration: event.options.animationDuration,
                    delay: 0,
                    options: event.options.animationOptions,
                    animations: {
                        self?.layoutIfNeeded()
                    }, completion: nil)

            }).disposed(by: self.keyboardDisposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateHighlightLineLayout() {
        highlightLine.snp.remakeConstraints { (make) in
            make.width.equalTo(dragging ? 3 : 0.5)
            make.top.bottom.equalToSuperview()
            if isRight {
                make.leading.equalTo(16)
            } else {
                make.trailing.equalTo(-20)
            }
        }
    }

    private func updateHighlightLineHidden() {
        highlightLine.isHidden = !dragging && highlightLineShouldHidden
        highlightLine.backgroundColor = dragging ? UIColor.ud.colorfulBlue : UIColor.ud.lineDividerDefault
    }

    private func updateHandleViewLayout(keyboardHeight: CGFloat = 0) {
        handleView.snp.remakeConstraints { (make) in
            make.width.equalTo(5)
            make.height.equalTo(36)
            make.leading.equalTo(self).offset(23)
            make.centerY.equalTo(self).offset(-keyboardHeight / 2)
        }
    }

    private func updateHandleViewColor() {
        if handleView.fallback {
            handleView.alpha = 1
            handleView.backgroundColor = UIColor.ud.N900.withAlphaComponent(dragging ? 0.6 : 0.3)
        } else {
            handleView.alpha = dragging ? 0.6 : 0.3
            handleView.backgroundColor = .clear
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if ignoreHitTest {
            return nil
        }
        let hitView = super.hitTest(point, with: event)
        if hitView == self.handleWrapperView || hitView == self.handleView {
            return hitView
        }

        if hitView == self.hotAreaView {
            /// 如果识别在热区内部 判断下层响应的是否是 _UIRemoteView
            /// 如果是 则直接返回 hotAreaView
            self.ignoreHitTest = true
            defer {
                self.ignoreHitTest = false
            }
            let new = self.convert(point, to: self.superview)
            if let remoteClass = NSClassFromString("_UIRemoteView"),
               let superHitView = self.superview?.hitTest(new, with: nil),
               superHitView.isKind(of: remoteClass) {
                return hitView
            }
        } else {
            let new = self.convert(point, to: self.hotAreaView)
            if self.hotAreaView.layer.contains(new) {
                return hitView
            }
        }
        return nil
    }
}

final class SplitPanGestureRecognizer: UIPanGestureRecognizer {

    var touchBeginPoint: CGPoint?

    var translation: CGPoint? {
        guard let startPoint = self.touchBeginPoint,
            let gestureView = self.view else {
            return nil
        }
        let location = self.location(in: gestureView)
        return CGPoint(
            x: location.x - startPoint.x,
            y: location.y - startPoint.y
        )
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        self.touchBeginPoint = self.location(in: self.view)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        self.touchBeginPoint = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        self.touchBeginPoint = nil
    }

    @available(iOS 13.4, *)
    override func shouldReceive(_ event: UIEvent) -> Bool {
        // 事件开始前 重置 startPoint,兼容触控板
        self.touchBeginPoint = nil
        return super.shouldReceive(event)
    }
}

final class IndicatorView: UIView {
    override class var layerClass: AnyClass {
        return Cons.Layer.capturableClass ?? CALayer.self
    }

    /// 是否处于兜底模式
    var fallback = true

    private static let logger = Logger.log(IndicatorView.self, category: "LarkSplitViewController.IndicatorView")

    init() {
        super.init(frame: .zero)

        guard type(of: layer) == Cons.Layer.capturableClass,
              let home = filter(with: Cons.FilterName.home),
              let brightness = filter(with: Cons.FilterName.brightness),
              let saturate = filter(with: Cons.FilterName.saturate),
              let invert = filter(with: Cons.FilterName.invert),
              let colorMap = Resources.colorMap.cgImage else {
            let category = [
                "create_layer_class": type(of: layer) == Cons.Layer.capturableClass,
                "create_home_filter": filter(with: Cons.FilterName.home) != nil,
                "create_brightness_filter": filter(with: Cons.FilterName.brightness) != nil,
                "create_saturate_filter": filter(with: Cons.FilterName.saturate) != nil,
                "create_invert_filter": filter(with: Cons.FilterName.invert) != nil
            ]
            Tracker.trackCreateIndicatorViewError(infoCategory: category)
            Self.logger.error("Failed to create IndicatorView: \(category)")
            fallback = true
            return
        }

        home.setValue(colorMap, forKey: Cons.FilterKey.colorMap)
        home.setValue(0.3, forKey: Cons.FilterKey.amount)
        home.setValue(0.4, forKey: Cons.FilterKey.addWhite)
        home.setValue(0.4, forKey: Cons.FilterKey.overlayOpacity)

        saturate.setValue(0, forKey: Cons.FilterKey.amount)

        brightness.setValue(0.06, forKey: Cons.FilterKey.amount)

        layer.filters = [home, brightness, saturate, invert]
        fallback = false
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private enum Cons {
        enum Layer {
            static let capturable: String = decryptedString("Q0FCYWNrZHJvcExheWVy") // CABackdropLayer
            static let capturableClass: AnyClass? = NSClassFromString(capturable) // CABackdropLayer.self
        }
        enum FilterName {
            static let filter: String = decryptedString("Q0FGaWx0ZXI=") // CAFilter
            static let initWithName: String = decryptedString("ZmlsdGVyV2l0aE5hbWU6") // filterWithName:
            static let home: String = decryptedString("aG9tZUFmZm9yZGFuY2VCYXNl") // homeAffordanceBase
            static let brightness: String = decryptedString("Y29sb3JCcmlnaHRuZXNz") // colorBrightness
            static let saturate: String = decryptedString("Y29sb3JTYXR1cmF0ZQ==") // colorSaturate
            static let invert: String = decryptedString("Y29sb3JJbnZlcnQ=") // colorInvert
        }
        enum FilterKey {
            static let colorMap: String = decryptedString("aW5wdXRDb2xvck1hcA==") // inputColorMap
            static let amount: String = decryptedString("aW5wdXRBbW91bnQ=") // inputAmount
            static let addWhite: String = decryptedString("aW5wdXRBZGRXaGl0ZQ==") // inputAddWhite
            static let overlayOpacity: String = decryptedString("aW5wdXRPdmVybGF5T3BhY2l0eQ==") // inputOverlayOpacity
        }

        static func decryptedString(_ encryptedString: String) -> String {
            String(data: Data(base64Encoded: encryptedString) ?? Data(), encoding: .utf8) ?? ""
        }
    }

    private func filter(with name: String) -> NSObject? {
        (NSClassFromString(Cons.FilterName.filter) as? NSObject.Type)?
            .perform(NSSelectorFromString(Cons.FilterName.initWithName), with: name)?
            .takeUnretainedValue() as? NSObject
    }
}
