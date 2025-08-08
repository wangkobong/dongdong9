
import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("홈")
                }

            BudgetView()
                .tabItem {
                    Image(systemName: "dollarsign.circle.fill")
                    Text("예산")
                }

            SettingsView()
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("설정")
                }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        let authViewModel = AuthViewModel()
        let budgetViewModel = BudgetViewModel(authViewModel: authViewModel)

        MainTabView()
            .environmentObject(authViewModel)
            .environmentObject(budgetViewModel)
    }
}
