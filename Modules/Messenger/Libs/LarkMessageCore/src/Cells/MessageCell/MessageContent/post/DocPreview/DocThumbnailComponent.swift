//
//  DocThumbnailComponent.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/20.
//

import UIKit
import Foundation
import UIImageViewAlignedSwift
import AsyncComponent
import EEFlexiable
import LarkCore
import LarkModel
import LKCommonsLogging
import RxSwift
import ByteWebImage
import RustPB
import UniverseDesignTheme

public protocol DocThumbnailComponentDelegate: AnyObject {
    var thumbnailDecryptionAvailable: Bool { get }
    func downloadThumbnail(url: String, fileType: Int, thumbnailInfo: [String: Any], imageViewSize: CGSize) -> Observable<UIImage>
}

enum DocThumbnailError: Error {
    case urlNotFound
    case delegateNotFound
}

public final class DocThumbnailComponent<C: AsyncComponent.Context>: ASComponent<DocThumbnailComponent.Props, EmptyState, DocThumbnailImageViewAligned, C> {
    public final class Props: ASComponentProps {
        public weak var delegate: DocThumbnailComponentDelegate?
        public var image: UIImage?
        public var imageUrlString: String?
        public var thumbNai: [String: Any]?

        public var contentMode: UIView.ContentMode = .scaleAspectFill
        public var alignment: UIImageViewAlignmentMask = .top
        public var docType: RustPB.Basic_V1_Doc.TypeEnum = .unknown
    }
    private let logger = Logger.log(DocThumbnailComponent.self, category: "LarkMessage.DocsPreview")

    public override func create(_ rect: CGRect) -> DocThumbnailImageViewAligned {
        let view = DocThumbnailImageViewAligned()
        view.clipsToBounds = true
        view.ud.setMaskView()
        return view
    }

    public override var isComplex: Bool {
        return true
    }

    var thumbnailDecryptionAvailable: Bool {
        props.delegate?.thumbnailDecryptionAvailable ?? false
    }

    public override func update(view: DocThumbnailImageViewAligned) {
        super.update(view: view)
        view.backgroundColor = .white
        guard thumbnailDecryptionAvailable else { // Lark Messenger App 中不下载加密的缩略图
            view.alignment = props.alignment
            view.contentMode = props.contentMode
            view.image = props.image
            updateThumbnailUsingKF(imageView: view, urlString: props.imageUrlString)
            return
        }

        updateThumbnailUsingDoc(imageView: view, props: props)
    }

    private func updateThumbnailUsingKF(imageView: DocThumbnailImageViewAligned, urlString: String?) {
        guard let urlString = urlString else {
            // 取消 KF 正在进行的下载请求
            imageView.bt.cancelImageRequest()
            imageView.alignment = .center
            imageView.contentMode = .center
            imageView.image = Resources.imageDownloadFailed
            logger.warn("Failed to download docs preview thumbnail, thumbnail url is nil")
            return
        }
        // 下载未加密的图片
        imageView.bt.setLarkImage(
            with: .default(key: urlString),
            trackStart: {
                TrackInfo(biz: .Messenger, scene: .Chat, fromType: .unknown)
            },
            completion: { [weak self, weak imageView] result in
                switch result {
                case .success:
                    imageView?.contentMode = .scaleAspectFill
                case .failure(let error):
                    if error.code == ByteWebImageErrorUserCancelled {
                        self?.logger.error("download unencrypt thumbnail failed, task was cancelled or other task is running")
                        return
                    }
                    // 其他错误需要设置错误兜底图片
                    imageView?.alignment = .center
                    imageView?.contentMode = .center
                    imageView?.image = Resources.imageDownloadFailed
                    self?.logger.error("download unencrypt thumbnail failed with error", error: error)
                }
            }
        )
    }

    private func updateThumbnailUsingDoc(imageView: DocThumbnailImageViewAligned, props: Props) {
        let thumbnailSource: Observable<UIImage>
        let resourceID: String
        if let urlString = props.imageUrlString {
            resourceID = urlString
            // 正常获取到缩略图 URL，使用 Docs 下载缩略图
            let thumbnailInfo: [String: Any]
            if let thumbnailDetail = props.thumbNai {
                thumbnailInfo = thumbnailDetail
            } else {
                thumbnailInfo = [:]
                logger.warn("Failed to retrive thumbnail detail from props")
            }
            thumbnailSource = downloadThumbnail(url: urlString,
                                                fileType: props.docType.rawValue,
                                                thumbnailInfo: thumbnailInfo,
                                                imageViewSize: imageView.bounds.size)
        } else {
            // 获取缩略图 URL 失败，直接返回错误
            resourceID = ""
            thumbnailSource = .error(DocThumbnailError.urlNotFound)
        }
        guard imageView.needUpdate(with: resourceID) else {
            return
        }
        // 仅在确认需要重新加载时才进行重用的清理逻辑
        imageView.alignment = props.alignment
        imageView.contentMode = props.contentMode
        imageView.image = props.image
        imageView.update(resourceID: resourceID,
                         thumbnailSource: thumbnailSource) { [weak imageView, weak self] result in
            switch result {
            case .success:
                imageView?.contentMode = .scaleAspectFill
            case let .failure(error):
                imageView?.alignment = .center
                imageView?.contentMode = .center
                imageView?.image = Resources.imageDownloadFailed
                self?.logger.error("Download docs preview thumbnail failed with error", error: error)
            }
        }
    }

    func downloadThumbnail(url: String, fileType: Int, thumbnailInfo: [String: Any], imageViewSize: CGSize) -> Observable<UIImage> {
        guard let delegate = props.delegate else {
            logger.error("Failed to get delegate when download thumbnail")
            assertionFailure("Failed to get delegate when download thumbnail")
            return .error(DocThumbnailError.delegateNotFound)
        }
        return delegate.downloadThumbnail(url: url, fileType: fileType, thumbnailInfo: thumbnailInfo, imageViewSize: imageViewSize)
    }
}
