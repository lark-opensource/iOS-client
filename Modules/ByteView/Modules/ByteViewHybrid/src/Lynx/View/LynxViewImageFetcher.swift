//
// Created by maozhixiang.lip on 2022/10/21.
//

import Foundation
import Lynx
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignCardHeader
import UniverseDesignTheme
import ByteViewCommon

protocol LynxViewImageLoader {
    var urlPrefix: String { get }
    func load(_ url: URL, _ size: CGSize) -> UIImage?
}

class LynxViewImageFetcher: NSObject, LynxImageFetcher {
    typealias DispatchBlock = () -> Void
    static let shared: LynxViewImageFetcher = .init()
    private let loaders: [LynxViewImageLoader] = [
        UniverseDesignIconLoader(),
        UniverseDesignEmptyLoader()
    ]

    private override init() {}

    func loadImage(with url: URL?,
                   size targetSize: CGSize,
                   contextInfo: [AnyHashable: Any]?,
                   completion completionBlock: LynxImageLoadCompletionBlock) -> DispatchBlock {
        guard let url = url else { return {} }
        guard targetSize.width > 0 && targetSize.height > 0 else { return {} }
        for loader in self.loaders {
            if url.absoluteString.hasPrefix(loader.urlPrefix) {
                completionBlock(loader.load(url, targetSize), nil, nil)
                return {}
            }
        }
        return {}
    }

    class UniverseDesignIconLoader: LynxViewImageLoader {
        private(set) var urlPrefix: String = "app://ud-icon"

        func load(_ url: URL, _ size: CGSize) -> UIImage? {
            let urlQueryItems = URLComponents(string: url.absoluteString)?.queryItems ?? []
            let iconKey = urlQueryItems.first { $0.name == "key" }?.value ?? ""
            let iconColorToken = urlQueryItems.first { $0.name == "color" }?.value ?? ""
            guard let iconType = UDIcon.getIconTypeByName(iconKey) else { return nil }
            guard let iconColor = UDColor.current.getValueByBizToken(token: iconColorToken) else { return nil }
            return UDIcon.getIconByKey(iconType, iconColor: iconColor, size: size)
        }
    }

    class UniverseDesignEmptyLoader: LynxViewImageLoader {
        private static let keyToEmptyType: [String: UDEmptyType] = [
            "noAccess": .noAccess,
            "noContent": .noContent
        ]
        private(set) var urlPrefix: String = "app://ud-empty"

        func load(_ url: URL, _ size: CGSize) -> UIImage? {
            let urlQueryItems = URLComponents(string: url.absoluteString)?.queryItems ?? []
            let iconKey = urlQueryItems.first { $0.name == "key" }?.value ?? ""
            return Self.keyToEmptyType[iconKey]?.defaultImage()
        }
    }
}
