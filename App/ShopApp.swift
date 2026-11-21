import SwiftUI

@main
struct ShopApp: App {
  var body: some Scene {
    WindowGroup { ShopView() }
  }
}

struct Product: Decodable, Identifiable {
  let id: String
  let name: String
  let price: Int
}

struct ProductList: Decodable {
  let items: [Product]
}

@MainActor
@Observable
final class ShopModel {
  var products: [Product] = []
  var status = "Loading"

  let baseURL: URL
  let mockState: String?

  init() {
    let environment = ProcessInfo.processInfo.environment
    baseURL = URL(string: environment["API_BASE_URL"] ?? "https://api.shop.example.test")!
    mockState = environment["MOCK_STATE"]
  }

  func load() async {
    do {
      let (data, _) = try await URLSession.shared.data(from: baseURL.appending(path: "products"))
      products = try JSONDecoder().decode(ProductList.self, from: data).items
      status = "Ready"
    } catch {
      status = "Could not load products"
    }
  }

  func buy() async {
    var request = URLRequest(url: baseURL.appending(path: "orders"))
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(UUID().uuidString, forHTTPHeaderField: "Idempotency-Key")
    if let mockState {
      request.setValue(mockState, forHTTPHeaderField: "x-mock-state")
    }
    request.httpBody = Data(#"{"productId":"p1","quantity":1}"#.utf8)
    do {
      let (_, response) = try await URLSession.shared.data(for: request)
      switch (response as? HTTPURLResponse)?.statusCode ?? 0 {
      case 200..<300: status = "Order placed"
      case 402: status = "Payment declined"
      case let code: status = "Order failed (\(code))"
      }
    } catch {
      status = "Network error"
    }
  }
}

struct ShopView: View {
  @State private var model = ShopModel()

  var body: some View {
    NavigationStack {
      List(model.products) { product in
        LabeledContent(product.name, value: (Double(product.price) / 100).formatted(.currency(code: "USD")))
      }
      .navigationTitle("Shop")
      .safeAreaInset(edge: .bottom) {
        VStack(spacing: 12) {
          Text(model.status)
            .font(.title2.bold())
            .foregroundStyle(statusColor)
            .accessibilityIdentifier("status")
          Button("Buy") {
            Task { await model.buy() }
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.large)
          .accessibilityIdentifier("buy")
          VStack(spacing: 2) {
            Text("API: \(model.baseURL.absoluteString)")
            if let mockState = model.mockState {
              Text("x-mock-state: \(mockState)")
            }
          }
          .font(.footnote.monospaced())
          .foregroundStyle(.secondary)
        }
        .padding()
      }
    }
    .task { await model.load() }
  }

  private var statusColor: Color {
    switch model.status {
    case "Order placed": .green
    case "Payment declined", "Network error", "Could not load products": .red
    default: .primary
    }
  }
}
