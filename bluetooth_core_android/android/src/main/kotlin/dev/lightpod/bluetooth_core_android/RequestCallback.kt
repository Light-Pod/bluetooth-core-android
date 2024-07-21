package dev.lightpod.bluetooth_core_android

import java.util.concurrent.ConcurrentHashMap


// TODO: what if exceeeds: 2147483647

class RequestCallback<T> {
    private val callbacks = ConcurrentHashMap<Int, T>()

    companion object {
        var id: Int = 0;
    }

    fun addRequest(result: T): Int {
        val requestId = id++;
        callbacks[requestId] = result;
        return requestId;
    }

    fun pop(requestCode: Int): T? {
        return callbacks.remove(requestCode);
    }
}