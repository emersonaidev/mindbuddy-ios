import SwiftUI

// MARK: - Optimized List Component

struct OptimizedList<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content
    let onLoadMore: (() -> Void)?
    
    @State private var visibleItems: Set<Item.ID> = []
    
    init(
        items: [Item],
        onLoadMore: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.onLoadMore = onLoadMore
        self.content = content
    }
    
    var body: some View {
        LazyVStack(spacing: Constants.UI.padding / 2) {
            ForEach(items) { item in
                content(item)
                    .onAppear {
                        handleItemAppearance(item)
                    }
                    .onDisappear {
                        visibleItems.remove(item.id)
                    }
            }
            
            // Load more trigger
            if let onLoadMore = onLoadMore {
                LoadMoreView(onLoadMore: onLoadMore)
            }
        }
    }
    
    private func handleItemAppearance(_ item: Item) {
        visibleItems.insert(item.id)
        
        // Trigger load more when reaching near the end
        if let onLoadMore = onLoadMore,
           let lastItem = items.last,
           item.id == lastItem.id {
            onLoadMore()
        }
    }
}

// MARK: - Load More View

private struct LoadMoreView: View {
    let onLoadMore: () -> Void
    @State private var isLoading = false
    
    var body: some View {
        HStack {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Loading more...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Tap to load more")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .onTapGesture {
            loadMore()
        }
        .onAppear {
            // Auto-load when view appears
            loadMore()
        }
    }
    
    private func loadMore() {
        guard !isLoading else { return }
        
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onLoadMore()
            isLoading = false
        }
    }
}

// MARK: - Cached Image View for Performance

struct CachedImageView: View {
    let url: URL?
    let placeholder: String
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
                    .frame(width: 40, height: 40)
            } else {
                Image(systemName: placeholder)
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let url = url, image == nil, !isLoading else { return }
        
        isLoading = true
        
        // Check cache first
        if let cachedImage = ImageCache.shared.image(for: url) {
            self.image = cachedImage
            self.isLoading = false
            return
        }
        
        // Load from network
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let data = data, let uiImage = UIImage(data: data) {
                    self.image = uiImage
                    ImageCache.shared.setImage(uiImage, for: url)
                }
            }
        }.resume()
    }
}

// MARK: - Simple Image Cache

class ImageCache {
    static let shared = ImageCache()
    
    private let cache = NSCache<NSURL, UIImage>()
    
    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    func image(for url: URL) -> UIImage? {
        return cache.object(forKey: url as NSURL)
    }
    
    func setImage(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}

// MARK: - Optimized Card Component

struct OptimizedCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(Constants.UI.padding)
            .background(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: Color.black.opacity(0.1),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            )
    }
}

// MARK: - Memory-Efficient Health Data Row

struct HealthDataRow: View {
    let healthData: HealthData
    
    // Pre-computed values to avoid recalculation
    private var formattedValue: String {
        switch healthData.value {
        case .number(let value):
            if value.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(value))"
            } else {
                return String(format: "%.1f", value)
            }
        case .string(let value):
            return value
        case .object, .array:
            return "N/A"
        }
    }
    
    private var iconName: String {
        switch healthData.type {
        case "heartRate":
            return "heart.fill"
        case "steps":
            return "figure.walk"
        case "bloodPressure":
            return "heart.text.square"
        default:
            return "heart"
        }
    }
    
    var body: some View {
        OptimizedCard {
            HStack {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(.red)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(healthData.type.capitalized)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(healthData.recordedAt.formatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(formattedValue)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        OptimizedList(
            items: [
                HealthData(
                    type: "heartRate",
                    value: .double(72.5),
                    unit: "bpm",
                    recordedAt: Date()
                )
            ]
        ) { healthData in
            HealthDataRow(healthData: healthData)
        }
    }
    .padding()
}