import SwiftUI
import ConfettiSwiftUI

struct ConfettiView: View {
    @State private var trigger: Int = 0
    
    var body: some View {
        ZStack {
            Color.clear
            
            Text("")
                .confettiCannon(
                    trigger: $trigger,
                    num: 150,
                    
                    confettis: [.shape(.slimRectangle), .shape(.circle)],
                    colors: [
                        Color(hex: "#7B80FF"),  // Purple-blue
                        Color(hex: "#9BC9FC"),  // Light blue
                        Color(hex: "#EAABFE"),  // Light purple
                        Color(hex: "#F5E3A0"),  // Light yellow
                        Color(hex: "#CE58F2")   // Bright purple
                    ],
                    
                    rainHeight: 800,
                    radius: 500,
                    repetitions: 1,
                    repetitionInterval: 0.1,
                    hapticFeedback: true
                )
                .offset(y: 200)
        }
        .onAppear {
            trigger += 1
        }
    }
} 
