//
//  BTTableSectionCardView.swift
//  SKBitable
//
//  Created by zhysan on 2023/1/11.
//

import UIKit
import SKFoundation
import UniverseDesignColor
import UniverseDesignFont


/// Table section card view with text header and footer, keep it as general as possible
class BTTableSectionCardView: UIView {
    
    // MARK: - public

    /// The card view where the content is placed, the corner radius is 10, and the background color is bgFloatOverlay
    let contentView = UIView().construct { it in
        it.layer.cornerRadius = 10.0
        it.clipsToBounds = true
        it.backgroundColor = UDColor.bgFloat
    }
    
    /// Title text, if not set, header label will not be displayed, default is nil
    var headerText: String? {
        didSet {
            headerLabel.text = headerText
            if headerText?.isEmpty == false  {
                stackView.insertArrangedSubview(headerWrapper, at: 0)
            } else {
                stackView.removeArrangedSubview(headerWrapper)
                headerWrapper.removeFromSuperview()
            }
        }
    }
    
    /// Footer text, if not set, footer label will not be displayed, default is nil
    var footerText: String? {
        didSet {
            footerLabel.text = footerText
            if footerText?.isEmpty == false  {
                stackView.addArrangedSubview(footerWrapper)
            } else {
                stackView.removeArrangedSubview(footerWrapper)
                footerWrapper.removeFromSuperview()
            }
        }
    }
    
    var headerTextHeight: CGFloat = 22.0 {
        didSet {
            setNeedsUpdateConstraints()
        }
    }
    
    var footerTextHeight: CGFloat = 22.0 {
        didSet {
            setNeedsUpdateConstraints()
        }
    }
    
    var headerTextInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 2, right: 0) {
        didSet {
            setNeedsUpdateConstraints()
        }
    }
    
    var footerTextInset: UIEdgeInsets = UIEdgeInsets(top: 2, left: 16, bottom: 0, right: 0) {
        didSet {
            setNeedsUpdateConstraints()
        }
    }
    
    // MARK: - life cycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        headerLabel.snp.updateConstraints { make in
            make.height.equalTo(headerTextHeight)
            make.edges.equalToSuperview().inset(headerTextInset)
        }
        
        footerLabel.snp.updateConstraints { make in
            make.height.equalTo(footerTextHeight)
            make.edges.equalToSuperview().inset(footerTextInset)
        }
        
        super.updateConstraints()
    }
    
    // MARK: - private
    
    private let stackView = UIStackView().construct { it in
        it.axis = .vertical
    }
    
    private let headerWrapper = UIView()
    
    private let headerLabel = UILabel().construct { it in
        it.textColor = UDColor.textPlaceholder
        it.font = UDFont.body2
        
    }
    
    private let footerWrapper = UIView()
    
    private let footerLabel = UILabel().construct { it in
        it.textColor = UDColor.textPlaceholder
        it.font = UDFont.body2
    }
    
    private func subviewsInit() {
        clipsToBounds = true
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        headerWrapper.addSubview(headerLabel)
        headerLabel.snp.makeConstraints { make in
            make.height.equalTo(headerTextHeight)
            make.edges.equalToSuperview().inset(headerTextInset)
        }
        
        footerWrapper.addSubview(footerLabel)
        footerLabel.snp.makeConstraints { make in
            make.height.equalTo(footerTextHeight)
            make.edges.equalToSuperview().inset(footerTextInset)
        }
        
        stackView.addArrangedSubview(contentView)
    }
    
}
