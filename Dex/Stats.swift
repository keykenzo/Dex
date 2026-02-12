//
//  Stats.swift
//  Dex
//
//  Created by Mario Duarte on 09/02/26.
//

import SwiftUI
import Charts

struct Stats: View {
    var pokemon: Pokemon
    
    var body: some View {
        
        
        Chart(pokemon.stats) { stat in
        BarMark (
            x: .value("Value", stat.value),
            y: .value("Stat", stat.name)
                )
        .cornerRadius(10)
        .annotation(position: .trailing) {
            Text("\(stat.value)")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.top, -5)
            }
        }
        .frame(height: 250)
        .padding([.horizontal, .bottom])
        .foregroundStyle(pokemon.typeColor)
        .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.subheadline.bold())
                }
            }
        .chartXScale(domain: 0...pokemon.highestStat.value + 20)
        
        VStack(alignment: .leading, spacing: 10) {
            Label("Moveset", systemImage: "bolt.shield.fill")
                .font(.headline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(pokemon.moves.prefix(4), id: \.self) { move in
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(.primary.opacity(0.5))
                        
                        Text(move.capitalized)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
    }
}

#Preview {
    Stats(pokemon: PersistenceController.previewPokemon)
}
