import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    var body: some View {
        
        TabView(selection: $selectedTab) {
            SystemKeychainView()
                .tabItem {
                    Label("SystemKeychain", systemImage: "arrow.triangle.2.circlepath")
                }
                .tag(0)
            
        }
    }
}

#Preview { ContentView() }
