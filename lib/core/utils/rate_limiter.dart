/// Rate limiter for AniList API requests
/// 
/// AniList currently has a limit of 30 requests per minute
/// (normally 90, but temporarily reduced due to infrastructure issues)
/// 
/// See: https://docs.anilist.co/guide/rate-limiting
class RateLimiter {
  static const int maxRequestsPerMinute = 30;
  static const Duration timeWindow = Duration(minutes: 1);
  
  final List<DateTime> _requestTimestamps = [];
  
  /// Check if we can make a request now
  bool canMakeRequest() {
    _cleanOldRequests();
    return _requestTimestamps.length < maxRequestsPerMinute;
  }
  
  /// Record that a request was made
  void recordRequest() {
    _requestTimestamps.add(DateTime.now());
  }
  
  /// Get how long to wait before next request (in milliseconds)
  /// Returns 0 if can make request immediately
  int getWaitTimeMs() {
    _cleanOldRequests();
    
    if (_requestTimestamps.length < maxRequestsPerMinute) {
      return 0;
    }
    
    // Calculate when the oldest request will expire
    final oldestRequest = _requestTimestamps.first;
    final expiryTime = oldestRequest.add(timeWindow);
    final now = DateTime.now();
    
    if (expiryTime.isAfter(now)) {
      return expiryTime.difference(now).inMilliseconds;
    }
    
    return 0;
  }
  
  /// Wait until we can make a request
  Future<void> waitForSlot() async {
    final waitTime = getWaitTimeMs();
    if (waitTime > 0) {
      print('Rate limit reached. Waiting ${waitTime}ms before next request...');
      await Future.delayed(Duration(milliseconds: waitTime + 100)); // Add 100ms buffer
    }
  }
  
  /// Make a request with rate limiting
  /// 
  /// Usage:
  /// ```dart
  /// final result = await rateLimiter.execute(() async {
  ///   return await apiClient.query(...);
  /// });
  /// ```
  Future<T> execute<T>(Future<T> Function() request) async {
    await waitForSlot();
    recordRequest();
    return await request();
  }
  
  /// Remove requests older than the time window
  void _cleanOldRequests() {
    final now = DateTime.now();
    final cutoffTime = now.subtract(timeWindow);
    
    _requestTimestamps.removeWhere((timestamp) => timestamp.isBefore(cutoffTime));
  }
  
  /// Get current request count in the time window
  int get currentRequestCount {
    _cleanOldRequests();
    return _requestTimestamps.length;
  }
  
  /// Get remaining requests in current window
  int get remainingRequests {
    _cleanOldRequests();
    return maxRequestsPerMinute - _requestTimestamps.length;
  }
  
  /// Reset the rate limiter (for testing)
  void reset() {
    _requestTimestamps.clear();
  }
}
