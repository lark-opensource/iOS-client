//
// Created by bytedance on 2021/6/25.
//

#ifndef DAVINCIRESOURCE_ID_GENERATOR_H
#define DAVINCIRESOURCE_ID_GENERATOR_H
#include <atomic>
namespace davinci {
    namespace executor {
        class IDGenerator {
        private:
            IDGenerator() = default;

            ~IDGenerator() = default;

            std::atomic<int64_t> idGenerator{0};

        public:
            IDGenerator(const IDGenerator &) = delete;

            IDGenerator &operator=(const IDGenerator &) = delete;

            static IDGenerator &get();

            int64_t generateId();
        };
    }
}
#endif //DAVINCIRESOURCE_ID_GENERATOR_H
