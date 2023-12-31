//
//  LabEffectSliderView.swift
//  ByteView
//
//  Created by wangpeiran on 2021/3/4.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import SnapKit
import RxSwift
import UIKit
import ByteViewUI

class SliderValueView: UIView {
    private lazy var valueBgView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgTips
        view.layer.cornerRadius = 8
        return view
    }()

    private lazy var arrowView: UIImageView = {
        let image = BundleResources.ByteView.Lab.ValueTriang
        let imagView = UIImageView()
        imagView.image = image.ud.withTintColor(UIColor.ud.bgTips, renderingMode: .alwaysOriginal)
        return imagView
    }()

    private lazy var valueLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.font = UIFont.systemFont(ofSize: 12)
        label.text = "0"
        return label
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    func setupViews() {
        layer.ud.setShadowColor(UIColor.ud.shadowDefaultMd)
        layer.shadowOpacity = 1
        layer.shadowOffset = CGSize(width: 0, height: 3)
        layer.shadowRadius = 4

        addSubview(valueBgView)
        addSubview(arrowView)
        addSubview(valueLabel)

        arrowView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 16, height: 6))
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        valueBgView.snp.makeConstraints { make in
            make.top.right.left.equalToSuperview()
            make.bottom.equalTo(arrowView.snp.top)
        }

        valueLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.left.equalTo(valueBgView).offset(12)
            make.right.equalTo(valueBgView).offset(-12)
            make.top.equalToSuperview().offset(8)
            make.height.equalTo(18)
        }
    }

    func setValue(value: String) {
        valueLabel.text = value
    }
}

class LabEffectSliderView: UIView {
    struct Layout {
        static let containerHeight: CGFloat = 46
        static let sliderThumbOffset: CGFloat = 0.5
        static func isRegular() -> Bool {
            return VCScene.rootTraitCollection?.isRegular ?? false
        }
    }

    private let disposeBag = DisposeBag()
    private let viewModel: InMeetingLabViewModel
    var isLandscapeMode: Bool { return viewModel.fromSource == .inMeet && isPhoneLandscape } // preview进入特效不横屏
    var effectModel: ByteViewEffectModel?
    var isFirstShow: Bool = true
    var sliderMargin: CGFloat { Layout.isRegular() ? 16 : 12 }

    lazy var slider: LabCustomerUISlider = {
        let slider = LabCustomerUISlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.minimumTrackTintColor = UIColor.ud.primaryContentDefault.alwaysLight
        slider.maximumTrackTintColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.4)
        slider.isContinuous = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(sliderTapped(_:)))
        slider.addGestureRecognizer(tap)

        // 设置滑动图标
        let slideIcon = UIView()
        slideIcon.frame = CGRect(x: 0, y: 0, width: 18, height: 18)
        slideIcon.layer.cornerRadius = 9
        slideIcon.layer.masksToBounds = true
        slideIcon.backgroundColor = UIColor.clear
        var iconImage = slideIcon.vc.screenshot()
        slider.setThumbImage(iconImage, for: .normal)
        slider.setThumbImage(iconImage, for: .selected)
        slider.setThumbImage(iconImage, for: .highlighted)
        return slider
    }()

    private lazy var sliderContainerView: UIView = {
        let view = UIView()
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var effectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .regular)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.isUserInteractionEnabled = false
        effectView.layer.cornerRadius = 10
        effectView.clipsToBounds = true
        effectView.isHidden = true
        return effectView
    }()

    private lazy var containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.backgroundColor = Layout.isRegular() ? UIColor.ud.staticBlack.withAlphaComponent(0.5) : .clear
        return view
    }()

    private lazy var customSliderThumbView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        view.layer.cornerRadius = 9
        view.layer.ud.setShadowColor(UIColor.ud.shadowDefaultSm)
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 4
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.borderWidth = 0.5
        view.ud.setLayerBorderColor(UIColor.ud.lineDividerModule)
        view.isUserInteractionEnabled = false
        return view
    }()

    private lazy var valueView: SliderValueView = {
        let view = SliderValueView()
        view.isHidden = true
        return view
    }()

    init(frame: CGRect, vm: InMeetingLabViewModel) {
        self.viewModel = vm
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reloadDate(effectModel: ByteViewEffectModel) {
        self.effectModel = effectModel

        if let min = self.effectModel?.min,
           let max = self.effectModel?.max,
           let defaultValue = self.effectModel?.defaultValue,
           let value = self.effectModel?.currentValue {
            self.slider.minimumValue = Float(min)
            self.slider.maximumValue = Float(max)
            reloadView(defaultValue: defaultValue, value: value)
        }
    }

    private func reloadView(defaultValue: Int, value: Int) {
        // 设置当前值
        self.slider.setValue(Float(value), animated: false)
        self.valueView.setValue(value: "\(value)")
    }

    private func setupViews() {
        self.addSubview(sliderContainerView)
        sliderContainerView.addSubview(effectView)
        sliderContainerView.addSubview(containerView)
        self.addSubview(valueView)

        self.containerView.addSubview(slider)
        self.containerView.addSubview(customSliderThumbView)

        sliderContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        effectView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(Layout.containerHeight)
        }

        containerView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(Layout.containerHeight)
        }

        slider.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.equalTo(sliderMargin)
            make.right.equalTo(-sliderMargin)
        }

        effectView.isHidden = !Layout.isRegular()

        self.setupSlider()

        slider.addTarget(self, action: #selector(dragChanged(slider:event:)), for: .valueChanged)
    }

    func layoutForTraitCollection() {
        containerView.backgroundColor = Layout.isRegular() ? UIColor.ud.staticBlack.withAlphaComponent(0.5) : .clear
        slider.maximumTrackTintColor = isLandscapeMode ? UIColor.ud.N90010 : UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.4)

        slider.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.left.equalTo(sliderMargin)
            make.right.equalTo(-sliderMargin)
        }
    }

    private func setupSlider() {
        slider.rx.value.map { [weak self] rawValue -> Int in
            let value = Int(rawValue.rounded())
            self?.valueView.setValue(value: "\(value)")
            return value
        }
        .map({ [weak self] value -> Int in
            if let model = self?.effectModel {
                model.currentValue = value
                self?.viewModel.applyEffect(model: model, shouldTrack: false) // 应用当前特效，由于拖动时变化太快，只在拖动结束与点击时埋点
                self?.viewModel.effectSliderEnded()
            }
            return value
        })
        .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
        .subscribe(onNext: { [weak self] _ in
            self?.viewModel.pretendService.saveEffectSetting(effectModel: self?.effectModel)
        }).disposed(by: disposeBag)

        slider.thumbCenterXRelay.subscribe(onNext: { [weak self] centerX in
            self?.updateValueLabelPos(centerX: centerX)
            }).disposed(by: disposeBag)
    }

    private func updateValueLabelPos(centerX: CGFloat) {
        valueView.snp.remakeConstraints { (maker) in
            maker.height.equalTo(42)
            maker.width.greaterThanOrEqualTo(32)
            maker.bottom.equalTo(self.containerView.snp.top).offset(10)
            maker.centerX.equalTo(self.slider.snp.left).offset(centerX)
            maker.top.equalToSuperview()
        }
        customSliderThumbView.snp.remakeConstraints { (maker) in
            maker.size.equalTo(18)
            maker.centerX.equalTo(self.slider.snp.left).offset(centerX)
            maker.centerY.equalTo(self.slider).offset(Layout.sliderThumbOffset)
        }
    }

    @objc
    private func dragChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                valueView.isHidden = false
            case .ended:
                valueView.isHidden = true
                if let effectModel = self.effectModel {
                    LabTrack.trackLabSliderEffect(source: viewModel.fromSource, model: effectModel, applyType: viewModel.pretendService.beautyCurrentStatus)
                    LabTrackV2.trackLabSliderEffect(model: effectModel, isFromInMeet: viewModel.isFromInMeet, applyType: viewModel.pretendService.beautyCurrentStatus)
                }
            default:
                break
            }
        }
    }

    @objc
    private func sliderTapped(_ tap: UITapGestureRecognizer) {
        if let slider = tap.view as? UISlider {
            if slider.isHighlighted {
                return
            }
            let pt = tap.location(in: slider)
            let percentage = pt.x / slider.bounds.size.width
            let delta = Float(percentage) * (slider.maximumValue - slider.minimumValue)
            var value = floor(slider.minimumValue + delta)
            value = value > slider.maximumValue ? slider.maximumValue : value // 有时候有误差会溢出
            slider.setValue(value, animated: false)
//            slider.rx.value.onNext(floor(value))
            if let model = self.effectModel { // 接收、应用、保存
                model.currentValue = Int(value)
                self.viewModel.applyEffect(model: model) // 应用当前特效
                self.viewModel.pretendService.saveEffectSetting(effectModel: self.effectModel)
                viewModel.effectSliderEnded()
                LabTrackV2.trackLabSliderEffect(model: model, isFromInMeet: viewModel.isFromInMeet, applyType: viewModel.pretendService.beautyCurrentStatus)
            }
            valueView.isHidden = true
        }
    }
}
