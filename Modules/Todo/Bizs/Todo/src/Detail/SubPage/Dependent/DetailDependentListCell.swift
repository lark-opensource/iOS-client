//
//  DetailDependentListCell.swift
//  Todo
//
//  Created by wangwanxin on 2023/7/17.
//

import Foundation
import UniverseDesignIcon
import LarkUIKit

struct DetailDependentListCellData {
    var contentType: V3ListContentType?
    var isSelected: Bool = false
    var showRemoveBtn: Bool = true
    // 缓存一个高度，避免多次计算
    var cellHeight: CGFloat?

    var todo: Rust.Todo
    var completeState: CompleteState

    init(with todo: Rust.Todo, completeState: CompleteState) {
        self.todo = todo
        self.completeState = completeState
    }

    func preferredHeight(maxWidth: CGFloat) -> CGFloat {
        guard let contentType = contentType else {
            return .leastNonzeroMagnitude
        }
        switch contentType {
        case .content(let data):
            let height = showRemoveBtn ? DetailDependentListCell.Config.topSpaceHeight : 0
            return data.preferredHeight(maxWidth: maxWidth) + height
        default:
            return .leastNonzeroMagnitude
        }
    }

}

protocol DetailDependentListCellDelegate: AnyObject {
    func didClickRemove(from sender: DetailDependentListCell)
    func didClickContent(from sender: DetailDependentListCell)
}


final class DetailDependentListCell: UICollectionViewCell {

    var viewData: DetailDependentListCellData? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            isHidden = false
            removeBtn.isHidden = !viewData.showRemoveBtn
            if viewData.isSelected {
                subView.layer.borderColor = UIColor.ud.primaryContentDefault.cgColor
                subView.layer.borderWidth = 1
            } else {
                subView.layer.borderColor = UIColor.clear.cgColor
                subView.layer.borderWidth = .zero
            }
            switch viewData.contentType {
            case .content(let data):
                subView.viewData = data
            default:
                subView.viewData = nil
            }
        }
    }

    weak var actionDelegate: DetailDependentListCellDelegate?


    private lazy var subView = V3ListContentView()

    private lazy var removeBtn: UIButton = {
        let icon = UDIcon.getIconByKey(.deleteNormalColorful, size: Config.removeIconSize)
        let button = UIButton()
        button.setImage(icon, for: .normal)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = UIColor.ud.bgFloatBase
        subView.backgroundColor = UIColor.ud.bgBody
        setupSubViews()
        let tap = UITapGestureRecognizer(target: self, action: #selector(clickContent))
        subView.addGestureRecognizer(tap)
        removeBtn.addTarget(self, action: #selector(clickRemove), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubViews() {
        contentView.addSubview(subView)
        subView.lu.addCorner(
            corners: [
                .layerMinXMinYCorner,
                .layerMaxXMinYCorner,
                .layerMinXMaxYCorner,
                .layerMaxXMaxYCorner],
            cornerSize: CGSize(width: 10, height: 10)
        )
        subView.clipsToBounds = true
        contentView.addSubview(removeBtn)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !removeBtn.isHidden {
            subView.frame = CGRect(
                x: Config.hPadding,
                y: Config.removeBtnSize.height / 2,
                width: bounds.width - Config.hPadding * 2,
                height: bounds.height - Config.topSpaceHeight
            )
            removeBtn.frame = CGRect(
                x: subView.frame.maxX - Config.removeBtnSize.width / 2,
                y: 0,
                width: Config.removeBtnSize.width,
                height: Config.removeBtnSize.height
            )
        } else {
            subView.frame = CGRect(
                x: Config.hPadding,
                y: 0,
                width: bounds.width - Config.hPadding * 2,
                height: bounds.height
            )
            removeBtn.frame = .zero
        }
    }

    @objc
    private func clickContent() {
        actionDelegate?.didClickContent(from: self)
    }

    @objc
    private func clickRemove() {
        actionDelegate?.didClickRemove(from: self)
    }


}

extension DetailDependentListCell {

    struct Config {
        static let removeBtnSize = CGSize(width: 24, height: 24)
        static let removeIconSize = CGSize(width: 20, height: 20)
        static let hPadding = 16.0
        static let topSpaceHeight = removeBtnSize.height / 2
    }



}
