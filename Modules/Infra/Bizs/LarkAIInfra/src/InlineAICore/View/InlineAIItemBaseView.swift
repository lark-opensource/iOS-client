//
//  InlineAIItemBaseView.swift
//  LarkInlineAI
//
//  Created by GuoXinyi on 2023/4/25.
//


import Foundation
import UIKit
import UniverseDesignColor
import RxSwift
import RxCocoa
import RxRelay

class InlineAIItemBaseView: UIView {
    
    var eventRelay = PublishRelay<InlineAIEvent>()
    
    var show: Bool = false {
        didSet {
            self.isHidden = !show
        }
    }
    
    private(set) var didPresent: Bool = false
    
    weak var aiPanelView: UIView?
    
    var panelWidth: CGFloat?

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        backgroundColor = UIColor.clear
    }
    
    func setupBottomRoundedCorner(showCorner: Bool) {
        if showCorner {
            layer.maskedCorners = .bottom
            layer.cornerRadius = 8
        } else {
            layer.cornerRadius = 0
            layer.maskedCorners = []
        }
    }
    
    func setupTopRoundedCorner(showCorner: Bool) {
        if showCorner {
            layer.maskedCorners = .top
            layer.cornerRadius = 8
        } else {
            layer.cornerRadius = 0
            layer.maskedCorners = []
        }
    }
    
    func didPresentCompletion() {
        self.didPresent = true
    }
    
    func didDismissCompletion() {
        self.show = false
        self.didPresent = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
