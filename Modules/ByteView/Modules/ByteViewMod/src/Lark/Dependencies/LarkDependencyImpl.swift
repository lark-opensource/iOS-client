//
//  LarkDependencyImpl.swift
//  ByteViewMod
//
//  Created by kiri on 2023/6/27.
//

import Foundation
import ByteView
import ByteViewCommon
import LarkContainer
import Heimdallr
import ByteWebImage
import LKCommonsTracker
import LarkGuide
import RxSwift
import LarkWaterMark

final class LarkDependencyImpl: LarkDependency {
    private let userResolver: UserResolver
    private let disposeBag = DisposeBag()

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    lazy var window: ByteView.WindowDependency = LarkWindowDependency(userResolver: userResolver)
    lazy var emotion: ByteView.EmotionDependency = EmotionDependencyImpl()
    lazy var emojiData: ByteView.EmojiDataDependency = EmojiDataDependencyImpl()
    lazy var security: ByteView.SecurityStateDependency = SecurityStateDependencyImpl(userResolver: userResolver)

    private var guideService: NewGuideService? {
        do {
            return try userResolver.resolve(assert: NewGuideService.self)
        } catch {
            Logger.dependency.error("resolve NewGuideService failed, \(error)")
            return nil
        }
    }

    func shouldShowGuide(key: String) -> Bool {
        guideService?.checkShouldShowGuide(key: key) ?? false
    }

    func didShowGuide(key: String) {
        guideService?.didShowedGuide(guideKey: key)
    }

    private var watermarkService: WaterMarkService? {
        do {
            return try userResolver.resolve(assert: WaterMarkService.self)
        } catch {
            Logger.dependency.error("resolve WaterMarkService failed, \(error)")
            return nil
        }
    }

    func getWatermarkView(completion: @escaping ((UIView) -> Void)) {
        watermarkService?.darkModeWaterMarkView.take(1).subscribe(onNext: { view in
            if Thread.isMainThread {
                completion(view)
            } else {
                DispatchQueue.main.async {
                    completion(view)
                }
            }
        }).disposed(by: disposeBag)
    }

    func getVCShareZoneWatermarkView() -> Observable<UIView?> {
        guard let service = watermarkService else {
            return .just(nil)
        }
        return service.getVCShareZoneWatermarkView()
    }
}
