#include "app_runtime.h"

#include <atomic>
#include <chrono>
#include <mutex>
#include <thread>

namespace {

class AppRuntime {
public:
    int init()
    {
        std::lock_guard<std::mutex> lock(snapshot_mutex_);
        snapshot_ = {};
        snapshot_.connected = true;
        return 0;
    }

    int start()
    {
        bool expected = false;
        if(!running_.compare_exchange_strong(expected, true)) {
            return 0;
        }

        stop_requested_.store(false);
        worker_thread_ = std::thread(&AppRuntime::worker_loop, this);
        return 0;
    }

    void stop()
    {
        if(!running_.load()) {
            return;
        }

        stop_requested_.store(true);
        if(worker_thread_.joinable()) {
            worker_thread_.join();
        }

        running_.store(false);
    }

    void get_snapshot(app_snapshot_t * out_snapshot)
    {
        if(out_snapshot == nullptr) {
            return;
        }

        std::lock_guard<std::mutex> lock(snapshot_mutex_);
        *out_snapshot = snapshot_;
    }

private:
    void worker_loop()
    {
        while(!stop_requested_.load()) {
            {
                std::lock_guard<std::mutex> lock(snapshot_mutex_);
                snapshot_.myvar1 += 1;
                snapshot_.heartbeat += 1;
            }

            std::this_thread::sleep_for(std::chrono::milliseconds(500));
        }
    }

    std::atomic<bool> running_ { false };
    std::atomic<bool> stop_requested_ { false };
    std::mutex snapshot_mutex_;
    std::thread worker_thread_;
    app_snapshot_t snapshot_ {};
};

AppRuntime & runtime_instance()
{
    static AppRuntime runtime;
    return runtime;
}

} /* namespace */

extern "C" int app_runtime_init(void)
{
    return runtime_instance().init();
}

extern "C" int app_runtime_start(void)
{
    return runtime_instance().start();
}

extern "C" void app_runtime_stop(void)
{
    runtime_instance().stop();
}

extern "C" void app_runtime_get_snapshot(app_snapshot_t * out_snapshot)
{
    runtime_instance().get_snapshot(out_snapshot);
}
