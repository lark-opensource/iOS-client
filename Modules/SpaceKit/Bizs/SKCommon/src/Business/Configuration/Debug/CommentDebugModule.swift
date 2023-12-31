//
//  CommentDebugModule.swift
//  SKCommon
//
//  Created by huayufan on 2022/6/10.
//  


import UIKit
import SnapKit
import SKFoundation
import SKInfra

public final class CommentDebugModule {
    
#if BETA || ALPHA || DEBUG
    static let standard = CommentDebugModule()
    
    private var docLogs: [String] = []
    
    fileprivate weak var debugVC: CommentLogViewController?
    
    fileprivate lazy var dotView: CommentDebugDot = {
        let dot = CommentDebugDot(frame: CGRect(x: 100, y: 100, width: 45, height: 45))
        dot.doubleTap = { [weak self] in
            self?.showDebugVC()
        }
        return dot
    }()
    
    private var fmt: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS > "
        return dateFormatter
    }()
    
    var timeLog: String {
        return fmt.string(from: Date())
    }
    
    private func showDebugVC() {
        if debugVC == nil {
            self.dotView.isHidden = true
            let vc = CommentLogViewController()
            vc.logs = CommentDebugModule.standard.docLogs
            topMostVC()?.present(vc, animated: true, completion: nil)
            vc.closeDebugView = { [weak self] in
                self?.dotView.isHidden = false
            }
            debugVC = vc
        }
    }
    
    private func topMostVC() -> UIViewController? {
        let keyWindow = UIApplication.shared.keyWindow
        let topMostVc = UIViewController.docs.topMost(of: keyWindow?.rootViewController)
        return topMostVc
    }
    
    init() {}
#endif

    
    public static func begin() {
#if BETA || ALPHA || DEBUG
        let dotView = CommentDebugModule.standard.dotView
        guard CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.commentDebugValue) == true else {
            dotView.removeFromSuperview()
            return
        }
        let keyWindow = UIApplication.shared.keyWindow
        keyWindow?.bringSubviewToFront(dotView)
        guard dotView.superview == nil else {
            return
        }
        keyWindow?.addSubview(dotView)
#endif
    }
    
    public static func log(_ message: String) {
#if BETA || ALPHA || DEBUG
        guard CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.commentDebugValue) == true else { return }
        let ins = CommentDebugModule.standard
        ins.docLogs.append(ins.timeLog + message)
        ins.debugVC?.update(logs: CommentDebugModule.standard.docLogs)
#endif
    }
    
    public static func clear() {
#if BETA || ALPHA || DEBUG
        CommentDebugModule.standard.docLogs = []
#endif
    }
    
    public static var canDebug: Bool {
#if BETA || ALPHA || DEBUG
        return CCMKeyValue.globalUserDefault.bool(forKey: UserDefaultKeys.commentDebugValue)
#endif
        return false
    }
}

#if BETA || ALPHA || DEBUG
private class CommentDebugDot: UIView {
    
    var doubleTap: (() -> Void)?
    
    var textLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .cyan
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(gestureHandle))
        addGestureRecognizer(gesture)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapHandle))
        tap.numberOfTapsRequired = 2
        addGestureRecognizer(tap)
        
        if frame.width > 0 {
            self.layer.cornerRadius = self.bounds.size.width / 2.0
            self.clipsToBounds = true
        }
        
        textLabel.textColor = .white
        textLabel.font = UIFont.systemFont(ofSize: 35)
        textLabel.text = "X"
        addSubview(textLabel)
        textLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func doubleTapHandle(gesture: UITapGestureRecognizer) {
        if gesture.state == .ended {
            doubleTap?()
        }
    }
    
    @objc
    private func gestureHandle(gesture: UIPanGestureRecognizer) {
        guard let superview = superview else { return }
        let location = gesture.location(in: superview)
        guard let dragView = gesture.view else { return }
        let w = dragView.bounds.size.width
        if location.x + w > superview.bounds.width ||
            location.x - 2 < 0 {
            dragView.center = CGPoint(x: dragView.center.x, y: location.y)
        } else {
            dragView.center = location
        }
        viewDraggedHandler(gesture, draggableView: dragView)
    }
       
       private func viewDraggedHandler(_ gesture: UIPanGestureRecognizer, draggableView: UIView?) {
           guard let superview = superview else { return }
           if gesture.state == .ended {
               if self.frame.midX >= superview.layer.frame.width / 2 {
                   UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                       self.center.x = superview.layer.frame.width - 40
                   }, completion: nil)
               } else {
                   UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseIn, animations: {
                       self.center.x = 40
                   }, completion: nil)
               }
           }
       }
}


private class CommentLogViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    class DebugCell: UITableViewCell {
        
        var logLabel = UILabel()
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            backgroundColor = .clear
            addSubview(logLabel)
            logLabel.textColor = .black
            logLabel.font = UIFont.systemFont(ofSize: 15)
            logLabel.numberOfLines = 0
            logLabel.backgroundColor = .clear
            logLabel.snp.makeConstraints { (make) in
                make.edges.equalToSuperview().inset(12)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    var logs: [String] = []
    
    var textColor = UIColor.black
    
    var pause: Bool = false
    
    var closeDebugView: (() -> Void)?
     
    lazy var tableView: UITableView = {
        let tbView = UITableView()
        tbView.dataSource = self
        tbView.delegate = self
        tbView.separatorStyle = .none
        tbView.backgroundColor = .clear
        tbView.register(DebugCell.self, forCellReuseIdentifier: "DebugCell")
        return tbView
    }()
    
    func update(logs: [String]) {
        guard pause == false else { return }
        self.logs = logs
        self.tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let titleView = UIView()
        titleView.backgroundColor = .white
        titleView.layer.borderWidth = 1
        titleView.layer.borderColor = UIColor.gray .cgColor
        view.addSubview(titleView)
        
        let closeBtn = UIButton()
        closeBtn.setTitle("close me", for: .normal)
        closeBtn.backgroundColor = UIColor.systemBlue
        closeBtn.layer.cornerRadius = 4
        closeBtn.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        titleView.addSubview(closeBtn)
        
        let switchColorBtn = UISwitch()
        switchColorBtn.addTarget(self, action: #selector(switchAction(sender:)), for: .valueChanged)
        titleView.addSubview(switchColorBtn)
        
        let switchStop = UISwitch()
        switchStop.addTarget(self, action: #selector(stopAction(sender:)), for: .valueChanged)
        titleView.addSubview(switchStop)
        
        titleView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(60)
        }
        
        closeBtn.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(10)
            make.size.equalTo(CGSize(width: 100, height: 40))
            make.top.equalToSuperview().offset(10)
        }
        
        switchColorBtn.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
        }
        
        switchStop.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(titleView.snp.bottom)
            make.left.right.bottom.equalToSuperview().inset(12)
        }
        tableView.reloadData()
        view.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.4)
    }
    
    @objc
    func closeAction() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc
    func switchAction(sender: UISwitch) {
        view.backgroundColor = sender.isOn ? UIColor.white: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.4)
        tableView.reloadData()
    }
    
    @objc
    func stopAction(sender: UISwitch) {
        pause = sender.isOn
    }

    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logs.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "DebugCell", for: indexPath) as? DebugCell {
            cell.logLabel.text = logs[indexPath.row]
            cell.logLabel.textColor = self.textColor
            return cell
        }
        return UITableViewCell()
    }
    
    deinit {
        closeDebugView?()
    }
}

#endif
