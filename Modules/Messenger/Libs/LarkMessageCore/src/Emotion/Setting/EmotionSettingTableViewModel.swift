//
//  EmotionSettingTableViewModel.swift
//  Pods
//
//  Created by huangjianming on 2019/8/8.
//

import Foundation
import RxSwift
import RxCocoa
import LarkModel
import LarkMessengerInterface
import RustPB
import LarkContainer

public final class EmotionSettingTableViewModel: EmotionShopBaseViewModel {
    public let dataDriver: Driver<Void>
    public var stickerSets = [RustPB.Im_V1_StickerSet]()

    let observable = BehaviorSubject(value: ())

    override init(userResolver: UserResolver) {
        self.dataDriver = observable.asDriver(onErrorJustReturn: ())
        super.init(userResolver: userResolver)
        self.setup()
    }

    func setup() {
        self.stickerService?.stickerSetsObserver
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (sets) in
                guard let `self` = self else {
                    return
                }

                self.stickerSets = sets
                self.observable.onNext(())
            }).disposed(by: self.disposeBag)
    }

    func delete(idx: Int) -> Observable<Void> {
        guard self.stickerSets.count > idx else {
            return Observable.empty()
        }

        let stickerSetID = self.stickerSets[idx].stickerSetID
        StickerTracker.tranckStickerDelet(stickerSetID: stickerSetID, stickerPackCount: stickerSets.count, stickersCount: self.stickerSets[idx].stickers.count)
        return self.stickerService?.deleteStickerSet(stickerSetID: stickerSetID) ?? .empty()
    }

    func move(from: Int, to: Int) {
        guard self.stickerSets.count > from, self.stickerSets.count > to else { return }
        let stickerSetToMove = self.stickerSets[from]
        self.stickerSets.remove(at: from)
        self.stickerSets.insert(stickerSetToMove, at: to)
    }

    func patch() -> Observable<Void> {
        var ids = [String]()
        for set in self.stickerSets {
            ids.append(set.stickerSetID)
        }
        guard !ids.isEmpty else {
            return Observable.just(())
        }

        return self.stickerService?.patchStickerSets(ids: ids) ?? .empty()
    }
}
