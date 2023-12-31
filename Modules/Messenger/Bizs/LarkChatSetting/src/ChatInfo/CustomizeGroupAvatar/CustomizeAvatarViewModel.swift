//
//  CustomizeAvatarViewModel.swift
//  LarkChatSetting
//
//  Created by kangsiwan on 2020/4/17.
//

import Foundation
import UIKit
import LarkModel
import LarkSDKInterface
import LarkAccountInterface
import LarkMessengerInterface
import RxSwift
import RustPB
import LarkContainer

class AvatarBaseViewModel: UserResolverWrapper {

    let drawStyle: AvatarDrawStyle
    var userResolver: LarkContainer.UserResolver
    let name: String?
    let defaultCenterIcon: UIImage
    let avatarMetaObservable: Observable<RustPB.Basic_V1_AvatarMeta?>

    @ScopedInjectedLazy private var searchAPI: SearchAPI?
    init(name: String?,
         defaultCenterIcon: UIImage,
         drawStyle: AvatarDrawStyle,
         resolver: UserResolver,
         avatarMetaObservable: Observable<RustPB.Basic_V1_AvatarMeta?>) {
        self.name = name
        self.defaultCenterIcon = defaultCenterIcon
        self.drawStyle = drawStyle
        self.userResolver = resolver
        self.avatarMetaObservable = avatarMetaObservable
    }

    /// 得到分词结果
    func getSegmentTexts() -> Observable<[String]> {
        guard let name = name, let searchAPI = self.searchAPI else { return .just([]) }
        // 允许展示的词性列表 htt ps://support.huaweicloud.com/api-nlp/nlp_03_0009.html
        let posAllowList: Set<String> = ["a", "b", "i", "j", "m", "n", "nd", "nh", "ni", "nl", "ns", "nt", "nz", "o", "q", "v", "ws"]
        return searchAPI.segmentText(text: name).catchErrorJustReturn(RustPB.Search_V1_SegmentTextResponse()).map { (response) -> [String] in
            // 和PC逻辑保持一致，只取第一个sentence
            guard let sentence = response.sentences.first else { return [] }
            // 过滤词性，取出展示文本
            return sentence.words.filter({ posAllowList.contains($0.pos) }).map({ $0.cont })
        }
    }

    func fetchRemoteData() -> Observable<([String], RustPB.Basic_V1_AvatarMeta?)> {
        let textOB = self.getSegmentTexts()
        let metaOB = self.avatarMetaObservable
       return Observable.zip(textOB, metaOB)
    }
}

final class CustomizeAvatarViewModel: AvatarBaseViewModel {

    let initAvatarType: AvatarSetType

    init(resolver: UserResolver,
         initAvatarType: AvatarSetType,
         name: String?,
         defaultCenterIcon: UIImage,
         drawStyle: AvatarDrawStyle,
         avatarMetaObservable: Observable<RustPB.Basic_V1_AvatarMeta?>) {
        self.initAvatarType = initAvatarType
        super.init(name: name,
                   defaultCenterIcon: defaultCenterIcon,
                   drawStyle: drawStyle,
                   resolver: resolver,
                   avatarMetaObservable: avatarMetaObservable)
    }
}
