//
//  Moves.swift
//  Dex
//
//  Created by Mario Duarte on 11/02/26.
//

import SwiftUI
import Charts

struct Moves: View {
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
            }
        }
        .chartXScale(domain: 0...pokemon.highestStat.value + 20)
    }
    
}

#Preview {
    Moves(pokemon: PersistenceController.previewPokemon)
}
