//
//  FeedBottomBarOpenAbility.swift
//  LarkOpenFeed
//
//  Created by liuxianyu on 2022/9/26.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkContainer

/// 注入类型（展示优先级依赖此数值）
public enum FeedBottomBarItemType: String, CaseIterable {
    case onBoarding
}

public enum FeedBottomBarItemCommand {
    case render(item: FeedBottomBarItem)
}

public protocol FeedBottomBarItem {
    var display: Bool { get }
    var authKey: String { get }
}

public typealias FeedBottomBarItemBuilder = (_ context: UserResolver,
                                             _ authKey: String,
                                             _ relay: PublishRelay<FeedBottomBarItemCommand>) throws -> FeedBottomBarItem?
public typealias FeedBottomBarItemViewBuilder = (_ context: UserResolver, _ item: FeedBottomBarItem) -> UIView?

public final class FeedBottomBarFactory {
    private static var itemBuilders: [String: FeedBottomBarItemBuilder] = [:]
    private static var viewBuilders: [String: FeedBottomBarItemViewBuilder] = [:]
    public private(set) static var typeMap: [String: FeedBottomBarItemType] = [:]

    // 注册 item & view 构造器
    public static func register(type: FeedBottomBarItemType,
                                itemBuilder: @escaping FeedBottomBarItemBuilder,
                                viewBuilder: @escaping FeedBottomBarItemViewBuilder) {
        if typeMap.values.contains(type) { return }
        let authKey = UUID().uuidString
        FeedBottomBarFactory.typeMap[authKey] = type
        FeedBottomBarFactory.itemBuilders[authKey] = itemBuilder
        FeedBottomBarFactory.viewBuilders[authKey] = viewBuilder
    }

    // 构造 itemProvider
    public static func item(context: UserResolver,
                            authKey: String,
                            relay: PublishRelay<FeedBottomBarItemCommand>) -> FeedBottomBarItem? {
        try? FeedBottomBarFactory.itemBuilders[authKey]?(context, authKey, relay)
    }

    // 构造 view
    public static func view(context: UserResolver,
                            for item: FeedBottomBarItem) -> UIView? {
        FeedBottomBarFactory.viewBuilders[item.authKey]?(context, item)
    }
}

/** Demo
public func regist(container: Container) {
    FeedBottomBarFactory.register(
        type: .onBoarding,
        itemBuilder: { context, authKey, publishRelay -> FeedBottomBarItem in
            guard let resolver = context as? UserResolver else {
                throw ContainerError.noResolver
            }
            let item = OnBoadingItem(authKey: authKey, publishRelay: publishRelay)
            return item
        }, viewBuilder: { item -> UIView? in
            guard let item = item as? OnBoadingItem else { return nil }
            let view = OnBoadingView(frame: .zero, item: item)
            return view
        })
}

class OnBoadingItem: FeedBottomBarItem {
    var _display: Bool = false
    var display: Bool {
        _display
    }
    let authKey: String
    private let displayRelay: PublishRelay<FeedBottomBarItemCommand>

    func show() {
        _display = true
        displayRelay.accept(.display(authKey))
    }

    func hide() {
        _display = false
        displayRelay.accept(.disappear(authKey))
    }

    init(authKey: String, publishRelay: PublishRelay<FeedBottomBarItemCommand>) {
        self.authKey = authKey
        self.displayRelay = publishRelay
    }
}

class OnBoadingView: UIView {
    let item: OnBoadingItem
    init(frame: CGRect, item: OnBoadingItem) {
        self.item = item
        super.init(frame: frame)
        setupViews()
    }

    func setupViews() {
        let view = UIView()
        view.backgroundColor = UIColor.ud.blue
        addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(100)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
*/
