import AnalyticsLibrary
import MacMagazineLibrary
import MacMagazineUILibrary
import PodcastLibrary
import SettingsLibrary
import StorageLibrary
import SwiftUI
import UIComponentsLibrary
import VideosLibrary

struct SocialView: View {
    @Environment(\.shouldUseSidebar) private var shouldUseSidebar
    @Environment(\.theme) private var theme: ThemeColor
    @Environment(MainViewModel.self) private var viewModel

    @State private var favorite = false
    @State private var scrollPosition = ScrollPosition()

    var body: some View {
        socialContent
        .onChange(of: viewModel.scrollToTopTrigger) { _, newValue in
            if newValue == .social {
                withAnimation {
                    scrollPosition.scrollTo(edge: .top)
                }
                viewModel.scrollToTopTrigger = nil
            }
        }
    }

    var socialContent: some View {
        ZStack {
            (theme.main.background.color ?? Color.secondary).ignoresSafeArea()
            content
        }
        .contentMargins(.top, 20, for: .scrollContent)
        .navigation(shouldUseSidebar: shouldUseSidebar,
                    title: viewModel.social.rawValue)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                menuView
            }
            ToolbarItem(placement: .principal) {
                if !shouldUseSidebar {
                    optionsView
                }
            }
        }
    }
}

private extension SocialView {
    @ViewBuilder
    var optionsView: some View {
        @Bindable var bindableViewModel = viewModel

        Picker("Seção social", selection: $bindableViewModel.social) {
            ForEach(viewModel.settingsViewModel.social, id: \.self) { option in
                Text(option.rawValue).tag(option)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    var content: some View {
        switch viewModel.social {
        case .videos:
            VideosView(
                viewModel: viewModel.videosViewModel,
                favorite: $favorite,
                scrollPosition: $scrollPosition
            ).transition(.opacity)
                .trackScreen(
                    viewModel.social.rawValue,
                    previous: nil,
                    analytics: viewModel.analytics
                )
        case .podcast:
            // EpT MVP: podcast ainda não existe — placeholder "Em breve" no lugar da PodcastView.
            ComingSoonView(
                title: "Em breve",
                message: "O Esporte para Todos está preparando seu podcast."
            )
            .transition(.opacity)
            .trackScreen(
                viewModel.social.rawValue,
                previous: nil,
                analytics: viewModel.analytics
            )
        case .instagram:
            MMWebView(url: "https://www.instagram.com/esporteparatodos/", cacheKey: "ept_instagram")
                .trackScreen(
                    viewModel.social.rawValue,
                    previous: nil,
                    analytics: viewModel.analytics
                )
        }
    }

    var menuView: some View {
        Button(action: {
            withAnimation {
                favorite.toggle()
                viewModel.analytics.track(
                    .buttonTap(
                        buttonId: AnalyticsConstants.ButtonID.favoriteButton.id,
                        screen: viewModel.social.analyticsScreen.name
                    )
                )
            }
        }, label: {
            Image(systemName: favorite ? "star.fill" : "star")
        })
        .accessibilityLabel(favorite ? "Mostrar tudo" : "Mostrar Favoritos")
        .disabled(viewModel.social == .instagram)
    }
}

#Preview {
    SocialView()
        .environment(\.theme, ThemeColor())
        .environment(MainViewModel(
            pushNotification: PushNotification(),
            inMemory: true
        ))
}

// MARK: - Coming Soon Placeholder -

/// Generic "Em breve" placeholder used when a feature isn't ready yet (currently the Podcast tab).
private struct ComingSoonView: View {
    @Environment(\.theme) private var theme: ThemeColor

    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "hourglass")
                .font(.system(size: 56, weight: .light))
                .foregroundColor(theme.text.terciary.color)
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background((theme.main.background.color ?? Color(.systemBackground)).ignoresSafeArea())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}
