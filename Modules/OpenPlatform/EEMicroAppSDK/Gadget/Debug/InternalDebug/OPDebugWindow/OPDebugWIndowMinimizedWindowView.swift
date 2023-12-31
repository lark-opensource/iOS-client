//
//  OPDebugWIndowMinimizedWindowView.swift
//  OPSDK
//
//  Created by 尹清正 on 2021/2/3.
//

import UIKit
import OPSDK
import OPFoundation

fileprivate let debugInfoFormatStr = "CPU: %.2f%%\n内存: %.2fM\nFree Mem: %.0fM\n帧率：%.0ffps"


/// 调试窗口最小化窗口状态时的View，可以拖拽以移动位置，也可以长按最大化调试窗口
class OPDebugWindowMinimizedWindowView: UILabel {
    // MARK: - delegates: 代理

    weak var displayTypeDelegate: OPDebugCommandWindowDisplayTypeDelegate?
    weak var moveDelegate: OPDebugCommandWindowMoveDelegate?

    private weak var timer: Timer?
    
    // MARK: -  initializers: 初始化方法

    override init(frame: CGRect) {
        super.init(frame: frame)

        text = debugText(0, 0, 0,0)
        font = .systemFont(ofSize: 11, weight: .medium)
        textAlignment = .center
        textColor = .black
        numberOfLines = 0
        backgroundColor = UIColor.systemTeal

        isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(longPress(_:)))
        addGestureRecognizer(tapGesture)

        // 创建timer，定时更新debug数据
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            let cpuUsage = OPPerformanceHelper.cpuUsage
            let memory = OPPerformanceHelper.usedMemoryInMB
            let fps = OPPerformanceHelper.fps
            let availableMemory = OPPerformanceHelper.availableMemory
            self.text = self.debugText(cpuUsage, memory,availableMemory, fps)
        }
        RunLoop.current.add(timer, forMode: .common)
        timer.fire()
        self.timer = timer

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - user interface responder: 用户交互响应

    @objc func longPress(_ sender: UIGestureRecognizer) {
        displayTypeDelegate?.maximize()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        moveDelegate?.touchBegan(touches.randomElement())
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        moveDelegate?.touchMoved(touches.randomElement())
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        moveDelegate?.touchEnded(touches.randomElement())
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        moveDelegate?.touchEnded(touches.randomElement())
    }

    // MARK: - 工具方法

    private func debugText(_ cpu: Float, _ mem: Float,_ availableMemory:Float, _ fps: Float) -> String {
        let debugStr = String(format: debugInfoFormatStr, cpu, mem,availableMemory, fps)
        return debugStr
    }


}
