//
//  SimpleMetadataUIActivityItemProvider.swift
//  SKUIKit
//
//  Created by lijuyou on 2021/1/7.
//  


import Foundation
import LinkPresentation

//精简metadata UIActivityItemProvider
//因为系统会自动解析文件metadata，解析加密后的视频会crash，所以如果文件被加密，则手动构造Metadata。如果要自定义metadata可以在此类基础上再扩展
public final class SimpleMetadataUIActivityItemProvider: UIActivityItemProvider {
    private let fileURL: URL
    public let isSimple: Bool //是否显示精简metadata
    public init(fileURL: URL, isSimple: Bool) {
        self.fileURL = fileURL
        self.isSimple = isSimple
        super.init(placeholderItem: fileURL)
    }

    public override var item: Any {
        return fileURL
    }

    @available(iOS 13.0, *)
    public override func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        if self.isSimple {
            let metadata = LPLinkMetadata()
            metadata.title = self.fileURL.lastPathComponent
            metadata.url = self.fileURL
            return metadata
        } else {
            return nil
        }
    }
}
