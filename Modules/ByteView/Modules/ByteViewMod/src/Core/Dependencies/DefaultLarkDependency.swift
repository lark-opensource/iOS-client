//
//  DefaultLarkDependency.swift
//  ByteViewMod
//
//  Created by kiri on 2023/6/27.
//

import Foundation
import ByteView
import ByteViewCommon
import RxSwift
import LarkContainer
import LarkStorage

final class DefaultLarkDependency: LarkDependency {
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    private lazy var storage = KVStores.udkv(space: .user(id: userResolver.userID), domain: Domain.biz.byteView.child("Demo"), mode: .normal)

    lazy var window: ByteView.WindowDependency = LarkWindowDependency(userResolver: userResolver)
    lazy var emotion: ByteView.EmotionDependency = EmotionDependencyImpl()
    lazy var emojiData: ByteView.EmojiDataDependency = EmojiDataDependencyImpl()
    lazy var security: ByteView.SecurityStateDependency = DefaultSecurityStateDependency()

    func shouldShowGuide(key: String) -> Bool {
        !storage.bool(forKey: "demo_guide_shown_\(key)")
    }

    func didShowGuide(key: String) {
        storage.set(true, forKey: "demo_guide_shown_\(key)")
    }

    func getWatermarkView(completion: @escaping ((UIView) -> Void)) {
        if Thread.isMainThread {
            completion(createWatermarkView())
        } else {
            DispatchQueue.main.async {
                completion(self.createWatermarkView())
            }
        }
    }

    private func createWatermarkView() -> UIView {
        let v = UIView()
        v.isUserInteractionEnabled = false
        v.backgroundColor = .clear
        return v
    }

    func getVCShareZoneWatermarkView() -> Observable<UIView?> {
        return .just(nil)
    }
}
