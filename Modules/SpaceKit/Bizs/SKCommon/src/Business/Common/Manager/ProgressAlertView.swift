//
//  ProgressAlertView.swift
//  SKCommon
//
//  Created by ByteDance on 2022/9/13.
//

import Foundation
import UIKit
import UniverseDesignProgressView
import UniverseDesignColor
import SKFoundation
import SKResource
import EENavigator
// nolint: duplicated_code 
open class ProgressAlertView: UIView {
    public var cancelAction: (() -> Void)?

    private(set) lazy var downloadingContainer: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UDColor.bgFloat
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        addSubview(view)
        return view
    }()

    private(set) lazy var titleLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        view.textColor = UIColor.ud.N900
        downloadingContainer.addSubview(view)
        return view
    }()

    private(set) lazy var progressBar: UDProgressView = {
        let config = UDProgressViewUIConfig(type: .linear, barMetrics: .default, layoutDirection: .horizontal, showValue: false)
        let view = UDProgressView(config: config)
        downloadingContainer.addSubview(view)
        return view
    }()

    private(set) lazy var progressLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = UIColor.ud.N600
        view.textAlignment = .center
        view.text = "0%"
        downloadingContainer.addSubview(view)
        return view
    }()

    private(set) lazy var seperateLine: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.ud.N300
        downloadingContainer.addSubview(view)
        return view
    }()

    private(set) lazy var cancelButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        btn.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        btn.setTitle(BundleI18n.SKResource.Drive_Drive_Cancel, for: .normal)
        btn.backgroundColor = UDColor.bgFloat
        btn.addTarget(self, action: #selector(cancelButtonClick(_:)), for: .touchUpInside)
        downloadingContainer.addSubview(btn)
        return btn
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UDColor.bgMask
        setupSubviews()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func cancelButtonClick(_ button: UIButton) {
        didCanceled()
    }

    deinit {
        DocsLogger.info("ProgressAlertView-----deinit")
    }
    
    private func setupSubviews() {
        progressLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        downloadingContainer.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.8)
            make.height.equalTo(160)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(20)
        }

        progressBar.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(17)
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.height.equalTo(4)
            make.centerY.equalToSuperview()
        }

        progressLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(progressBar.snp.centerY)
            make.left.equalTo(progressBar.snp.right).offset(12)
            make.right.equalToSuperview().offset(-17)
        }

        cancelButton.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(49)
        }

        seperateLine.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(cancelButton.snp.top)
            make.height.equalTo(0.5)
        }
    }
    
    public var titleText: String = "" {
        didSet {
            titleLabel.text = titleText
        }
    }
    // 主动点击cancel按钮
    open func didCanceled() {
        dismiss()
        cancelAction?()
    }
    public func show(on viewController: UIViewController) {
        viewController.view.addSubview(self)
        self.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    public func dismiss() {
        removeFromSuperview()
    }
    public func updateProgress(_ progress: Float) {
        let pro = max(min(progress, 1.0), 0)
        progressBar.setProgress(CGFloat(pro), animated: true)
        progressLabel.text = String(format: "%.0f", (pro / 1.0) * 100) + "%"
    }
}
