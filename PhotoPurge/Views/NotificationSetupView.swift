import SwiftUI

struct NotificationSetupView: View {
    @Binding var showNotificationSetup: Bool
    @Binding var showWelcome: Bool
    @State private var selectedTime = Date()
    @State private var selectedOption: NotificationOption = .none
    @State private var showTimePicker = false
    
    enum NotificationOption {
        case none
        case random
        case specific
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        // Header Image
                        Image("hero-noti")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: geometry.size.width)
                            .background(Color.theme.secondaryBackground)
                            .ignoresSafeArea(edges: .top)
                        
                        VStack(spacing: 16) {
                            // Header
                            VStack(spacing: 12) {
                                Text("Stay Organized")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(Color.theme.primaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 24)
                                
                                Text("When should we remind you to review?")
                                    .font(.title2)
                                    .foregroundStyle(Color.theme.accent)
                                    .multilineTextAlignment(.center)
                                    .padding(.bottom, 8)
                            }
                            .padding(.horizontal)
                            
                            // Options
                            VStack(spacing: 24) {
                                // Random Time Option
                                Button {
                                    selectedOption = .random
                                    showTimePicker = false
                                } label: {
                                    NotificationOptionCard(
                                        title: "Random Time",
                                        description: "We'll remind you at a random time between 9 AM and 9 PM",
                                        icon: "shuffle.circle.fill",
                                        isSelected: selectedOption == .random
                                    )
                                }
                                
                                // Specific Time Option
                                Button {
                                    selectedOption = .specific
                                    showTimePicker = true
                                } label: {
                                    NotificationOptionCard(
                                        title: "Choose Time",
                                        description: "Pick a specific time that works best for you",
                                        icon: "clock.fill",
                                        isSelected: selectedOption == .specific
                                    )
                                }
                                
                                if showTimePicker {
                                    DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                                        .datePickerStyle(.wheel)
                                        .labelsHidden()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.theme.secondaryBackground)
                                        .cornerRadius(16)
                                        .accentColor(Color.theme.accent)
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                }
                                
                                // Next Button
                                Button {
                                    scheduleNotification()
                                } label: {
                                    Text("Next")
                                        .font(.headline)
                                        .foregroundStyle(Color.theme.primaryText)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(selectedOption != .none ? Color.theme.accent : Color.theme.disabled)
                                        .cornerRadius(16)
                                }
                                .disabled(selectedOption == .none)
                            }
                            .padding(.horizontal)
                            .animation(.spring(response: 0.3), value: showTimePicker)
                            .animation(.spring(response: 0.3), value: selectedOption)
                        }
                    }
                }
                .background(Color.theme.background)
                .ignoresSafeArea(edges: .top)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            showNotificationSetup = false
                            showWelcome = true
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(Color.theme.primaryText)
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                }
            }
        }
    }
    
    private func scheduleNotification() {
        switch selectedOption {
        case .random:
            NotificationManager.shared.scheduleNotification(at: nil, random: true)
            UserDefaults.standard.set(true, forKey: "useRandomTime")
            UserDefaults.standard.removeObject(forKey: "notificationTime")
        case .specific:
            NotificationManager.shared.scheduleNotification(at: selectedTime, random: false)
            UserDefaults.standard.set(false, forKey: "useRandomTime")
            UserDefaults.standard.set(selectedTime, forKey: "notificationTime")
        case .none:
            break
        }
        showNotificationSetup = false
        showWelcome = false
    }
} 