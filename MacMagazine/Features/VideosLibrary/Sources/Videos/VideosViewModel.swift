import Foundation
import NetworkLibrary
import StorageLibrary
import SwiftData
import UIComponentsLibrary
import YouTubeLibrary

@Observable
public class VideosViewModel {
    var options: Options = .home
    var status: APIStatus = .loading

    enum Options: Equatable {
        case home
        case search(text: String)
    }

    private let storage: Database
    private let mock: [NetworkMockData]?

    public let youtube: YouTubeAPI

    // EpT: credenciais do canal Programa Fôlego (parceria com Gustavo Maia).
    // channelId UCXBnKQ_Yq92QXQFAFnw_e-w / playlistId UUXBnKQ_Yq92QXQFAFnw_e-w (uploads).
    // apiKey é Google Cloud project esporte-para-todos-app, restrita a YouTube Data API v3.
    // Bytes XOR-encoded com salt "AppDelegateNSObject" pra dificultar extração via decompile.
    let credentials = YouTubeCredentials(salt: "AppDelegateNSObject",
                                         keys: [
                                            [0, 57, 10, 37, 54, 21, 36, 56, 52, 18, 86, 41, 43, 14, 9, 51, 12, 85, 39, 6, 49, 21, 62, 82, 54, 60, 84, 76, 0, 36, 56, 53, 53, 59, 56, 52, 59, 89, 46]
                                         ],
                                         playlistId: [20, 37, 40, 6, 11, 39, 52, 56, 56, 5, 92, 124, 2, 23, 51, 44, 36, 37, 26, 54, 47, 21, 105, 18],
                                         channelId: [20, 51, 40, 6, 11, 39, 52, 56, 56, 5, 92, 124, 2, 23, 51, 44, 36, 37, 26, 54, 47, 21, 105, 18])

    @MainActor
    var context: ModelContext { youtube.context }

    @MainActor
    public init(storage: Database,
                mock: [NetworkMockData]? = nil) {
        self.storage = storage
        self.mock = mock

        self.youtube = YouTubeAPI(credentials: credentials,
                                  mock: mock,
                                  storage: storage,
                                  language: "pt-BR",
                                  filter: Filter(
                                    // EpT: filtra Shorts via título "corte" e duração mínima de 3 min.
                                    // Termos MM-specific ("macmagazine", "no ar") removidos.
                                    title: ["corte"],
                                    duration: "03:00"
                                  ))
    }
}
