import '../models/tag_model.dart';
import '../models/transaction_model.dart';

abstract class IBalanceRepository {
  Future<String> createTag(TagModel tag);
  Future<int> updateTag(TagModel tag);
  Future<int> deleteTag(String id);
  Future<List<TagModel>> getAllTags();

  Future<String> createTransaction(TransactionModel transaction);
  Future<int> updateTransaction(TransactionModel transaction);
  Future<int> deleteTransaction(String id);
  Future<List<TransactionModel>> getTransactions({String? tagId});

  Future<void> setBudget(String monthYear, double amount);
  Future<double?> getBudget(String monthYear);
}

