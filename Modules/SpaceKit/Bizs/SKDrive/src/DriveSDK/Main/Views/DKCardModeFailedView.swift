//
//  DKCardModeFailedView.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/11/2.
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa
import SKCommon
import SKResource
import UniverseDesignEmpty
import UniverseDesignColor
import UniverseDesignButton
import UniverseDesignFont

class DKCardModeFailedView: UIView, UIGestureRecognizerDelegate {
    private var model: DKPreviewFailedViewData?
    private var bag = DisposeBag()
    private var displayMode: DrivePreviewMode = .card
    private lazy var containView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()
    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.image = UDEmptyType.loadingFailure.defaultImage()
        return view
    }()
    
    private lazy var descLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UDEmptyColorTheme.emptyDescriptionColor
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    private lazy var openInOtherBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.layer.cornerRadius = 4.0
        btn.layer.borderWidth = 1
        btn.layer.masksToBounds = true
        btn.layer.ud.setBorderColor(UDEmptyColorTheme.primaryButtonBorderColor)
        btn.setTitleColor(UDEmptyColorTheme.primaryButtonTextColor, for: .normal)
        btn.setTitleColor(UIColor.ud.udtokenBtnPriTextDisabled, for: .disabled)
        btn.setTitle(BundleI18n.SKResource.Drive_Drive_OpenWithOtherApps, for: .normal)
        btn.backgroundColor = UDEmptyColorTheme.primaryButtonBackgroundColor
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        btn.addTarget(self, action: #selector(openClick(_:)), for: .touchUpInside)
        return btn
    }()
    
    var didClickRetryAction: (() -> Void)?

    init(data: DKPreviewFailedViewData, mode: DrivePreviewMode) {
        self.model = data
        super.init(frame: .zero)
        self.displayMode = mode
        setupUI()
        addGestureRecognizer()
        render(data: data)
    }
    
    init(mode: DrivePreviewMode) {
        super.init(frame: .zero)
        self.displayMode = mode
        setupUI()
        addGestureRecognizer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func render(data: DKPreviewFailedViewData) {
        self.model = data
        updateEmptyView()
        
        data.retryEnable.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] enable in
            self?.setDescription(canRetry: data.showRetryButton, retryEanble: enable)
        }).disposed(by: bag)
  
        data.openWithOtherEnable.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] enable in
            self?.setOpenWithOtherApp(enable: enable)
        }).disposed(by: bag)
        
        data.showOpenWithOtherApp.observeOn(MainScheduler.instance).skip(1).subscribe(onNext: { [weak self] _ in
            self?.updateEmptyView()
        }).disposed(by: bag)
    }
    
    private func updateEmptyView() {
        guard let data = self.model else { return }
        iconView.image = data.image
        setDescription(canRetry: data.showRetryButton, retryEanble: data.retryEnable.value)
        let hideBtn = !data.showOpenWithOtherApp.value || (displayMode == .card)
        openInOtherBtn.isHidden = hideBtn
        let size: CGSize = hideBtn ? .zero: buttonSize()
        let margin: CGFloat = hideBtn ? 0 : labelBtnMargin()
        openInOtherBtn.snp.updateConstraints { make in
            make.height.equalTo(size.height)
            make.top.equalTo(descLabel.snp.bottom).offset(margin)
        }
    }
    
    private func setupUI() {
        backgroundColor = UDColor.bgBase
        addSubview(containView)
        containView.addSubview(iconView)
        containView.addSubview(descLabel)
        containView.addSubview(openInOtherBtn)

        
        containView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }
        let iconWidth = iconSize()
        iconView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.width.height.equalTo(iconWidth)
            make.centerX.equalToSuperview()
        }
        
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(iconLabelMargin())
            make.centerX.equalToSuperview()
            make.leading.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().offset(-8)
        }
        
        let hideBtn = (displayMode == .card)
        openInOtherBtn.isHidden = hideBtn
        let size: CGSize = hideBtn ? .zero: buttonSize()
        let margin: CGFloat = hideBtn ? 0 : labelBtnMargin()
        let height = hideBtn ? 0 : size.height
        openInOtherBtn.isHidden = hideBtn
        openInOtherBtn.contentEdgeInsets = UIEdgeInsets(top: 0, left: edgeInsets(), bottom: 0, right: edgeInsets())
        openInOtherBtn.snp.makeConstraints { make in
            make.top.equalTo(descLabel.snp.bottom).offset(margin)
            make.centerX.equalToSuperview()
            make.height.equalTo(height)
            make.width.greaterThanOrEqualTo(size.width)
            make.bottom.equalToSuperview()
        }
    }
    
    private func buttonSize() -> CGSize {
        let size = displayMode == .normal ? CGSize(width: 76, height: 36) : CGSize(width: 60, height: 28)
        return size
    }
    
    private func iconSize() -> CGFloat {
        return displayMode == .normal ? 120 : 75
    }
    
    private func iconLabelMargin() -> CGFloat {
        return displayMode == .normal ? 12 : 16
    }
    
    private func labelBtnMargin() -> CGFloat {
        return displayMode == .normal ? 16 : 8
    }
    
    private func edgeInsets() -> CGFloat {
        return displayMode == .normal ? 20 : 12
    }
    @objc
    func openClick(_ button: UIButton) {
        guard let data = model, data.openWithOtherEnable.value else { return }
        model?.openWithOtherAppHandler(button, button.bounds)
    }
    
    @objc
    func retryClick(_ button: UIButton) {
        didClickRetryAction?()
        model?.retryHandler()
    }
    
    @objc
    private func onTapDimiss(sender: UIGestureRecognizer) {
        guard let data = model else { return }
        if data.retryEnable.value && data.showRetryButton {
            didClickRetryAction?()
            data.retryHandler()
        }
    }
    
    func addGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapDimiss))
        tapGesture.delegate = self
        descLabel.isUserInteractionEnabled = true
        descLabel.addGestureRecognizer(tapGesture)
    }
    
    private func setOpenWithOtherApp(enable: Bool) {
        guard let data = self.model, data.showOpenWithOtherApp.value else { return }
        let borderColor = enable ? UDEmptyColorTheme.primaryButtonBorderColor : UIColor.clear
        let backColor = enable ?  UDEmptyColorTheme.primaryButtonBackgroundColor : UIColor.ud.fillDisabled
        openInOtherBtn.isEnabled = enable
        openInOtherBtn.layer.ud.setBorderColor(borderColor)
        openInOtherBtn.backgroundColor = backColor
    }
    
    private func setDescription(canRetry: Bool, retryEanble: Bool) {
        guard let data = model else { return }
        let retryDesc = BundleI18n.SKResource.CreationMobile_PDFPreview_Failed_Placeholder1 +
            BundleI18n.SKResource.CreationMobile_PDFPreview_Failed_Placeholder2
        let text: String
        if canRetry {
            text = retryEanble ? retryDesc : BundleI18n.SKResource.CreationMobile_Common_NoInternet
        } else {
            text = data.mainText
        }
        let descriptionString = NSMutableAttributedString(string: text)
        descriptionString.addAttribute(.foregroundColor,
                                       value: UDEmptyColorTheme.emptyDescriptionColor,
                                       range: .init(location: 0, length: descriptionString.length))
        let range = descriptionString.mutableString.range(of: BundleI18n.SKResource.CreationMobile_PDFPreview_Failed_Placeholder2, options: .caseInsensitive)
        descriptionString.addAttribute(.foregroundColor,
                                       value: UDEmptyColorTheme.emptyNegtiveOperableColor,
                                       range: range)
        descLabel.attributedText = descriptionString
    }
    
    // UIGestureRecognizerDelegate
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
}


extension DKCardModeFailedView: DKViewModeChangable {
    func changeMode(_ mode: DrivePreviewMode, animate: Bool) {
        guard displayMode != mode else { return }
        displayMode = mode
        
        guard let data = model else { return }
        iconView.snp.updateConstraints { make in
            make.width.height.equalTo(iconSize())
        }
        descLabel.snp.updateConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(iconLabelMargin())
        }
        
        
        let hideBtn = !data.showOpenWithOtherApp.value || (displayMode == .card)
        openInOtherBtn.isHidden = hideBtn
        let size: CGSize = hideBtn ? .zero: buttonSize()
        let margin: CGFloat = hideBtn ? 0 : labelBtnMargin()
        openInOtherBtn.snp.updateConstraints { make in
            make.height.equalTo(size.height)
            make.top.equalTo(descLabel.snp.bottom).offset(margin)
        }
        
        if animate {
            UIView.animate(withDuration: 0.25) {
                self.setNeedsLayout()
                self.layoutIfNeeded()
            }
        }
    }
}
