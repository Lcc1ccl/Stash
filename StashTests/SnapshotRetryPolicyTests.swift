import Testing
@testable import Stash

struct SnapshotRetryPolicyTests {
    @Test
    func snapshotSuccessTransitionsToSucceeded() async throws {
        try await Task.sleep(nanoseconds: 1_000_000)
        let status = SnapshotRetryPolicy.nextStatus(after: .success, attemptCount: 1)
        #expect(status == .succeeded)
        #expect(SnapshotRetryPolicy.message(for: .success, attemptCount: 1) == nil)
    }
    
    @Test
    func snapshotTimeoutBeforeLimitKeepsPending() async throws {
        try await Task.sleep(nanoseconds: 1_000_000)
        let status = SnapshotRetryPolicy.nextStatus(after: .timeout, attemptCount: 1)
        #expect(status == .pending)
        #expect(SnapshotRetryPolicy.shouldRetry(status: status, attemptCount: 1))
    }
    
    @Test
    func snapshotTimeoutAtLimitStopsRetry() async throws {
        try await Task.sleep(nanoseconds: 1_000_000)
        let status = SnapshotRetryPolicy.nextStatus(after: .timeout, attemptCount: SnapshotRetryPolicy.maxAttempts)
        #expect(status == .failed)
        #expect(SnapshotRetryPolicy.shouldRetry(status: status, attemptCount: SnapshotRetryPolicy.maxAttempts) == false)
        #expect(SnapshotRetryPolicy.message(for: .timeout, attemptCount: SnapshotRetryPolicy.maxAttempts) != nil)
    }
}
