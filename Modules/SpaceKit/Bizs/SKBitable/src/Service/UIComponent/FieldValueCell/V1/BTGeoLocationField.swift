//
//  BTLocationField.swift
//  SKBitable
//
//  Created by 曾浩泓 on 2022/4/19.
//  

import UIKit
import Foundation
import SKCommon
import SKBrowser
import SKResource
import SKFoundation
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignIcon
import UniverseDesignLoading

final class BTGeoLocationField: BTBaseTextField, BTFieldLocationCellProtocol {

    var isClickDeleteMenuItem = false
    private var rightInsetOfTextView: CGFloat = 0
    private lazy var autoLocateView: AutoLocateView = {
        let view = AutoLocateView(frame: .zero)
        view.update(style: .compact)
        let tap = UITapGestureRecognizer(target: self, action: #selector(clickAutoLocate(tap:)))
        view.addGestureRecognizer(tap)
        return view
    }()
    private lazy var fullAutoLocateView: AutoLocateView = {
        let view = AutoLocateView(frame: .zero)
        view.update(style: .full)
        let tap = UITapGestureRecognizer(target: self, action: #selector(clickAutoLocate(tap:)))
        view.addGestureRecognizer(tap)
        return view
    }()
    private lazy var manualLocateView: ManualLocateView = {
        let view = ManualLocateView(frame: .zero)
        view.icon = UDIcon.editOutlined.ud.withTintColor(UDColor.iconN2)
        let tap = UITapGestureRecognizer(target: self, action: #selector(clickManualLocateButton(tap:)))
        view.addGestureRecognizer(tap)
        return view
    }()
    private lazy var fullManualLocateView: ManualLocateView = {
        let view = ManualLocateView(frame: .zero)
        view.icon = UDIcon.localOutlined.ud.withTintColor(UDColor.iconN2)
        let tap = UITapGestureRecognizer(target: self, action: #selector(clickManualLocateButton(tap:)))
        view.addGestureRecognizer(tap)
        return view
    }()
    
    override func setupLayout() {
        super.setupLayout()
        textView.isEditable = false
        textView.isSelectable = false
        self.isShowCustomMenuViewWhenLongPress = true
        containerView.addSubview(autoLocateView)
        containerView.addSubview(fullAutoLocateView)
        containerView.addSubview(manualLocateView)
        containerView.addSubview(fullManualLocateView)
        setupTextViewConstraints()
        autoLocateView.snp.makeConstraints { make in
            make.top.bottom.right.equalToSuperview()
            make.left.equalTo(textView.snp.right)
        }
        fullAutoLocateView.snp.makeConstraints { make in
            make.top.bottom.left.right.equalToSuperview()
        }
        manualLocateView.snp.makeConstraints { make in
            make.top.bottom.right.equalToSuperview()
            make.left.equalTo(textView.snp.right)
        }
        fullManualLocateView.snp.makeConstraints { make in
            make.top.bottom.left.right.equalToSuperview()
        }
    }
    private func setupTextViewConstraints() {
        let needInset = LKFeatureGating.bitableGeoLocationFieldEnable && fieldModel.editable
        let inset: CGFloat = needInset ? 47 : 0
        if abs(rightInsetOfTextView - inset) > 0.001 {
            rightInsetOfTextView = inset
            textView.snp.remakeConstraints { it in
                it.top.bottom.equalToSuperview()
                it.left.equalToSuperview()
                it.right.equalToSuperview().inset(inset)
            }
        }
    }
    
    override func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        super.loadModel(model, layout: layout)
        
        var displayText = ""
        if let location = model.geoLocationValue.first {
            displayText = location.fullAddress ?? ""
        }
        let isEmpty = model.geoLocationValue.first == nil
        textView.text = displayText
        setupTextViewConstraints()
        var needHideViews: [LocateView] = [
            autoLocateView,
            fullAutoLocateView,
            manualLocateView,
            fullManualLocateView
        ]
        var needShowView: LocateView?
        if LKFeatureGating.bitableGeoLocationFieldEnable, fieldModel.editable {
            if fieldModel.property.inputType == .onlyMobile {
                needShowView = needHideViews.remove(at: isEmpty ? 1 : 0)
            } else {
                needShowView = needHideViews.remove(at: isEmpty ? 3 : 2)
            }
        }
        needShowView?.isHidden = false
        needShowView?.update(isLoading: model.isFetchingGeoLocation)
        needHideViews.forEach({ $0.isHidden = true })
    }
    
    override func btTextView(_ textView: BTTextView, didSigleTapped sender: UITapGestureRecognizer) {
        if (fieldModel.geoLocationValue.first?.isEmpty ?? true) && !fieldModel.editable {
            showUneditableToast()
        }
        clickTextView()
    }

    override func stopEditing() {
        fieldModel.update(isEditing: false)
        updateBorderMode(.normal)
        delegate?.stopEditingField(self, scrollPosition: nil)
    }
    
    @objc
    private func clickAutoLocate(tap: UITapGestureRecognizer) {
        if fieldModel.editable {
            delegate?.startEditing(inField: self, newEditAgent: nil)
        }
        if tap.view == self.fullAutoLocateView {
            trackOnClick(clickType: "blank")
        } else {
            trackOnClick(clickType: "edit")
        }
    }
    @objc
    override func clearContent() {
        if fieldModel.editable {
            isClickDeleteMenuItem = true
            delegate?.startEditing(inField: self, newEditAgent: nil)
        }
    }
    @objc
    private func clickManualLocateButton(tap: UITapGestureRecognizer) {
        if fieldModel.editable {
            delegate?.startEditing(inField: self, newEditAgent: nil)
        }
        if tap.view == fullManualLocateView {
            let tapPoint = tap.location(in: tap.view)
            if fullManualLocateView.isClickOnRightImageView(with: tapPoint) {
                trackOnClick(clickType: "icon")
            } else {
                trackOnClick(clickType: "blank")
            }
        } else {
            trackOnClick(clickType: "edit")
        }
    }
    @objc
    private func clickTextView() {
        guard LKFeatureGating.bitableGeoLocationFieldEnable else {
            return
        }
        guard let geoLocation = fieldModel.geoLocationValue.first, !geoLocation.isEmpty else {
            return
        }
        delegate?.didClickOpenLocation(inField: self)
    }
    
    private func trackOnClick(clickType: String) {
        var params = [
            "target": "none",
            "input_type": fieldModel.property.inputType.trackText
        ]
        params["click"] = clickType
        delegate?.track(event: DocsTracker.EventType.bitableGeoCardClick.rawValue, params: params)
    }
}

protocol LocateView: UIView {
    func update(isLoading: Bool)
}

final class AutoLocateView: UIView, LocateView {
    enum Style {
    case full
    case compact
    }
    
    private(set) var style: Style = .full {
        didSet {
            update()
        }
    }
    
    private var isLoading: Bool = false
    
    private lazy var locateImageView = UIImageView().construct { it in
        it.image = UDIcon.locatedOutlined.ud.withTintColor(UDColor.iconN1)
    }
    private lazy var label = UILabel().construct { it in
        it.textColor = UDColor.textTitle
        it.font = UIFont(name: "PingFangSC-Regular", size: 14)
    }
    private lazy var refreshImageView = UIImageView().construct { it in
        it.image = UDIcon.refreshOutlined.ud.withTintColor(UDColor.iconN2)
    }
    private lazy var loadingView: UDSpin = {
        let indicatorConfig: UDSpinIndicatorConfig = UDSpinIndicatorConfig(size: 18, color: UIColor.ud.colorfulBlue)
        let indicatorSpin = UDLoading.spin(config: UDSpinConfig(indicatorConfig: indicatorConfig, textLabelConfig: nil))
        return indicatorSpin
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label)
        addSubview(locateImageView)
        addSubview(refreshImageView)
        addSubview(loadingView)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        locateImageView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
            make.centerY.equalTo(label)
            make.trailing.equalTo(label.snp.leading).offset(-4)
        }
        refreshImageView.snp.makeConstraints { make in
            make.width.height.equalTo(18)
            make.center.equalToSuperview()
        }
        loadingView.snp.makeConstraints { make in
            make.width.height.equalTo(18)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(label.snp.leading).offset(-4)
        }
        update()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func update() {
        label.isHidden = style == .compact
        locateImageView.isHidden = style == .compact || isLoading
        refreshImageView.isHidden = style == .full || isLoading
        label.text = isLoading ? BundleI18n.SKResource.Bitable_Field_GettingLocation : BundleI18n.SKResource.Bitable_Field_GetCurrentLocation
        label.textColor = isLoading ? UDColor.udtokenComponentTextDisabledLoading : UDColor.textTitle
        loadingView.isHidden = !isLoading
        loadingView.snp.remakeConstraints { make in
            make.width.height.equalTo(18)
            make.centerY.equalToSuperview()
            if style == .full {
                make.trailing.equalTo(label.snp.leading).offset(-4)
            } else {
                make.centerX.equalTo(refreshImageView)
            }
        }
    }
    func update(isLoading: Bool) {
        guard self.isLoading != isLoading else {
            return
        }
        self.isLoading = isLoading
        update()
    }
    func update(style: Style) {
        guard self.style != style else {
            return
        }
        self.style = style
        update()
    }
}

final class ManualLocateView: UIView, LocateView {
    private var isLoading: Bool = false
    var icon: UIImage? {
        didSet {
            rightImageView.image = icon
        }
    }
    private lazy var loadingView: UDSpin = {
        let indicatorConfig: UDSpinIndicatorConfig = UDSpinIndicatorConfig(size: 18, color: UDColor.primaryContentDefault)
        let indicatorSpin = UDLoading.spin(config: UDSpinConfig(indicatorConfig: indicatorConfig, textLabelConfig: nil))
        return indicatorSpin
    }()
    
    private lazy var rightImageView = UIImageView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.cornerRadius = 6
        self.layer.masksToBounds = true
        addSubview(rightImageView)
        addSubview(loadingView)
        rightImageView.snp.makeConstraints { make in
            make.width.height.equalTo(18)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
        }
        loadingView.snp.makeConstraints { make in
            make.width.height.equalTo(18)
            make.center.equalTo(rightImageView)
        }
        loadingView.isHidden = !isLoading
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(isLoading: Bool) {
        guard isLoading != self.isLoading else {
            return
        }
        self.isLoading = isLoading
        self.loadingView.isHidden = !isLoading
        self.rightImageView.isHidden = isLoading
    }
    
    func isClickOnRightImageView(with point: CGPoint) -> Bool {
        return rightImageView.frame.contains(point)
    }
}
