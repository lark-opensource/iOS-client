//
//  DKPreviewFailedView.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/7/12.
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

struct DKPreviewFailedViewData {
    let mainText: String // 错误信息
    let showRetryButton: Bool // 是否显示重试按钮
    let retryEnable: BehaviorRelay<Bool> // 重试按钮是否可点
    let retryHandler: (() -> Void) // 重试事件

    let showOpenWithOtherApp: BehaviorRelay<Bool> // 是否展示第三方应用打开按钮
    let openWithOtherEnable: BehaviorRelay<Bool> // 第三方打开按钮是否可点
    let openWithOtherAppHandler: ((UIView, CGRect) -> Void) // 使用第三方应用打开事件
    let image: UIImage
    init(mainText: String = BundleI18n.SKResource.Drive_Drive_LoadingFail,
         image: UIImage = UDEmptyType.loadingFailure.defaultImage(),
         showRetryButton: Bool,
         retryEnable: BehaviorRelay<Bool>,
         retryHandler: @escaping (() -> Void),
         showOpenWithOtherApp: BehaviorRelay<Bool>,
         openWithOtherEnable: BehaviorRelay<Bool>,
         openWithOtherAppHandler: @escaping ((UIView, CGRect) -> Void)) {
        self.mainText = mainText
        self.showRetryButton = showRetryButton
        self.retryEnable = retryEnable
        self.retryHandler = retryHandler
        self.showOpenWithOtherApp = showOpenWithOtherApp
        self.openWithOtherEnable = openWithOtherEnable
        self.openWithOtherAppHandler = openWithOtherAppHandler
        self.image = image
    }
    
    // 其他异常显示，比如self不存在，asDriver on Error的场景，只展示加载失败文案
    static func defaultData() -> DKPreviewFailedViewData {
        let data = DKPreviewFailedViewData(mainText: BundleI18n.SKResource.Drive_Drive_LoadingFail,
                                           showRetryButton: false,
                                           retryEnable: BehaviorRelay<Bool>(value: false),
                                           retryHandler: {},
                                           showOpenWithOtherApp: BehaviorRelay<Bool>(value: false),
                                           openWithOtherEnable: BehaviorRelay<Bool>(value: false),
                                           openWithOtherAppHandler: { _, _ in })
        return data

    }
}



class DKPreviewFailedView: UIView {
    private var model: DKPreviewFailedViewData?
    private var bag = DisposeBag()
    
    private lazy var emptyConfig: UDEmptyConfig = {
        let config = UDEmptyConfig(title: .init(titleText: ""),
                                   description: .init(descriptionText: BundleI18n.SKResource.Drive_Drive_LoadingFail),
                                   type: .loadingFailure,
                                   labelHandler: nil,
                                   primaryButtonConfig: nil,
                                   secondaryButtonConfig: nil)
        return config
    }()
    
    private(set) lazy var failedView: UDEmpty = {
        let failedView = UDEmpty(config: emptyConfig)
        return failedView
    }()
    
    var didClickRetryAction: (() -> Void)?

    init(data: DKPreviewFailedViewData) {
        self.model = data
        super.init(frame: .zero)
        setupUI()
        render(data: data)
    }

    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    func render(data: DKPreviewFailedViewData) {
        self.model = data
        updateEmptyView()
        
        data.retryEnable.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] enable in
            self?.setRetryButton(enable: enable)
            let mainText: String
            if data.showRetryButton {
                mainText = enable ? data.mainText : BundleI18n.SKResource.CreationMobile_Common_NoInternet
            } else {
                mainText = data.mainText
            }
            self?.updateMainText(mainText)
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
        var openWithOtherConfig: (String?, (UIButton) -> Void)?
        var retryConfig: (String?, (UIButton) -> Void)?
        openWithOtherConfig = (BundleI18n.SKResource.Drive_Drive_OpenWithOtherApps, { [weak self] button in
            guard let self = self else { return }
            guard data.openWithOtherEnable.value else { return }
            self.openClick(button)
        })
        retryConfig = (BundleI18n.SKResource.Drive_Drive_ClickRetry, { [weak self] button in
            guard let self = self else { return }
            guard data.retryEnable.value else { return }
            self.retryClick(button)
        })
        
        emptyConfig.description = .init(descriptionText: data.mainText)
        emptyConfig.type = .custom(data.image)
        if data.showRetryButton && data.showOpenWithOtherApp.value {
            emptyConfig.primaryButtonConfig = openWithOtherConfig
            emptyConfig.secondaryButtonConfig = retryConfig
        } else if data.showRetryButton {
            emptyConfig.primaryButtonConfig = retryConfig
        } else if data.showOpenWithOtherApp.value {
            emptyConfig.primaryButtonConfig = openWithOtherConfig
        } else {
            emptyConfig.primaryButtonConfig = nil
            emptyConfig.secondaryButtonConfig = nil
        }
        
        failedView.update(config: emptyConfig)
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBase
        addSubview(failedView)
        failedView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func setOpenWithOtherApp(enable: Bool) {
        guard let data = self.model, data.showOpenWithOtherApp.value else { return }
        let buttonThemeColor = enable ? UDEmpty.primaryColor : UDEmpty.primaryDisableColor
        failedView.primaryButtonConfig = UDButtonUIConifg(normalColor: buttonThemeColor, type: .middle)
    }
    
    private func setRetryButton(enable: Bool) {
        guard let data = self.model, data.showRetryButton else { return }
        var isRetryButtonPrimary: Bool
        var themeColor = UDEmpty.secordaryColor
        var disableColor = UDEmpty.secordaryDisableColor
        if data.showOpenWithOtherApp.value {
            isRetryButtonPrimary = false
        } else {
            // 没有 "其它应用打开"按钮时，重试按钮为主要按钮
            isRetryButtonPrimary = true
            themeColor = UDEmpty.primaryColor
            disableColor = UDEmpty.primaryDisableColor
        }
        
        let buttonThemeColor = enable ? themeColor : disableColor
        if isRetryButtonPrimary {
            failedView.primaryButtonConfig = UDButtonUIConifg(normalColor: buttonThemeColor, type: .middle)
        } else {
            failedView.secondaryButtonConfig = UDButtonUIConifg(normalColor: buttonThemeColor, type: .middle)
        }
    }
    
    private func updateMainText(_ text: String) {
        emptyConfig.description = .init(descriptionText: text)
        failedView.update(config: emptyConfig)
    }
    
    @objc
    func openClick(_ button: UIButton) {
        model?.openWithOtherAppHandler(button, button.bounds)
    }
    
    @objc
    func retryClick(_ button: UIButton) {
        didClickRetryAction?()
        model?.retryHandler()
    }
}

extension UDEmpty {
    static let primaryColor = UDButtonUIConifg.ThemeColor(borderColor: UDEmptyColorTheme.primaryButtonBorderColor,
                                                          backgroundColor: UDEmptyColorTheme.primaryButtonBackgroundColor,
                                                          textColor: UDEmptyColorTheme.primaryButtonTextColor)
    static let primaryDisableColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                                  backgroundColor: UIColor.ud.fillDisabled,
                                                                  textColor: UIColor.ud.udtokenBtnPriTextDisabled)
    static let secordaryColor = UDButtonUIConifg.ThemeColor(borderColor: UDEmptyColorTheme.secondaryButtonBorderColor,
                                                             backgroundColor: UDEmptyColorTheme.secondaryButtonBackgroundColor,
                                                             textColor: UDEmptyColorTheme.secondaryButtonTextColor)
    static let secordaryDisableColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.lineBorderComponent,
                                                                    backgroundColor: UIColor.clear,
                                                                    textColor: UIColor.ud.textDisabled)
}
