//
//  ImageEditFunctionBottomView.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/8/17.
//  Copyright © 2018 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import RxSwift

protocol FunctionBottomViewDelegate: AnyObject {
    func bottomView(_ bottomView: ImageEditFunctionBottomView, didChange lineWidth: CGFloat)
    func bottomView(_ bottomView: ImageEditFunctionBottomView, didChange color: ColorPanelType)
    func bottomView(_ bottomView: ImageEditFunctionBottomView, didChange mosaicType: MosaicType)
    func bottomView(_ bottomView: ImageEditFunctionBottomView, didChange selectionType: SelectionType)
    func bottomView(_ bottomView: ImageEditFunctionBottomView, didInvoke panGesture: UIPanGestureRecognizer)
}

final class ImageEditFunctionBottomView: UIView, UIGestureRecognizerDelegate {
    private let gradientView = GradientView()
    // addLine
    private let addLineSlider = ImageEditSlideView(maxValue: AddLineMaxLineWidth, minValue: AddLineMinLineWidth)
    var hasEverAdjustAddLineSlider: Bool { return addLineSlider.hasEverChangedValue }
    private let addLineColorPanel = ImageEditColorPanel()

    // mosaic
    private let mosaicSlider = ImageEditSlideView(maxValue: MosaicMaxLineWidth, minValue: MosaicMinLineWidth)
    var hasEverAdjustAddMosaicSlider: Bool { return mosaicSlider.hasEverChangedValue }
    private var mosaicPanel: ImageEditAddMosaicPanel

    // text
    private let addTextColorPanel = ImageEditColorPanel()
    private let panGesture: UIPanGestureRecognizer = UIPanGestureRecognizer()
    weak var delegate: FunctionBottomViewDelegate?

    var currentFunction: BottomPanelFunction {
        didSet {
            configUIWith(function: currentFunction)
        }
    }

    init(currentFunction: BottomPanelFunction, smartMosaicStateObservable: Observable<SmartMosaicState>) {
        self.currentFunction = currentFunction
        mosaicPanel = ImageEditAddMosaicPanel(type: MosaicType.default,
                                              smartMosaicStateObservable: smartMosaicStateObservable)

        super.init(frame: .zero)

        gradientView.backgroundColor = UIColor.clear
        gradientView.colors = [UIColor.clear,
                               UIColor.ud.color(39, 39, 39).withAlphaComponent(0.5)]
        addSubview(gradientView)
        gradientView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        addLineSlider.delegate = self
        addSubview(addLineSlider)
        addLineSlider.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
        }
        addLineColorPanel.delegate = self
        addSubview(addLineColorPanel)
        addLineColorPanel.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
        }

        mosaicSlider.delegate = self
        addSubview(mosaicSlider)
        mosaicSlider.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
        }
        mosaicPanel.delegate = self
        addSubview(mosaicPanel)
        mosaicPanel.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
        }

        addTextColorPanel.delegate = self
        addSubview(addTextColorPanel)
        addTextColorPanel.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
        }

        configUIWith(function: currentFunction)

        snp.makeConstraints { (make) in
            make.height.equalTo(105)
        }

        panGesture.addTarget(self, action: #selector(panGestureDidInvoke(gesture:)))
        addGestureRecognizer(panGesture)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var textColorPannelColor: ColorPanelType {
        get {
            return addTextColorPanel.currentColor
        }
        set {
            addTextColorPanel.currentColor = newValue
        }
    }

    // ImageEditView会在图片旋转之后被重新初始化
    // 需要将最新的设置同步回去，确保几个View之间的设置一致
    func refreshSettings() {
        switch currentFunction {
        case .mosaic:
            mosaicPanel.refreshSettings()
            mosaicSlider.refreshSettings()
        case .line:
            addLineSlider.refreshSettings()
            addLineColorPanel.refreshSettings()
        case .text:
            addTextColorPanel.refreshSettings()
        default:
            break
        }
    }

    @objc
    private func panGestureDidInvoke(gesture: UIPanGestureRecognizer) {
        delegate?.bottomView(self, didInvoke: gesture)
    }

    private func configUIWith(function: BottomPanelFunction) {
        gradientView.isHidden = false
        [addLineSlider, addLineColorPanel, mosaicSlider, mosaicPanel, addTextColorPanel]
            .forEach { $0.isHidden = true }

        switch function {
        case .mosaic:
            mosaicSlider.isHidden = false
            mosaicPanel.isHidden = false
        case .line:
            addLineSlider.isHidden = false
            addLineColorPanel.isHidden = false
        case .text:
            addTextColorPanel.isHidden = false
        case .trim:
            gradientView.isHidden = true
        }
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return false
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return false
    }
}

extension ImageEditFunctionBottomView: ImageEditColorPanelDelegate,
                                       ImageEditAddMosaicPanelDelegate,
                                       ImageEditSlideViewDelegate {
    func colorPanel(_ colorPanel: ImageEditColorPanel, didSelect color: ColorPanelType) {
        delegate?.bottomView(self, didChange: color)
    }

    func panel(_ panel: ImageEditAddMosaicPanel, didChange mosaicType: MosaicType) {
        delegate?.bottomView(self, didChange: mosaicType)
    }

    func panel(_ panel: ImageEditAddMosaicPanel, didChange selectionType: SelectionType) {
        if currentFunction == .mosaic {
            self.mosaicSlider.isHidden = selectionType == .area
        }
        delegate?.bottomView(self, didChange: selectionType)
    }

    func sliderDidChangeValue(_ sliderView: ImageEditSlideView, from oldValue: Int, to newValue: Int) {
        delegate?.bottomView(self, didChange: CGFloat(newValue))
    }
}
