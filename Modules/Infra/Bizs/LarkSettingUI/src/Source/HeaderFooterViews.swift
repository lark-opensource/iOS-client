//
//  BaseSettingViews.swift
//  LarkMine
//
//  Created by panbinghua on 2021/12/16.
//

import Foundation
import UIKit
import RxDataSources
import UniverseDesignColor

public enum HeaderFooterType {
    case normal // 默认是空白的
    case empty
    case title(String)
    case custom((() -> UITableViewHeaderFooterView))
    case prop(HeaderFooterProp)
}

open class HeaderFooterProp {
    public let identifier: String
    public init(identifier: String) {
        self.identifier = identifier
    }
}

open class BaseHeaderFooterView: UITableViewHeaderFooterView {
    open func update(_ info: HeaderFooterProp) { }
}

public final class NormalHeaderView: UITableViewHeaderFooterView {
    let view = UIView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.addSubview(view)
        view.snp.makeConstraints {
            $0.height.equalTo(height).priority(.high)
            $0.edges.equalToSuperview()
        }
    }

    public var height: CGFloat = 8 {
        didSet {
            view.snp.updateConstraints {
                $0.height.equalTo(height)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public final class TitleHeaderView: UITableViewHeaderFooterView {
    public static let headerLeadingSpacing: CGFloat = 4
    private let horizontalSpacing: CGFloat = 16

    private let label: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()

    public override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.leading.equalTo(leadingSpacing)
            make.trailing.equalTo(-horizontalSpacing)
            make.top.equalTo(4).priority(.high)
            make.bottom.equalTo(-4).priority(.high)
        }
    }

    public var text: String = "" {
        didSet {
            label.setFigmaText(text)
        }
    }

    public var leadingSpacing: CGFloat = headerLeadingSpacing {
        didSet {
            label.snp.updateConstraints {
                $0.leading.equalTo(leadingSpacing)
            }
        }
    }

    public var topSpacing: CGFloat = 4 {
        didSet {
            label.snp.updateConstraints {
                $0.top.equalTo(topSpacing).priority(.high)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public final class TitleFooterView: UITableViewHeaderFooterView {
    public static let footerLeadingSpacing: CGFloat = 16
    private let horizontalSpacing: CGFloat = 16

    private let label: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.leading.equalTo(leadingSpacing)
            make.trailing.equalTo(-horizontalSpacing)
            make.top.equalTo(4).priority(.high)
            make.bottom.equalTo(-4).priority(.high)
        }
    }

    public var text: String = "" {
        didSet {
            label.setFigmaText(text)
        }
    }

    public var leadingSpacing: CGFloat = footerLeadingSpacing {
        didSet {
            label.snp.updateConstraints {
                $0.leading.equalTo(leadingSpacing)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
