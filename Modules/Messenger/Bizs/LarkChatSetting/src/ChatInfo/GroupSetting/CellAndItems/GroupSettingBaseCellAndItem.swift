//
//  GroupSettingBaseCellAndItem.swift
//  Lark
//
//  Created by K3 on 2018/8/9.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import RxSwift
import LarkUIKit
import Foundation

typealias GroupSettingItemProtocol = CommonCellItemProtocol

class GroupSettingCell: BaseSettingCell, CommonCellProtocol {
    var item: CommonCellItemProtocol? {
        didSet {
            setCellInfo()
        }
    }

    private var tapIdentify: String?
    var canHandleEvent: Bool {
        self.tapIdentify == item?.tapIdentify
    }
    private let disposeBag = DisposeBag()

    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        contentView.addSubview(label)
        return label
    }()

    private(set) lazy var detailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        contentView.addSubview(label)
        return label
    }()

    private(set) lazy var switchButton: LoadingSwitch = {
        let switchButton = LoadingSwitch(behaviourType: .normal)
        switchButton.isHidden = true
        switchButton.onTintColor = UIColor.ud.primaryContentDefault
        switchButton
            .rx.isOn
            .asDriver()
            .debounce(.milliseconds(300))
            .drive(onNext: { [weak self] (isOn) in
                if let self = self, self.canHandleEvent {
                    self.switchButtonStatusChange(to: isOn)
                }
            }).disposed(by: disposeBag)
        contentView.addSubview(switchButton)
        return switchButton
    }()

    private(set) lazy var arrow: UIImageView = {
        let imageView = UIImageView(image: Resources.right_arrow)
        imageView.isHidden = true
        contentView.addSubview(imageView)
        return imageView
    }()

    private lazy var separator: UIView = {
        let separater = UIView()
        separater.backgroundColor = UIColor.ud.lineDividerDefault
        separater.isHidden = true
        contentView.addSubview(separater)
        return separater
    }()

    fileprivate var separatorStyle: SeparaterStyle = .none

    func defaultLayoutSwitchButton() {
        switchButton.isHidden = false
        switchButton.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.right.equalToSuperview().offset(-12)
        }
    }

    func defaultLayoutArrow() {
        arrow.isHidden = false
        arrow.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.right.equalToSuperview().offset(-16)
            maker.size.equalTo(CGSize(width: 12, height: 12))
        }
    }

    func layoutSeparater(_ style: SeparaterStyle) {
        guard style != separatorStyle else {
            return
        }
        if style == .none {
            separator.isHidden = true
        } else {
            separator.isHidden = false
            separator.snp.remakeConstraints { (maker) in
                maker.bottom.right.equalToSuperview()
                maker.height.equalTo(0.5)
                maker.left.equalToSuperview().offset(style == .half ? 16 : 0)
            }
        }
    }

    func switchButtonStatusChange(to status: Bool) {}

    func setCellInfo() {
        assert(false, "没有实现对应的填充方法")
    }

    func updateAvailableMaxWidth(_ width: CGFloat) {

    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view != nil {
            self.tapIdentify = self.item?.tapIdentify
        }
        return view
    }
}

final class GroupSettingSectionView: UITableViewHeaderFooterView {
    var touchesBeganCallBack: (() -> Void)?
    static let titleFont = UIFont.systemFont(ofSize: 14)
    static let titleTopMarigin: CGFloat = 14
    static let titleBottomMarigin: CGFloat = 14
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = Self.titleFont
        label.isHidden = true
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.ud.bgFloatBase
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
                .inset(UIEdgeInsets(top: Self.titleTopMarigin, left: 4, bottom: Self.titleBottomMarigin, right: 16))
            maker.height.equalTo(20)
        }
    }

    func setTitleHorizontalMargin(_ value: CGFloat) {
        titleLabel.snp.remakeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
                .inset(UIEdgeInsets(top: Self.titleTopMarigin, left: value, bottom: Self.titleBottomMarigin, right: value))
        }
    }

    func setTitleTopMargin(_ value: CGFloat) {
        titleLabel.snp.remakeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
                .inset(UIEdgeInsets(top: value, left: 4, bottom: Self.titleBottomMarigin, right: 16))
            maker.height.equalTo(20)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchesBeganCallBack?()
    }
}

//文本中包含可点击内容时，使用这个SectionView来处理
final class GroupSettingClickableSectionView: UITableViewHeaderFooterView {
    lazy var titleTextView: UITextView = {
        let view = UITextView()
        view.font = UIFont.systemFont(ofSize: 14)
        view.isHidden = true
        view.textColor = UIColor.ud.textPlaceholder
        view.typingAttributes = [.foregroundColor: UIColor.ud.textPlaceholder,
                                   .font: UIFont.systemFont(ofSize: 14)]
        view.isEditable = false
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.isScrollEnabled = false
        return view
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.ud.bgFloatBase
        contentView.addSubview(titleTextView)
        titleTextView.setContentHuggingPriority(.required, for: .vertical)
        titleTextView.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
                .inset(UIEdgeInsets(top: 14, left: 4, bottom: 2, right: 16))
            maker.bottom.equalToSuperview()
        }
    }

    func setTitleTopMargin(_ value: CGFloat) {
        titleTextView.snp.remakeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
                .inset(UIEdgeInsets(top: value, left: 4, bottom: 2, right: 16))
            maker.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class GroupSettingSectionEmptyView: UITableViewHeaderFooterView {
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.ud.bgFloatBase
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
