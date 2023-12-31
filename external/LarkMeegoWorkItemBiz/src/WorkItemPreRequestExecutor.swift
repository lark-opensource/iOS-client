import LarkMeegoStrategy
import LarkMeegoStorage
import LarkContainer

final public class WorkItemPreRequestExecutor: PreRequestExecutor {
    public init(
        userResolver: UserResolver,
        userKvStorage: UserSharedKvStorage
    ) {
        super.init(
            userResolver: userResolver,
            userKvStorage: userKvStorage,
            scope: .detail
        )

        if let detailAPI = try? DetailPreRequestAPI(userResolver: userResolver) {
            preRequestAPIs.append(detailAPI)
        }
        if let workflowAPI = try? WorkflowPreRequestAPI(userResolver: userResolver) {
            preRequestAPIs.append(workflowAPI)
        }
    }
}
