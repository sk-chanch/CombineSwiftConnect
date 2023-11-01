//
//  APIClient.swift
//  CombineSwiftConnectExample
//
//  Created by Chanchana Koedtho on 1/11/2566 BE.
//

import Foundation
import CombineSwiftConnect
import Combine

class APIClient{
    static let shared = APIClient()
    
    lazy var requester:Requester = {
        .init(initBaseUrl: "https://pokeapi.co/api/v2/",
              timeout: 15,
              isPreventPinning: false,
              initSessionConfig: .default)
    }()
    
    func ability()->AnyPublisher<Result<PokemonResult, CustomError>, Never>{
        requester.get(path: "ability/?limit=20&offset=20")
    }
}
