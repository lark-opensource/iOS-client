//
// Created by maozhixiang.lip on 2022/8/3.
//

import Foundation
import ByteViewNetwork
import ByteViewUI

final class InterviewQuestionnaireWindow: FollowVcWindow {
    private static let shared = VCScene.createWindow(InterviewQuestionnaireWindow.self, tag: .prompt)

    static func show(_ info: InterviewQuestionnaireInfo, dependency: InterviewQuestionnaireDependency) {
        Util.runInMainThread { Self.shared.show(info, dependency: dependency) }
    }

    static func hide() {
        Util.runInMainThread { Self.shared.hide() }
    }

    private var viewController: InterviewQuestionnaireViewController?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupWindow()
    }

    @available(iOS 13.0, *)
    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        self.setupWindow()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setupWindow() {
        self.backgroundColor = .clear
        self.windowLevel = .interviewQuestionnaire
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hittableView = self.viewController?.hittableView else { return nil }
        let pointRelativeToHittableView = self.convert(point, to: hittableView)
        return hittableView.hitTest(pointRelativeToHittableView, with: event)
    }

    func show(_ info: InterviewQuestionnaireInfo, dependency: InterviewQuestionnaireDependency) {
        let controller = InterviewQuestionnaireViewController(viewModel: .init(info: info, dependency: dependency))
        controller.dismissAction = { [weak self] in self?.hide() }
        self.rootViewController = controller
        self.viewController = controller
        self.isHidden = false
    }

    func hide() {
        self.rootViewController = nil
        self.viewController = nil
        self.isHidden = true
    }
}
