//
//  ExportDownloadLoadingView.swift
//  SKBrowser
//
//  Created by lizechuang on 2020/11/24.
//  该能力需要被替换，当larkUI组件完成后

import Foundation
import SKCommon
import SKUIKit
import SKResource
import SKFoundation
import UniverseDesignProgressView

// nolint: duplicated_code
class ExportDownloadLoadingView: UIView {
    var cancelAction: (() -> Void)?
    var progress: Float = 0.0
    private(set) lazy var downloadingContainer: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.ud.N00
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        addSubview(view)
        return view
    }()

    private(set) lazy var titleLabel: UILabel = {
        let view = UILabel(frame: .zero)

        view.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        view.textColor = UIColor.ud.N900
        view.text = BundleI18n.SKResource.Drive_Drive_Loading
        downloadingContainer.addSubview(view)
        return view
    }()

    private(set) lazy var progressBar: UDProgressView = {
        let view = UDProgressView()
        downloadingContainer.addSubview(view)
        return view
    }()

    private(set) lazy var progressLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = UIColor.ud.N600
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
        btn.backgroundColor = UIColor.ud.N00
        btn.addTarget(self, action: #selector(cancelButtonClick(_:)), for: .touchUpInside)
        downloadingContainer.addSubview(btn)
        return btn
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.2)
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func complete() {
        removeFromSuperview()
    }

    @objc
    private func cancelButtonClick(_ button: UIButton) {
        cancelAction?()
    }

    deinit {
        DocsLogger.info("ExportDownloadLoadingView-----deinit")
    }
}

extension ExportDownloadLoadingView {
    private func setupSubviews() {
        downloadingContainer.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(160)
            if SKDisplay.pad {
                make.width.equalTo(CGFloat.scaleBaseline)
            } else {
                make.width.equalToSuperview().multipliedBy(0.8)
            }
        }

        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(20)
        }

        progressBar.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.height.equalTo(4)
            make.width.equalToSuperview().multipliedBy(0.8)
        }

        progressLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(progressBar.snp.bottom).offset(12)
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
}

extension ExportDownloadLoadingView {
    func updateProgress(_ progress: Float) {
        let pro = max(min(progress, 1.0), 0)
        self.progress = pro
        self.progressBar.setProgress(CGFloat(pro), animated: false)
        progressLabel.text = String(format: "%.0f", (pro / 1.0) * 100) + "%"
    }

    static weak var currentLoadingView: ExportDownloadLoadingView?

    class func show(fromVC: UIViewController) -> ExportDownloadLoadingView {
        if let view = currentLoadingView {
            return view
        }

        let loadingView = ExportDownloadLoadingView(frame: .zero)
        fromVC.view.window?.addSubview(loadingView)
        loadingView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        currentLoadingView = loadingView
        return loadingView
    }
}
