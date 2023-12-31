//
//  LocationContentViewModel.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/6/23.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import LarkMessengerInterface
import EENavigator
import RxRelay
import RxSwift
import RustPB

public final class LocationContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: LocationContentContext>: MessageSubViewModel<M, D, C> {
    public override var identifier: String {
        return "location"
    }

    var content: LocationContent {
        return (self.message.content as? LocationContent) ?? .transform(pb: RustPB.Basic_V1_Message())
    }

    /// 地理位置名称
    public var name: String {
        return self.content.location.name.isEmpty ? BundleI18n.LarkMessageCore.Lark_Chat_MessageReplyStatusLocation("") : self.content.location.name
    }
    /// 地理位置描述
    public var description: String {
        return self.content.location.description_p
    }
    /// 预览图片的原始大小
    public var originSize: CGSize {
        return content.image.intactSize
    }

    public var setting: ChatLocationViewStyleSetting {
        var setting = ChatLocationConsts.setting
        setting.imageViewSize.width = min(setting.imageViewSize.width, contentPreferMaxWidth)
        return setting
    }

    /// 气泡最大宽度
    public var contentPreferMaxWidth: CGFloat {
        var preferMaxWidth = metaModelDependency.getContentPreferMaxWidth(message)
        // 对于话题模式，需要把宽度加回contentPadding
        if (context.scene == .newChat || context.scene == .mergeForwardDetail), message.showInThreadModeStyle {
            preferMaxWidth += metaModelDependency.contentPadding * 2
        }
        return min(ChatLocationConsts.contentMaxWidth, preferMaxWidth)
    }

    public override var contentConfig: ContentConfig? {
        var contentConfig = ContentConfig(
            hasMargin: false,
            backgroundStyle: .white,
            maskToBounds: true,
            supportMutiSelect: true,
            contentMaxWidth: setting.imageViewSize.width,
            hasPaddingBottom: false,
            hasBorder: true
        )
        contentConfig.isCard = true
        return contentConfig
    }

    func viewDidTapped() {
        guard message.localStatus == .success else {
            return
        }
        let body = LocationNavigateBody(
            messageID: message.id,
            // code_next_line tag CryptChat
            source: .common,
            psdaToken: "LARK-PSDA-ChatLocationDetail-requestLocationAuthorization",
            isCrypto: metaModel.getChat().isCrypto
        )
        self.context.navigator(type: .push, body: body, params: nil)
    }
}
