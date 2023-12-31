///*
// * @Author       : mark
// * @Date         : 2020-06-16
// * @copyleft Apache 2.0
// */
//#ifndef SMARTMOVIEDEMO_BLOCKDEQUE_H
//#define SMARTMOVIEDEMO_BLOCKDEQUE_H
//
//#include <string>
//#include <mutex>
//#include <deque>
//#include <condition_variable>
//#include <sys/time.h>
//
//namespace TemplateConsumer {
//
//    template<class T>
//    class BlockDeque {
//    public:
//        explicit BlockDeque(size_t maxCapacity = 10);
//
//        ~BlockDeque();
//
//        void clear();
//
//        bool empty();
//
//        bool full();
//
//        void close();
//
//        size_t size();
//
//        size_t capacity();
//
//        T front();
//
//        T back();
//
//        void push_back(const T &item);
//
//        void push_front(const T &item);
//
//        bool pop(T &item);
//
//        bool pop(T &item, int timeout);
//
//        void flush();
//
//    private:
//        std::deque<T> deq_;
//
//        size_t capacity_;
//
//        std::mutex mtx_;
//
//        bool isClose_;
//
//        std::condition_variable condConsumer_;
//
//        std::condition_variable condProducer_;
//    };
//}
//#endif // SMARTMOVIEDEMO_BLOCKDEQUE_H