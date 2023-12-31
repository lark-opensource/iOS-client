//
//  DropInteraction+Extension.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/23.
//

import UIKit
import Foundation

extension DropInteraction {

    /// 创建 Drop Interaction
    /// - Parameters:
    ///   - canHandle: 是否可以整体响应 drop
    ///   - itemHandleType: item handle 的策略
    ///   - itemTypes: 支持的 item type 以及对应的 handler
    ///   - itemOptions: item 的一些可选项
    ///   - resultCallback: 结果回调
    public static func create(
        canHandle: @escaping DropItemHandler.CanHandleBlock = { (_, _) -> Bool in true },
        itemHandleType: DropItemHandleTactics = .containSupportTypes,
        itemTypes: [DropItemType],
        itemOptions: [DropItemOptions] = [],
        resultCallback: @escaping ([DropItemValue]) -> Void
    ) -> DropInteraction {
        let dropInteraction = DropInteraction()

        dropInteraction.dropItemHandler.canHandle = { (interaction, session) -> Bool in
            /// 整体判断是否响应
            guard canHandle(interaction, session) else {
                return false
            }

            return DropInteraction.canHanle(
                session: session,
                items: session.items,
                itemTypes: itemTypes,
                itemHandleType: itemHandleType,
                itemOptions: itemOptions
            )
        }

        dropInteraction.dropItemHandler.handleDragSession = { (interaction, session) in
            DropInteraction.handleDropItems(session.items, itemTypes: itemTypes) { (results) in
                if !results.isEmpty {
                    resultCallback(results)
                }
            }
        }

        return dropInteraction
    }

    // lint:disable lark_storage_check - component 层级组件，临时存储，用于上下文同步，不做存储检查
    // TODO: Library/Caches/ -> tmp/ 更合理
    private static func randomFileURL() -> URL? {
        guard let urlStr = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
            return nil
        }
        let url = URL(fileURLWithPath: urlStr)
        return url.appendingPathComponent(UUID().uuidString)
    }

    private static func copyOrMoveFile(at: URL, to: URL) -> Bool {
        do {
            try FileManager.default.moveItem(at: at, to: to)
            return true
        } catch {
            do {
                try FileManager.default.copyItem(at: at, to: to)
                return true
            } catch _ {
                return false
            }
        }
    }
    // lint:enable lark_storage_check

    /// 根据参数判断是否可以处理 items
    static func canHanle(
        session: UIDropSession,
        items: [UIDragItem],
        itemTypes: [DropItemType],
        itemHandleType: DropItemHandleTactics,
        itemOptions: [DropItemOptions]
    ) -> Bool {
        /// 判断是否支持多个 item
        if items.count > 1,
            itemOptions.contains(.onlySupportOneItem) {
            return false
        }

        /// 判断是否支持其他 app 的 drop
        if itemOptions.contains(.onlySupportCurrentApplication),
            session.localDragSession == nil {
            return false
        }

        /// 判断是否支持当前 app 的 drop
        if itemOptions.contains(.notSupportCurrentApplication),
            session.localDragSession != nil {
            return false
        }

        var containSupportType: Bool = false
        for itemType in itemTypes {
            var support: Bool = false
            switch itemType {
            case .classType(let classType):
                support = session.canLoadObjects(ofClass: classType)
            case .UTIDataType(let uti):
                support = session.hasItemsConforming(
                    toTypeIdentifiers: [uti]
            )
            case .UTIURLType(let uti):
                support = session.hasItemsConforming(
                    toTypeIdentifiers: [uti]
                )
            }
            containSupportType = containSupportType || support

            if itemHandleType == .onlySupportTypes && !containSupportType {
                return false
            }
            if itemHandleType == .containSupportTypes && containSupportType {
                return true
            }
        }
        return containSupportType
    }

    /// 获取 UIDragItem 数据
    static func handleDropItems(
        _ items: [UIDragItem],
        itemTypes: [DropItemType],
        callback: @escaping ([DropItemValue]) -> Void
    ) {
        let disposeGroup = DispatchGroup()
        var canHandleItems: [UIDragItem] = []
        items.forEach { (item) in
            let itemProvider = item.itemProvider
            var canHandle: Bool = false
            for itemType in itemTypes {
                if canHandle {
                    break
                }
                switch itemType {
                case let .classType(classType):
                    canHandle = itemProvider.canLoadObject(ofClass: classType)
                    if canHandle {
                        disposeGroup.enter()
                        itemProvider.loadObject(
                            ofClass: classType
                        ) { (result, error) in
                            if let error = error {
                                item.liItemResult = .failure(error)
                            } else if let result = result {
                                item.liItemResult = .success(.init(
                                    suggestedName: itemProvider.fullSuggestedName,
                                    itemData: .classType(result)
                                    )
                                )
                            }
                            disposeGroup.leave()
                        }
                }
                case let .UTIDataType(uti):
                    canHandle = itemProvider.hasItemConformingToTypeIdentifier(uti)
                    if canHandle {
                        disposeGroup.enter()
                        itemProvider.loadDataRepresentation(
                            forTypeIdentifier: uti
                        ) { (data, error) in
                            if let error = error {
                                item.liItemResult = .failure(error)
                            } else if let data = data {
                                item.liItemResult = .success(.init(
                                    suggestedName: itemProvider.fullSuggestedName,
                                    itemData: .UTIDataType(uti, data)
                                    )
                                )
                            }
                            disposeGroup.leave()
                        }
                }
                case let .UTIURLType(uti):
                    canHandle = itemProvider.hasItemConformingToTypeIdentifier(uti)
                    if canHandle {
                        disposeGroup.enter()
                        itemProvider.loadFileRepresentation(
                            forTypeIdentifier: uti
                        ) { (url, error) in
                            if let error = error {
                                item.liItemResult = .failure(error)
                            } else if let url = url,
                                let randomURL = randomFileURL(),
                                copyOrMoveFile(at: url, to: randomURL) {
                                /// 这里把文件 copy 到本地 cache 目录

                                item.liItemResult = .success(.init(
                                    suggestedName: itemProvider.fullSuggestedName,
                                    itemData: .UTIURLType(uti, randomURL)
                                    )
                                )
                            }
                            disposeGroup.leave()
                        }
                    }
                }
            }
            if canHandle {
                canHandleItems.append(item)
            }
        }
        disposeGroup.notify(queue: DispatchQueue.main) {
            let results = canHandleItems.compactMap { (item) -> Result<DropItemValue, Error>? in
                return item.liItemResult
            }.compactMap { (result) -> DropItemValue? in
                switch result {
                case .failure:
                    return nil
                case .success(let value):
                    return value
                }
            }
            callback(results)
        }
    }
}
