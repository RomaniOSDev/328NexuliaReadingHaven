import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppDataStore()

    var body: some View {
        MainShellView()
            .environmentObject(store)
            .preferredColorScheme(.dark)
    }
}
