//
//  MailStrangerThreadCell.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/3/6.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignButton
import UniverseDesignIcon
import RustPB
import FigmaKit

protocol MailStrangerThreadCellDelegate: AnyObject {
    func didClickStrangerReply(_ cell: MailStrangerThreadCell, cellModel: MailThreadListCellViewModel, status: Bool)
    func didClickAvatar(mailAddress: MailAddress, cellModel: MailThreadListCellViewModel)
}

class MailStrangerThreadCell: UICollectionViewCell, MailStrangerManageDelegate {

//    var replyHandler: (() -> Void)?
    var replyHandler: ((_ status: Bool) -> Void)?
    var cellViewModel: MailThreadListCellViewModel? {
        didSet {
            if let cellViewModel = cellViewModel {
                self.configureStrangerThreadCell(cellViewModel)
            }
         }
    }
    var showShadow: Bool = true {
        didSet {
            cornerLayer.isHidden = !showShadow
            if showShadow {
                bgView.snp.remakeConstraints { make in
                    make.top.left.equalToSuperview()
                    make.width.equalTo(StrangerCardConst.cardWidth)
                    make.height.equalTo(StrangerCardConst.cardHeight)
                }
                bgView.layer.borderWidth = 0
                bgView.layer.cornerRadius = 10
//                bgView.layer.masksToBounds = false
            } else {
                bgView.snp.remakeConstraints { make in
                    make.edges.equalToSuperview()
                }
                bgView.layer.borderWidth = 0.5
                bgView.layer.cornerRadius = 8
                bgView.layer.masksToBounds = true
            }
            shadows.isHidden = !showShadow
            shapes.isHidden = !showShadow
            stroke.isHidden = !showShadow
        }
    }
    var indexPath: IndexPath?
    var selectedIndexPath: IndexPath? {
        didSet {
            if Display.pad {
                selectedBgView.backgroundColor = (isSelected || indexPath == selectedIndexPath) ? UIColor.ud.primaryPri50 : UIColor.ud.bgFloat
            } else {
                selectedBgView.backgroundColor = UIColor.ud.bgFloat
            }
            manageView.refreshButton()
        }
    }
//    override var isSelected: Bool {
//        didSet {
//            if Display.pad {
//                selectedBgView.backgroundColor = isSelected ? UIColor.ud.primaryPri50 : UIColor.ud.bgFloat
//            } else {
//                selectedBgView.backgroundColor = UIColor.ud.bgFloat
//            }
//            manageView.refreshButton()
//        }
//    }
    weak var delegate: MailStrangerThreadCellDelegate?

    private let avatarWidth: CGFloat = 34
    private let arrowWidth: CGFloat = 12
    private let titleMargin: CGFloat = 78
    private let convDefaultMargin: CGFloat = 10
    private let convDigitsMargin: CGFloat = 16
    private let convTenDigitsMargin: CGFloat = 22
    private let convMaxDigitsMargin: CGFloat = 27

    private let cardShadowView = UIView()
    private let cardBgView = UIView()
    private let cardHeaderView = UIView()
    private let avatarView = MailAvatarImageView()
    private let senderTitle = UILabel()
    private let senderAddress = UILabel()
    private let arrowIcon = UIImageView()

    private let convLabel = UILabel()
    private let titleLabel = UILabel()
    private let summaryLabel = UILabel()

    private let cornerLayer = CALayer()
    private let selectedBgView = UIView()

    // shadows
    private let bgView = UIView()
    private let shadows = UIView()
    private let shapes = UIView()
    private let stroke = UIView()

    private let manageView: MailStrangerManageView = MailStrangerManageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureStrangerThreadCell(_ mailThread: MailThreadListCellViewModel) {
        senderAddress.text = mailThread.address
        titleLabel.text = mailThread.title
        setNameLabelText(mailThread)

        let summary = mailThread.desc.getDesc()
        summaryLabel.text = summary
    }
    
    func setNameLabelText(_ mailThread: MailThreadListCellViewModel) {
        var mailThread = mailThread
        var margin = avatarWidth + titleMargin + arrowWidth
        var convWidth: CGFloat = 0
        var convText = ""
        if mailThread.convCount > StrangerCardConst.maxThreadCount {
            margin += convMaxDigitsMargin
            convWidth = convMaxDigitsMargin
            convText = "99+"
        } else if mailThread.convCount > 1 {
            margin += convDigitsMargin
            convWidth = convDigitsMargin
            convText = "\(mailThread.convCount)"
        } else if mailThread.convCount > Int(convDefaultMargin) {
            margin += convTenDigitsMargin
            convWidth = convTenDigitsMargin
            convText = "\(mailThread.convCount)"
        } else {
            margin += convDefaultMargin
        }
        let nameFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        senderTitle.setText(mailThread.getDisplayName("", self.contentView.bounds.width - margin,
                                                    inDraftLabel: cellViewModel?.currentLabelID == Mail_LabelId_Draft,
                                                    nameFont: nameFont) ?? BundleI18n.MailSDK.Mail_ThreadList_NoName)
        convLabel.text = convText
        convLabel.snp.updateConstraints { make in
            make.width.equalTo(convWidth)
        }
        avatarView.loadAvatar(name: senderTitle.text ?? "",
                              avatarKey: "",
                              entityId: mailThread.fromAddressList.first?.larkID ?? "",
                              setBackground: false) { _, error in
            if let error = error {
                MailLogger.debug("MailStrangerThreadCell load avatar Fail: \(error)")
            }
        }
    }

    func setupViews() {
        contentView.backgroundColor = UIColor.ud.bgFloat
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 0.5
        contentView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard) // borderColor = UIColor.ud.lineBorderCard.cgColor

        cornerLayer.frame = CGRect(origin: CGPoint(x: 0.5, y: 0),
                                   size: CGSize(width: contentView.frame.width - 1, height: contentView.frame.height))
//        cornerLayer.frame = contentView.frame
        cornerLayer.cornerRadius = 10
        cornerLayer.borderWidth = 0.5
        cornerLayer.ud.setShadowColor(UIColor.ud.rgb("1F2329").withAlphaComponent(0.08)) //shadowColor = UIColor.ud.rgb("1F2329").cgColor
        cornerLayer.masksToBounds = false
        cornerLayer.shadowOffset = CGSize(width: 0, height: 2)
        cornerLayer.shadowRadius = 6
        cornerLayer.shadowOpacity = 1
//        cornerLayer.ud.setShadow(type: .s2Down)
//        self.layer.insertSublayer(cornerLayer, below: contentView.layer)




        bgView.backgroundColor = UIColor.ud.bgFloat
        bgView.frame = CGRect(x: 0, y: 0, width: StrangerCardConst.cardWidth, height: StrangerCardConst.cardHeight)
        bgView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        bgView.layer.borderWidth = 0.5
        shadows.frame = bgView.frame
        shadows.clipsToBounds = false
        bgView.addSubview(shadows)
        let shadowPath0 = UIBezierPath(roundedRect: shadows.bounds, cornerRadius: 8)
        let layer0 = CALayer()
        layer0.shadowPath = shadowPath0.cgPath
        layer0.shadowColor = UIColor(red: 0.122, green: 0.137, blue: 0.161, alpha: 0.08).cgColor
        layer0.shadowOpacity = 1
        layer0.shadowRadius = 6
        layer0.shadowOffset = CGSize(width: 0, height: 2)
        layer0.bounds = shadows.bounds
        layer0.position = shadows.center
        shadows.layer.addSublayer(layer0)
        shapes.backgroundColor = UIColor.ud.bgFloat
        shapes.frame = bgView.frame
        shapes.clipsToBounds = true
        bgView.addSubview(shapes)
        let layer1 = CALayer()
        layer1.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor
        layer1.bounds = shapes.bounds
        layer1.position = shapes.center
        shapes.layer.addSublayer(layer1)
        shapes.layer.cornerRadius = 8
        stroke.layer.cornerRadius = 8
        stroke.backgroundColor = UIColor.ud.bgFloat
        stroke.bounds = bgView.bounds.insetBy(dx: -0.5, dy: -0.5)
        stroke.center = bgView.center
        bgView.addSubview(stroke)
        stroke.layer.cornerRadius = 8.5
        bgView.bounds = bgView.bounds.insetBy(dx: -0.5, dy: -0.5)
        stroke.layer.borderWidth = 0.5
        stroke.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)// borderColor = UIColor(red: 0.871, green: 0.878, blue: 0.89, alpha: 1).cgColor

        self.addSubview(bgView)
        bgView.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
            make.top.left.equalToSuperview()
            make.width.equalTo(StrangerCardConst.cardWidth)
            make.height.equalTo(StrangerCardConst.cardHeight)
        }
//        view.translatesAutoresizingMaskIntoConstraints = false
//        view.widthAnchor.constraint(equalToConstant: 278).isActive = true
//        view.heightAnchor.constraint(equalToConstant: 145).isActive = true


        selectedBgView.backgroundColor = UIColor.ud.bgFloat
        selectedBgView.layer.cornerRadius = 8
        selectedBgView.layer.masksToBounds = true
        bgView.addSubview(selectedBgView)
        selectedBgView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(0.5)
        }

        bgView.addSubview(cardHeaderView)
        cardHeaderView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(39)
            make.top.equalTo(12)
        }

        avatarView.dafaultBackgroundColor = UIColor.clear
        avatarView.layer.cornerRadius = avatarWidth / 2.0
        avatarView.layer.masksToBounds = true
        bgView.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.leading.equalTo(14)
            make.width.height.equalTo(avatarWidth)
            make.top.equalTo(14.5)
        }
        avatarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleAvatarClick)))

        arrowIcon.image = UDIcon.rightBoldOutlined.withRenderingMode(.alwaysTemplate)
        arrowIcon.tintColor = .ud.iconN3
        bgView.addSubview(arrowIcon)
        arrowIcon.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-12)
            make.width.height.equalTo(arrowWidth)
            make.centerY.equalTo(avatarView)
        }

        convLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        convLabel.textColor = UIColor.ud.udtokenTagNeutralTextNormal
        convLabel.textAlignment = .center
        convLabel.layer.ud.setBackgroundColor(UIColor.ud.udtokenTagNeutralBgNormal)
        convLabel.layer.cornerRadius = 4
        convLabel.layer.masksToBounds = true
        convLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        bgView.addSubview(convLabel)
        convLabel.snp.makeConstraints { make in
            make.left.equalTo(12)
            make.top.equalTo(avatarView.snp.bottom).offset(14.5)
            make.height.equalTo(16)
            make.width.equalTo(0)
        }

        senderTitle.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        senderTitle.textColor = UIColor.ud.textTitle
        bgView.addSubview(senderTitle)
        senderTitle.snp.makeConstraints { make in
            make.top.equalTo(13)
            make.left.equalTo(avatarView.snp.right).offset(10)
            make.right.lessThanOrEqualTo(arrowIcon.snp.left).offset(-4)
            make.height.equalTo(22)
        }

        senderAddress.font = UIFont.systemFont(ofSize: 12)
        senderAddress.textColor = UIColor.ud.textTitle
        bgView.addSubview(senderAddress)
        senderAddress.snp.makeConstraints { make in
            make.bottom.equalTo(avatarView.snp.bottom)
            make.left.equalTo(avatarView.snp.right).offset(10)
            make.right.equalTo(arrowIcon.snp.left).offset(-4)
            make.height.equalTo(18)
        }

        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.textCaption
        bgView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(convLabel.snp.right).offset(4)
            make.trailing.equalToSuperview().offset(-10)
            make.centerY.equalTo(convLabel)
            make.height.greaterThanOrEqualTo(20)
        }

        manageView.delegate = self
        bgView.addSubview(manageView)
        manageView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(14)
            make.leading.trailing.bottom.equalToSuperview().inset(14)
            make.height.equalTo(36)
        }
    }

    @objc func handleAvatarClick() {
        if let cellViewModel = cellViewModel, let fromAddress = cellViewModel.fromAddressList.first {
            delegate?.didClickAvatar(mailAddress: fromAddress, cellModel: cellViewModel)
        }
    }

    func didClickStrangerReply(status: Bool) {
        if let cellViewModel = cellViewModel {
            delegate?.didClickStrangerReply(self, cellModel: cellViewModel, status: status)
//            replyHandler?()
            replyHandler?(status)
        }
    }
}
