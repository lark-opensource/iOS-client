//
//  DriveSubTitleView.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/4/15.
//

import UIKit
import SnapKit
import SKCommon
import SKUIKit
import SKFoundation
import UniverseDesignColor
import UniverseDesignIcon

/// 主页导航栏TitleView
class DriveSubTitleView: UIView {
    weak var navigationBar: SKNavigationBar?
    // 标志是否有展示密级状态
    private var hasSensitivity: Bool = false
    struct Const {
        static let pointWidth: CGFloat = 2
        static let pointLeftOffset: CGFloat = 3
        static let pointRightOffset: CGFloat = 4
        static let sensitivityImageWidth: CGFloat = 14
        static let sensitivityImageRightOffset: CGFloat = 2
        static let titleBottomOffset: CGFloat = 1
    }

    // MARK: - Lazy initialize

    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        configTextLabel(label, color: UDColor.textTitle, fontSize: 16)
        addSubview(label)
        return label
    }()

    private(set) lazy var subTitleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        configTextLabel(label, color: UDColor.textCaption, fontSize: 11, weight: .regular)
        addSubview(label)
        return label
    }()
    
    private(set) lazy var pointView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 1
        view.layer.masksToBounds = true
        view.backgroundColor = UDColor.textCaption
        view.isHidden = true
        addSubview(view)
        return view
    }()
    
    private(set) lazy var sensitivityLabel: SensitivityLabel = {
        let label = SensitivityLabel(frame: .zero)
        label.backgroundColor = .clear
        label.isHidden = true
        addSubview(label)
        return label
    }()

    // MARK: - Initialize

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override var intrinsicContentSize: CGSize {
        return  UIView.layoutFittingExpandedSize
    }
}

// MARK: - Public interface
extension DriveSubTitleView {

    func setTitle(_ title: String, subTitle: String) {
        titleLabel.text = title
        subTitleLabel.text = subTitle
    }

    func addTo(_ parentView: UIView) {
        guard let bar = parentView as? SKNavigationBar else {
            DocsLogger.driveInfo("missing the SKNavigationBar")
            return
        }
        self.navigationBar = bar
        bar.titleView.addSubview(self)
        self.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        bar.layoutAttributes.titleVerticalAlignment = .fill
    }
    
    func setSensitivityTitile(_ title: String, sensitivityTitle: String) {
        titleLabel.text = title
        sensitivityLabel.setTitle(title: sensitivityTitle)
    }
    
    // 设置密集管控布局
    func setSensitivityLabel(haveSubview: Bool) {
        self.hasSensitivity = true
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(5)
            make.left.right.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
            make.height.equalTo(18)
        }
        if haveSubview {
            subTitleLabel.snp.makeConstraints { (make) in
                make.top.equalTo(titleLabel.snp.bottom).offset(1)
                make.left.equalToSuperview()
                make.right.lessThanOrEqualToSuperview()
                make.bottom.equalToSuperview()
                make.width.lessThanOrEqualToSuperview()
            }
            pointView.snp.makeConstraints { (make) in
                make.centerY.equalTo(subTitleLabel.snp.centerY)
                make.left.equalTo(subTitleLabel.snp.right).offset(3)
                make.height.width.equalTo(2)
            }
            sensitivityLabel.snp.makeConstraints { (make) in
                make.centerY.equalTo(subTitleLabel.snp.centerY)
                make.left.equalTo(pointView.snp.right).offset(4)
                make.height.equalTo(subTitleLabel)
                make.width.lessThanOrEqualToSuperview()
            }
            pointView.isHidden = false
        } else {
            sensitivityLabel.snp.makeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(1)
                make.left.equalTo(titleLabel)
                make.right.lessThanOrEqualToSuperview()
                make.bottom.equalToSuperview()
                make.width.lessThanOrEqualToSuperview()
            }
        }
        sensitivityLabel.isHidden = false
    }
    
    func actualSizeThatFits(_ maxAvailableSize: CGSize) -> CGSize {
        // 计算第一行的宽度
        let topWidth = titleLabel.intrinsicContentSize.width
        // 计算第二行的宽度
        var bottomWidth = subTitleLabel.intrinsicContentSize.width
        var bottomTitleHeight = subTitleLabel.intrinsicContentSize.width
        if hasSensitivity {
            bottomWidth += Const.pointLeftOffset + Const.pointWidth + Const.pointRightOffset + sensitivityLabel.actuallySizeThatFits().width
            bottomTitleHeight = max(subTitleLabel.intrinsicContentSize.height, sensitivityLabel.actuallySizeThatFits().height) + Const.titleBottomOffset
            if SKDisplay.pad {
                //iPad上布局有微小差异，因此间距加一
                bottomTitleHeight += 1
            }
        }
        // 计算两行宽度和高度的最大值
        let width = max(topWidth, bottomWidth)
        let height = titleLabel.intrinsicContentSize.height + bottomTitleHeight + Const.titleBottomOffset
        
        return CGSize(width: min(maxAvailableSize.width, width), height: min(maxAvailableSize.height, height))
    }
}

// MARK: - Private Methods
private extension DriveSubTitleView {

    func configTextLabel(_ label: UILabel,
                         color: UIColor,
                         fontSize: CGFloat,
                         weight: UIFont.Weight = .medium,
                         alig: NSTextAlignment = .center) {
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.textColor = color
        label.font = UIFont.systemFont(ofSize: fontSize, weight: weight)
    }

    func setupSubviews() {

        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(5)
            make.left.right.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
            make.height.equalTo(18)
        }

        subTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(1)
            make.left.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.bottom.equalToSuperview()
            make.width.lessThanOrEqualToSuperview()
        }
    }
}

class SensitivityLabel: UIView {
    private lazy var icon: UIImageView =  {
        let view = UIImageView()
        view.backgroundColor = .clear
        view.image = UDIcon.safePassOutlined.ud.withTintColor(UDColor.iconN3)
        addSubview(view)
        return view
    }()
    
    private lazy var label: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.textColor = UDColor.textCaption
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        addSubview(label)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func setupUI() {
        icon.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(14)
            make.height.equalTo(14)
        }
        label.snp.makeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(2)
            make.centerY.equalToSuperview()
            make.height.equalTo(17)
            make.right.lessThanOrEqualToSuperview()
        }
    }
    
    func setTitle(title: String) {
        label.text = title
    }
    
    func actuallySizeThatFits() -> CGSize {
        let width = 16 + label.intrinsicContentSize.width
        let height = label.intrinsicContentSize.height
        return CGSize(width: width, height: height)
    }
}
