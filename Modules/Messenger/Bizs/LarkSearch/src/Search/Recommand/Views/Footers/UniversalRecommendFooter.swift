//
//  UniversalRecommendFooter.swift
//  LarkSearch
//
//  Created by Patrick on 2021/8/25.
//

import UIKit
import Foundation

protocol UniversalRecommendFooterProtocol: UITableViewHeaderFooterView {}

final class UniversalRecommendFooter: UIView {
    static let height: CGFloat = 10
    private lazy var container: UIView = {
        let view = UIView()
        view.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 8.0)
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = .ud.bgBase
        addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

final class UniversalRecommendCardFooter: UITableViewHeaderFooterView, UniversalRecommendFooterProtocol {
    private lazy var container: UIView = {
        let view = UIView()
        view.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 8.0)
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        contentView.backgroundColor = .ud.bgBase
        addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

final class UniversalRecommendChipFooter: UITableViewHeaderFooterView, UniversalRecommendFooterProtocol {

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        contentView.backgroundColor = .ud.bgBase
    }
}
