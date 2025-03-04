import Foundation
import Photos

struct Photo: Identifiable {
    let id: String
    let asset: PHAsset
    var isReviewed: Bool
    var decision: PhotoDecision
    
    enum PhotoDecision {
        case keep
        case delete
        case undecided
    }
    
    var isVideo: Bool {
        asset.mediaType == .video
    }
    
    var duration: TimeInterval {
        asset.duration
    }
    
    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.asset = asset
        self.isReviewed = false
        self.decision = .undecided
    }
} 