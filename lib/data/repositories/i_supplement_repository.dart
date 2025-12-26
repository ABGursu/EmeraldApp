import '../models/ingredient_model.dart';
import '../models/product_model.dart';
import '../models/product_composition_model.dart';
import '../models/supplement_log_model.dart';
import '../models/supplement_log_detail_model.dart';

/// Interface for the supplement module repository.
abstract class ISupplementRepository {
  // === Ingredients Library ===
  Future<List<IngredientModel>> getAllIngredients();
  Future<IngredientModel?> getIngredientById(String id);
  Future<String> createIngredient(IngredientModel ingredient);
  Future<int> updateIngredient(IngredientModel ingredient);
  Future<int> deleteIngredient(String id);

  // === Products ===
  Future<List<ProductModel>> getAllProducts({bool includeArchived = false});
  Future<ProductModel?> getProductById(String id);
  Future<String> createProduct(ProductModel product);
  Future<int> updateProduct(ProductModel product);
  Future<int> deleteProduct(String id);
  Future<int> archiveProduct(String id);

  // === Product Composition ===
  Future<List<ProductCompositionModel>> getProductComposition(String productId);
  Future<void> setProductComposition(
      String productId, List<ProductCompositionModel> composition);

  // === Supplement Logs ===
  Future<List<SupplementLogModel>> getLogs({DateTime? from, DateTime? to});
  Future<SupplementLogModel?> getLogById(String id);
  Future<String> createLog(
      SupplementLogModel log, List<SupplementLogDetailModel> details);
  Future<int> deleteLog(String id);
  Future<List<SupplementLogDetailModel>> getLogDetails(String logId);

  // === Analytics ===
  /// Returns total intake by ingredient name for a given date range.
  Future<Map<String, ({double amount, String unit})>> getTotalIntake({
    required DateTime from,
    required DateTime to,
  });
}

