//
//  MagicShareRuntimeLogic.swif
//  ByteView
//
//  Created by chentao on 2020/4/18.
//

import Foundation
import RxAutomaton
import RxSwift

class MagicShareRuntimeLogic {

    typealias State = MagicShareDocumentStatus
    typealias LogicProducer = () -> Observable<Input>

    enum Input {
        /// *Any* -> Sharing
        case startRecord
        /// Sharing -> Free
        case stopRecord
        /// *Any* -> Follow
        case startFollow
        /// Follow -> Free
        case stopFollow
        /// *Any but SSToMSFree* -> SSToMSFollow
        case startSSToMS
        /// SSToMSFollow -> SSToMSFree
        case stopSSToMS
    }

    let automation: Automaton<State, Input>
    let inputObserver: AnyObserver<Input>
    let stateObservable: Observable<State>

    var state: State {
        return automation.state.value
    }

    init(startRecordProducer: LogicProducer,
         stopRecordProducer: LogicProducer,
         startFollowProducer: LogicProducer,
         stopFollowProducer: LogicProducer) {
        // swiftlint:disable line_length operator_usage_whitespace
        let mappings: [Automaton<State, Input>.EffectMapping] = [
            /* Input     | fromState        =>  toState         | Effect */
            /* ---------------------------------------------------------------*/
            .startRecord | .following       => .sharing         | stopFollowProducer().concat(startRecordProducer()),
            .startRecord | .free            => .sharing         | startRecordProducer(),
            .startRecord | .sstomsFollowing => .sharing         | stopFollowProducer().concat(startRecordProducer()),
            .startRecord | .sstomsFree      => .sharing         | startRecordProducer(),
            .stopRecord  | .sharing         => .free            | stopRecordProducer(),
            .startFollow | .sharing         => .following       | stopRecordProducer().concat(startFollowProducer()),
            .startFollow | .free            => .following       | startFollowProducer(),
            .startFollow | .sstomsFollowing => .following       | stopFollowProducer().concat(startFollowProducer()),
            .startFollow | .sstomsFree      => .following       | startFollowProducer(),
            .stopFollow  | .following       => .free            | stopFollowProducer(),
            .startSSToMS | .sharing         => .sstomsFollowing | stopRecordProducer().concat(startFollowProducer()),
            .startSSToMS | .following       => .sstomsFollowing | stopFollowProducer().concat(startFollowProducer()),
            .startSSToMS | .free            => .sstomsFollowing | startFollowProducer(),
            .stopSSToMS  | .sstomsFollowing => .sstomsFree      | stopFollowProducer()
        ]
        // swiftlint:enable line_length operator_usage_whitespace
        let (inputSignal, inputObserver) = Observable<Input>.pipe()
        self.automation = Automaton(
            state: .free,
            input: inputSignal,
            mapping: reduce(mappings),
            strategy: .latest
        )
        self.inputObserver = inputObserver
        self.stateObservable = automation.state.asObservable()
    }
}
