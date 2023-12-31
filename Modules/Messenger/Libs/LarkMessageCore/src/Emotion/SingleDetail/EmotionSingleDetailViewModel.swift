//
//  EmotionSingleDetailViewModel.swift
//  LarkUIKit
//
//  Created by huangjianming on 2019/8/8.
//

import Foundation
import LarkModel
import RxCocoa
import RxSwift
import LarkMessengerInterface
import RustPB
import LarkContainer

public final class EmotionSingleDetailViewModel: EmotionShopBaseViewModel {
    public var stickerSet: RustPB.Im_V1_StickerSet?
    public let dataDriver: Driver<Bool>
    public let sticker: RustPB.Im_V1_Sticker
    public let message: Message

    var stickerSetID: String

    var dataSubject = PublishSubject<Bool>()

    init(stickerSet: RustPB.Im_V1_StickerSet?, stickerSetID: String,
         sticker: RustPB.Im_V1_Sticker, message: Message,
         userResolver: UserResolver) {
        self.stickerSet = stickerSet
        self.stickerSetID = stickerSetID
        self.sticker = sticker
        self.message = message
        self.dataDriver = self.dataSubject.asDriver(onErrorJustReturn: false)
        super.init(userResolver: userResolver)
    }

    func fetchData() {
        if self.stickerSet != nil {
            self.dataSubject.onNext(true)
            return
        }

        self.stickerService?.getStickerSet(stickerSetID: stickerSetID).subscribe(onNext: { [weak self] (stickerSet) in
            guard let self = self else {
                return
            }
            self.stickerSet = stickerSet
            self.dataSubject.onNext(true)
        }, onError: { (_) in
            self.dataSubject.onNext(false)
        }).disposed(by: self.disposeBag)
    }
}
