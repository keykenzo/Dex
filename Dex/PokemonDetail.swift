//
//  PokemonDetail.swift
//  Dex
//
//  Created by Mario Duarte on 09/02/26.
//

import SwiftUI
import SwiftData


struct PokemonDetail: View {
    @Environment(\.modelContext) private var modelContext
    
    var pokemon: Pokemon
    
    @State private var showShiny = false
    
    var body: some View {
        ScrollView {
            ZStack {
                Image(pokemon.background)
                    .resizable()
                    .scaledToFit()
                if pokemon.sprite == nil || pokemon.shiny == nil {
                    AsyncImage(url: showShiny ? pokemon.shinyURL: pokemon.spriteURL) { image in
                        image
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .padding(.top, 10)
                            .shadow(color: .black, radius: 6)
                    } placeholder: {
                        ProgressView()
                    }
                } else {
                    (showShiny ? pokemon.shinyImage : pokemon.spriteImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .padding(.top, 50)
                        .shadow(color: .black, radius: 6)
                }
            }
            
            Text("\(pokemon.name.capitalized ) Gallery")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.top, .leading])
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    // Criamos um array com as URLs que queremos exibir
                    let images = [
                        pokemon.spriteURL,      // Frente Normal
                        pokemon.backURL,        // Costas Normal
                        pokemon.shinyURL,       // Frente Shiny
                        pokemon.backShinyURL    // Costas Shiny
                    ]
                    
                    ForEach(images, id: \.self) { url in
                        AsyncImage(url: url) { image in
                            image
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .padding(10)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .shadow(radius: 2)
                        } placeholder: {
                            ProgressView()
                                .frame(width: 120, height: 120)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            HStack {
                ForEach(pokemon.types, id: \.self) { type in
                    Text(type.capitalized)
                        .font(.title2)
                        .foregroundStyle(.black)
                        .padding(.vertical, 7)
                        .padding(.horizontal)
                        .background(Color(type.capitalized))
                        .clipShape(.capsule)
                }
                
                Spacer()
                
                Button {
                    pokemon.favorite.toggle()
                    do {
                        try modelContext.save()
                    } catch {
                         print(error)
                    }
                } label: {
                    Image(systemName: pokemon.favorite ? "star.fill" : "star")
                        .font(.largeTitle)
                        .tint(.yellow)
                }
            }
            .padding()
            
            Text("Stats")
                .font(.title)
                .padding(.bottom, -5)
            Stats(pokemon: pokemon)
        }
        .navigationTitle(pokemon.name.capitalized)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showShiny.toggle()
                } label: {
                    Image(systemName: showShiny ? "wand.and.stars" : "wand.and.stars.inverse")
                }
                .tint(showShiny ? .yellow : .primary)
            }
        }
    }
}

#Preview {
    NavigationStack{
        PokemonDetail(pokemon:  PersistenceController.previewPokemon)
    }
}
