//
//  EmotionShopViewModel.swift
//  LarkUIKit
//
//  Created by huangjianming on 2019/8/8.
//

import Foundation
import RxSwift
import RxCocoa
import LarkModel
import UIKit
import LarkMessengerInterface
import RustPB
import LarkContainer

let initPageNum: Int32 = 0

public final class EmotionShopViewModel: EmotionShopBaseViewModel {
    public let cellHeight: CGFloat = 116
    public let defaultPageCount: Int32

    public var stickerSets = [RustPB.Im_V1_StickerSet]()
    public var dataDriver: Driver<Bool> {
        return dataObserver.asDriver(onErrorJustReturn: true)
    }

    var curruntPage: Int32 = initPageNum //记录页数
    var hasMore = false //是否有下一页
    public let dataObserver = PublishSubject<Bool>()

    override init(userResolver: UserResolver) {
        self.defaultPageCount = Int32(UIScreen.main.bounds.height / cellHeight * 3)
        super.init(userResolver: userResolver)
        self.setupSubscription()
    }

    private func setupSubscription() {
        self.stickerService?.stickerSetsObserver.subscribe { (_) in
            //如果状态发生变化的时候需要刷新一下
            self.dataObserver.onNext(self.hasMore)
        }.disposed(by: self.disposeBag)
    }

    public func fetchData() {
        self.curruntPage = initPageNum
        guard let setType = RustPB.Im_V1_GetStickerSetsStoreRequest.FilterType(rawValue: 1) else { return }
        self.stickerService?.fetchStickerSets(type: setType,
                                              count: defaultPageCount,
                                              position: self.curruntPage)
            .subscribe(onNext: {[weak self] (result) in
                guard let self = self else { return }
                self.stickerSets = result.stickerSets
                self.curruntPage = result.lastPosition
                self.hasMore = result.hasMore
                self.dataObserver.onNext(self.hasMore)
                }, onError: { [weak self] (error) in
                    guard let self = self else { return }
                    self.dataObserver.onError(error)
            }).disposed(by: self.disposeBag)
    }

    public func loadMoreData() {
        guard self.hasMore == true else {
            return self.dataObserver.onNext(false)
        }
        guard let setType = RustPB.Im_V1_GetStickerSetsStoreRequest.FilterType(rawValue: 1) else { return }
        self.stickerService?.fetchStickerSets(type: setType,
                                              count: defaultPageCount,
                                              position: self.curruntPage)
            .subscribe(onNext: {[weak self] (result) in
                guard let self = self else { return }
                self.stickerSets.append(contentsOf: result.stickerSets)
                self.curruntPage = result.lastPosition
                self.hasMore = result.hasMore
                self.dataObserver.onNext(self.hasMore)
                }, onError: { [weak self] (error) in
                    guard let self = self else { return }
                    self.dataObserver.onError(error)
            }).disposed(by: self.disposeBag)
    }
}
