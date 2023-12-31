//
//  OperationDialogImageView.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/8/24.
//

import UIKit
import ByteWebImage
import UniverseDesignLoading
import UniverseDesignEmpty
import LKCommonsLogging

private enum State {
    case initial
    case loading
    case success
    case failure
}

enum WPDialogImageAction {
    case retry
    case onTap
}

final class OperationDialogImageView: UIView {
    static let logger = Logger.log(OperationDialogImageView.self)

    // MARK: - public properties
    var eventHandler: ((OperationDialogImageView, WPDialogImageAction) -> Void)?

    // MARK: - private properties
    private let scrollView: UIScrollView = {
        UIScrollView()
    }()

    private let imageView: ByteImageView = {
        let vi = ByteImageView()
        vi.contentMode = .scaleAspectFit
        return vi
    }()

    private let loadingView: UDSpin = {
        let str = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_Loading
        return UDLoading.presetSpin(size: .large, loadingText: str)
    }()

    private let emptyView: UDEmpty = {
        let str = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_FailRefreshMsg
        let desc = UDEmptyConfig.Description(descriptionText: str)
        let config = UDEmptyConfig(description: desc, type: .loadingFailure)
        let vi = UDEmpty(config: config)
        vi.isUserInteractionEnabled = false
        return vi
    }()

    private let imageFetcher: ImageManager

    private var state = State.initial {
        didSet {
            backgroundColor = (state == .success ? UIColor.clear : UIColor.ud.bgFloat)
            imageView.alpha = (state == .success ? 1.0 : 0.0)
            loadingView.alpha = (state == .loading ? 1.0 : 0.0)
            emptyView.alpha = (state == .failure ? 1.0 : 0.0)
        }
    }

    // MARK: - life cycle

    init(imageFetcher: ImageManager) {
        self.imageFetcher = imageFetcher
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - public

    func loadImage(_ url: URL?) {
        guard let url = url else {
            self.state = .failure
            return
        }
        self.state = .loading
        // 用下载器下载是因为只有下载器才支持设置 HTTP Header
        Self.logger.info("[dialog] img load start!")
        // 闭包过长，注意精简
        // swiftlint:disable closure_body_length
        imageFetcher.requestImage(url, completion: { [weak self] result in
            guard let `self` = self else {
                return
            }
            switch result {
            case .success(let ret):
                if let image = ret.image {
                    self.state = .success
                    if image.size.width > 0, image.size.height > 0 {
                        let scale = self.bounds.size.width / image.size.width
                        let scaleSize = CGSize(
                            width: image.size.width * scale,
                            height: floor(image.size.height * scale)
                        )
                        self.imageView.snp.remakeConstraints { make in
                            if scaleSize.height > self.bounds.height {
                                make.left.top.equalToSuperview()
                            } else {
                                make.center.equalToSuperview()
                            }
                            make.size.equalTo(scaleSize)
                        }
                        self.scrollView.contentSize = scaleSize
                        Self.logger.info(
                            "[dialog] img load scale size: \(scaleSize), container size: \(self.bounds.size)"
                        )
                    } else {
                        // 异常兜底
                        Self.logger.warn("[dialog] img invalid size")
                        self.imageView.snp.remakeConstraints { make in
                            make.edges.equalToSuperview()
                        }
                        self.scrollView.contentSize = self.bounds.size
                    }
                    Self.logger.info("[dialog] img load success, size: \(image.size)!")
                    self.imageView.image = image
                } else {
                    self.state = .failure
                    Self.logger.error("[dialog] img load fail: nil image!")
                }
            case .failure(let err):
                self.state = .failure
                Self.logger.error("[dialog] img load fail: \(err)!")
            }
        })
        // swiftlint:enable closure_body_length
    }

    // MARK: - private

    @objc
    private func onTap(_ sender: UITapGestureRecognizer) {
        switch state {
        case .failure:
            eventHandler?(self, .retry)
        case .success:
            eventHandler?(self, .onTap)
        default:
            break
        }
    }

    private func setupSubviews() {
        layer.masksToBounds = true
        layer.cornerRadius = 8.0

        state = .initial

        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        addGestureRecognizer(tap)

        addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        scrollView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
