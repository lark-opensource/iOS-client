//
// Created by duanxiaochen.7 on 2020/10/25.
// Affiliated with SpaceKit.
//
// Description:

import SKUIKit
import SnapKit
import SKResource
import UniverseDesignColor

// 有三个头像和一个 n+ 的 right view
class ReminderUserAvatarArray: UIView {
    let maxShowCount = 3
    let avatarHeight: CGFloat = 34

    init(_ userModels: [ReminderUserModel]?) {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
    }

    func updateArray(with userModels: [ReminderUserModel]) {
        subviews.forEach { $0.removeFromSuperview() }
        var referenceTrailingEdge: ConstraintRelatableTarget
        var referenceLeadingEdge: ConstraintRelatableTarget
        let totalCount = userModels.count
        if totalCount > maxShowCount {
            let moreIndicator = UILabel().construct { it in
                it.text = "\(totalCount - maxShowCount)+"
                it.font = .systemFont(ofSize: 17)
                it.textColor = UDColor.textPlaceholder
                it.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
            }
            referenceLeadingEdge = self.snp.leading
            for i in 0..<maxShowCount {
                let avatar = constructAvatar(with: userModels[i])
                addSubview(avatar)
                avatar.snp.makeConstraints { (make) in
                    make.leading.equalTo(referenceLeadingEdge).offset(9)
                    make.width.height.equalTo(avatarHeight)
                    make.top.bottom.equalToSuperview()
                }
                referenceLeadingEdge = avatar.snp.trailing
                if i == maxShowCount - 1 {
                    addSubview(moreIndicator)
                    moreIndicator.snp.makeConstraints { (make) in
                        make.leading.equalTo(avatar.snp.trailing).offset(12)
                        make.trailing.equalToSuperview()
                        make.top.bottom.equalToSuperview()
                        make.height.equalTo(avatarHeight)
                    }
                }
            }
        } else {
            referenceTrailingEdge = self.snp.trailing
            for i in (0..<totalCount).reversed() {
                let avatar = constructAvatar(with: userModels[i])
                addSubview(avatar)
                avatar.snp.makeConstraints { (make) in
                    make.trailing.equalTo(referenceTrailingEdge).offset(-9)
                    make.width.height.equalTo(avatarHeight)
                    make.top.bottom.equalToSuperview()
                }
                referenceTrailingEdge = avatar.snp.leading
                if i == 0 {
                    self.snp.makeConstraints { (make) in
                        make.leading.equalTo(avatar).offset(-9)
                    }
                }
            }
        }
    }

    private func constructAvatar(with model: ReminderUserModel) -> UIImageView {
        let avatarView = SKAvatar(configuration: .init(style: .circle, contentMode: .scaleToFill))
        avatarView.frame = .init(origin: .zero, size: CGSize(width: avatarHeight, height: avatarHeight))
        avatarView.kf.setImage(with: URL(string: model.avatarURL),
                               placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder)
        avatarView.layer.cornerRadius = avatarHeight / 2
        avatarView.layer.masksToBounds = true
        return avatarView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
