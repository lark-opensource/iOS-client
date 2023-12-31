//
//  BTTableCardBaseCell.swift
//  SKBitable
//
//  Created by zhysan on 2023/4/12.
//

import SKFoundation
import UniverseDesignColor

class BTTableCardBaseCell: UITableViewCell {
    // MARK: - public
    
    static var defaultReuseID: String {
        String(describing: self)
    }
    
    let cardView: UIView = UIView().construct { it in
        it.backgroundColor = UDColor.bgFloat
        it.clipsToBounds = true
    }
    
    let spLine: UIView = UIView().construct { it in
        it.backgroundColor = UDColor.lineDividerDefault
        it.isUserInteractionEnabled = false
    }
    
    var cardInset = UIEdgeInsets(horizontal: 16, vertical: 0) {
        didSet {
            cardView.snp.updateConstraints { make in
                make.edges.equalToSuperview().inset(cardInset)
            }
        }
    }
    
    var spLineIndent: CGFloat = 0 {
        didSet {
            spLine.snp.updateConstraints { make in
                make.left.equalToSuperview().inset(spLineIndent)
            }
        }
    }
    
    func updateIndex(_ index: Int, total: Int, cardRadius: CGFloat = 10.0) {
        updateStyle(isFirstCell: index == 0, isLastCell: index == total - 1, cardRadius: cardRadius)
    }
    
    func updateStyle(isFirstCell: Bool, isLastCell: Bool, cardRadius: CGFloat = 10.0) {
        if isFirstCell && isLastCell {
            // only one
            cardView.layer.cornerRadius = cardRadius
            cardView.layer.maskedCorners = .all
            spLine.isHidden = true
        } else if isFirstCell {
            // first but not last
            cardView.layer.cornerRadius = cardRadius
            cardView.layer.maskedCorners = .top
            spLine.isHidden = false
        } else if isLastCell {
            // last but not first
            cardView.layer.cornerRadius = cardRadius
            cardView.layer.maskedCorners = .bottom
            spLine.isHidden = true
        } else {
            // middle position, not first nor last
            cardView.layer.cornerRadius = 0
            spLine.isHidden = false
        }
    }
    
    // MARK: - life cycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - private
    
    private func subviewsInit() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        contentView.addSubview(cardView)
        cardView.addSubview(spLine)
        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(cardInset)
        }
        spLine.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(spLineIndent)
            make.bottom.right.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        
        spLine.isHidden = true
    }
    
}

