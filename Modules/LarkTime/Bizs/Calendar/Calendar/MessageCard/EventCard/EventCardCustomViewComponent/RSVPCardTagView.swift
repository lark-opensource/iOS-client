//
//  RSVPCardTagView.swift
//  Calendar
//
//  Created by pluto on 2023/2/9.
//

import UIKit
import Foundation
import UniverseDesignColor
import UniverseDesignTag

enum RSVPCardTagType {
    case update
    case conflict
    case optional
    case externel
}

struct CalendarEventCardTag {
    var title: String
    var type: RSVPCardTagType
    var size: CGSize
    var font: UIFont
    
    public init (title: String, type: RSVPCardTagType, size: CGSize, font: UIFont) {
        self.title = title
        self.type = type
        self.size = size
        self.font = font
    }
}

final class RSVPCardTagView: UIView {

    private let tagView: UDTag = UDTag()
    
    init(tagString: String, tagType: RSVPCardTagType) {
        super.init(frame: .zero)
        
        tagView.text = tagString
        tagView.sizeClass = .mini
        
        configColorScheme(tagType: tagType)
        layoutTagView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configColorScheme(tagType: RSVPCardTagType) {
        switch tagType {
        case .update:
            tagView.colorScheme = .yellow
        case .conflict:
            tagView.colorScheme = .red
        case .optional:
            tagView.colorScheme = .normal
        case .externel:
            tagView.colorScheme = .blue
        }
    }
    
    private func layoutTagView() {
        addSubview(tagView)
        tagView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
