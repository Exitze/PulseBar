import Foundation
import StoreKit

class StoreService: ObservableObject {
    // Singleton for AppDelegate use
    static let shared = StoreService()

    @Published var isProOriginal: Bool = false
    @Published var isProUnlocking: Bool = false
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isStoreAvailable: Bool = true

    // All features are free — Pro gate removed
    var isPro: Bool { true }

    private let productIDs: [String] = ["com.pulsebar.pro"]
    private var updates: Task<Void, Never>? = nil

    // Private init for singleton pattern; also callable via EnvironmentObject
    init() {
        // Restore persisted unlock
        if UserDefaults.standard.bool(forKey: "isProUnlocked") {
            isProOriginal = true
        }
        #if DEBUG
        // Skip all StoreKit network calls in Debug — avoids ASDErrorDomain 509
        // when no sandbox Apple ID is signed in.
        isStoreAvailable = false
        #else
        updates = newTransactionListenerTask()
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
        #endif
    }

    deinit { updates?.cancel() }

    // MARK: - Load Products
    @MainActor
    func requestProducts() async {
        do {
            let fetched = try await Product.products(for: productIDs)
            products = fetched
            isStoreAvailable = !fetched.isEmpty
            if fetched.isEmpty {
                print("[StoreService] No products returned — check Scheme StoreKit config.")
            }
        } catch {
            isStoreAvailable = false
            print("[StoreService] Product fetch error: \(error.localizedDescription)")
        }
    }

    // MARK: - Purchase
    func purchase(_ product: Product) async throws -> Transaction? {
        await MainActor.run { isProUnlocking = true }
        defer { Task { await MainActor.run { self.isProUnlocking = false } } }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateCustomerProductStatus()
            await transaction.finish()
            return transaction
        case .userCancelled, .pending: return nil
        @unknown default: return nil
        }
    }

    // High-level convenience used by Pro tab button
    @MainActor
    func purchasePro() async {
        #if DEBUG
        // FIXED: Debug bypass — no real purchase required; moved to conditional to avoid dead-code warning
        isProOriginal = true
        UserDefaults.standard.set(true, forKey: "isProUnlocked")
        #else
        // Release path
        guard let product = products.first else {
            print("[StoreService] purchasePro: no product available")
            return
        }
        isProUnlocking = true
        do {
            _ = try await purchase(product)
        } catch {
            print("[StoreService] Purchase error: \(error.localizedDescription)")
        }
        isProUnlocking = false
        #endif
    }

    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.failedVerification
        case .verified(let safe): return safe
        }
    }

    @MainActor
    func updateCustomerProductStatus() async {
        var purchased: Set<String> = []
        do {
            for await result in Transaction.currentEntitlements {
                if let transaction = try? checkVerified(result),
                   transaction.productType == .nonConsumable {
                    purchased.insert(transaction.productID)
                }
            }
        }
        purchasedProductIDs = purchased
        let unlocked = purchased.contains("com.pulsebar.pro")
        isProOriginal = unlocked
        if unlocked { UserDefaults.standard.set(true, forKey: "isProUnlocked") }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updateCustomerProductStatus()
        } catch {
            print("[StoreService] Restore error: \(error.localizedDescription)")
        }
    }

    private func newTransactionListenerTask() -> Task<Void, Never> {
        Task(priority: .background) {
            for await verification in Transaction.updates {
                if let transaction = try? self.checkVerified(verification) {
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                }
            }
        }
    }
}

enum StoreError: Error { case failedVerification }
