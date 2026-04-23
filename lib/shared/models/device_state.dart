enum DeviceConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  signalLost, // Used for the exponential backoff reconnect phase
}