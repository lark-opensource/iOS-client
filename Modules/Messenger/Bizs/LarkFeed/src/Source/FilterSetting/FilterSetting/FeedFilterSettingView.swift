//
//  FeedFilterSettingView.swift
//  LarkFeed
//
//  Created by liuxianyu on 2021/8/23.
//

import UIKit
import Foundation
import LarkUIKit

/// switch点击事件
typealias FeedFilterSettingSwitchHandler = (_ switchControl: LoadingSwitch, _ status: Bool) -> Void

/// 所有赋值给cell的model必须满足这个协议
protocol FeedFilterSettingItemProtocol {
    /// 重用标识符
    var cellIdentifier: String { get }
}

/// 所有的cell必须满足这个协议
class FeedFilterSettingBaseCell: BaseTableViewCell {

    var item: FeedFilterSettingItemProtocol? {
        didSet {
            setCellInfo()
        }
    }

    func setCellInfo() {
        assert(false, "没有实现对应的填充方法")
    }
}

struct FeedFilterSettingSwitchModel: FeedFilterSettingItemProtocol {
    var cellIdentifier: String
    var title: String
    var status: Bool
    var switchEnable: Bool
    var switchHandler: FeedFilterSettingSwitchHandler?
}

final class FeedFilterSettingSwitchCell: FeedFilterSettingBaseCell {
    /// 中间标题
    private var titleLabel: UILabel = .init()
    /// 开关
    private var loadingSwitch: LoadingSwitch = .init()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.contentView.backgroundColor = UIColor.ud.bgFloat

        /// 开关
        self.loadingSwitch = LoadingSwitch(behaviourType: .normal)
        self.loadingSwitch.onTintColor = UIColor.ud.primaryContentDefault
        self.loadingSwitch.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.contentView.addSubview(self.loadingSwitch)
        self.loadingSwitch.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
        }
        self.loadingSwitch.valueChanged = { [weak self] (isOn) in
            if let strongSelf = self {
                guard let currItem = strongSelf.item as? FeedFilterSettingSwitchModel else {
                    assert(false, "\(strongSelf):item.Type error")
                    return
                }
                currItem.switchHandler?(strongSelf.loadingSwitch, isOn)
            }
        }

        /// 中间标题
        self.titleLabel = UILabel()
        self.titleLabel.textColor = UIColor.ud.textTitle
        self.titleLabel.numberOfLines = 0
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.right.lessThanOrEqualTo(self.loadingSwitch.snp.left).offset(-16)
            make.left.equalTo(16)
            make.top.equalTo(16)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let currItem = self.item as? FeedFilterSettingSwitchModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        self.titleLabel.text = currItem.title
        self.loadingSwitch.setOn(currItem.status, animated: false)
        self.loadingSwitch.isEnabled = currItem.switchEnable
    }
}

struct FeedFilterSettingFeedFilterModel: FeedFilterSettingItemProtocol {
    var cellIdentifier: String
    var title: String
    var tapHandler: () -> Void
}

final class FeedFilterSettingFeedFilterCell: FeedFilterSettingBaseCell {
    /// 中间标题
    private lazy var titleLabel: UILabel = UILabel()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = UIColor.ud.bgFloat
        /// 中间标题
        self.titleLabel.textColor = UIColor.ud.textTitle
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.titleLabel.numberOfLines = 0
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.right.equalTo(-16)
            make.left.equalTo(16)
            make.top.equalTo(15)
            make.centerY.equalToSuperview()
        }

        /// 箭头
        let arrowImageView = UIImageView()
        arrowImageView.image = Resources.feed_right_arrow
        self.contentView.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let currItem = self.item as? FeedFilterSettingFeedFilterModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        self.titleLabel.text = currItem.title
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let setting = self.item as? FeedFilterSettingFeedFilterModel {
            setting.tapHandler()
        }
        super.setSelected(selected, animated: animated)
    }
}
