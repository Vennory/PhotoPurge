import SwiftUI
import Photos
import AVKit

class VideoLoader: ObservableObject {
    @Published var player: AVPlayer?
    @Published var thumbnail: UIImage?
    @Published private(set) var isLoading = false
    private var requestID: PHImageRequestID?
    private let asset: PHAsset
    
    init(asset: PHAsset) {
        self.asset = asset
        loadThumbnail()
        loadVideo()
    }
    
    func loadThumbnail() {
        isLoading = true
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        // Calculate target size based on asset's aspect ratio
        let aspectRatio = CGFloat(asset.pixelWidth) / CGFloat(asset.pixelHeight)
        let targetWidth: CGFloat = 1200
        let targetHeight = targetWidth / aspectRatio
        
        requestID = PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: targetWidth, height: targetHeight),
            contentMode: .aspectFit,
            options: options
        ) { [weak self] result, info in
            DispatchQueue.main.async {
                self?.thumbnail = result
                self?.isLoading = false
            }
        }
    }
    
    func loadVideo() {
        let options = PHVideoRequestOptions()
        options.version = .original
        options.deliveryMode = .automatic
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestAVAsset(
            forVideo: asset,
            options: options
        ) { [weak self] (asset, _, _) in
            DispatchQueue.main.async {
                if let asset = asset {
                    self?.player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
                }
            }
        }
    }
    
    deinit {
        if let requestID = requestID {
            PHImageManager.default().cancelImageRequest(requestID)
        }
    }
}

class PhotoLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var fullResolutionImage: UIImage?
    @Published private(set) var isLoading = false
    private var requestID: PHImageRequestID?
    private var fullResRequestID: PHImageRequestID?
    private let asset: PHAsset
    private static let cache = NSCache<NSString, UIImage>()
    
    init(asset: PHAsset) {
        self.asset = asset
        loadImage()  // Start loading immediately on init
    }
    
    func loadImage() {
        // Check cache first
        if let cachedImage = PhotoLoader.cache.object(forKey: asset.localIdentifier as NSString) {
            self.image = cachedImage
            self.isLoading = false
            return
        }
        
        isLoading = true
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic // Allow quick degraded images first
        options.isNetworkAccessAllowed = true
        options.resizeMode = .exact
        options.isSynchronous = false
        
        // Cancel any existing request
        if let requestID = requestID {
            PHImageManager.default().cancelImageRequest(requestID)
        }
        
        // Calculate target size based on asset's aspect ratio
        let aspectRatio = CGFloat(asset.pixelWidth) / CGFloat(asset.pixelHeight)
        let targetWidth: CGFloat = 1200
        let targetHeight = targetWidth / aspectRatio
        
        requestID = PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: targetWidth, height: targetHeight),
            contentMode: .aspectFit,
            options: options
        ) { [weak self] result, info in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let image = result {
                    // Show degraded image immediately
                    if self.image == nil {
                        self.image = image
                        self.isLoading = false
                    }
                    
                    // Update with final image if this is the final result
                    if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool,
                       !isDegraded {
                        self.image = image
                        PhotoLoader.cache.setObject(image, forKey: self.asset.localIdentifier as NSString)
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    func loadFullResolutionImage() {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.resizeMode = .none
        options.isSynchronous = false
        
        // Cancel any existing full resolution request
        if let fullResRequestID = fullResRequestID {
            PHImageManager.default().cancelImageRequest(fullResRequestID)
        }
        
        fullResRequestID = PHImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { [weak self] result, info in
            DispatchQueue.main.async {
                // Only update if this is the final result
                if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool,
                   !isDegraded {
                    self?.fullResolutionImage = result
                }
            }
        }
    }
    
    deinit {
        if let requestID = requestID {
            PHImageManager.default().cancelImageRequest(requestID)
        }
        if let fullResRequestID = fullResRequestID {
            PHImageManager.default().cancelImageRequest(fullResRequestID)
        }
    }
}

struct PhotoAssetView: View {
    let asset: PHAsset
    let nextAssets: [PHAsset]
    @StateObject private var loader: PhotoLoader
    @StateObject private var videoLoader: VideoLoader
    @State private var isShowingFullScreen = false
    @State private var opacity: Double = 0
    @State private var isPlaying = false
    
    init(asset: PHAsset, nextAssets: [PHAsset] = []) {
        self.asset = asset
        self.nextAssets = nextAssets
        
        if asset.mediaType == .video {
            _videoLoader = StateObject(wrappedValue: VideoLoader(asset: asset))
            _loader = StateObject(wrappedValue: PhotoLoader(asset: asset)) // For thumbnail
        } else {
            _videoLoader = StateObject(wrappedValue: VideoLoader(asset: asset)) // Initialize with same asset for type safety
            _loader = StateObject(wrappedValue: PhotoLoader(asset: asset))
        }
        
        // Preload next assets
        for nextAsset in nextAssets.prefix(3) {
            let _ = PhotoLoader(asset: nextAsset)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.theme.background
                    .ignoresSafeArea()
                
                if asset.mediaType == .video {
                    videoView(geometry: geometry)
                        .overlay(alignment: .bottomTrailing) {
                            videoDurationBadge
                        }
                } else {
                    imageView(geometry: geometry)
                }
                
                if loader.isLoading && loader.image == nil {
                    Color(.systemBackground)
                        .overlay(
                            ProgressView()
                                .scaleEffect(1.5)
                        )
                }
            }
        }
        .onChange(of: asset.localIdentifier) { _ in
            opacity = 0
            if asset.mediaType == .video {
                videoLoader.loadVideo()
                videoLoader.loadThumbnail()
            } else {
                loader.loadImage()
            }
        }
        .fullScreenCover(isPresented: $isShowingFullScreen) {
            if asset.mediaType == .video {
                if let player = videoLoader.player {
                    VideoPlayerView(player: player, isPresented: $isShowingFullScreen)
                }
            } else {
                FullScreenImageView(image: loader.fullResolutionImage, isPresented: $isShowingFullScreen)
            }
        }
        .id(asset.localIdentifier)
        .transaction { transaction in
            transaction.animation = nil
        }
    }
    
    private func imageView(geometry: GeometryProxy) -> some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: geometry.size.width - 32)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .opacity(opacity)
                    .onAppear {
                        withAnimation(.easeIn(duration: 0.1)) {
                            opacity = 1
                        }
                    }
                    .onTapGesture {
                        loader.loadFullResolutionImage()
                        isShowingFullScreen = true
                    }
            }
        }
    }
    
    private func videoView(geometry: GeometryProxy) -> some View {
        Group {
            if let thumbnail = videoLoader.thumbnail {
                ZStack {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: geometry.size.width - 32)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .opacity(opacity)
                        .onAppear {
                            withAnimation(.easeIn(duration: 0.1)) {
                                opacity = 1
                            }
                        }
                    
                    // Play button overlay
                    Circle()
                        .fill(.black.opacity(0.5))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "play.fill")
                                .foregroundColor(.white)
                                .font(.title2)
                        )
                }
                .onTapGesture {
                    isShowingFullScreen = true
                }
            }
        }
    }
    
    private var videoDurationBadge: some View {
        Text(formatDuration(asset.duration))
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.black.opacity(0.6))
            .cornerRadius(4)
            .padding(12)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "0:00"
    }
}

struct VideoPlayerView: View {
    let player: AVPlayer
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            VideoPlayer(player: player)
                .ignoresSafeArea()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .medium))
                                .padding(8)
                        }
                    }
                }
                .onAppear {
                    player.play()
                }
                .onDisappear {
                    player.pause()
                    player.seek(to: .zero)
                }
        }
        .preferredColorScheme(.dark)
    }
}

struct FullScreenImageView: View {
    let image: UIImage?
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @GestureState private var magnifyBy = CGFloat(1.0)
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale * magnifyBy)
                            .gesture(
                                MagnificationGesture()
                                    .updating($magnifyBy) { currentState, gestureState, _ in
                                        gestureState = currentState
                                    }
                                    .onEnded { value in
                                        scale *= value
                                        scale = min(max(scale, 1), 4)
                                    }
                            )
                            .onTapGesture {
                                // Only dismiss if not zoomed in
                                if scale <= 1.0 {
                                    isPresented = false
                                } else {
                                    // Reset zoom if zoomed in
                                    withAnimation(.spring()) {
                                        scale = 1.0
                                    }
                                }
                            }
                    } else {
                        ProgressView()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .medium))
                            .padding(8)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled(scale > 1.0) // Prevent swipe to dismiss when zoomed
    }
} 