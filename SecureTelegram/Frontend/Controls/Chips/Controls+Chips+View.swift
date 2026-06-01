//
//  Controls+Chips+View.swift
//  SecureTelegram
//
//  Created by Codex on 31.05.2026.
//

import SwiftUI

extension Controls.Chips {

    struct View: SwiftUI.View {

        @ObservedObject var viewModel: Controls.Chips.ViewModel

        var body: some SwiftUI.View {

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.items) { item in
                        chip(item)
                    }
                }
                .padding(.vertical, 2)
            }
            .background(Color.clear)
        }

        private func chip(_ item: Controls.Chips.ViewModel.Item) -> some SwiftUI.View {

            let isSelected = viewModel.selectedItemID == item.id

            return Button {
                viewModel.didTapItem(item)
            } label: {
                Text(item.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.white : Color.text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(chipBackground(isSelected: isSelected), in: Capsule())
            }
            .buttonStyle(.plain)
        }

        private func chipBackground(isSelected: Bool) -> some ShapeStyle {

            if isSelected {
                return AnyShapeStyle(
                    LinearGradient(
                        colors: [
                            Color.registrationGradient1,
                            Color.registrationGradient2,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }

            return AnyShapeStyle(Color(.secondarySystemBackground))
        }

    } // View

} // Controls.Chips
