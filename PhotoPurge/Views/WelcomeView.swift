import SwiftUI

struct WelcomeView: View {
    @Binding var showWelcome: Bool
    @Binding var reviewMode: PhotoReviewMode
    @State private var showNotificationSetup = false
    @State private var selectedMode: PhotoReviewMode?
    
    private let modes: [PhotoReviewMode] = [
        .fromToday,
        .pastWeek,
        .pastMonth,
        .allTime
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    headerImage(geometry: geometry)
                    mainContent
                }
            }
            .background(Color.theme.background)
            .ignoresSafeArea(edges: .top)
        }
        .edgesIgnoringSafeArea(.top)
        .fullScreenCover(isPresented: $showNotificationSetup) {
            NotificationSetupView(showNotificationSetup: $showNotificationSetup, showWelcome: $showWelcome)
        }
        .animation(.spring(response: 0.3), value: selectedMode)
    }
    
    private func headerImage(geometry: GeometryProxy) -> some View {
        Image("photo_review_header")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: geometry.size.width)
            .background(Color.theme.secondaryBackground)
            .ignoresSafeArea(edges: .top)
    }
    
    private var mainContent: some View {
        VStack(spacing: 24) {
            welcomeHeader
                .padding(.top, 16)
            
            timeOptions
            
            nextButton
        }
    }
    
    private var welcomeHeader: some View {
        VStack(spacing: 12) {
            Text("Welcome to PhotoPurge")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Color.theme.staticBlack)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
            
            Text("Let's declutter your photo library")
                .font(.title2)
                .foregroundStyle(Color.theme.accent)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
        }
        .padding(.horizontal)
    }
    
    private var timeOptions: some View {
        VStack(spacing: 12) {
            ForEach(modes, id: \.rawValue) { mode in
                TimeOptionCard(
                    mode: mode,
                    isSelected: selectedMode == mode
                ) {
                    selectedMode = mode
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var nextButton: some View {
        Button {
            if let selected = selectedMode {
                reviewMode = selected
                showNotificationSetup = true
            }
        } label: {
            Text("Next")
                .font(.headline)
                .foregroundStyle(Color.theme.primaryText)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedMode != nil ? Color.theme.accent : Color.theme.disabled)
                .cornerRadius(16)
        }
        .disabled(selectedMode == nil)
        .padding(.horizontal)
    }
}

struct TimeOptionCard: View {
    let mode: PhotoReviewMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Circle()
                    .fill(Color.theme.accent.opacity(isSelected ? 0.2 : 0.1))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: mode.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(Color.theme.accent)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.title)
                        .font(.headline)
                        .foregroundStyle(Color.theme.primaryText)
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(0.8)
                    
                    Text(mode.description)
                        .font(.subheadline)
                        .foregroundStyle(Color.theme.tertiaryText)
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(0.8)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.theme.accent)
                        .font(.system(size: 22))
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.theme.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? Color.theme.accent : Color.theme.disabled.opacity(0.3), 
                                lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
} 