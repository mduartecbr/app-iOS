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
            // EpT MVP temporário: Instagram bloqueia embed de perfil em webview.
            // Tela com botão honesto que abre o Instagram externo (Safari/app nativo).
            // Quando a página WP com plugin Meks Easy Photo Feed Widget estiver pronta,
            // voltar a usar MMWebView apontando pra essa página.
            OpenExternalView(
                systemImage: "camera.fill",
                title: "Esporte para Todos no Instagram",
                message: "Acompanhe os posts e bastidores no nosso Instagram.",
                buttonTitle: "Abrir @esporteparatodos",
                url: URL(string: "https://www.instagram.com/esporteparatodos/")!
            )
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

// MARK: - Open External Placeholder -

/// Placeholder used when a feature exists outside the app and we want to send the user
/// to an external destination (Safari/native app) instead of trying to embed it.
/// Currently used for the Instagram tab — Instagram blocks profile embedding in webviews.
private struct OpenExternalView: View {
    @Environment(\.theme) private var theme: ThemeColor
    @Environment(\.openURL) private var openURL

    let systemImage: String
    let title: String
    let message: String
    let buttonTitle: String
    let url: URL

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 56, weight: .light))
                .foregroundColor(theme.text.terciary.color)
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(action: { openURL(url) }) {
                Text(buttonTitle)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(theme.main.tint.color ?? Color.accentColor)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
            .accessibilityHint("Abre o link em Safari ou no app do Instagram")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background((theme.main.background.color ?? Color(.systemBackground)).ignoresSafeArea())
    }
}
