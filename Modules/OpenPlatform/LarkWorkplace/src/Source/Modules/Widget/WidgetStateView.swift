//
//  File.swift
//  LarkWorkplace
//
//  Created by 李论 on 2020/5/24.
//

import Foundation
import UIKit
import RxSwift
import LarkLocalizations
import UniverseDesignEmpty
import LKCommonsLogging

private let stateImageSize: CGFloat = 48

/// 展示widget当前状态的View
final class WidgetStateView: UIView {
    static let logger = Logger.log(WidgetStateView.self)

    // MARK: 状态属性
    var state: WidgetUIState {
        didSet {
            /// state更新时触发视图更新
            updateStateView(state: state)
        }
    }
    /// 失败点击重试
    var faildRetryAction: (() -> Void)?
    /// 事件的内存管理
    private let disposeBag = DisposeBag()
    /// stateView: Dynamic（动态的状态图-loading）
    private lazy var stateDynamicImage: UIImageView = {
        UIImageView()
    }()
    /// stateView: Static（静态的状态-加载失败）
    private lazy var stateStaticImage: UIImageView = {
       UIImageView()
    }()
    /// stateView: Text（状态提示）
    private lazy var stateLabel: UILabel = {
        let label = UILabel()
        // state 文字   字体应当使用 UD Token 初始化
        // swiftlint:disable init_font_with_token
        label.font = UIFont.systemFont(ofSize: 12)
        // swiftlint:enable init_font_with_token
        label.textColor = UIColor.ud.textCaption.alwaysLight
        return label
    }()

    // MARK: 初始化
    init(frame: CGRect, state: WidgetUIState) {
        self.state = state
        super.init(frame: frame)
        setupViews()
        updateStateView(state: .loading)
    }

    ///  Default Init
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: 加载视图
    private func setupViews() {
        backgroundColor = UIColor.ud.bgFloat.alwaysLight
        self.addSubview(stateDynamicImage)
        stateDynamicImage.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview().offset(-10)
            make.height.equalTo(68)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        self.addSubview(stateStaticImage)
        stateStaticImage.snp.makeConstraints { (make) in
            make.width.equalTo(stateImageSize)
            make.height.equalTo(stateImageSize)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-24)
        }
        self.addSubview(stateLabel)
        stateLabel.snp.makeConstraints { (make) in
            make.top.equalTo(stateStaticImage.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
        }
        stateDynamicImage.isHidden = true
        stateStaticImage.isHidden = true
        stateLabel.isHidden = true
        let tap = UITapGestureRecognizer()
        self.addGestureRecognizer(tap)
        tap.rx.event.subscribe(onNext: { [weak self] (_) in
            self?.onStateTap()
        }).disposed(by: disposeBag)
    }

    /// 根据状态刷新UI
    private func updateStateView(state: WidgetUIState) {
        switch state {
        case .loading:  // 加载&显示「loading」的状态动图
            stateDynamicImage.isHidden = false
            stateStaticImage.isHidden = true
            stateLabel.isHidden = true
            self.isHidden = false
            guard let data = NSDataAsset(name: "widget_loading", bundle: BundleConfig.LarkWorkplaceBundle)?.data else {
                Self.logger.error("read data 'widget_loading' from bundle failed")
                return
            }
            stateDynamicImage.image = UIImage.lu.animated(with: data)
        case .loadFail: // 显示「加载失败」的状态图
            stateDynamicImage.isHidden = true
            stateStaticImage.isHidden = false
            stateLabel.isHidden = false
            self.isHidden = false
            let size = CGSize(width: stateImageSize, height: stateImageSize)
            stateStaticImage.image = UDEmptyType.loadingFailure.defaultImage().alwaysLight.bd_imageByResize(to: size)
            stateLabel.text = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_FailRefreshMsg
        case .updateTip: // 提示客户端升级
            stateDynamicImage.isHidden = true
            stateStaticImage.isHidden = false
            stateLabel.isHidden = false
            self.isHidden = false
            let size = CGSize(width: stateImageSize, height: stateImageSize)
            stateStaticImage.image = UDEmptyType.upgraded.defaultImage().alwaysLight.bd_imageByResize(to: size)
            stateLabel.text = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_IOSUpdtVerMsg(
                LanguageManager.bundleDisplayName
            )
        case .running: // 「正常运行」隐藏所有状态图
            stateDynamicImage.isHidden = true
            stateStaticImage.isHidden = true
            stateLabel.isHidden = true
            self.isHidden = true
        }
    }

    /// stateView点击事件
    private func onStateTap() {
        Self.logger.info("user tap stateView")
        if state == .loadFail {
            Self.logger.info("biz data loaded fail, please try again")
            faildRetryAction?()
        }
    }
}

/// Widget UI状态, 对应Widget容器的状态页
enum WidgetUIState {
    /// 资源加载中的状态
    case loading
    /// 资源加载失败的状态
    case loadFail
    /// 客户端版本低于widget最低版本
    case updateTip
    /// Card正常展示状态
    case running
}
