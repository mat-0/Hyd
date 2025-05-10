//  PreviewView.swift
//  Hyde

import Markdown
import SwiftUI

struct PreviewView: View {
    let text: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Preview")
                    .font(.headline)
                    .padding(.leading)
                Spacer()
                Button("Close") { dismiss() }
                    .padding(.trailing)
            }
            .frame(height: 44)
            .background(Color(.systemBackground))
            Divider()
            ScrollView {
                Text(text)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
        }
        .interactiveDismissDisabled(true)
    }
}

struct MarkdownContentView: View {
    let markdown: String
    var body: some View {
        if #available(iOS 15.0, macOS 12.0, *) {
            // Use the built-in Markdown view if available
            Text(.init(markdown))
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
        } else {
            // Fallback: show raw markdown
            ScrollView {
                Text(markdown)
                    .font(.body)
            }
        }
    }
}
