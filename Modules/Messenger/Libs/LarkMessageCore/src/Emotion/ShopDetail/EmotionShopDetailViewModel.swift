//
//  File.swift
//  LarkMessageCore
//
//  Created by huangjianming on 2019/8/11.
//

import Foundation
import RxCocoa
import RxSwift
import LarkModel
import LarkMessengerInterface
import RustPB
import LarkContainer

public final class EmotionShopDetailViewModel: EmotionShopBaseViewModel {
    public var stickerSet: RustPB.Im_V1_StickerSet?
    var stickerSetID: String
    let observable = PublishSubject<Bool>()

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(stickerSetID: String, stickerSet: RustPB.Im_V1_StickerSet? = nil, userResolver: UserResolver) {
        self.stickerSet = stickerSet
        self.stickerSetID = stickerSetID
        super.init(userResolver: userResolver)
    }

    func fetchData() {
        if self.stickerSet != nil {
            self.observable.onNext(true)
        }

        self.stickerService?.getStickerSet(stickerSetID: self.stickerSetID).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (stickerSet) in
            guard let self = self else {
                return
            }
            self.stickerSet = stickerSet
            self.observable.onNext(true)
        }, onError: { (_) in
            self.observable.onNext(false)
        }).disposed(by: self.disposeBag)
    }

    func dataDriver() -> Driver<Bool> {
        return self.observable.asDriver(onErrorJustReturn: false)
    }
}
