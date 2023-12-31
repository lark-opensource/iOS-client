//
//  MultiEditStatusComponent.swift
//  LarkMessageCore
//
//  Created by bytedance on 7/18/22.
//

import Foundation
import AsyncComponent
import EEFlexiable
import UIKit
import UniverseDesignIcon
import UniverseDesignLoading
import LarkModel

public final class MultiEditStatusComponentProps: ASComponentProps {
    public var requestStatus: Message.EditMessageInfo.EditRequestStatus?
    public var retryCallback: (() -> Void)?
    public init(requestStatus: Message.EditMessageInfo.EditRequestStatus?) {
        self.requestStatus = requestStatus
    }
}
public final class MultiEditStatusComponent<C: Context>: ASComponent<MultiEditStatusComponentProps, EmptyState, MultiEditStatusView, C> {

    public override init(props: MultiEditStatusComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
    }

    public override func create(_ rect: CGRect) -> MultiEditStatusView {
        let view = MultiEditStatusView(frame: rect, requestStatus: props.requestStatus)
        view.retryCallback = props.retryCallback
        return view
    }

    public override var isComplex: Bool {
        return true
    }

    public override var isSelfSizing: Bool {
        return true
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        guard let requestStatus = props.requestStatus else {
            return .zero
        }
        return MultiEditStatusView.sizeToFit(requestStatus: requestStatus)
    }

    public override func update(view: MultiEditStatusView) {
        super.update(view: view)
        view.requestStatus = props.requestStatus
        view.retryCallback = props.retryCallback
        view.updateUI()
    }
}
public final class MultiEditStatusView: UIView {
    fileprivate var retryCallback: (() -> Void)?
    fileprivate static func sizeToFit(requestStatus: Message.EditMessageInfo.EditRequestStatus) -> CGSize {
        switch requestStatus {
        case .wating:
            return CGSize(width: Self.loadingViewCalculatedWidth,
                          height: 18)
        case .failed:
            return CGSize(width: Self.failViewCalculatedWidth,
                          height: 18)
        @unknown default: return .zero
        }
    }
    fileprivate static var loadingViewCalculatedWidth: CGFloat = {
        return BundleI18n.LarkMessageCore.Lark_IM_EditMessage_MessageUpdating_Text
            .lu.width(font: .systemFont(ofSize: 12), height: 18) + 18
    }()
    fileprivate static var failViewCalculatedWidth: CGFloat = {
        return BundleI18n.LarkMessageCore.Lark_IM_EditMessage_MessageUpdateFailed_Text
            .lu.width(font: .systemFont(ofSize: 12), height: 18) + 18
    }()

    private lazy var loadingView: UDSpin = {
        let textLabelConfig = UDSpinLabelConfig(text: BundleI18n.LarkMessageCore.Lark_IM_EditMessage_MessageUpdating_Text,
                                                font: .systemFont(ofSize: 12),
                                                textColor: .ud.primaryContentDefault)
        let indicatorConfig = UDSpinIndicatorConfig(size: 14, color: UIColor.ud.primaryContentDefault)
        let spinConfig = UDSpinConfig(indicatorConfig: indicatorConfig, textLabelConfig: textLabelConfig, textDistribution: .horizonal)
        let spin = UDSpin(config: spinConfig)
        return spin
    }()

    private lazy var failView: MultiEditStatusFailView = {
        let view = MultiEditStatusFailView()
        return view
    }()

    fileprivate var requestStatus: Message.EditMessageInfo.EditRequestStatus?

    init(frame: CGRect, requestStatus: Message.EditMessageInfo.EditRequestStatus?) {
        self.requestStatus = requestStatus
        super.init(frame: frame)
        addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.centerY.left.equalToSuperview()
        }
        addSubview(failView)
        failView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        failView.retryCallback = { [weak self] in
            self?.requestStatus = .wating
            self?.updateUI()
            self?.retryCallback?()
        }
        updateUI()
    }

    func updateUI() {
        failView.isHidden = true
        loadingView.isHidden = true
        if let requestStatus = requestStatus {
            switch requestStatus {
            case .wating:
                loadingView.isHidden = false
            case .failed:
                failView.isHidden = false
            @unknown default:
                break
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class MultiEditStatusFailView: UIView {
    fileprivate var retryCallback: (() -> Void)?

    private lazy var iconView: UIImageView = {
        let iconView = UIImageView()
        var image = UDIcon.getIconByKey(.warningRedColorful, size: CGSize(width: 14, height: 14))
        image = image.withRenderingMode(.alwaysOriginal)
        iconView.image = image
        return iconView
    }()

    private lazy var label: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkMessageCore.Lark_IM_EditMessage_MessageUpdateFailed_Text
        label.font = .systemFont(ofSize: 12)
        label.textColor = .ud.functionDangerContentDefault
        return label
    }()

    init() {
        super.init(frame: .zero)
        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.centerY.left.equalToSuperview()
            make.width.height.equalTo(14)
        }
        addSubview(label)
        label.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(iconView.snp.right).offset(4)
        }
        lu.addTapGestureRecognizer(action: #selector(retry))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func retry() {
        retryCallback?()
    }
}
