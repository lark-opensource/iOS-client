import LarkMeegoStrategy
import LarkMeegoStorage
import LarkContainer

final public class SingleViewPreRequestExecutor: PreRequestExecutor {
    public init(
        userResolver: UserResolver,
        userKvStorage: UserSharedKvStorage
    ) {
        super.init(
            userResolver: userResolver,
            userKvStorage: userKvStorage,
            scope: .singleView
        )

        if let singleViewAPI = try? SingleViewPreRequestAPI(userResolver: userResolver) {
            preRequestAPIs.append(singleViewAPI)
        }
    }
}
