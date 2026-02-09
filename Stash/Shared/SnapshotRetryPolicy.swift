import Foundation

enum SnapshotAttemptResult {
    case success
    case timeout
    case failure
}

enum SnapshotRetryPolicy {
    static let maxAttempts = 3
    
    static func shouldRetry(status: SnapshotStatus, attemptCount: Int) -> Bool {
        status == .pending && attemptCount < maxAttempts
    }
    
    static func nextStatus(after result: SnapshotAttemptResult, attemptCount: Int) -> SnapshotStatus {
        switch result {
        case .success:
            return .succeeded
        case .timeout, .failure:
            return attemptCount >= maxAttempts ? .failed : .pending
        }
    }
    
    static func message(for result: SnapshotAttemptResult, attemptCount: Int) -> String? {
        switch result {
        case .success:
            return nil
        case .timeout where attemptCount >= maxAttempts:
            return "Snapshot timed out \(maxAttempts) times; retry stopped."
        case .timeout:
            return "Snapshot timed out; will retry."
        case .failure where attemptCount >= maxAttempts:
            return "Snapshot capture failed \(maxAttempts) times; retry stopped."
        case .failure:
            return "Snapshot capture failed; will retry."
        }
    }
}
