//
//  BTCardLayoutSettingView.swift
//  SKBitable
//
//  Created by zhysan on 2023/1/10.
//

import UIKit
import SnapKit

final class BTCardLayoutSettingView: UIView {
    
    // MARK: - public
    
    let styleSTView = BTCardLayoutColumnView()
    
    let titleSTView = BTCardLayoutTitleView()
    
//    let coverSTView = BTCardLayoutCoverView()
    
    let displayFieldSTView = BTCardLayoutDisplayFieldView()
    
    let moreFieldSTView = BTCardLayoutMoreFieldView()
    
    func update(_ settings: BTCardLayoutSettings) {
        // update styleSTView
        if let columnSection = settings.column {
            stackView.addArrangedSubview(styleSTView)
            styleSTView.update(columnSection)
        } else {
            stackView.removeArrangedSubview(styleSTView)
            styleSTView.removeFromSuperview()
        }
        
        // update titleSTView
        if let titleSection = settings.titleAndCover {
            stackView.addArrangedSubview(titleSTView)
            titleSTView.update(titleSection)
        } else {
            stackView.removeArrangedSubview(titleSTView)
            titleSTView.removeFromSuperview()
        }
        
        // update coverSTView
//        if let coverSection = settings.cover {
//            stackView.addArrangedSubview(coverSTView)
//            coverSTView.update(coverSection)
//        } else {
//            stackView.removeArrangedSubview(coverSTView)
//            coverSTView.removeFromSuperview()
//        }
        
        // update displayFieldSTView
        stackView.addArrangedSubview(displayFieldSTView)
        displayFieldSTView.update(settings.display)
        
        // update moreFieldSTView
        stackView.addArrangedSubview(moreFieldSTView)
        moreFieldSTView.update(settings.more)
    }
    
    // MARK: - life cycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - private
    
    private lazy var stackView: UIStackView = {
        let children = [styleSTView, titleSTView, displayFieldSTView, moreFieldSTView]
        let vi = UIStackView(arrangedSubviews: children)
        vi.axis = .vertical
        vi.spacing = 16.0
        return vi
    }()
    
    private func subviewsInit() {
        clipsToBounds = true
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
    }
}
