//
//  DocImageComponentViewModel.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/12/2.
//

import UIKit
import Foundation
import RustPB
import RxSwift
import SwiftyJSON
import TangramComponent
import TangramUIComponent
import LKCommonsLogging

public final class DocImageComponentViewModel: RenderComponentBaseViewModel {
    static let logger = Logger.log(DocImageComponentViewModel.self, category: "DynamicURLComponent.DocImageComponentViewModel")

    private lazy var _component: DocImageComponent<EmptyContext> = .init(props: .init())
    public override var component: Component {
        return _component
    }
    private let disposeBag = DisposeBag()

    public override func buildComponent(stateID: String,
                                        componentID: String,
                                        component: Basic_V1_URLPreviewComponent,
                                        style: Basic_V1_URLPreviewComponent.Style,
                                        property: Basic_V1_URLPreviewComponent.OneOf_UrlpreviewComponentProperty?,
                                        renderStyle: RenderComponentStyle) {
        let docImage = property?.docImage ?? .init()
        let props = buildComponentProps(property: docImage)
        _component = DocImageComponent<EmptyContext>(props: props, style: renderStyle)
    }

    private func buildComponentProps(property: Basic_V1_URLPreviewComponent.DocImageProperty) -> DocImageComponentProps {
        let props = DocImageComponentProps()
        let thumbnailInfo: [String: Any] = [
            "url": property.secretURL,
            "nonce": property.secretNonce,
            "secret": property.secretKey,
            "type": Int(property.secretType)
        ]
        // 需要使用缩略图加载所需的所有信息作为identifier
        let identifier = "\(property.thumbnailURL)\(thumbnailInfo)\(property.docType.rawValue)"
        props.identifier = "\(identifier.hashValue)"
        props.setImageTask.update { [weak self] size, completion in
            guard let self = self else { return }
            self.downloadThumbnail(url: property.thumbnailURL,
                                   fileType: property.docType.rawValue,
                                   thumbnailInfo: thumbnailInfo,
                                   viewSize: size)
                // 此处主线程监听也可能导致下一个Runloop才执行（即使信号主线程发送），downloadThumbnail内部保证主线程回调
                // .observeOn(MainScheduler.instance)
                .subscribe(onNext: { image in
                    // 为了解决缩略图闪烁，downloadThumbnail内部保证主线程回调，此处也兜底一下
                    mainOrAsync {
                        let config = ImageViewAlignedWrapper.Config(image: image,
                                                                    contentMode: .scaleAspectFill,
                                                                    alignment: .top)
                        completion(config)
                    }
                }, onError: { error in
                    mainOrAsync {
                        let config = ImageViewAlignedWrapper.Config(image: Resources.imageDownloadFailed,
                                                                    contentMode: .center,
                                                                    alignment: .center,
                                                                    error: error)
                        completion(config)
                        Self.logger.error("downloadThumbnail error", error: error)
                    }
                })
                .disposed(by: self.disposeBag)
        }
        return props
    }

    func downloadThumbnail(url: String, fileType: Int, thumbnailInfo: [String: Any], viewSize: CGSize) -> Observable<UIImage> {
        return dependency.downloadDocThumbnail(url: url, fileType: fileType, thumbnailInfo: thumbnailInfo, viewSize: viewSize)
    }
}
