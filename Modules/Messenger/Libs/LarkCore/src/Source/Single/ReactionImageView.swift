//
//  ReactionImageView.swift
//  LarkCore
//
//  Created by 李晨 on 2019/1/20.
//

import Foundation
import LarkEmotion
import LarkContainer
import ByteWebImage
import UIKit
import RxSwift
import LKCommonsLogging

public final class ReactionImageView: UIImageView {

    private static let logger = Logger.log(ReactionImageView.self, category: "Module.LarkCore.ReactionImageView")

    let disposeBag = DisposeBag()

    var reactionType: String?

    public convenience init() {
        self.init(frame: .zero)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.contentMode = .scaleAspectFit
        // 注意：企业自定义表情管理员随时会在后台配置，每次需要渲染的时候才会去下载图片，因此需要监听下载成功事件并及时刷新
        self.handleImageDownloadSucceed()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func set(height: CGFloat,
                    type: String,
                    placeholder: UIImage? = nil) {
        // 你不能保证业务传过来的height都是合法值，所以必须兜底
        var defaultHeight: CGFloat = height > 0 ? height : 18
        let start = CACurrentMediaTime()
        reactionType = type
        if let icon = EmotionResouce.shared.imageBy(key: type) {
            self.image = icon
            CoreTracker.trackerEmojiLoadDuration(duration: CACurrentMediaTime() - start, emojiKey: type, isLocalImage: true)
            return
        }
        // 走到这边的话表示该reaction没有本地缓存图片，需要从服务端下载
        Self.logger.error("reaction image view: has no cached image reactionType = \(type)")
        // 用imageKey发起请求，如果imageKey为空的话就传空字符串（其他企业的自定义表情会出现为空的情况）
        var isEmojis: Bool = false; var key: String = ""
        if let imageKey = EmotionResouce.shared.imageKeyBy(key: type) {
            isEmojis = true; key = imageKey
        }
        if key.isEmpty {
            isEmojis = true
            Self.logger.error("reaction image view: imageKey is empty reactionType = \(type)")
        }
        let resource = LarkImageResource.reaction(key: key, isEmojis: isEmojis)
        self.contentMode = .topLeft
        self.layer.masksToBounds = true
        self.layer.cornerRadius = defaultHeight / 2
        self.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.06)
        var scale: CGFloat = 1.0
        if let placeHolderImage = placeholder, placeHolderImage.size.height > 0 {
            scale = defaultHeight / placeHolderImage.size.height
        }
        let scaledPlaceholder = placeholder?.ud.scaled(by: scale) ?? placeholder
        self.bt.setLarkImage(with: resource,
                             placeholder: scaledPlaceholder,
                             trackStart: {
                                 TrackInfo(biz: .Messenger, scene: .Chat, fromType: .reaction)
                             },
                             completion: { [weak self] result in
            var isCache = false
            switch result {
            case .success(let imageResult):
                if let reactionIcon = imageResult.image {
                    self?.contentMode = .scaleAspectFit
                    self?.image = reactionIcon
                    self?.layer.cornerRadius = 0
                    self?.layer.masksToBounds = false
                    self?.backgroundColor = UIColor.clear
                }
                isCache = imageResult.from == .diskCache || imageResult.from == .memoryCache
            case .failure:
                Self.logger.error("reaction image view: setLarkImage failed reactionType = \(type)")
                break
            }
            CoreTracker.trackerEmojiLoadDuration(duration: CACurrentMediaTime() - start, emojiKey: type, isLocalImage: isCache)
        })
    }

    // 表情图片下载成功后要刷新下数据源
    private func handleImageDownloadSucceed() {
        NotificationCenter
            .default
            .rx
            .notification(.LKEmojiImageDownloadSucceedNotification)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (notification) in
                guard let `self` = self else { return }
                guard let info = notification.object as? [String: Any] else { return }
                if let key = info["key"] as? String, key == self.reactionType, let resource = EmotionResouce.shared.resourceBy(key: key), let image = resource.image {
                    self.contentMode = .scaleAspectFit
                    self.image = image
                    self.layer.cornerRadius = 0
                    self.layer.masksToBounds = false
                    self.backgroundColor = UIColor.clear
                }
            })
            .disposed(by: disposeBag)
    }
}
