//
//  WorkspaceCreateView.swift
//  SKWorkspace
//
//  Created by Weston Wu on 2023/9/26.
//

import UIKit
import SpaceInterface
import UniverseDesignIcon
import UniverseDesignColor
import SnapKit
import SKUIKit
import RxSwift
import RxCocoa
import SKResource
import SKFoundation

public enum WorkspaceCreatePanelType {
    case create
    case upload
    case template
}

public class WorkspaceCreateView: UIView {

    private var showTemplate: Bool = true

    private lazy var createItemView: WorkspaceCreateItemView = {
        let view = WorkspaceCreateItemView()
        view.update(config: .create)
        view.addTarget(self, action: #selector(didClickCreate), for: .touchUpInside)
        return view
    }()

    private lazy var uploadItemView: WorkspaceCreateItemView = {
        let view = WorkspaceCreateItemView()
        view.update(config: .upload)
        view.addTarget(self, action: #selector(didClickUpload), for: .touchUpInside)
        return view
    }()

    private lazy var templateItemView: WorkspaceCreateItemView = {
        let view = WorkspaceCreateItemView()
        view.update(config: .template)
        view.addTarget(self, action: #selector(didClickTemplate), for: .touchUpInside)
        return view
    }()

    private lazy var placeHolderView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()

    private lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [createItemView, uploadItemView, templateItemView, placeHolderView])
        view.axis = .horizontal
        view.distribution = .fillEqually
        view.alignment = .fill
        view.spacing = 12
        return view
    }()

    public var onClickPanel: ((UIView, WorkspaceCreatePanelType) -> Void)?
    
    private let enableObservable: Observable<Bool>
    private let reachabilityRelay = BehaviorRelay<Bool>(value: true)
    private let disposeBag = DisposeBag()

    public init(enableObservable: Observable<Bool> = .just(true)) {
        self.enableObservable = enableObservable
        super.init(frame: .zero)
        setupUI()
        bindAction()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(24)
            make.top.bottom.equalToSuperview()
        }
    }
    
    private func bindAction() {
        RxNetworkMonitor.networkStatus(observerObj: self)
            .map { $1 }
            .bind(to: reachabilityRelay)
            .disposed(by: disposeBag)
        
        Observable.combineLatest(enableObservable, reachabilityRelay.asObservable())
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] enable, reachable in
                self?.createItemView.update(enable: enable)
                // 上传和模板库依赖网络状态
                self?.uploadItemView.update(enable: enable && reachable)
                self?.templateItemView.update(enable: enable && reachable)
            })
            .disposed(by: disposeBag)
    }

    public func setTemplate(hidden: Bool) {
        templateItemView.isHidden = hidden
        placeHolderView.isHidden = !hidden
    }

    @objc
    private func didClickCreate() {
        onClickPanel?(createItemView, .create)
    }

    @objc
    private func didClickUpload() {
        onClickPanel?(uploadItemView, .upload)
    }

    @objc
    private func didClickTemplate() {
        onClickPanel?(templateItemView, .template)
    }
}

private class WorkspaceCreateItemView: UIControl {

    struct Config {
        let title: String
        let subtitle: String
        let icon: UIImage

        static var create: Config {
            Config(title: BundleI18n.SKResource.LarkCCM_NewCM_Mobile_CreateNewDoc_Button,
                   subtitle: BundleI18n.SKResource.LarkCCM_NewCM_NewDoc__Title,
                   icon: UDIcon.newDocColorful)
        }

        static var upload: Config {
            Config(title: BundleI18n.SKResource.LarkCCM_NewCM_Mobile_UploadFiles_Button,
                   subtitle: BundleI18n.SKResource.LarkCCM_NewCM_UploadFile_Title,
                   icon: UDIcon.cloudUploadColorful)
        }

        static var template: Config {
            Config(title: BundleI18n.SKResource.LarkCCM_NewCM_Mobile_TemplateCenter_Button,
                   subtitle: BundleI18n.SKResource.LarkCCM_NewCM_Mobile_TemplateCenter_Desc,
                   icon: UDIcon.templateColorful)
        }
    }

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = UDColor.textTitle
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = UDColor.textCaption
        return label
    }()

    private lazy var titleStackView: UIStackView = {
        let view = PassThroughStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        view.axis = .vertical
        view.spacing = 2
        view.distribution = .fill
        view.alignment = .leading
        return view
    }()

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                backgroundColor = UDColor.fillPressed
            } else {
                backgroundColor = .clear
            }
        }
    }

    private var hoverGesture: UIGestureRecognizer?
    private var iconCenterConstraint: Constraint?
    private let bag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.ud.setBorderColor(UDColor.lineBorderCard)

        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16).priority(.low)
            iconCenterConstraint = make.centerX.equalToSuperview().priority(.required).constraint
            iconCenterConstraint?.deactivate()
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
        }


        addSubview(titleStackView)
        titleStackView.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.right.lessThanOrEqualToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview().offset(8)
        }
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleStackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        if #available(iOS 13.0, *) {
            setupHoverInteraction()
        }
    }

    @available(iOS 13.0, *)
    private func setupHoverInteraction() {
        guard SKDisplay.pad else { return }
        let gesture = UIHoverGestureRecognizer()
        gesture.rx.event.subscribe(onNext: { [weak self] gesture in
            guard let self else { return }
            switch gesture.state {
            case .began, .changed:
                if !self.isHighlighted {
                    self.backgroundColor = UDColor.fillHover
                }
            case .ended, .cancelled:
                if !self.isHighlighted {
                    self.backgroundColor = .clear
                }
            default:
                break
            }
        })
        .disposed(by: bag)
        hoverGesture = gesture
        addGestureRecognizer(gesture)
    }

    func update(config: Config) {
        titleLabel.text = config.title
        subtitleLabel.text = config.subtitle
        iconView.image = config.icon
    }
    
    func update(enable: Bool) {
        if !enable {
            iconView.alpha = 0.4
            titleLabel.textColor = UDColor.textDisabled
            subtitleLabel.textColor = UDColor.textDisabled
        } else {
            iconView.alpha = 1.0
            titleLabel.textColor = UDColor.textTitle
            subtitleLabel.textColor = UDColor.textCaption
        }
    }

    override func layoutSubviews() {
        subtitleLabel.isHidden = frame.width < 240
        if frame.width < 110 {
            titleLabel.isHidden = true
            iconCenterConstraint?.activate()
        } else {
            titleLabel.isHidden = false
            iconCenterConstraint?.deactivate()
        }
        super.layoutSubviews()
    }
}
