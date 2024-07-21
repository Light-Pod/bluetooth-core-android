package dev.lightpod.bluetooth_core_android

import android.os.Build

open class FlutterException(
    val errorCode: String,
    val errorMessage: String,
    val errorDetails: Any?
) : Exception(errorMessage)

class UnsupportedOsVersionException(
    val expectedOsVersion: Int,
) : FlutterException(
    "UNSUPPORTED_OS_VERSION",
    "Expected OS version: $expectedOsVersion. Current OS Version: ${Build.VERSION.SDK_INT}",
    mapOf(
        "currentOsVersion" to Build.VERSION.SDK_INT,
        "expectedOsVersion" to expectedOsVersion,
    )
)

class SocketNotFoundException(
    val id: String,
) : FlutterException(
    "SOCKET_NOT_FOUND",
    "Unable to find socket",
    mapOf("socketId" to id)
)

class SocketConnectionFailedException() : FlutterException(
    "CONNECTION_FAILED",
    "Could not connect to device",
    null
)

class UnableToOpenOutputStream(errorDetails: Any) : FlutterException(
    "UNABLE_TO_OPEN_OUTPUT_STREAM",
    "Error occurred when opening output stream",
    errorDetails
)

class UnableToOpenInputStream(errorDetails: Any) : FlutterException(
    "UNABLE_TO_OPEN_INPUT_STREAM",
    "Error occurred when opening input stream",
    errorDetails
)
