//
//  DocsEditorDependency.swift
//  SKBrowser
//
//  Created by lijuyou on 2021/7/13.
//  


import Foundation
import SKEditor

class DocsEditorDependency: EditorDependency {
    var dataSource: EditorDataSource? {
        DocsEditorDataSource()
    }

    var imageLoader: ImageDownloaderProtocol? {
        KFImageDownloader.shared
    }

    var pluginList: [EditorPlugin]? {
        nil
    }

}
