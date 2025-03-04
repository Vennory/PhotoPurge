import SwiftUI

struct NotificationOptionCard: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.theme.accent.opacity(isSelected ? 0.2 : 0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(Color.theme.accent)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.theme.primaryText)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(Color.theme.tertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
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
                .strokeBorder(isSelected ? Color.theme.accent : Color.theme.disabled.opacity(0.3), lineWidth: isSelected ? 2 : 1)
        )
    }
} 