//
//  DriveFetchFailedView.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/1/23.
//

import UIKit
import SKCommon
import SKResource
import SKFoundation
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignButton

class DriveFetchFailedView: UIView {

    enum Status {
        case failed
        case failedNoRetry
    }

    var retryAction: (() -> Void)?
    var retryButtonEnable: Bool = true {
        didSet {
            let buttonThemeColor = retryButtonEnable ? UDEmpty.primaryColor : UDEmpty.primaryDisableColor
            failedView.primaryButtonConfig = UDButtonUIConifg(normalColor: buttonThemeColor, type: .middle)
        }
    }

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

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UDColor.bgBase
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func retryButtonClick(_ button: UIButton) {
        retryAction?()
    }

    deinit {
        DocsLogger.driveInfo("DriveFetchFailedView-----deinit")
    }
    
    private func setupSubviews() {
        addSubview(failedView)
        failedView.snp.makeConstraints { (make) in
            make.center.left.right.equalToSuperview()
        }
    }
}

// MARK: - Public
extension DriveFetchFailedView {
    func render(status: Status) {
        var retryConfig: (String?, (UIButton) -> Void)?
        switch status {
        case .failed:
            retryConfig = (BundleI18n.SKResource.Drive_Drive_Retry, { [weak self] button in
                guard let self = self else { return }
                guard self.retryButtonEnable else { return }
                self.retryButtonClick(button)
            })
        case .failedNoRetry:
            retryConfig = nil
        }
        emptyConfig.primaryButtonConfig = retryConfig
        emptyConfig.description = .init(descriptionText: BundleI18n.SKResource.Drive_Drive_LoadingFail)
        failedView.update(config: emptyConfig)
    }

    func render(reason: String, image: UIImage?) {
        emptyConfig.primaryButtonConfig = nil
        emptyConfig.description = .init(descriptionText: reason)
        if let customImage = image {
            emptyConfig.type = .custom(customImage)
        } else {
            emptyConfig.type = .loadingFailure
        }
        failedView.update(config: emptyConfig)
    }
}
