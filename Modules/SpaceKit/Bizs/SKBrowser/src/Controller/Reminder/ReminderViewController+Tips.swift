//
//  ReminderViewController+Tips.swift
//  SKBrowser
//
//  Created by lijuyou on 2022/10/28.
//  


import Foundation

extension ReminderViewController {
    
    func setupInvalidTimeTipsItemView(isShow: Bool) {
        if isShow {
            let needAnimation = invalidTimeTipsItemView.isHidden
            invalidTimeTipsItemView.isHidden = false
            let height = invalidTimeTipsItemView.calcHeightWithPreferedWidth(self.view.frame.width)
            if invalidTimeTipsItemView.superview == nil {
                scrollView.addSubview(invalidTimeTipsItemView)
                invalidTimeTipsItemView.snp.makeConstraints { (make) in
                    make.top.equalTo(timePicker.snp.bottom).offset(height)
                    make.height.equalTo(height)
                    make.left.right.equalTo(view)
                }
                
            }
            
            if needAnimation {
                //需要动画时reset layout
                invalidTimeTipsItemView.snp.updateConstraints { make in
                    make.top.equalTo(timePicker.snp.bottom).offset(height)
                    make.height.equalTo(height)
                }
                self.scrollView.layoutIfNeeded()
                updateTipsViewLayout(isShow: true, height: height)
                UIView.animate(withDuration: 0.2) {
                    self.scrollView.layoutIfNeeded()
                }
            } else {
                updateTipsViewLayout(isShow: true, height: height)
            }
        } else {
            invalidTimeTipsItemView.isHidden = true
            updateTipsViewLayout(isShow: false, height: 0)
        }
    }
    
    func updateTipsViewLayout(isShow: Bool? = nil, height: CGFloat? = nil) {
        guard invalidTimeTipsItemView.superview != nil else { return }
        let isShow = isShow ?? !invalidTimeTipsItemView.isHidden
       
        if isShow {
            let height = height ?? invalidTimeTipsItemView.calcHeightWithPreferedWidth(self.view.frame.width)
            invalidTimeTipsItemView.snp.updateConstraints { make in
                make.height.equalTo(height)
                make.top.equalTo(timePicker.snp.bottom)
            }
        } else {
            invalidTimeTipsItemView.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
        }
    }
}
