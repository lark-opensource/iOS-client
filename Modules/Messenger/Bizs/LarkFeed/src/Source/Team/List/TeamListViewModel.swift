//
//  TeamListViewModel.swift
//  LarkFeed
//
//  Created by chaishenghua on 2022/12/28.
//

import UIKit
import Foundation
import RustPB
import LarkSDKInterface
import LarkContainer
import RxSwift
import EENavigator
import UniverseDesignToast
import LarkMessengerInterface
import LarkUIKit
import LarkModel
import UniverseDesignDialog

class TeamListViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    var dataSource: [Basic_V1_Team] = [] {
        didSet {
            self.dataSourceSubject.onNext(self.dataSource)
        }
    }

    private let teamAPI: TeamAPI
    private let pushFeedPreview: Observable<PushFeedPreview>
    private var feedPreview: FeedPreview
    private let feedTeamViewModel: FeedTeamViewModelInterface
    let teamAction: TeamActionService
    private let disposeBag = DisposeBag()
    private var navigator: Navigatable { self.userResolver.navigator }
    let title: String = BundleI18n.LarkTeam.Project_T_AddToTeam_Title

    private let dataSourceSubject: BehaviorSubject<[Basic_V1_Team]> = BehaviorSubject<[Basic_V1_Team]>(value: [])
    var dataSourceObservable: Observable<[Basic_V1_Team]> {
        return dataSourceSubject.asObservable()
    }

    init(userResolver: UserResolver,
         teamAPI: TeamAPI,
         pushFeedPreview: Observable<PushFeedPreview>,
         feedPreview: FeedPreview,
         feedTeamViewModel: FeedTeamViewModelInterface,
         teamAction: TeamActionService) {
        self.userResolver = userResolver
        self.teamAPI = teamAPI
        self.pushFeedPreview = pushFeedPreview
        self.feedPreview = feedPreview
        self.feedTeamViewModel = feedTeamViewModel
        self.teamAction = teamAction
        bind()
    }

    private func updateData() {
        let teams = self.feedTeamViewModel.teamUIModel.teamModels.map { $0.teamEntity }
        self.dataSource = teams.compactMap { team -> Basic_V1_Team? in
            if self.feedPreview.chatFeedPreview?.teamEntity.joinedTeams[team.id] == nil {
                return team
            }
            return nil
        }
    }

    private func bind() {
        self.feedTeamViewModel.dataSourceObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
                self.updateData()
        }).disposed(by: self.disposeBag)

        self.pushFeedPreview
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] pushFeed in
                guard let self = self else { return }
                if let feedInfo = pushFeed.updateFeeds[self.feedPreview.id] {
                    self.feedPreview = feedInfo.feedPreview
                    self.updateData()
                }
            }).disposed(by: self.disposeBag)
    }

    func joinToTeamDialog(team: Basic_V1_Team, currentVC: UIViewController, isNewTeam: Bool) {
        self.teamAction.joinTeamDialog(team: team,
                                       feedPreview: self.feedPreview,
                                       on: currentVC,
                                       isNewTeam: isNewTeam) { [weak currentVC] in
            currentVC?.closeWith(animated: true)
        }
    }

    func createTeam(currentVC: UIViewController) {
        let body = CreateTeamBody { [weak self] team in
            guard let self = self else { return }
            self.joinToTeamDialog(team: team, currentVC: currentVC, isNewTeam: true)
        }
        navigator.present(body: body,
                          wrap: LkNavigationController.self,
                          from: currentVC,
                          prepare: {
            $0.modalPresentationStyle = .formSheet
        })
    }
}
