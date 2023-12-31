//
//  SendSingleEmotionConfig.swift
//  LarkForward
//
//  Created by ByteDance on 2023/5/24.
//

//
//  SendSingleEmotionConfig.swift
//  LarkForward
//
//  Created by huangjianming on 2019/9/3.
//

import LarkModel
import ByteWebImage
import LarkMessengerInterface

final class SendSingleEmotionConfig: ForwardAlertConfig {
    // MARK: - override
    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? SendSingleEmotionContent != nil {
            return true
        }
        return false
    }

    override func getContentView() -> UIView? {
        guard let content = content as? SendSingleEmotionContent else { return nil }

        let container = UIView()
        let imageView = ByteImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.bt.setLarkImage(with: .sticker(key: content.sticker.image.origin.key,
                                                 stickerSetID: content.sticker.stickerSetID),
                                  trackStart: {
                                    TrackInfo(scene: .Chat, isOrigin: true, fromType: .sticker)
                                  })
        container.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.width.equalTo(100)
        }
        return container
    }
}
