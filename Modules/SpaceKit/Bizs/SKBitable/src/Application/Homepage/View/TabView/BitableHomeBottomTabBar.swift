//
//  BitableHomeBottomBar.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/10/29.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor

protocol BitableHomeBottomTabBarDelegate: AnyObject {
    func tabBar(_ tabbar: BitableHomeBottomTabBar, didSelect scene: BitableHomeScene)
}

final class BitableHomeBottomTabBar: UIView {
    private static let iconConfig: [BitableHomeScene] = [.homepage, .recommend, .new]

    weak var delegate: BitableHomeBottomTabBarDelegate?

    private lazy var line: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    private lazy var contentStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.alignment = .fill
        view.distribution = .fillEqually
        view.spacing = 0
        return view
    }()

    init() {
        super.init(frame: .zero)
        setupSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        for scene in Self.iconConfig {
            let itemView = BitableHomeBottomTabBarItemView(scene: scene) { [weak self] scene in
                guard let self = self else { return }
                self.delegate?.tabBar(self, didSelect: scene)
            }
            contentStackView.addArrangedSubview(itemView)
        }

        addSubview(contentStackView)
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addSubview(line)
        line.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    func update(selectScene: BitableHomeScene, animated: Bool) {
        let views = contentStackView.arrangedSubviews
        for view in views {
            guard let realView = view as? BitableHomeBottomTabBarItemView else {
                continue
            }
            realView.updateSelect(isSelect: realView.scene == selectScene, animated: animated)
        }
    }
}
