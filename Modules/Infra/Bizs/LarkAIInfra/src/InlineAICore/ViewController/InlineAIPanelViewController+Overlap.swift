//
//  InlineAIPanelViewController+Overlap.swift
//  LarkInlineAI
//
//  Created by huayufan on 2023/5/10.
//  


import Foundation

extension InlineAIPanelViewController {
    
    func showOverlapPromptViewIfNeed(prompt: InlineAIPanelModel.Prompts?) {
        guard let prompt = prompt,
              prompt.show,
              !prompt.data.isEmpty,
              prompt.overlap else {
            dismissOverlapPromptView()
            return
        }
        let firstTimeShow = overlapPromptView.superview == nil
        
        lazyAddOverlapPromptView()
        
        setOverlapPromptView(hidden: false)
        
        mainPanelView.textInputView.update(fullRoundedcorners: false)

        // 确定最大高度
        var maxHeight: CGFloat
        if viewModel.keyBoardHeight > 0 {
            // 如果有结果页
            maxHeight = maxPanelHeightWhenKeyboardShow(with: keyboardInset)
        } else {
            maxHeight = defaultHeight
        }
        overlapPromptView.update(groups: prompt)
        let updateHeight = updateOverlapPromptConstraint(maxHeight: maxHeight)
    
        guard let height = updateHeight else { return }
        
        // 先隐藏在底部不展示
        self.overlapPromptView.updatPromptView(bottom: height)
        
        // 如果是第一次展示，要等布局稳定后再做动画
        if firstTimeShow {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.25) {
                    self.overlapPromptView.updatPromptView(bottom: 0)
                    self.view.layoutIfNeeded()
                }
            }
        } else {
            UIView.animate(withDuration: 0.25) {
                self.overlapPromptView.updatPromptView(bottom: 0)
                self.view.layoutIfNeeded()
            }
        }
    }
    
    private func lazyAddOverlapPromptView() {
        if overlapPromptView.superview == nil {
            view.addSubview(overlapPromptView)
            overlapPromptView.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(6)
                make.top.equalToSuperview()
                make.bottom.equalTo(self.mainPanelView.textInputView.snp.top)
            }
        }
        if overlapMaskView.superview == nil {
            view.addSubview(overlapMaskView)
            view.sendSubviewToBack(overlapMaskView)
            overlapMaskView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }

    func dismissOverlapPromptView() {
        guard self.overlapPromptView.show else { return }
        let height = self.overlapPromptView.getOverlapPromptHeight()
        UIView.animate(withDuration: 0.25) {
            self.overlapPromptView.updatPromptView(bottom: height)
            self.overlapPromptView.layoutIfNeeded()
        } completion: { _ in
            self.setOverlapPromptView(hidden: true)
        }
    }
    
    func setOverlapPromptView(hidden: Bool) {
        if hidden {
            self.mainPanelView.overlapMaskView.alpha = 0
            self.overlapPromptView.alpha = 0
            self.overlapMaskView.alpha = 0
            self.overlapPromptView.show = false
        } else {
            self.mainPanelView.overlapMaskView.alpha = 1
            self.overlapPromptView.alpha = 1
            self.overlapMaskView.alpha = 1
            self.overlapPromptView.show = true
        }
    }
    
    /// 传入面板可以展示最高的长度用于更新overlapPromptView的最大高度
    @discardableResult
    func updateOverlapPromptConstraint(maxHeight: CGFloat) -> CGFloat? {
        guard overlapPromptView.show else { return nil }
        return overlapPromptView.update(maxHeight: maxHeight - mainPanelView.getTextViewHeight())
    }
}
