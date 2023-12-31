//
//  EmotionShopBsaeViewModel.swift
//  LarkMessageCore
//
//  Created by huangjianming on 2019/8/21.
//

import Foundation
import RxSwift
import LarkModel
import RxCocoa
import LarkMessengerInterface
import LarkContainer
import RustPB

public class EmotionShopBaseViewModel: UserResolverWrapper {
    public let userResolver: UserResolver
    @ScopedInjectedLazy var stickerService: StickerService?

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    let disposeBag = DisposeBag()

    var progressDict = [String: BehaviorSubject<Progress>]()

    func addEmotionPackage(stickerSet: RustPB.Im_V1_StickerSet) {
        self.stickerService?.addEmotionPackage(for: stickerSet)
    }

    func getDownloadState(stickerSet: RustPB.Im_V1_StickerSet) -> Observable<EmotionStickerSetState> {
        return self.stickerService?.getDownloadState(for: stickerSet) ?? .empty()
    }
}
