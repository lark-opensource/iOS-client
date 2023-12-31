//
//  DriveCommentBottomView.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/3/27.
//

import UIKit
import RxSwift
import SKCommon
import SKFoundation
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import SnapKit

protocol DriveCommentBottomViewDelegate: AnyObject {
    func didEnterComment(in driveCommentBottomView: DriveCommentBottomView)
    func didViewAllComments(in driveCommentBottomView: DriveCommentBottomView)
    func didLikeFile(in driveCommentBottomView: DriveCommentBottomView)
    func didClickLikeLabel(in driveCommentBottomView: DriveCommentBottomView)
}

protocol DriveCommentBottomViewDataSource: AnyObject {
    func numberOfCommentsCount(in driveCommentBottomView: DriveCommentBottomView) -> Int

    func likeModel() -> DriveLikeDataManager

    func canComment() -> Bool
}

class DriveCommentBottomView: UIView {
    weak var delegate: DriveCommentBottomViewDelegate?
    weak var dataSource: DriveCommentBottomViewDataSource?

    let enterCommentButton: UIButton = {
        let button = UIButton()
        button.setAttributedTitle(NSAttributedString(string: BundleI18n.SKResource.Drive_Drive_EnterComment,
                                                     attributes: [.font: UIFont.systemFont(ofSize: 16),
                                                                  .foregroundColor: UDColor.textPlaceholder]),
                                  for: .normal)
        button.contentHorizontalAlignment = .left
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        return button
    }()
    let seperatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineBorderCard
        return view
    }()
    let viewCommentButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.addCommentOutlined.ud.withTintColor(UDColor.iconN1), for: .normal)
        button.adjustsImageWhenHighlighted = false
        button.docs.addHighlight(with: UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8), radius: 8)
        return button
    }()

    private let bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        return view
    }()

    private lazy var likeLabel: DriveLikeLable = {
        var label = DriveLikeLable()
        label.backgroundColor = UDColor.bgBody
        return label
    }()

    lazy var likeButtonView = DriveLikeButtonView()
    
    private lazy var commentAmountLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.iconN1
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        return label
    }()
    private var commentAmountLabelConstraint: Constraint?

    private let bag = DisposeBag()

    let preferHeight: CGFloat = 48
    let likeEnabled: Bool

    init(likeEnabled: Bool) {
        self.likeEnabled = likeEnabled
        super.init(frame: .zero)
        setupUI(likeEnabled: likeEnabled)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(likeEnabled: Bool) {
        backgroundColor = UDColor.bgBody
        layer.ud.setShadowColor(UDColor.shadowDefaultSm)
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowOpacity = 1

        enterCommentButton.addTarget(self, action: #selector(enterComment), for: .touchUpInside)
        viewCommentButton.rx.tap
            .throttle(.seconds(2), scheduler: MainScheduler.instance)
            .subscribe(onNext: {[weak self] _ in
                self?.viewComment()
            }).disposed(by: bag)

        if likeEnabled {
            setupLayoutWithLikeComponent()
        } else {
            setupLayoutWithoutLikeComponent()
        }
    }

    private func setupLayoutWithoutLikeComponent() {
        addSubview(bottomView)
        bottomView.backgroundColor = UDColor.bgBody
        bottomView.addSubview(enterCommentButton)
        bottomView.addSubview(viewCommentButton)
        viewCommentButton.addSubview(commentAmountLabel)

        bottomView.snp.makeConstraints { (make) in
            make.height.equalTo(self.preferHeight)
            make.left.right.top.equalToSuperview()
        }
        enterCommentButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(12)
            make.height.equalTo(20)
            make.right.equalTo(viewCommentButton.snp.left)
            make.top.equalToSuperview().offset(14)
        }
        setupViewCommentButtonLayout()
    }

    private func setupLayoutWithLikeComponent() {
        likeLabel.delegate = self
        likeButtonView.likeButton.addTarget(self, action: #selector(likeFile), for: .touchUpInside)
        addSubview(bottomView)
        bottomView.addSubview(likeButtonView)
        bottomView.addSubview(likeLabel)
        bottomView.addSubview(seperatorLine)
        bottomView.addSubview(enterCommentButton)
        bottomView.addSubview(viewCommentButton)
        viewCommentButton.addSubview(commentAmountLabel)

        bottomView.snp.makeConstraints { (make) in
            make.height.equalTo(self.preferHeight)
            make.left.right.top.equalToSuperview()
        }
        likeButtonView.snp.makeConstraints { (make) in
            make.height.equalTo(28)
            make.width.equalTo(48)
            make.left.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
        }
        likeLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(70)
            make.height.equalTo(20)
            make.centerY.equalToSuperview()
            make.width.equalTo(32)
        }
        seperatorLine.snp.makeConstraints { (make) in
            make.width.equalTo(1)
            make.height.equalTo(22)
            make.top.equalToSuperview().offset(13)
            make.left.equalToSuperview().offset(60)
        }
        enterCommentButton.snp.makeConstraints { (make) in
            make.left.equalTo(seperatorLine.snp.right).offset(12)
            make.height.equalTo(20)
            make.right.equalTo(viewCommentButton.snp.left)
            make.top.equalToSuperview().offset(14)
        }
        setupViewCommentButtonLayout()
    }
    
    private func setupViewCommentButtonLayout() {
        viewCommentButton.snp.makeConstraints { (make) in
            make.height.equalTo(48)
            make.width.equalTo(56)
            make.top.right.equalToSuperview()
        }
        commentAmountLabel.snp.makeConstraints { (make) in
            make.height.equalTo(20)
            make.bottom.equalTo(-22)
            commentAmountLabelConstraint = make.centerX.equalToSuperview().offset(7).constraint
        }
    }

    @objc
    func enterComment() {
        delegate?.didEnterComment(in: self)
    }

    @objc
    func viewComment() {
        delegate?.didViewAllComments(in: self)
    }

    @objc
    func likeFile() {
        delegate?.didLikeFile(in: self)
    }
    
    private func updateViewCommentLabelConstraint(textCount: Int) {
        var offset: CGFloat = 0
        if textCount == 1 {
            offset = 7       // 1~9
        } else if textCount == 2 {
            offset = 8        // 10~99
        } else if textCount == 3 {
            offset = 11        // 99+
        }
        guard let constant = commentAmountLabelConstraint?.layoutConstraints.first?.constant,
              constant != offset else { return }
        if textCount == 3 {
            // "99+" 情况，缩小字体为 12
            commentAmountLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        } else {
            commentAmountLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        }
        commentAmountLabelConstraint?.update(offset: offset)
    }

    func reloadCommentCount() {
        let count = dataSource?.numberOfCommentsCount(in: self) ?? 0
        let countString: String = count > 99 ? "99+" : "\(String(count))"
        let newImage: UIImage?
        viewCommentButton.isEnabled = true
        commentAmountLabel.text = countString
        if count == 0 {
            newImage = UDIcon.addCommentOutlined.ud.withTintColor(UDColor.iconN1)
            commentAmountLabel.isHidden = true
            if let canComment = dataSource?.canComment(), !canComment {
                viewCommentButton.isEnabled = false
            }
        } else {
            commentAmountLabel.isHidden = false
            updateViewCommentLabelConstraint(textCount: countString.count)
            newImage = UDIcon.commentNumberAOutlined.ud.withTintColor(UDColor.iconN1)
        }

        viewCommentButton.setImage(newImage, for: .normal)
    }

    func reloadLikeStatus() {
        guard let likeStatus = dataSource?.likeModel().likeStatus,
            let likeCount = dataSource?.likeModel().count else {
            DocsLogger.warning("can not get like status")
            return
        }
        likeButtonView.reload(likeStatus: likeStatus, likeCount: likeCount)
    }

    func reloadLikeLabel() {
        guard dataSource?.likeModel().likeStatus != nil else {
            DocsLogger.warning("can not get like status")
            return
        }

        likeLabel.likeModel = dataSource?.likeModel()
        likeLabel.reload()
    }
}

extension DriveCommentBottomView: DriveLikeLableDelegate {
    func didDriveLikeLabelAppear(_ likeLable: DriveLikeLable) {
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveLinear, animations: { [weak self] in
            self?.seperatorLine.snp.updateConstraints { (make) in
                    make.left.equalToSuperview().offset(124)
            }
            self?.layoutIfNeeded()
        }, completion: { [weak self] _ in
            self?.likeLabel.isHidden = false
        })
    }

    func didDriveLikeLabelDisappear(_ likeLable: DriveLikeLable) {
        UIView.animate(withDuration: 0.15) { [weak self] in
            self?.likeLabel.isHidden = true
            self?.seperatorLine.snp.updateConstraints { (make) in
                make.left.equalToSuperview().offset(60)
            }
            self?.layoutIfNeeded()
        }
    }

    func didClickDriveLikeLable(_ likeLable: DriveLikeLable) {
        delegate?.didClickLikeLabel(in: self)
    }
}
