//
//  SandboxFilesController.swift
//  LarkStorageAssembly
//
//  Created by 李昊哲 on 2022/11/3.
//

#if !LARK_NO_DEBUG
import UIKit
import Foundation
import EENavigator
import LarkStorage

final class SandboxFilesController: ContainerFilesController {
    private static let identifier = "SandboxFilesCell"

    let rootPath: String
    let spaceName: String
    let domainName: String
    let relativePath: String

    init(name: String, root: String, space: String, domain: String, relative: String) {
        rootPath = root
        spaceName = space
        domainName = domain
        relativePath = relative

        let absolutePath = NSString.path(withComponents: [
            rootPath, globalPrefix, "\(spacePrefix)\(spaceName)",
            "\(domainPrefix)\(domainName)", relativePath
        ])
        super.init(name: name, path: absolutePath)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didSelected(_ item: ContainerFilesItem) {
        if item.isDirectory {
            let newPath = NSString.path(withComponents: [relativePath, item.title])
            let controller = SandboxFilesController(
                name: item.title,
                root: rootPath,
                space: spaceName,
                domain: domainName,
                relative: newPath
            )
            Navigator.shared.push(controller, from: self)
        } else {
            present(ContainerPreviewController(path: item.path), animated: true)
        }
    }
}
#endif
