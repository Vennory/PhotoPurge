import SwiftUI

struct StatsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("totalReviewed") private var totalReviewed: Int = 0
    @AppStorage("totalDeleted") private var totalDeleted: Int = 0
    @AppStorage("totalKept") private var totalKept: Int = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Stats Cards
                    VStack(spacing: 16) {
                        StatCard(title: "Total Reviewed", value: totalReviewed, icon: "photo.stack", color: .blue)
                        StatCard(title: "Media Kept", value: totalKept, icon: "heart.fill", color: .green)
                        StatCard(title: "Media Deleted", value: totalDeleted, icon: "trash.fill", color: .red)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
                .padding(.top, 24)
            }
            .navigationTitle("Your Stats")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color.theme.accent)
                    .font(.headline)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.theme.background, for: .navigationBar)
        }
        .tint(.purple)
    }
}

struct StatCard: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(color)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.tertiaryText)
                Text("\(value)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.theme.primaryText)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.theme.secondaryBackground)
        )
    }
} 
