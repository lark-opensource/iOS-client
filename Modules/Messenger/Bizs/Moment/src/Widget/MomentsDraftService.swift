//
//  DraftService.swift
//  Moment
//
//  Created by liluobin on 2021/3/22.
//

// 草稿管理器：草稿的存储和获取服务
import Foundation
import UIKit
import LarkContainer
import RxSwift
import RustPB
import LarkCore
import LarkBaseKeyboard
import LKCommonsLogging
/// 存储
struct MomentsDraftItem: Persistable {
    public static let `default` = MomentsDraftItem()

    init(unarchive: [String: Any]) {
        guard let contentStr = unarchive["jsonContent"] as? String,
              let images = unarchive["images"] as? [String],
              let videos = unarchive["videos"] as? [String],
              let categoryID = unarchive["categoryID"] as? String,
              let anonymous = unarchive["anonymous"] as? Bool
        else {
            return
        }
        self.jsonContent = contentStr
        self.categoryID = categoryID
        self.anonymous = anonymous
        self.images = images
        self.videos = videos
        self.content = try? RustPB.Basic_V1_RichText(jsonString: contentStr)
    }

    func archive() -> [String: Any] {
        return [
            "jsonContent": jsonContent,
            "images": images,
            "videos": videos,
            "categoryID": categoryID,
            "anonymous": anonymous
        ]
    }

    var content: RustPB.Basic_V1_RichText?
    var images: [String] = []
    var videos: [String] = []
    var categoryID: String = ""
    var anonymous: Bool = false

    private var jsonContent = ""

    init(categoryID: String = "",
         anonymous: Bool = false,
         content: RustPB.Basic_V1_RichText? = nil,
         images: [String] = [],
         videos: [String] = []) {
        self.categoryID = categoryID
        self.anonymous = anonymous
        self.content = content
        self.images = images
        self.videos = videos
        self.jsonContent = jsonString(from: content)
    }

    static func draftKeyWith(postID: String, commentID: String? = nil) -> String {
        guard let commentID = commentID else {
            return postID
        }
        return postID + "_" + commentID
    }

    func jsonString(from: RustPB.Basic_V1_RichText?) -> String {
        guard let richText = from else {
            return ""
        }
        return (try? richText.jsonString()) ?? ""
    }

    func contentToAttrbuteStringWith(attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        if let richText = self.content {
            return RichTextTransformKit.transformRichTextToStr(
                richText: richText,
                attributes: attributes,
                attachmentResult: [:])
        }
        return NSAttributedString()
    }
}
final class DraftNameSpaceConfig {
    let maxCount: Int
    let nameSpace: String
    let type: RawData.StorageType

    fileprivate var values: [String] = []
    init(maxCount: Int, nameSpace: String, type: RawData.StorageType) {
        self.nameSpace = nameSpace
        self.maxCount = maxCount
        self.type = type
    }
}

protocol MomentsDraftService {
    /// 设置key value
    func setValue(_ value: String, forKey key: String, nameSpace: String)
    /// 主线程回调
    func valueForKey(_ key: String, nameSpace: String, complete: ((Bool, String) -> Void)?)
    /// 移除对应nameSpace下的元素
    func removeValueForKey(_ key: String, nameSpace: String)
}

final class MomentsDraftServiceImp: MomentsDraftService, UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(MomentsDraftServiceImp.self, category: "Module.Moments.MomentsDraftServiceImp")

    @ScopedInjectedLazy private var draftApi: UserDraftApiService?
    public lazy var dataQueue: DispatchQueue = {
        let queue = DispatchQueue(label: "moments.draft.data.queue", qos: .userInitiated)
        return queue
    }()

    public lazy var dataScheduler: SerialDispatchQueueScheduler = {
        let scheduler = SerialDispatchQueueScheduler(queue: dataQueue, internalSerialQueueName: dataQueue.label)
        return scheduler
    }()
    let nameSpaces: [DraftNameSpaceConfig]
    let disposeBag = DisposeBag()
    init(userResolver: UserResolver, nameSpaces: [DraftNameSpaceConfig]) {
        self.userResolver = userResolver
        self.nameSpaces = nameSpaces
        self.initData()
    }

    func initData() {
        self.dataQueue.async { [weak self] in
            guard let self = self else { return }
            for item in self.nameSpaces {
                self.getNameSpaceInfo(item.nameSpace) { [weak self] (values) in
                    item.values = values
                    /// 清楚无用的元素
                    self?.removeUnexpectValueIfNeedForItem(item)
                }
            }
        }
    }

    func setValue(_ value: String, forKey key: String, nameSpace: String) {
        guard !nameSpace.isEmpty,
              !key.isEmpty,
              !nameSpaces.isEmpty,
              let item = getItemForNameSpace(nameSpace) else {
            return
        }
        self.setValue(value, forKey: key, type: item.type, nameSpace: item.nameSpace)
    }

    /// 设置数据
    private func setValue(_ value: String, forKey key: String, type: RawData.StorageType, nameSpace: String) {
        let newKey = nameSpaceKeyWith(key: key, nameSpace: nameSpace)
        self.draftApi?.asynSetUserDraftWithKey(newKey, value: value, type: type)
            .subscribeOn(dataScheduler)
            .subscribe(onNext: { [weak self] in
                if let spaceItem = self?.getItemForNameSpace(nameSpace) {
                    self?.updateNameSpaceIfNeed(key: newKey, value: value, nameSpace: nameSpace, item: spaceItem)
                }
            }, onError: { (error) in
                Self.logger.error("setValue 失败 -- key: \(key) nameSpace: \(nameSpace) value:\(value.count) errror:\(error)")
            }).disposed(by: self.disposeBag)
    }

    func removeValueForKey(_ key: String, nameSpace: String) {
        guard !key.isEmpty, !nameSpaces.isEmpty, let item = getItemForNameSpace(nameSpace) else {
            return
        }
        self.setValue("", forKey: key, type: item.type, nameSpace: nameSpace)
    }

    private func getItemForNameSpace(_ nameSpace: String) -> DraftNameSpaceConfig? {
        if !nameSpace.isEmpty, let item = self.nameSpaces.first(where: { (item) -> Bool in
            item.nameSpace == nameSpace }) {
            return item
        }
        return nil
    }

    /// 获取数据
    func valueForKey(_ key: String, nameSpace: String, complete: ((Bool, String) -> Void)?) {
        draftApi?.asynGetUserDraftWithKey(nameSpaceKeyWith(key: key, nameSpace: nameSpace))
            .subscribeOn(dataScheduler)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (value) in
                complete?(true, value)
            }, onError: { (error) in
                complete?(false, "")
                Self.logger.error("获取key失败 -- key: \(key) nameSpace: \(nameSpace) errror:\(error)")
            }).disposed(by: disposeBag)
    }

    private func nameSpaceKeyWith(key: String, nameSpace: String) -> String {
        return nameSpace + "_" + key
    }

    /// 更新nameSpace的数量
    private func updateNameSpaceIfNeed(key: String, value: String, nameSpace: String, item: DraftNameSpaceConfig) {
        self.dataQueue.async { [weak self] in
            let contain = item.values.contains(key)
            /// 不需要处理的情况
            if (value.isEmpty && !contain) || (!value.isEmpty && contain) {
                return
            }
            if value.isEmpty, contain {
                item.values.removeAll { $0 == key }
            }
            if !value.isEmpty, !contain {
                item.values.append(key)
                if item.values.count > item.maxCount, item.maxCount > 0 {
                    let removeKey = item.values[0]
                    item.values.remove(at: 0)
                    self?.draftApi?.synSetUserDraftWithKey(removeKey, value: "", type: item.type)
                }
            }
            let valueStr = item.values.isEmpty ? "" : item.values.joined(separator: "#")
            self?.draftApi?.synSetUserDraftWithKey(nameSpace, value: valueStr, type: item.type)
        }
    }

    /// 获取当前的数量
    private func getNameSpaceInfo(_ nameSpace: String, complete: (([String]) -> Void)?) {
        let value = self.draftApi?.synGetUserDraftWithKey(nameSpace) ?? ""
        let items = value.components(separatedBy: "#").filter { !$0.isEmpty }
        complete?(items)
    }

    /// 移除多余元素
    private func removeUnexpectValueIfNeedForItem(_ item: DraftNameSpaceConfig) {
        if item.values.count <= item.maxCount {
            return
        }
        Self.logger.warn("可能有异常逻辑 导致草稿走入这里")
        for (index, key) in item.values.enumerated() where index < (item.values.count - item.maxCount) {
            self.draftApi?.synSetUserDraftWithKey(key, value: "", type: item.type)
        }
        item.values = item.values.suffix(item.maxCount)
    }
}
