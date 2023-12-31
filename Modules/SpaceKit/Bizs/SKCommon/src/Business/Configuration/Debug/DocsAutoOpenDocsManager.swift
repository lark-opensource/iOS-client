//
//  DocsAutoOpenDocsManager.swift
//  SpaceKit
//
//  Created by lizechuang on 2019/12/19.
//

#if BETA || ALPHA || DEBUG
import Foundation
import EENavigator
import SpaceInterface
import SKInfra

class DocsAutoOpenDocsManager {

    class func manager(navigator: UIViewController) -> DocsAutoOpenDocsManager {
        return DocsAutoOpenDocsManager(navigator: navigator)
    }

    private var autoOpenDocsTypes:[(docsType: DocsType, isSelect: Bool)] = []

    private var isBeingOpenTest: Bool = false
    private var alreadyOpenDocsCount: Int = 0
    private weak var curOpenDocsVC: UIViewController?
    private var recordOpenDocsCountView: RecordOpenDocsCountView?
    private weak var targetVC: UIViewController!
    private let semaphore = DispatchSemaphore(value: 0)

    private init(navigator: UIViewController) {
        self.targetVC = navigator
        autoOpenDocsTypes = [(DocsType.doc, false),
                             (DocsType.sheet, false),
                             (DocsType.bitable, false),
                             (DocsType.mindnote, false),
                             (DocsType.slides, false)]
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiverOpenDocsEnd(info:)), name: Notification.Name.OpenFileRecord.AutoOpenEnd, object: nil)
    }

    public func beginAutoOpenDocs() {
        guard let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self) else {
            return
        }
        let recentFiles = dataCenterAPI.spaceEntries(for: .recent)
        let readyOpenFiles = teaseFileEntrys(fileEntrys: recentFiles)
        resetAutoOpenData()
        guard readyOpenFiles.count != 0 else {
            return
        }
        let count = readyOpenFiles.count
        recordOpenDocsCountView = RecordOpenDocsCountView(frame: targetVC.view.frame)
        recordOpenDocsCountView?.delegate = self
        recordOpenDocsCountView!.setupRecordData(title: "总共\(readyOpenFiles.count)篇文档", message: "已经打开\(alreadyOpenDocsCount)篇文档")
        targetVC.view.addSubview(recordOpenDocsCountView!)
        DispatchQueue.global().async {
            var i = 0
            while i >= 0 && i < count && self.isBeingOpenTest {
                if !self.isBeingOpenTest {
                    break
                }
                let readyOpenFile = readyOpenFiles[i]
                DispatchQueue.main.async {
                    let result = self.selectFile(readyOpenFile, fileList: readyOpenFiles)
                    self.curOpenDocsVC = result.0
                    self.targetVC.navigationController?.pushViewController(self.curOpenDocsVC!, animated: true)
                }
                i = self.loopIncrease(index: i, limitedCount: count - 1)
                self.semaphore.wait()
            }
            self.stopAutoOpenDocs()
            DispatchQueue.main.async {
                self.recordOpenDocsCountView?.removeFromSuperview()
            }
        }
    }
    
    private func loopIncrease(index: Int, limitedCount: Int) -> Int {
        if index < limitedCount {
            return index + 1
        } else {
            return 0
        }
    }

    private func selectFile(_ file: SpaceEntry, fileList: [SpaceEntry] = []) -> (UIViewController?, Bool) {
        FileListStatistics.curFileObjToken = file.objToken
        FileListStatistics.curFileType = file.type
        let context: [String: Any] = [SKEntryBody.fileEntryListKey: fileList]
        return SKRouter.shared.open(with: file, params: context)
    }

    @objc
    func didReceiverOpenDocsEnd(info: NSNotification) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
            guard self.curOpenDocsVC != nil else {
                return
            }
            self.targetVC.navigationController?.popViewController(animated: true)
            
            self.alreadyOpenDocsCount += 1
            self.recordOpenDocsCountView?.updateRecordData(message: "已经打开\(self.alreadyOpenDocsCount)篇文档")
            // 测试要求文档打开失败不停止测试
//            if let infoData =  info.object as? [String: Bool] {
//                if !(infoData["open_docs_result"] ?? true) {
//                    self.stopAutoOpenDocs()
//                    DispatchQueue.main.async {
//                        self.recordOpenDocsCountView?.removeFromSuperview()
//                    }
//                }
//            }
            self.semaphore.signal()
        }
    }

    private func teaseFileEntrys(fileEntrys: [SpaceEntry]) -> [SpaceEntry] {
        var curFileList: [SpaceEntry] = []
        let selectDocsTypes = obtainSelectDocsTypes()
        for fileEntry in fileEntrys {
            if selectDocsTypes.contains(fileEntry.type) {
                curFileList.append(fileEntry)
            }
        }
        return curFileList
    }

    private func resetAutoOpenData() {
        isBeingOpenTest = true
        alreadyOpenDocsCount = 0
    }

    private func stopAutoOpenDocs() {
        isBeingOpenTest = false
        alreadyOpenDocsCount = 0
    }

    private func obtainSelectDocsTypes() -> [DocsType] {
        var selectDocsTypes: [DocsType] = []
        for autoOpenDocsType in autoOpenDocsTypes where autoOpenDocsType.isSelect {
            selectDocsTypes.append(autoOpenDocsType.docsType)
        }
        if selectDocsTypes.count == 0 {
            selectDocsTypes.append(DocsType.doc)
        }
        return selectDocsTypes
    }

    public func obtainAutoOpenDocsTypes() -> [(docsType: DocsType, isSelect: Bool)] {
        return autoOpenDocsTypes
    }

    public func updateAutoOpenDocsTyep(_ selectIndex: Int) {
        if autoOpenDocsTypes[selectIndex].isSelect {
           autoOpenDocsTypes[selectIndex].isSelect = false
        } else {
            autoOpenDocsTypes[selectIndex].isSelect = true
        }
    }
}

extension DocsAutoOpenDocsManager: RecordOpenDocsCountViewDelegate {
    func clickOutSideView() {
        stopAutoOpenDocs()
    }
}

protocol RecordOpenDocsCountViewDelegate: AnyObject {
    func clickOutSideView()
}

class RecordOpenDocsCountView: UIView {

    private lazy var backgroundView: UIView = {
        let view = UIView().construct({
               $0.backgroundColor = .clear
        })
        return view
    }()
    private lazy var contentView: UIView = {
        let view = UIView().construct({
            $0.backgroundColor = UIColor.ud.N00
            $0.layer.masksToBounds = true
            $0.layer.cornerRadius = 10
        })
        return view
    }()
    private lazy var titleLabel: UILabel = {
         let label = UILabel().construct({
              $0.textColor = .black
              $0.textAlignment = .center
              $0.font = UIFont.systemFont(ofSize: 16)
         })
        return label
    }()
    private lazy var messageLabel: UILabel = {
        let label = UILabel().construct({
             $0.textColor = .black
             $0.textAlignment = .center
             $0.font = UIFont.systemFont(ofSize: 16)
        })
        return label
    }()

    weak var delegate: RecordOpenDocsCountViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
        setupLayout()
    }
    //移除recordOpenDocsCountView
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.first?.view != contentView {
            removeFromSuperview()
            self.delegate?.clickOutSideView()
        }
    }

    func setupRecordData(title: String, message: String) {
        titleLabel.text = title
        messageLabel.text = message
    }

    func updateRecordData(message: String) {
        messageLabel.text = message
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        addSubview(backgroundView)
        backgroundView.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(messageLabel)
    }

    private func setupLayout() {
        backgroundView.snp.makeConstraints {
            $0.left.top.right.bottom.equalToSuperview()
        }
        contentView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.height.equalTo(100)
            $0.width.equalTo(200)
        }
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(contentView).offset(10)
            $0.left.right.equalToSuperview()
        }
        messageLabel.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalTo(titleLabel).offset(15)
            $0.bottom.equalTo(contentView).offset(10)
        }
    }
}
#endif
