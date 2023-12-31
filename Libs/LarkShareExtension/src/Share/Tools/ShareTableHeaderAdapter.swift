//
//  ShareTableHeaderAdapter.swift
//  ShareExtension
//
//  Created by K3 on 2018/7/3.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices
import LarkExtensionCommon

protocol ShareTableHeaderProtocol {
    /// Header 需要根据内容提供自己的高度
    var viewHeight: CGFloat { get }
}

final class ShareTableHeaderAdapter {
    private var viewWidth: CGFloat
    init(viewWidth: CGFloat) {
        self.viewWidth = viewWidth
    }

    func header(with content: ShareContent) -> ShareTableHeaderProtocol? {
        var header: ShareTableHeaderProtocol?
        // 分享视频时，即使在Extension里判断了视频以文件发送，但还是需要在IM侧重新对视频进行判断（时长、文件大小等），所以要content.contentType=.movie的形式发送
        if let movieItem = content.item as? ShareMovieItem, movieItem.isFallbackToFile {
            return fileHeader(ShareFileItem(url: movieItem.url, name: movieItem.name))
        }

        switch content.contentType {
        case .text: header = textHeader(content.item)
        case .image: header = imageHeader(content.item)
        case .fileUrl: header = fileHeader(content.item)
        case .multiple: header = multipleHeader(content.item)
        case .movie: header = movieHeader(content.item)
        }
        return header
    }

    private func textHeader(_ item: ShareItemProtocol?) -> ShareTableHeaderProtocol? {
        guard let item = item as? ShareTextItem else {
            return nil
        }
        let view = ShareTextView(item: item)
        view.frame = frame(with: view.viewHeight)
        return view
    }

    private func imageHeader(_ item: ShareItemProtocol?) -> ShareTableHeaderProtocol? {
        guard let item = item as? ShareImageItem else {
            return nil
        }
        if item.images.count == 1 {
            let view = ShareSingleImageView(item: item, availableWidth: viewWidth)
            view.frame = frame(with: view.viewHeight)
            return view
        } else {
            let view = ShareImagesView(item: item, availableWidth: viewWidth)
            view.frame = frame(with: view.viewHeight)
            return view
        }
    }

    private func fileHeader(_ item: ShareItemProtocol?) -> ShareTableHeaderProtocol? {
        guard let item = item as? ShareFileItem else {
            return nil
        }
        let view = ShareFileView(item: item)
        view.frame = frame(with: view.viewHeight)
        return view
    }

    private func multipleHeader(_ item: ShareItemProtocol?) -> ShareTableHeaderProtocol? {
        guard let item = item as? ShareMultipleItem,
              let fileItem = item.fileItems.first else {
            return nil
        }
        let view = ShareFileView(item: fileItem)
        view.frame = frame(with: view.viewHeight)
        return view
    }

    private func movieHeader(_ item: ShareItemProtocol?) -> ShareTableHeaderProtocol? {
        guard let movieItem = item as? ShareMovieItem else { return nil }
        let view = ShareMovieView(item: movieItem)
        view.frame = frame(with: view.viewHeight)
        return view
    }

    private func frame(with viewHeight: CGFloat) -> CGRect {
        return CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
    }
}
