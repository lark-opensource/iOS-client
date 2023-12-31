//
//  NotesWrapperViewController.swift
//  ByteView
//
//  Created by liurundong.henry on 2023/5/11.
//

import Foundation
import SnapKit
import ByteViewNetwork

final class NotesWrapperViewController: BaseViewController, UIGestureRecognizerDelegate {

    let notesRuntime: NotesRuntime
    let meeting: InMeetMeeting

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
    }

    init(notesRuntime: NotesRuntime, meeting: InMeetMeeting) {
        self.notesRuntime = notesRuntime
        self.meeting = meeting
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpUI() {
        view.backgroundColor = .ud.bgBody

        let documentVC = notesRuntime.documentVC
        addChild(documentVC)
        view.addSubview(documentVC.view)
        documentVC.didMove(toParent: self)

        documentVC.view.snp.remakeConstraints {
            $0.edges.equalToSuperview()
        }

        if documentVC !== notesRuntime.documentVC {
            Logger.notes.error("notesRuntime.documentVC changed during layout")
        }
    }

    override var shouldAutorotate: Bool {
        return notesRuntime.documentVC.shouldAutorotate
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        var mask = notesRuntime.documentVC.supportedInterfaceOrientations
        if !mask.contains(.portrait) { // 保证必有竖屏，原因是Lark里面有该保证
            mask.insert(.portrait)
        }
        return mask
    }

    deinit {
        Logger.notes.info("NotesWrapperVC.deinit")
        notesRuntime.documentVC.willMove(toParent: nil)
        notesRuntime.documentVC.view.removeFromSuperview()
        notesRuntime.documentVC.removeFromParent()
        notesRuntime.documentVC.didMove(toParent: nil)
    }
}
