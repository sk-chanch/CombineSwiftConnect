//
//  ContentView.swift
//  CombineSwiftConnectExample
//
//  Created by Chanchana Koedtho on 1/11/2566 BE.
//

import SwiftUI
import Combine

class ContentViewViewModel{
    var cancellable = Set<AnyCancellable>()
    func api(){
        APIClient.shared.ability()
            .sink(receiveCompletion: {completion in
                switch completion {
                case .finished:
                    print("perfect!!")
                    
                case .failure(let error):
                    print("error \(error.errorInfo)")
                }
            }, receiveValue: { result in
               
                
                print(result.results.first?.name)
            })
            .store(in: &cancellable)
    }
}

struct ContentView: View {
    
    let viewModel = ContentViewViewModel()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
        .onAppear{
            viewModel.api()
        }
    }
    
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
