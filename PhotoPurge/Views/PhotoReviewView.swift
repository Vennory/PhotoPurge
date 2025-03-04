import SwiftUI
import Photos

struct PhotoReviewView: View {
    @ObservedObject var viewModel: PhotoReviewViewModel
    @State private var offset: CGSize = .zero
    @State private var showSettings = false
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    LoadingView(message: viewModel.loadingMessage)
                } else if viewModel.photos.isEmpty {
                    CompletionView(showConfetti: viewModel.showingCongrats)
                } else {
                    photoReviewCard
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Group {
                        if viewModel.isLoading {
                            Text("PhotoPurge")
                                .font(.headline)
                                .foregroundStyle(Color.theme.staticBlack)
                        } else if viewModel.photos.isEmpty || viewModel.showingCongrats {
                            Text("PhotoPurge")
                                .font(.headline)
                                .foregroundStyle(Color.theme.staticBlack)
                        } else {
                            Text("\(viewModel.remainingPhotos) remaining")
                                .font(.headline)
                                .foregroundStyle(Color.theme.staticWhite)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gear")
                            .foregroundStyle(
                                (!viewModel.isLoading && !viewModel.photos.isEmpty && !viewModel.showingCongrats) ?
                                    Color.theme.staticWhite : Color.theme.staticBlack
                            )
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    viewModel.fetchPhotos()
                }
            }
        }
    }
    
    private var photoReviewCard: some View {
        GeometryReader { geometry in
            if let currentPhoto = viewModel.photos[safe: viewModel.currentIndex] {
                ZStack {
                    Color.theme.background
                        .ignoresSafeArea()
                    
                    // Next photo (if available)
                    if let nextPhoto = viewModel.photos[safe: viewModel.currentIndex + 1] {
                        PhotoAssetView(
                            asset: nextPhoto.asset,
                            nextAssets: Array(
                                viewModel.photos[
                                    (viewModel.currentIndex + 2)..<min(viewModel.currentIndex + 4, viewModel.photos.count)
                                ].map { $0.asset }
                            )
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(false)  // Prevent interaction with background card
                    }
                    
                    // Current photo card
                    PhotoAssetView(
                        asset: currentPhoto.asset,
                        nextAssets: Array(
                            viewModel.photos[
                                (viewModel.currentIndex + 1)..<min(viewModel.currentIndex + 3, viewModel.photos.count)
                            ].map { $0.asset }
                        )
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(offset)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                offset = gesture.translation
                            }
                            .onEnded { gesture in
                                handleSwipeGesture(gesture, geometry: geometry)
                            }
                    )
                    .rotation3DEffect(
                        .degrees(Double(offset.width / 20)),
                        axis: (x: 0, y: 0, z: 1)
                    )
                    
                    // Swipe indicators
                    ZStack {
                        // Keep indicator
                        SwipeIndicator(
                            systemName: "heart.fill",
                            text: "KEEP",
                            color: .green,
                            opacity: shouldShowKeepIndicator ? min(Double(offset.width / 50), 1) : 0,
                            scale: shouldShowKeepIndicator ? 1 + min(Double(offset.width / 500), 0.5) : 1
                        )
                        
                        // Delete indicator
                        SwipeIndicator(
                            systemName: "trash.fill",
                            text: "DELETE",
                            color: .red,
                            opacity: shouldShowDeleteIndicator ? min(Double(-offset.width / 50), 1) : 0,
                            scale: shouldShowDeleteIndicator ? 1 + min(Double(-offset.width / 500), 0.5) : 1
                        )
                    }
                }
                .animation(.none, value: viewModel.currentIndex)
                .transaction { transaction in
                    transaction.animation = nil
                }
                .id(currentPhoto.id)
            }
        }
        .ignoresSafeArea()
    }
    
    // Add computed properties for indicator visibility
    private var shouldShowKeepIndicator: Bool {
        offset.width > 0
    }
    
    private var shouldShowDeleteIndicator: Bool {
        offset.width < 0
    }
    
    private func handleSwipeGesture(_ gesture: DragGesture.Value, geometry: GeometryProxy) {
        let threshold: CGFloat = 50
        let horizontalMovement = abs(gesture.translation.width)
        
        if horizontalMovement > threshold {
            // Swipe left or right
            let swipeOut = gesture.translation.width > 0 ? geometry.size.width * 1.5 : -geometry.size.width * 1.5
            
            withAnimation(.easeOut(duration: 0.2)) {
                offset.width = swipeOut
                offset.height = 0
            }
            
            let direction = gesture.translation.width > 0 ? SwipeDirection.right : .left
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                viewModel.handleSwipe(direction)
                offset = .zero
            }
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                offset = .zero
            }
        }
    }
}

struct SwipeIndicator: View {
    let systemName: String
    let text: String
    let color: Color
    let opacity: Double
    let scale: Double
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemName)
                .font(.system(size: 80, weight: .bold))
                .foregroundColor(color)
            
            Text(text)
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(color)
        }
        .opacity(opacity)
        .scaleEffect(scale)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

struct SwipeInstructionButton: View {
    let systemName: String
    let text: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(color.opacity(0.9))
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

struct CompletionView: View {
    let showConfetti: Bool
    @State private var showingStats = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.theme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Image
                    Image("celebrate")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: geometry.size.width)
                        .background(Color.theme.secondaryBackground)
                        .ignoresSafeArea(edges: .top)
                    
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.theme.accent)
                        Text("Congrats! You're all caught up!")
                            .font(.title)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color.theme.primaryText)
                        Text("Check back after you have taken some photos & videos!")
                            .font(.subheadline)
                            .foregroundStyle(Color.theme.tertiaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    Spacer()
                    
                    // Stats Button at bottom
                    Button {
                        showingStats = true
                    } label: {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                            Text("View Stats")
                        }
                        .font(.headline)
                        .foregroundStyle(Color.theme.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.accent)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
                
                // Confetti on top
                if showConfetti {
                    ConfettiView()
                        .ignoresSafeArea()
                }
            }
        }
        .sheet(isPresented: $showingStats) {
            StatsView()
        }
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
} 
