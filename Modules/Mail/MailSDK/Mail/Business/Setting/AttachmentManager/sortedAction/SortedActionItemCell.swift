//
//  SortedActionSectionCell.swift
//  MailSDK
//
//  Created by ByteDance on 2023/5/9.
//

import Foundation
import LarkInteraction
import UniverseDesignIcon

class SortedActionSectionCell: UITableViewCell {
    private let nameLabel = UILabel()
    private let bottomLineView = UIView()
    private let seletedBtn = UIImageView()
    
    private static let labelFont = UIFont.systemFont(ofSize: 16)
    private static let offset: CGFloat = 16
    private static let topOffset: CGFloat = 13
    
    static func cellHeightFor(title: String, cellWidth: CGFloat) -> CGFloat {
        let textWidth = cellWidth - 3 * SortedActionSectionCell.offset
        let titleHeight = (title as NSString).boundingRect(with: CGSize(width: textWidth, height: CGFloat.greatestFiniteMagnitude),
                                                           options: .usesLineFragmentOrigin,
                                                           attributes: [.font: SortedActionSectionCell.labelFont],
                                                           context: nil).height
        let labelHeight = min(ceil(SortedActionSectionCell.labelFont.lineHeight * 2), ceil(titleHeight))
        return labelHeight + 2 * SortedActionSectionCell.topOffset
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
    }

    func updateBottomLine(isHidden: Bool) {
        bottomLineView.isHidden = isHidden
    }
    
    private func setupSubviews() {
        selectionStyle = .none
        nameLabel.font = SortedActionSectionCell.labelFont
        nameLabel.backgroundColor = .clear
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.numberOfLines = 2
        
        bottomLineView.backgroundColor = UIColor.ud.lineDividerDefault
//        backgroundColor = UIColor.ud.bgFloat
        seletedBtn.image = UDIcon.listCheckBoldOutlined.withRenderingMode(.alwaysTemplate)
        seletedBtn.isHidden = true
        contentView.addSubview(nameLabel)
        contentView.addSubview(bottomLineView)
        contentView.addSubview(seletedBtn)
        
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(SortedActionSectionCell.offset)
            make.right.equalTo(-2*SortedActionSectionCell.offset)
            make.top.equalToSuperview().offset(SortedActionSectionCell.topOffset)
            make.bottom.equalToSuperview().offset(-SortedActionSectionCell.topOffset)
        }
        seletedBtn.snp.makeConstraints { make in
            make.right.equalTo(-SortedActionSectionCell.offset)
            make.centerY.equalTo(nameLabel)
            make.width.height.equalTo(16)
        }
        bottomLineView.snp.makeConstraints { (make) in
            make.left.equalTo(nameLabel)
            make.bottom.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: PointerStyle(
                effect: .hover()
                )
            )
            self.addLKInteraction(pointer)
        }
    }
    
    func config(title: String, isSeleted: Bool) {
        nameLabel.text = title
        seletedBtn.isHidden = !isSeleted
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
