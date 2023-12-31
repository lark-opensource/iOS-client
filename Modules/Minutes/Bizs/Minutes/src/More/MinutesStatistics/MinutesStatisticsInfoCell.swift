//
//  MinutesStatisticsInfoCell.swift
//  Minutes
//
//  Created by sihuahao on 2021/7/6.
//

import Foundation
import EENavigator
import SkeletonView
import MinutesFoundation
import UniverseDesignIcon

// MARK: - MinutesStatisticsInfoCell - 查看、互动统计

public protocol MinutesStatisticsCellAlertDelegate: AnyObject {
     func statisticsCellAlert()
}

class MinutesStatisticsInfoCell: UITableViewCell, MinutesStatisticsCell {

    var tapAction: (() -> Void)?
    private lazy var titleView: UIView = {
        let view: UIView = UIView(frame: CGRect.zero)
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.numberOfLines = 1
        label.textAlignment = .left
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        return label
    }()

    private lazy var titleAdditionImageView: UIImageView = {
        let imageView: UIImageView = UIImageView(frame: CGRect.zero)
        return imageView
    }()

     private lazy var leftNumLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.numberOfLines = 1
        label.textAlignment = .left
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        return label
    }()

    private lazy var rightNumLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.numberOfLines = 0
        label.textAlignment = .left
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        return label
    }()

    private lazy var leftBottomLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.numberOfLines = 1
        label.textAlignment = .left
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        return label
    }()

    private lazy var rightBottomLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.numberOfLines = 0
        label.textAlignment = .left
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        return label
    }()

    private lazy var leftLoadingLabel: UILabel = {
        let label = UILabel()
        label.isSkeletonable = true
        label.linesCornerRadius = 2
        label.numberOfLines = 1
        return label
    }()

    private lazy var rightLoadingLabel: UILabel = {
        let label = UILabel()
        label.isSkeletonable = true
        label.linesCornerRadius = 2
        label.numberOfLines = 1
        return label
    }()

    private lazy var leftNoInternetLabel: UILabel = {
        let label = UILabel()
        label.layer.cornerRadius = 2
        label.layer.masksToBounds = true
        label.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.05)
        return label
    }()

    private lazy var rightNoInternetLabel: UILabel = {
        let label = UILabel()
        label.layer.cornerRadius = 2
        label.layer.masksToBounds = true
        label.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.05)
        return label
    }()

    private lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        return tapGestureRecognizer
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        contentView.backgroundColor = UIColor.ud.bgBody
        titleView.addSubview(titleLabel)
        titleView.addSubview(titleAdditionImageView)
        contentView.addSubview(titleView)
        contentView.addSubview(leftLoadingLabel)
        contentView.addSubview(rightLoadingLabel)
        contentView.addSubview(leftNoInternetLabel)
        contentView.addSubview(rightNoInternetLabel)
        contentView.addSubview(leftNumLabel)
        contentView.addSubview(rightNumLabel)
        contentView.addSubview(leftBottomLabel)
        contentView.addSubview(rightBottomLabel)

        self.leftNoInternetLabel.isHidden = true
        self.rightNoInternetLabel.isHidden = true
        configCellLayout()
        configSkeletonStyle()
    }

    func configSkeletonStyle() {
        let gradient = SkeletonGradient(baseColor: UIColor.ud.N900.withAlphaComponent(0.05), secondaryColor: UIColor.ud.N900.withAlphaComponent(0.08))
        let animation = SkeletonAnimationBuilder().makeSlidingAnimation(withDirection: .leftRight, duration: 10)
        self.leftLoadingLabel.showAnimatedGradientSkeleton(usingGradient: gradient)
        self.leftLoadingLabel.startSkeletonAnimation()
        self.rightLoadingLabel.showAnimatedGradientSkeleton(usingGradient: gradient)
        self.rightLoadingLabel.startSkeletonAnimation()
    }

    func configCellLayout() {
        titleView.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview()
            maker.left.equalToSuperview().offset(12)
            maker.height.equalTo(20)
            maker.width.equalTo(82)
        }

        titleLabel.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview()
            maker.left.equalToSuperview().offset(4)
            maker.height.equalTo(20)
        }

        titleAdditionImageView.snp.makeConstraints { (maker) in
            maker.centerY.equalTo(titleLabel)
            maker.left.equalTo(titleLabel.snp.right).offset(4)
            maker.height.width.equalTo(14)
        }

        leftNumLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(titleLabel.snp.bottom).offset(10)
            maker.left.equalToSuperview().offset(16)
            maker.height.equalTo(32)
        }

        leftBottomLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(titleView.snp.bottom).offset(46)
            maker.left.equalToSuperview().offset(16)
            maker.height.equalTo(18)
        }

        rightBottomLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalTo(leftBottomLabel)
            maker.left.equalToSuperview().offset(164)
            maker.height.equalTo(18)
        }

        rightNumLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(rightBottomLabel.snp.left)
            maker.top.equalTo(titleLabel.snp.bottom).offset(10)
            maker.height.equalTo(32)
        }

        leftLoadingLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(titleLabel.snp.bottom).offset(20)
            maker.left.equalToSuperview().offset(16)
            maker.width.equalTo(80)
            maker.height.equalTo(14)
        }

        rightLoadingLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(rightBottomLabel.snp.left)
            maker.top.equalTo(titleLabel.snp.bottom).offset(20)
            maker.width.equalTo(80)
            maker.height.equalTo(14)
        }

        leftNoInternetLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(titleLabel.snp.bottom).offset(20)
            maker.left.equalToSuperview().offset(16)
            maker.width.equalTo(80)
            maker.height.equalTo(14)
        }

        rightNoInternetLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(rightBottomLabel.snp.left)
            maker.top.equalTo(titleLabel.snp.bottom).offset(20)
            maker.width.equalTo(80)
            maker.height.equalTo(14)
        }
    }

    func setData(cellInfo: CellInfo) {
        if let item = cellInfo as? StatisticsCellInfo {
            rightLoadingLabel.isHidden = item.isSingle
            titleLabel.text = item.titleLabelText
            leftBottomLabel.text = item.leftBottomLabelText
            rightBottomLabel.text = item.rightBottomLabelText

            if let realhasStatistics = item.hasStatistics {
                if realhasStatistics {
                    self.titleAdditionImageView.isHidden = true
                } else {
                    self.titleAdditionImageView.isHidden = false
                    self.titleAdditionImageView.image = UDIcon.getIconByKey(.maybeOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 24, height: 24))

                    titleView.addGestureRecognizer(tapGestureRecognizer)
                }
            }

            if let realLeftlabelNum = item.leftlabelNum, let realRightlabelNum = item.rightLabelNum {
                leftNumLabel.text = String(realLeftlabelNum)
                rightNumLabel.text = String(realRightlabelNum)
                self.leftLoadingLabel.isHidden = true
                self.rightLoadingLabel.isHidden = true
                rightNumLabel.isHidden = realRightlabelNum == -1
            }
        } else {
            MinutesLogger.detail.error("error get StatisticsCellInfo", additionalData: ["cellIdentifier": cellInfo.withIdentifier])
        }
    }

    func setFailureCellStyle() {
        self.leftLoadingLabel.isHidden = true
        self.rightLoadingLabel.isHidden = true
        self.leftNoInternetLabel.isHidden = false
        self.rightNoInternetLabel.isHidden = false
    }

    @objc
    private func handleTapGesture(_ sender: UITapGestureRecognizer) {
        tapAction?()
    }
}
