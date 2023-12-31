//
//  BTURLEditBoardManagerView.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/4/19.
//  

import UIKit


protocol BTURLEditBoardManagerViewDelegate: AnyObject {
    func getHandlerWhenTapAtLocationToWindow(_ location: CGPoint) -> (() -> Void)
}


final class BTURLEditBoardManagerView: UIView {
    
    weak var delegate: BTURLEditBoardManagerViewDelegate?
    
    let editBoardView: BTURLEditBoardView
    
    init(frame: CGRect, baseContext: BaseContext?) {
        self.editBoardView = BTURLEditBoardView(frame: .zero, baseContext: baseContext)
        super.init(frame: frame)
        addSubview(editBoardView)
        self.backgroundColor = .clear
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(handleTapGR(_:)))
        self.addGestureRecognizer(tapGR)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(data: BTURLEditBoardViewModel, superView: UIView) {
        editBoardView.updateData(data)
        superView.addSubview(self)
        self.frame = superView.bounds
        editBoardView.frame = CGRect(x: 0, y: self.frame.height, width: self.frame.width, height: BTFieldLayout.Const.urlEditBoardHeight)
        editBoardView.focusFirstTextField()
    }
    
    func hide() {
        editBoardView.endEditing(true)
        self.removeFromSuperview()
    }
    
    /// 设置编辑面板内容到底部的距离
    func setEditBoardBottom(_ bottom: CGFloat, animated: Bool = true) {
        UIView.animate(withDuration: animated ? 0 : 0.25) {
            self.editBoardView.frame.origin.y = self.frame.height - bottom - BTFieldLayout.Const.urlEditBoardHeight
        }
    }
    
    @objc
    private func handleTapGR(_ tapGR: UITapGestureRecognizer) {
        let location = tapGR.location(in: self)
        let locationToWindow = self.convert(location, to: self.window)
        let handler = delegate?.getHandlerWhenTapAtLocationToWindow(locationToWindow)
        editBoardView.delegate?.urlEditBoardDidCancel(isByClose: false)
        // 这里的 handle 要在 cancel 前算出来，是因为 cancel 后可能获取到的视图点不匹配。
        handler?()
    }
}
