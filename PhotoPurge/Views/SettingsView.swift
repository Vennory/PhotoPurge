import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("notificationTime") private var notificationTime = Date()
    @AppStorage("useRandomTime") private var useRandomTime = false
    @AppStorage("totalReviewed") private var totalReviewed: Int = 0
    @AppStorage("totalDeleted") private var totalDeleted: Int = 0
    @AppStorage("totalKept") private var totalKept: Int = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                mainContent
            }
            .background(Color.theme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    doneButton
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.theme.background, for: .navigationBar)
        }
        .tint(.purple)
    }
    
    private var doneButton: some View {
        Button("Done") {
            presentationMode.wrappedValue.dismiss()
        }
        .foregroundStyle(Color.theme.accent)
        .font(.headline)
    }
    
    private var mainContent: some View {
        VStack(spacing: 32) {
            statsSection
            notificationSection
            aboutSection
        }
        .padding(.top, 24)
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.headline)
                .foregroundStyle(Color.theme.primaryText)
                .padding(.horizontal, 24)
            
            VStack(spacing: 16) {
                StatCard(title: "Total Reviewed", value: totalReviewed, icon: "photo.stack", color: .blue)
                StatCard(title: "Media Kept", value: totalKept, icon: "heart.fill", color: .green)
                StatCard(title: "Media Deleted", value: totalDeleted, icon: "trash.fill", color: .red)
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notifications")
                .font(.headline)
                .foregroundStyle(Color.theme.primaryText)
                .padding(.horizontal, 24)
            
            VStack(spacing: 16) {
                randomTimeButton
                specificTimeButton
                if !useRandomTime {
                    DatePicker("", selection: $notificationTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .background(Color.theme.secondaryBackground)
                        .cornerRadius(16)
                        .accentColor(Color.theme.accent)
                        .onChange(of: notificationTime) { newTime in
                            NotificationManager.shared.scheduleNotification(at: newTime, random: false)
                        }
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var randomTimeButton: some View {
        Button {
            useRandomTime = true
            NotificationManager.shared.scheduleNotification(at: nil, random: true)
        } label: {
            NotificationOptionCard(
                title: "Random Time",
                description: "We'll remind you at a random time between 9 AM and 9 PM",
                icon: "shuffle.circle.fill",
                isSelected: useRandomTime
            )
        }
    }
    
    private var specificTimeButton: some View {
        Button {
            useRandomTime = false
            NotificationManager.shared.scheduleNotification(at: notificationTime, random: false)
        } label: {
            NotificationOptionCard(
                title: "Choose Time",
                description: "Pick a specific time that works best for you",
                icon: "clock.fill",
                isSelected: !useRandomTime
            )
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.headline)
                .foregroundStyle(Color.theme.primaryText)
                .padding(.horizontal, 24)
            
            VStack(spacing: 0) {
                Link(destination: URL(string: "https://vennory.com/privacy-policy")!) {
                    SettingsLinkRow(title: "Privacy Policy")
                }
                
                Divider()
                    .background(Color.theme.disabled)
                
                Link(destination: URL(string: "https://vennory.com/terms-of-use")!) {
                    SettingsLinkRow(title: "Terms of Use")
                }
                
                Divider()
                    .background(Color.theme.disabled)
                
                Link(destination: URL(string: "https://vennory.com/contact.php")!) {
                    SettingsLinkRow(title: "Contact")
                }
            }
            .background(Color.theme.secondaryBackground)
            .cornerRadius(16)
            .padding(.horizontal, 24)
        }
    }
}

struct SettingsLinkRow: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.theme.primaryText)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Color.theme.tertiaryText)
        }
        .padding()
    }
} 
