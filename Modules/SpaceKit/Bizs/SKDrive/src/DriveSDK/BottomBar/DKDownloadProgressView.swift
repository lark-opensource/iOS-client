//
//  DKDownloadProgressView.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/7/7.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import SKCommon
import SKResource
import UniverseDesignProgressView
import UniverseDesignIcon
import UniverseDesignColor

class DKDownloadProgressView: UIView, DKBottomBarItemView {
    typealias ViewData = (text: String,
        textColor: UIColor,
        progress: Double?,
        progressBarColor: UIColor)
    
    enum DownloadViewAction {
        case update(data: ViewData)
        case success(url: URL)
        case cancel
    }
    var dismissed: ((DKBottomBarItemView) -> Void)?
    private let viewModel: DKDownloadViewModel
    private var bag = DisposeBag()
    
    private(set) lazy var progressView: UDProgressView = {
        let config = UDProgressViewUIConfig(type: .linear, barMetrics: .default, layoutDirection: .horizontal, showValue: false)
        let view = UDProgressView(config: config)
        return view
    }()
    
    lazy var tipsLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N900
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .left
        label.text = BundleI18n.SKResource.Drive_Sdk_Downloading
        return label
    }()
    
    private lazy var closeBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(UDIcon.closeOutlined.withColor(UDColor.iconN1), for: .normal)
        btn.addTarget(self, action: #selector(closeClicked), for: .touchUpInside)
        return btn
    }()
    
    init(viewModel: DKDownloadViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupSubviews()
        setupViewModel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = 56.0
        return size
    }
    
    private func setupSubviews() {
        backgroundColor = UIColor.ud.N00
        addSubview(progressView)
        addSubview(tipsLabel)
        addSubview(closeBtn)
        
        closeBtn.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
            make.right.equalToSuperview().offset(-12)
        }
        
        tipsLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(12.0)
            make.top.equalToSuperview().offset(12.0)
            make.right.lessThanOrEqualTo(closeBtn.snp.right)
        }
        
        progressView.snp.makeConstraints { (make) in
            make.left.equalTo(tipsLabel)
            make.top.equalToSuperview().offset(36.0)
            make.height.equalTo(4.0)
            make.right.equalTo(closeBtn.snp.left).offset(-12.0)
        }
    }
    private func setupViewModel() {
        viewModel.viewAction.drive(self.rx.action).disposed(by: bag)
    }

    
    @objc
    private func closeClicked() {
        viewModel.cancelDownload()
    }
}

extension Reactive where Base: DKDownloadProgressView {
    internal var action: Binder<DKDownloadProgressView.DownloadViewAction> {
        return Binder(self.base) { downloadView, action in
            switch action {
            case .update(let data):
                downloadView.tipsLabel.text = data.text
                downloadView.tipsLabel.textColor = data.textColor
                if let progress = data.progress {
                    downloadView.progressView.setProgress(CGFloat(progress), animated: true)
                } else {
                    downloadView.progressView.setProgressLoadFailed()
                }
            case .success, .cancel:
                downloadView.dismissed?(downloadView)
            }
        }
    }
}
