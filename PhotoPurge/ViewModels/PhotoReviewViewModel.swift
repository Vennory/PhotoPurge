import Foundation
import Photos
import SwiftUI
import UIKit

class PhotoReviewViewModel: NSObject, ObservableObject {
    @Published var photos: [Photo] = []
    @Published var currentIndex: Int = 0
    @Published var showingCongrats: Bool = false
    @Published var totalPhotos: Int = 0
    @Published var remainingPhotos: Int = 0
    @Published var isLoading: Bool = false
    @Published var loadingMessage: String = ""
    
    @AppStorage("selectedReviewMode") private var storedReviewMode: String = PhotoReviewMode.fromToday.rawValue
    @AppStorage("keptPhotoIds") private var keptPhotoIds: String = "[]"
    @AppStorage("lastCompletionTime") private var lastCompletionTime: Double = 0
    @AppStorage("totalReviewed") private var totalReviewed: Int = 0
    @AppStorage("totalDeleted") private var totalDeleted: Int = 0
    @AppStorage("totalKept") private var totalKept: Int = 0
    
    private let minimumCongratsDisplayTime: TimeInterval = 3.5 // Increased minimum display time
    private var isRefreshScheduled = false
    
    private var keptPhotoIdArray: [String] {
        get {
            if let data = keptPhotoIds.data(using: .utf8),
               let array = try? JSONDecoder().decode([String].self, from: data) {
                return array
            }
            return []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let string = String(data: data, encoding: .utf8) {
                keptPhotoIds = string
            }
        }
    }
    
    var reviewMode: PhotoReviewMode {
        get {
            PhotoReviewMode(rawValue: storedReviewMode) ?? .fromToday
        }
        set {
            storedReviewMode = newValue.rawValue
            fetchPhotos()
        }
    }
    
    private let photoLibrary = PHPhotoLibrary.shared()
    private var isFirstLoad = true
    
    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
        requestPhotoLibraryAuthorization()
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    private func requestPhotoLibraryAuthorization() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    self?.fetchPhotos()
                case .denied, .restricted:
                    print("Photo library access denied")
                case .notDetermined:
                    print("Photo library access not determined")
                @unknown default:
                    print("Unknown photo library access status")
                }
            }
        }
    }
    
    func fetchPhotos() {
        // Don't refresh if we just completed and are showing congrats
        let timeSinceLastCompletion = Date().timeIntervalSince1970 - lastCompletionTime
        if showingCongrats && timeSinceLastCompletion < minimumCongratsDisplayTime {
            // Schedule a refresh after the minimum display time if not already scheduled
            if !isRefreshScheduled {
                isRefreshScheduled = true
                let delayTime = minimumCongratsDisplayTime - timeSinceLastCompletion
                DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) { [weak self] in
                    guard let self = self else { return }
                    self.isRefreshScheduled = false
                    self.fetchPhotos()
                }
            }
            return
        }
        
        // Only show loading indicator on first load or mode change
        if isFirstLoad {
            isLoading = true
            loadingMessage = reviewMode == .allTime ? 
                "Loading your entire photo library...\nThis might take a moment if you have lots of photos" :
                "Loading today's photos..."
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.predicate = self.reviewMode.fetchPredicate
            
            let assets = PHAsset.fetchAssets(with: fetchOptions)
            var newPhotos: [Photo] = []
            
            let keptIds = self.keptPhotoIdArray
            assets.enumerateObjects { (asset, _, _) in
                // Skip photos that have been kept
                if !keptIds.contains(asset.localIdentifier) {
                    let photo = Photo(asset: asset)
                    newPhotos.append(photo)
                }
            }
            
            DispatchQueue.main.async {
                // Reset congrats state if we found new photos
                if !newPhotos.isEmpty {
                    self.showingCongrats = false
                }
                
                // Update the photos array and counts
                self.photos = newPhotos
                self.totalPhotos = newPhotos.count
                self.remainingPhotos = newPhotos.count
                
                // Reset current index if needed
                if self.currentIndex >= newPhotos.count {
                    self.currentIndex = max(0, newPhotos.count - 1)
                }
                
                // Update loading states
                self.isLoading = false
                self.isFirstLoad = false
            }
        }
    }
    
    private func updateRemainingPhotosCount() {
        DispatchQueue.main.async {
            self.remainingPhotos = self.photos.count
            self.totalPhotos = self.photos.count
            
            // Check for completion
            if self.photos.isEmpty {
                self.lastCompletionTime = Date().timeIntervalSince1970
                self.showingCongrats = true
                self.isRefreshScheduled = false
            }
        }
    }
    
    func hasUnreviewedPhotos() -> Bool {
        return !photos.isEmpty
    }
    
    func handleSwipe(_ direction: SwipeDirection) {
        guard currentIndex < photos.count else { return }
        
        switch direction {
        case .left:
            deleteCurrentPhoto()
            totalDeleted += 1
        case .right:
            keepCurrentPhoto()
            totalKept += 1
        }
        
        totalReviewed += 1
        updateRemainingPhotosCount()
    }
    
    private func moveToNextPhoto() {
        if currentIndex >= photos.count {
            currentIndex = max(0, photos.count - 1)
        }
        updateRemainingPhotosCount()
    }
    
    private func keepCurrentPhoto() {
        guard currentIndex < photos.count else { return }
        let photo = photos[currentIndex]
        let nextIndex = currentIndex + 1
        
        // Add to kept photos list and remove from current array
        var currentKeptIds = keptPhotoIdArray
        currentKeptIds.append(photo.asset.localIdentifier)
        photos.remove(at: currentIndex)
        // Update kept photos after removing from current array
        keptPhotoIdArray = currentKeptIds
        
        // Preload next photo if available
        if nextIndex < photos.count {
            let _ = PhotoLoader(asset: photos[nextIndex].asset)
        }
        
        moveToNextPhoto()
    }
    
    private func deleteCurrentPhoto() {
        guard currentIndex < photos.count else { return }
        let photoToDelete = photos[currentIndex]
        let nextIndex = currentIndex + 1
        
        // Preload next photo before deletion if available
        if nextIndex < photos.count {
            let _ = PhotoLoader(asset: photos[nextIndex].asset)
        }
        
        PHPhotoLibrary.shared().performChanges({
            // Request to delete the asset
            PHAssetChangeRequest.deleteAssets([photoToDelete.asset] as NSFastEnumeration)
        }) { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if success {
                    // Remove the photo from our array
                    if self.currentIndex < self.photos.count {
                        self.photos.remove(at: self.currentIndex)
                        self.moveToNextPhoto()
                    }
                } else {
                    if let error = error {
                        print("Error deleting photo: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

extension PhotoReviewViewModel: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Don't refresh if we just completed and are showing congrats
            let timeSinceLastCompletion = Date().timeIntervalSince1970 - self.lastCompletionTime
            if self.showingCongrats && timeSinceLastCompletion < self.minimumCongratsDisplayTime {
                // Schedule a refresh after the minimum display time if not already scheduled
                if !self.isRefreshScheduled {
                    self.isRefreshScheduled = true
                    let delayTime = self.minimumCongratsDisplayTime - timeSinceLastCompletion
                    DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) { [weak self] in
                        guard let self = self else { return }
                        self.isRefreshScheduled = false
                        self.fetchPhotos()
                    }
                }
                return
            }
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.predicate = self.reviewMode.fetchPredicate
            
            let assets = PHAsset.fetchAssets(with: fetchOptions)
            
            // Check if there are any changes to the fetch result
            if let changes = changeInstance.changeDetails(for: assets) {
                // Only update if there are actual changes
                if changes.hasIncrementalChanges {
                    self.fetchPhotos()
                }
            }
        }
    }
} 