//
//  NoPermissionViewController.swift
//  LarkSecurityAndCompliance
//
//  Created by qingchun on 2022/4/7.
//

import UIKit
import LarkUIKit
import UniverseDesignEmpty
import UniverseDesignColor
import UniverseDesignButton
import UniverseDesignTheme
import UniverseDesignDialog
import UniverseDesignFont
import UniverseDesignToast
import RxSwift
import RxCocoa
import SnapKit
import LarkSecurityComplianceInfra

final class NoPermissionViewController: BaseViewController<NoPermissionViewModel> {

    private let container = Container(frame: LayoutConfig.bounds)
    private let bag = DisposeBag()

    override func loadView() {
        view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        isNavigationBarHidden = true
        bindViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        SCMonitor.info(business: .no_permission, eventName: "vc_appear")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        SCMonitor.info(business: .no_permission, eventName: "vc_disappear")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard #available(iOS 13.0, *),
            traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
            // 如果当前设置主题一致，则不需要切换资源
            return
        }

        let isDarkModeTheme = self.traitCollection.userInterfaceStyle == .dark

        let topColor: UIColor = isDarkModeTheme ? UIColor.ud.rgb("#192031") : UIColor.ud.rgb("#DFE9FF")
        let bottomColor: UIColor = isDarkModeTheme ? UIColor.ud.rgb("#191A1C") : UIColor.ud.rgb("#FFFFFF").withAlphaComponent(0)
        container.gradientViewHeader.colors = [topColor, bottomColor]
        container.gradientViewHeader.layoutIfNeeded()
    }

    private func bindViewModel() {
        container.switchButton.rx.tap
            .map { [weak self] in self?.container.switchButton }
            .bind(to: viewModel.showAlert)
            .disposed(by: bag)
        container.retryButton.rx.tap
            .bind(to: viewModel.retryButtonClicked)
            .disposed(by: bag)
        container.nextButton.rx.tap
            .bind(to: viewModel.gotoNext)
            .disposed(by: bag)
        viewModel.showDeviceOwnershipLoading
            .bind(to: container.loadingView.rx.animating)
            .disposed(by: bag)
        viewModel.showRefreshLoading
            .bind(to: showRefreshLoading)
            .disposed(by: bag)
        viewModel.nextButtonLoading
            .bind { [weak self] animating in
                animating ? self?.container.nextButton.showLoading() : self?.container.nextButton.hideLoading()
            }
            .disposed(by: bag)
        viewModel.updateUI
            .bind { [weak self] () in

                self?.updateUIs()
            }
            .disposed(by: bag)

        updateUIs()
    }

    private func updateUIs() {
        guard let uiConfig = viewModel.UIConfig else { return }
        container.nextButton.isHidden = uiConfig.nextHidden
        container.nextButton.setTitle(uiConfig.nextTitle, for: .normal)
        container.detailView.isHidden = uiConfig.reasonDetailHidden
        refreshRetryButton(uiConfig.refreshTop)
        refreshNextButton(uiConfig.nextTop)
        let title = UDEmptyConfig.Title(titleText: BundleI18n.LarkSecurityCompliance.Lark_Conditions_NoPermission,
                                        font: UIFont.ud.title3)
        let description = UDEmptyConfig.Description(descriptionText: uiConfig.emptyDetail,
                                                    font: UIFont.ud.body2)
        let config = UDEmptyConfig(title: title,
                                   description: description,
                                   imageSize: 125,
                                   spaceBelowImage: 24,
                                   spaceBelowTitle: 4,
                                   spaceBelowDescription: 0,
                                   spaceBetweenButtons: 0,
                                   type: .noAccess)
        container.emptyView.update(config: config)

        container.detailView.titleLabel.text = uiConfig.detailTitle
        container.detailView.detailLabel.text = uiConfig.detailSubtitle
    }

    private func refreshRetryButton(_ layout: NoPermissionLayout.Refresh) {
        let target: UIView
        switch layout.align {
        case .detail:
            target = container.detailView
        case .next:
            target = container.nextButton
        }
        container.retryButton.snp.remakeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.height.equalTo(48)
            make.top.equalTo(target.snp.bottom).offset(layout.top)
            make.bottom.equalToSuperview()
        }
    }

    private func refreshNextButton(_ layout: NoPermissionLayout.Next) {
        let target: UIView
        switch layout.align {
        case .detail:
            target = container.detailView
        case .empty:
            target = container.emptyView
        }
        container.nextButton.snp.remakeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.height.equalTo(48)
            make.top.equalTo(target.snp.bottom).offset(layout.top)
        }
   }
}

extension NoPermissionViewController {
    var showRefreshLoading: Binder<Bool> {
        return Binder<Bool>(self) { target, value in
            if value {
                UDToast.showLoading(with: I18N.Lark_Conditions_VisitAgain, on: target.view)
            } else {
                UDToast.removeToast(on: target.view)
            }
        }
    }
}

private final class Container: UIView {

    let bgView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()

    let centerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    let loadingView: NoPermissionLoadingView = {
        let view = NoPermissionLoadingView()
        view.isHidden = true
        return view
    }()

    let detailView = DetailView(frame: .zero)

    let nextButton: UDButton = {
        let button = UDButton(UDButtonUIConifg.primaryBlue)
        button.titleLabel?.font = UIFont.ud.title4
        button.setTitle(BundleI18n.LarkSecurityCompliance.Lark_Conditions_GoVerifyNow, for: .normal)
        return button
    }()

    let retryButton: UDButton = {
        let button = UDButton(UDButtonUIConifg.secondaryGray)
        button.titleLabel?.font = UIFont.ud.title4
        button.setTitle(BundleI18n.LarkSecurityCompliance.Lark_Conditions_RevisitAgainOk, for: .normal)
        return button
    }()

    let switchButton: UDButton = {
        let button = UDButton(UDButtonUIConifg.textBlue)
        button.setTitle(BundleI18n.LarkSecurityCompliance.Lark_Conditions_Switch, for: .normal)
        button.titleLabel?.font = UIFont.ud.headline
        return button
    }()

    let gradientViewHeader: GradientView = {
        let gradientView = GradientView()
        gradientView.backgroundColor = UIColor.clear
        gradientView.colors = [UIColor.ud.rgb("#DFE9FF") & UIColor.ud.rgb("#192031"),
                               UIColor.ud.rgb("#FFFFFF").withAlphaComponent(0) & UIColor.ud.rgb("#191A1C")]
        gradientView.automaticallyDims = false
        gradientView.direction = .vertical
        return gradientView
    }()

    let patternImgView: UIImageView = {
        let patternImgView = UIImageView(frame: .zero)
        patternImgView.image = Display.pad ? BundleResources.LarkSecurityCompliance.pattern_bg_ipad : BundleResources.LarkSecurityCompliance.pattern_bg
        patternImgView.contentMode = .scaleAspectFit
        return patternImgView
    }()

    let emptyView: UDEmpty = {
        let title = UDEmptyConfig.Title(titleText: BundleI18n.LarkSecurityCompliance.Lark_Conditions_NoPermission,
                                        font: UIFont.ud.title3)
        let description = UDEmptyConfig.Description(descriptionText: BundleI18n.LarkSecurityCompliance.Lark_Conditions_ThisWay,
                                                    font: UIFont.ud.body2)
        let empty = UDEmpty(config: UDEmptyConfig(title: title,
                                                  description: description,
                                                  spaceBelowImage: 24,
                                                  spaceBelowTitle: 4,
                                                  spaceBelowDescription: 0,
                                                  spaceBetweenButtons: 0,
                                                  type: .noAccess))
        return empty
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        var isDarkModeTheme: Bool = false
        if #available(iOS 13.0, *) {
            isDarkModeTheme = UDThemeManager.getRealUserInterfaceStyle() == .dark
        }
        let topColor: UIColor = isDarkModeTheme ? UIColor.ud.rgb("#192031") : UIColor.ud.rgb("#DFE9FF")
        let bottomColor: UIColor = isDarkModeTheme ? UIColor.ud.rgb("#191A1C") : UIColor.ud.rgb("#FFFFFF").withAlphaComponent(0)
        gradientViewHeader.colors = [topColor, bottomColor]

        addSubview(gradientViewHeader)
        gradientViewHeader.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(240)
        }

        let ratio = Display.pad ? 160.0 / 1112.0 : 424.0 / 750.0
        let patternImgView = UIImageView(frame: .zero)
        patternImgView.image = Display.pad ? BundleResources.LarkSecurityCompliance.pattern_bg_ipad : BundleResources.LarkSecurityCompliance.pattern_bg
        patternImgView.contentMode = .scaleAspectFit
        addSubview(patternImgView)
        patternImgView.snp.makeConstraints { make in
            make.top.right.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(patternImgView.snp.width).multipliedBy(ratio)
        }

        emptyView.sizeToFit()

        addSubview(bgView)
        bgView.addSubview(centerView)
        centerView.addSubview(detailView)
        centerView.addSubview(emptyView)
        centerView.addSubview(nextButton)
        centerView.addSubview(retryButton)
        bgView.addSubview(switchButton)
        addSubview(loadingView)

        bgView.snp.makeConstraints { make in
            make.centerX.top.height.equalToSuperview()
            if Display.phone {
                make.width.equalToSuperview()
            } else {
                let width = min(400, LayoutConfig.bounds.width)
                make.width.equalTo(width)
            }
        }
        centerView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.right.equalToSuperview()
        }
        emptyView.snp.makeConstraints { (make) in
            make.top.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview().offset(-32)
        }
        detailView.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.equalTo(emptyView.snp.bottom).offset(16)
        }

        nextButton.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.height.equalTo(48)
            make.top.equalTo(detailView.snp.bottom).offset(24)
        }
        retryButton.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.height.equalTo(48)
            make.top.equalTo(detailView.snp.bottom).offset(88)
            make.bottom.equalToSuperview()
        }
        switchButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(-1 * LayoutConfig.safeAreaInsets.bottom - 12)
            make.left.greaterThanOrEqualTo(16)
            make.right.lessThanOrEqualTo(-16)
        }
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !Display.phone {
            let width = min(400, bounds.width)
            bgView.snp.updateConstraints { make in
                make.width.equalTo(width)
            }
        }
    }
}

private final class DetailView: UIView {

    let dotView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.textPlaceholder
        view.layer.cornerRadius = 3
        return view
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkSecurityCompliance.Lark_Conditions_TryNow
        label.font = UIFont.ud.headline
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    let detailLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkSecurityCompliance.Lark_Conditions_OnceEdited
        label.font = UIFont.ud.body2
        label.textColor = UIColor.ud.textCaption
        label.numberOfLines = 0
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.ud.bgBase
        layer.cornerRadius = 8

        addSubview(dotView)
        addSubview(titleLabel)
        addSubview(detailLabel)

        dotView.snp.makeConstraints { make in
            make.size.equalTo(6)
            make.left.equalTo(16)
            make.top.equalTo(25)
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(dotView.snp.right).offset(12)
            make.centerY.equalTo(dotView)
            make.right.lessThanOrEqualTo(-16)
        }
        detailLabel.snp.makeConstraints { make in
            make.left.equalTo(dotView.snp.right).offset(12)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.right.lessThanOrEqualTo(-16)
            make.bottom.equalTo(-20)
        }
    }

    required init?(coder: NSCoder) {
        return nil
    }
}
