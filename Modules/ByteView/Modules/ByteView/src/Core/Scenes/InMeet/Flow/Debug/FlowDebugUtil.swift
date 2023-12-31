//
//  DebugUtil.swift
//  ByteView
//
//  Created by chentao on 2020/5/14.
//

#if DEBUG

import UIKit
import SnapKit
import UniverseDesignIcon

final class FlowDebugUtil {
    static func setupDebugView(on view: UIView, meeting: InMeetMeeting) {
        let oldView = view.subviews.first(where: { $0 is FlowDebugView })
        if meeting.storage.bool(forKey: .meetingWindow) {
            if oldView != nil { return }
            let debugView = FlowDebugView()
            debugView.update(meeting)
            view.addSubview(debugView)
            debugView.snp.makeConstraints { (make) in
                make.top.equalToSuperview().offset(100)
                make.width.equalTo(100)
            }
        } else if let debug = oldView {
            debug.removeFromSuperview()
        }
    }
}

private class FlowDebugView: FloatingContainerView {

    private func configureDisplayLink() {
        self.displayLink = CADisplayLink(target: TargetProxy(target: self),
                                         selector: #selector(TargetProxy.displayLinkAction))
        self.displayLink.preferredFramesPerSecond = 1
        self.displayLink?.add(to: .current, forMode: .common)
    }

    class TargetProxy {
        private weak var target: FlowDebugView?

        init(target: FlowDebugView) {
            self.target = target
        }
        @objc
        func displayLinkAction() {
            target?.takePerformanceEvidence()
        }
    }

    private func takePerformanceEvidence() {
        let cpuUsage = Performance.cpuUsage * 100
        let cpuColor: UIColor
        if cpuUsage > 85 {
            cpuColor = UIColor.ud.R600
        } else if cpuUsage > 60 {
            cpuColor = UIColor.ud.Y900
        } else {
            cpuColor = UIColor.ud.N800
        }
        cpuLabel.backgroundColor = cpuColor.withAlphaComponent(0.6)
        cpuLabel.text = String(format: "cpu: %.1f", cpuUsage)

        let memoryUsage = Double(Performance.memoryUsage) / 1024 / 1024
        let memoryColor: UIColor
        if memoryUsage > 600 {
            memoryColor = UIColor.ud.R600
        } else if memoryUsage > 400 {
            memoryColor = UIColor.ud.Y900
        } else {
            memoryColor = UIColor.ud.N800
        }
        memoryLabel.backgroundColor = memoryColor.withAlphaComponent(0.6)
        memoryLabel.text = String(format: "memory: %.1f", memoryUsage)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(closeButton)
        addSubview(cpuLabel)
        addSubview(memoryLabel)
        addSubview(meetingLabel)
        addSubview(rtcEnvironmentLabel)
        closeButton.snp.makeConstraints { (make) in
            make.right.top.equalToSuperview()
            make.width.height.equalTo(24)
        }
        cpuLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(closeButton.snp.bottom)
        }
        memoryLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(cpuLabel.snp.bottom)
        }
        meetingLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(memoryLabel.snp.bottom)
        }
        rtcEnvironmentLabel.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(meetingLabel.snp.bottom)
        }

        configureDisplayLink()
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(gestureReconizer:)))
        addGestureRecognizer(longPress)
    }

    private weak var service: MeetingBasicService?
    func update(_ meeting: InMeetMeeting) {
        self.meetingId = meeting.meetingId
        self.service = meeting.service
        meetingLabel.text = "meetingId:\n\(meeting.meetingId)"
        rtcEnvironmentLabel.text = "vendor: \(meeting.info.vendorType)"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var cpuLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()

    private lazy var memoryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()

    private lazy var meetingLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.ud.N800.withAlphaComponent(0.6)
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()

    lazy var rtcEnvironmentLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.ud.N800.withAlphaComponent(0.6)
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.closeOutlined, iconColor: .ud.primaryOnPrimaryFill, size: CGSize(width: 24, height: 24)), for: .normal)
        button.addTarget(self, action: #selector(didTapClose(_:)), for: .touchUpInside)
        return button
    }()

    private var displayLink: CADisplayLink!
    private lazy var menuFixer = MenuFixer(targetWindowProvider: { [weak self] in
        return self?.window
    })

    @objc
    private func longPress(gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state == .began {
            _ = menuFixer
            becomeFirstResponder()
            let item = UIMenuItem(title: "复制会议ID", action: #selector(copyText))
            UIMenuController.shared.menuItems = [item]
            var frame = self.meetingLabel.frame
            frame.origin = CGPoint(x: frame.origin.x, y: frame.origin.y + frame.size.height)
            UIMenuController.shared.setTargetRect(frame, in: self)
            UIMenuController.shared.setMenuVisible(true, animated: true)
        }
    }

    @objc
    private func copyText(menu: UIMenuController) {
        if let meetingId = meetingId {
            self.service?.security.copy(meetingId, token: .debugToken)
        }
    }

    @objc
    private func didTapClose(_ sender: UIButton) {
        removeFromSuperview()
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(copyText)
    }

    var meetingId: String?

    deinit {
        displayLink.invalidate()
    }
}

private class FloatingContainerView: UIView {

    private var lastLocation: CGPoint = .zero

    var movableRegion: CGRect = {
        let statusBar = UIApplication.shared.statusBarFrame.height
        let screenFrame = UIScreen.main.bounds
        return CGRect(x: 0, y: statusBar, width: screenFrame.width, height: screenFrame.height - statusBar)
    }() {
        didSet {
            recoverSizeIfNeed()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isExclusiveTouch = true
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handPan))
        addGestureRecognizer(pan)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc
    private func handPan(_ pan: UIPanGestureRecognizer) {
        let newLocation = pan.location(in: pan.view)
        switch pan.state {
        case .possible:
            break
        case .began:
            lastLocation = newLocation
        case .changed:
            handPanChanged(location: newLocation)
        case .ended, .cancelled, .failed:
            recoverSizeIfNeed()
        @unknown default:
            break
        }
    }

    private func handPanChanged(location: CGPoint) {
        let dx = location.x - lastLocation.x
        let dy = location.y - lastLocation.y
        var newFrame = self.frame
        newFrame.origin.x += dx
        newFrame.origin.y += dy
        self.frame = newFrame
    }

    private func recoverSizeIfNeed() {
        let originFrame = self.frame
        var newFrame = originFrame
        if newFrame.midX > movableRegion.midX {
            newFrame.origin.x = movableRegion.maxX - newFrame.width
        } else {
            newFrame.origin.x = movableRegion.minX
        }

        if newFrame.minY < movableRegion.minY {
            newFrame.origin.y = movableRegion.minY
        } else if newFrame.maxY > movableRegion.maxY {
            newFrame.origin.y = movableRegion.maxY - newFrame.height
        }
        guard newFrame != originFrame else {
            return
        }
        // nolint-next-line: magic number
        UIView.animate(withDuration: 0.25,
                       delay: 0.0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 0.0,
                       options: [],
                       animations: { [weak self] in
                        self?.frame = newFrame
                       })
    }
}

extension FlowDebugView {
    class Performance {
        private static let taskVmInfoCount = MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size
        private static let threadBasicInfoCount = MemoryLayout<thread_basic_info>.size / MemoryLayout<integer_t>.size

        static var memoryUsage: Int64 {
            var info = task_vm_info_data_t()
            var count = mach_msg_type_number_t(taskVmInfoCount)
            let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: integer_t.self, capacity: taskVmInfoCount) {
                    task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
                }
            }

            if kerr == KERN_SUCCESS {
                return Int64(info.phys_footprint)
            }
            return 0
        }

        static var cpuUsage: Double {
            var arr: thread_act_array_t?
            var threadCount: mach_msg_type_number_t = 0
            guard task_threads(mach_task_self_, &arr, &threadCount) == KERN_SUCCESS,
                  let threads = arr else {
                      return 0.0
                  }

            defer {
                let size = MemoryLayout<thread_t>.size * Int(threadCount)
                vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads), vm_size_t(size))
            }

            var cpuUsage = 0.0
            for i in 0..<Int(threadCount) {
                var info = thread_basic_info()
                var infoCount = mach_msg_type_number_t(threadBasicInfoCount)
                let kerr = withUnsafeMutablePointer(to: &info) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: threadBasicInfoCount) {
                        thread_info(threads[i], thread_flavor_t(THREAD_BASIC_INFO), $0, &infoCount)
                    }
                }
                guard kerr == KERN_SUCCESS else {
                    return 0.0
                }
                if info.flags & TH_FLAGS_IDLE == 0 {
                    cpuUsage += Double(info.cpu_usage) / Double(TH_USAGE_SCALE)
                }
            }
            return cpuUsage
        }
    }
}

#endif
