//
//  SearchInChatResourcePresntable.swift
//  LarkSearch
//
//  Created by Patrick on 2022/1/5.
//

import Foundation
import RxSwift
import LarkModel
import RustPB
import LarkSDKInterface

struct SearchResource {
    enum Data {
        case image(ImageSet)
        case video(Basic_V1_MediaContent)

        init(resource: Media_V1_GetChatResourcesResponse.Resource) {
            switch resource.type {
            case .image:
                self = .image(resource.image)
            case .video:
                self = .video(resource.video.mediaContent)
            @unknown default:
                assert(false, "new value")
                self = .image(resource.image)
            }
        }

        init(content: Search_Resource_ResourceMeta.ResourceContent) {
            switch content.typedResource {
            case .imageContent(let content):
                self = .image(content.image)
            case .videoContent(let content):
                self = .video(content.media)
            case .none:
                fallthrough // use unknown default setting to fix warning
            @unknown default:
                assert(false, "new value")
                self = .image(content.imageContent.image)
            }
        }
    }
    let messageId: String
    let threadID: String
    let messagePosition: Int32
    let data: Data
    let createTime: Date
    let originSize: UInt64?
    let isOriginSource: Bool?
    let threadPosition: Int32
    let hasPreviewPremission: Bool?

    init(messageId: String,
         threadID: String,
         messagePosition: Int32,
         threadPosition: Int32,
         data: Data,
         createTime: Date,
         hasPreviewPremission: Bool? = nil,
         originSize: UInt64? = nil,
         isOriginSource: Bool? = nil) {
        self.messageId = messageId
        self.threadID = threadID
        self.messagePosition = messagePosition
        self.threadPosition = threadPosition
        self.data = data
        self.createTime = createTime
        self.hasPreviewPremission = hasPreviewPremission
        self.originSize = originSize
        self.isOriginSource = isOriginSource
    }
}

protocol SearchInChatResourcePresntable {
    var chatAPI: ChatAPI { get }
    var messageAPI: MessageAPI { get }
    var resoures: Observable<([SearchResource], String, HotAndColdTipType?)> { get }
    var status: Observable<SearchImageInChatViewModel.Status> { get }
    var loadMoreDuration: Observable<Double> { get }
    func fetchInitData()
    func loadMore()
    func search(param: SearchParam) // Optional
}

extension SearchInChatResourcePresntable {
    func search(param: SearchParam) {}
}
