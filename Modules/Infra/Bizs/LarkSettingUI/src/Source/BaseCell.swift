//
//  BaseCell.swift
//  LarkMine
//
//  Created by panbinghua on 2021/12/1.
//

import Foundation
import UIKit
import RxSwift

fileprivate let normalBackgroundColor = UIColor.ud.bgFloat
fileprivate let selectedBackgroundColor = UIColor.ud.fillHover
fileprivate let highlightColor = UIColor.ud.Y50

open class CellProp {
    public var cellIdentifier: String
    public var separatorLineStyle: CellSeparatorLineStyle
    public var selectionStyle: CellSelectionStyle
    public var isHighlight: Bool
    public var id: String?

    public init(cellIdentifier: String = "",
         separatorLineStyle: CellSeparatorLineStyle = .normal,
         selectionStyle: CellSelectionStyle = .none,
         isHighlight: Bool = false,
         id: String? = nil) {
        self.cellIdentifier = cellIdentifier
        self.selectionStyle = selectionStyle
        self.separatorLineStyle = separatorLineStyle
        self.isHighlight = isHighlight
        self.id = id
    }
}

public enum CellSelectionStyle {
    case normal
    case none
}

public enum CellSeparatorLineStyle {
    case normal // 左边间隔16
    case full
    case none
}

public typealias ClickHandler = (_ view: UITableViewCell) -> Void

public protocol CellClickable {
    var onClick: ClickHandler? { get }
}

open class BaseCell: UITableViewCell {

    private(set) var disposeBag = DisposeBag()
    public private(set) var prop: CellProp?

    private(set) var separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    public func hideSeparatorLine(_ isHidden: Bool) {
        if let style = prop?.separatorLineStyle, .none != style {
            separatorLine.isHidden = isHidden
        }
    }

    open func update(_ info: CellProp) {
        selectionStyle = info.selectionStyle == .none ? .none : .default
        backgroundView?.backgroundColor = info.isHighlight ? highlightColor : normalBackgroundColor
        // 分割线
        let separatorLineStyle = info.separatorLineStyle
        separatorLine.isHidden = separatorLineStyle == .none
        if separatorLineStyle != .none {
            if let prop = prop, prop.separatorLineStyle != info.separatorLineStyle {
                separatorLine.snp.updateConstraints {
                    $0.leading.equalTo(separatorLineStyle == .full ? 0 : 16)
                }
            }
        }
        prop = info
    }

    /// 子类覆写这个方法时，一定要记得重新创建disposeBag
    public override func prepareForReuse() {
        disposeBag = DisposeBag()
        prop = nil
        super.prepareForReuse()
    }

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        // 按压态
        backgroundView = UIView()
        backgroundView?.backgroundColor = normalBackgroundColor
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = selectedBackgroundColor
        // 分割线
        contentView.addSubview(separatorLine)
        separatorLine.snp.makeConstraints {
            $0.height.equalTo(1.0 / UIScreen.main.scale)
            $0.bottom.trailing.equalToSuperview()
            $0.leading.equalTo(16)
        }
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
